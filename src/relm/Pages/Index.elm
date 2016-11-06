module Pages.Index exposing (Model, Msg(..), init, update, view, subscriptions)

import Html exposing (Html, text, ul, li, a, h1, div, input, label, form)
import Html.Attributes exposing (type', checked, value, tabindex)
import Html.Events exposing (onClick, onBlur, onInput, onSubmit)
import Html.App
import RemoteData as RD
import Http
import Array exposing (Array)
import Time exposing (Time)
import Date exposing (Date)
import Dict exposing (Dict)
import Date.Extra.Duration as Duration exposing (Duration, zeroDelta)
import String
import String.Extra as String
import Task
import Basics.Extra exposing (never)
import Json.Decode as JD exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Json.Encode as JE


-- extra
-- ours

import Api.Apps as Apps
import Components.App as App
import Helpers exposing (imap, rdpimap, iamap, class, withCrash, first3, third3)
import RCSS
import Out
import Ports


type alias Model =
    { apps : RD.WebData (Array App.Model)
    , timer : Bool
    , timerPeriod :
        Int
        -- number of seconds
    , timerCurrent :
        Int
        -- number of seconds since start of timer
    , json : Maybe String
    , floor : Int
    , floorI : String
    , floorE : Bool
    , ceiling : Int
    , ceilingI : String
    , ceilingE : Bool
    , globalLevel : Bool
    , windowSelectorOpen : Bool
    , window : Window
    , absoluteWindow :
        -- this decides if start or start0 + now is to be used
        Bool
    , startI : String
    , endI : String
    , startE : Bool
    , endE : Bool
    , now : Maybe Date
    , store : Dict String String
    }


init : List ( String, String ) -> Model
init store =
    { apps = RD.NotAsked
    , timer = False
    , timerPeriod = 60
    , timerCurrent = 0
    , json = Nothing
    , floor = 0
    , floorI = "0"
    , floorE = False
    , ceiling =
        -- 5 sec
        5000000000
    , ceilingI = "5s"
    , ceilingE = False
    , globalLevel = True
    , absoluteWindow = False
    , window =
        { start = RelativeDate Duration.Minute -10
        , end = RelativeDate Duration.Minute 0
        }
    , windowSelectorOpen = False
    , now = Nothing
    , startI = "-10 minute"
    , endI = "now"
    , startE = False
    , endE = False
    , store = Dict.fromList store
    }
        |> readKey "timer" (\v m -> { m | timer = v == "True" })
        |> readKey "global_level" (\v m -> { m | globalLevel = v == "True" })
        |> readKey "floor_i" (\v m -> { m | floorI = v })
        |> readKey "ceiling_i" (\v m -> { m | ceilingI = v })
        |> readKey "floor"
            (\v m ->
                { m
                    | floor =
                        (String.toInt v
                            |> Result.toMaybe
                            |> Maybe.withDefault 0
                        )
                }
            )
        |> readKey "ceiling"
            (\v m ->
                { m
                    | ceiling =
                        (String.toInt v
                            |> Result.toMaybe
                            |> Maybe.withDefault 5000000000
                        )
                }
            )
        |> readKey "window"
            (\v m ->
                setWindow
                    (JD.decodeString window v
                        |> Result.toMaybe
                        |> Maybe.withDefault
                            { start = RelativeDate Duration.Minute -10
                            , end = RelativeDate Duration.Minute 0
                            }
                    )
                    m
            )


str2dur : String -> JD.Decoder Duration
str2dur val =
    case val of
        "Millisecond" ->
            JD.succeed Duration.Millisecond

        "Second" ->
            JD.succeed Duration.Second

        "Minute" ->
            JD.succeed Duration.Minute

        "Hour" ->
            JD.succeed Duration.Hour

        "Day" ->
            JD.succeed Duration.Day

        "Week" ->
            JD.succeed Duration.Week

        "Month" ->
            JD.succeed Duration.Month

        "Year" ->
            JD.succeed Duration.Year

        _ ->
            JD.fail ("unknown val " ++ val)


zero : Duration
zero =
    Duration.Delta zeroDelta


tenMins : Duration
tenMins =
    Duration.Delta { zeroDelta | minute = -10 }


oneHr : Duration
oneHr =
    Duration.Delta { zeroDelta | minute = -60 }


readKey : String -> (String -> Model -> Model) -> Model -> Model
readKey key fn model =
    case Dict.get ("index__" ++ key) model.store of
        Just v ->
            fn v model

        Nothing ->
            model


resolve : DateSpec -> Date -> Date
resolve d now =
    case d of
        AbsoluteDate d ->
            d

        RelativeDate d c ->
            Duration.add d c now


start : Model -> Date
start model =
    resolve model.window.start (withCrash model.now)


end : Model -> Date
end model =
    resolve model.window.end (withCrash model.now)


type DateSpec
    = AbsoluteDate Date
    | RelativeDate Duration Int


datespec2 : String -> JD.Decoder DateSpec
datespec2 tag =
    case tag of
        "absolute" ->
            JD.succeed AbsoluteDate
                |: ("date" := JD.map Date.fromTime JD.float)

        "relative" ->
            JD.succeed RelativeDate
                |: ("duration" := JD.string `JD.andThen` str2dur)
                |: ("count" := JD.int)

        _ ->
            JD.fail ("Invalid tag " ++ tag)


datespec : JD.Decoder DateSpec
datespec =
    ("tag" := JD.string `JD.andThen` datespec2)


window : JD.Decoder Window
window =
    JD.succeed Window
        |: ("start" := datespec)
        |: ("end" := datespec)


type alias Window =
    { start : DateSpec, end : DateSpec }


datespec_encoder : DateSpec -> JE.Value
datespec_encoder d =
    case d of
        RelativeDate d c ->
            JE.object
                [ ( "tag", JE.string "relative" )
                , ( "duration", JE.string (toString d) )
                , ( "count", JE.int c )
                ]

        AbsoluteDate d ->
            JE.object
                [ ( "tag", JE.string "absolute" )
                , ( "date", JE.float (Date.toTime d) )
                ]


window_json : Window -> String
window_json w =
    let
        encoder =
            JE.object
                [ ( "start", datespec_encoder w.start )
                , ( "end", datespec_encoder w.end )
                ]
    in
        JE.encode 4 encoder


type Msg
    = Viewed
    | CurrentTime Time.Time
    | AppsFetched (List Apps.App)
    | AppsFailed Http.Error
    | AppMsg Int App.Msg
    | TimerToggle
    | Tick Time.Time
    | HideJson
    | ToggleGlobalLevel
    | OnFloor String
    | CommitFloor
    | OnCeiling String
    | CommitCeiling
    | ToggleWindowSelector
    | SetWindow Window
    | SetStart String
    | SetEnd String
    | CommitWindow
      -- List (spec, err, id, (floor, ceiling), List Point)
    | GraphDataFetched (List ( String, String, String, ( Int, Int ), List ( Int, Int ) ))


graphToApp :
    Int
    -> ( String, String, String, ( Int, Int ), List ( Int, Int ) )
    -> Model
    -> Model
graphToApp idx ( spec, err, id, ( floor, ceiling ), points ) model =
    let
        name =
            String.leftOf ":" spec

        rest =
            String.rightOf ":" spec
    in
        case model.apps of
            RD.Success apps ->
                case Array.get idx apps of
                    Just app ->
                        if app.name == name then
                            { model
                                | apps =
                                    RD.Success <|
                                        Array.set idx
                                            (App.graphToViews
                                                0
                                                ( rest
                                                , err
                                                , id
                                                , ( floor, ceiling )
                                                , points
                                                )
                                                app
                                            )
                                            apps
                            }
                        else
                            graphToApp
                                (idx + 1)
                                ( spec, err, id, ( floor, ceiling ), points )
                                model

                    Nothing ->
                        model

            _ ->
                model


updateApps :
    (App.Model -> ( App.Model, Cmd App.Msg, List Out.Msg ))
    -> Model
    -> Cmd Msg
    -> ( Model, Cmd Msg )
updateApps fn model cmd =
    case model.apps of
        RD.Success apps ->
            let
                result =
                    (Array.map fn apps)

                apps =
                    Array.map first3 result

                cmds =
                    iamap (\( i, ( a, c, m ) ) -> Cmd.map (AppMsg i) c) result
            in
                ( { model | apps = RD.Success apps }
                , Cmd.batch (cmd :: cmds)
                , List.concat <| List.map third3 <| Array.toList result
                )
                    |> handleOutMsgs

        _ ->
            ( model, cmd )


updateLevels : Model -> Cmd Msg -> ( Model, Cmd Msg )
updateLevels model cmd =
    updateApps
        (App.updateLevels
            model.floor
            model.floorI
            model.ceiling
            model.ceilingI
            model.globalLevel
        )
        model
        cmd


win2strs : Window -> ( String, String )
win2strs w =
    ( case w.start of
        AbsoluteDate d ->
            (toString d)

        RelativeDate d c ->
            (duration2text d c)
    , case w.end of
        AbsoluteDate d ->
            (toString d)

        RelativeDate d c ->
            (duration2text d c)
    )


setWindow : Window -> Model -> Model
setWindow window model =
    let
        ( startI, endI ) =
            win2strs window
    in
        { model | window = window, startI = startI, endI = endI }


updateWindow : Model -> ( Model, Cmd Msg )
updateWindow m =
    updateApps
        (App.updateWindow (start m) (end m))
        m
        Cmd.none


parseInt : String -> Int -> ( Int, Bool )
parseInt val fac =
    let
        res =
            String.toInt val
    in
        case res of
            Err err ->
                ( 0, False )

            Ok i ->
                ( i * fac, True )


parseTime : String -> ( Int, Bool )
parseTime val =
    if String.endsWith "ns" val then
        parseInt (String.dropRight 2 val) 1
    else if String.endsWith "us" val then
        parseInt (String.dropRight 2 val) 1000
    else if String.endsWith "ms" val then
        parseInt (String.dropRight 2 val) 1000000
    else if String.endsWith "sec" val then
        parseInt (String.dropRight 3 val) 1000000000
    else if String.endsWith "m" val then
        parseInt (String.dropRight 1 val) 60000000000
    else if String.endsWith "min" val then
        parseInt (String.dropRight 3 val) 60000000000
    else if String.endsWith "mins" val then
        parseInt (String.dropRight 4 val) 60000000000
    else if String.endsWith "hr" val then
        parseInt (String.dropRight 2 val) 3600000000000
    else if String.endsWith "hrs" val then
        parseInt (String.dropRight 5 val) 3600000000000
    else if String.endsWith "s" val then
        parseInt (String.dropRight 1 val) 1000000000
    else
        parseInt val 1000000000


extractGraphFromOutMsgs : List Out.Msg -> List ( String, String )
extractGraphFromOutMsgs list =
    case list of
        [] ->
            []

        first :: rest ->
            case first of
                Out.LoadURL app view ->
                    ( app, view ) :: extractGraphFromOutMsgs rest

                _ ->
                    extractGraphFromOutMsgs rest


extractJSONFromOutMsgs : List Out.Msg -> Maybe String
extractJSONFromOutMsgs list =
    case list of
        [] ->
            Nothing

        first :: rest ->
            case first of
                Out.ShowJson json ->
                    Just json

                _ ->
                    extractJSONFromOutMsgs rest


handleOutMsgs : ( Model, Cmd Msg, List Out.Msg ) -> ( Model, Cmd Msg )
handleOutMsgs ( model, cmd, list ) =
    let
        graphs =
            extractGraphFromOutMsgs list

        json =
            extractJSONFromOutMsgs list
    in
        ( { model | json = json }
        , Cmd.batch <|
            [ cmd
            , Ports.getGraphs
                (List.map
                    (\( app, view ) ->
                        ( app, view, "" )
                    )
                    graphs
                )
                (start model)
                (end model)
                model.floor
                model.ceiling
            ]
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Viewed ->
            ( { model | apps = RD.Loading }
            , Cmd.batch
                [ Ports.title "welcome"
                , Time.now
                    |> Task.perform never CurrentTime
                ]
            )

        CurrentTime now ->
            ( { model | now = Just (Date.fromTime now) }
            , Apps.getAppList AppsFailed AppsFetched
            )

        TimerToggle ->
            ( { model | timer = not model.timer }
            , Ports.set_key ( "index__timer", (toString <| not model.timer) )
            )

        ToggleGlobalLevel ->
            updateLevels { model | globalLevel = not model.globalLevel }
                (Ports.set_key
                    ( "index__global_level", (toString <| not model.globalLevel) )
                )

        ToggleWindowSelector ->
            ( { model | windowSelectorOpen = not model.windowSelectorOpen }
            , Cmd.none
            )

        SetWindow w ->
            let
                ( model, cmd ) =
                    updateWindow
                        (setWindow w { model | windowSelectorOpen = False })
            in
                ( model
                , Cmd.batch
                    [ cmd
                    , Ports.set_key ( "index__window", window_json model.window )
                    ]
                )

        SetStart str ->
            ( { model | startI = str }, Cmd.none )

        SetEnd str ->
            ( { model | endI = str }, Cmd.none )

        CommitWindow ->
            ( { model | windowSelectorOpen = False }, Cmd.none )

        OnFloor val ->
            let
                ( v, ok ) =
                    parseTime val
            in
                if ok then
                    ( { model | floor = v, floorI = val, floorE = False }
                    , Ports.set_keys
                        [ ( "index__floor", (toString v) )
                        , ( "index__floor_i", val )
                        ]
                    )
                else
                    ( { model | floorI = val, floorE = True }, Cmd.none )

        OnCeiling val ->
            let
                ( v, ok ) =
                    parseTime val
            in
                if ok then
                    ( { model | ceiling = v, ceilingI = val, ceilingE = False }
                    , Ports.set_keys
                        [ ( "index__ceiling", (toString v) )
                        , ( "index__ceiling_i", val )
                        ]
                    )
                else
                    ( { model | ceilingI = val, ceilingE = True }, Cmd.none )

        CommitFloor ->
            if model.floorE then
                ( model, Cmd.none )
            else
                updateLevels model Cmd.none

        CommitCeiling ->
            if model.ceilingE then
                ( model, Cmd.none )
            else
                updateLevels model Cmd.none

        Tick now ->
            if model.timer then
                let
                    current =
                        model.timerCurrent + 1
                in
                    if current == model.timerPeriod then
                        updateWindow
                            { model
                                | timerCurrent = 0
                                , now = Just (Date.fromTime now)
                            }
                    else
                        ( { model | timerCurrent = current }, Cmd.none )
            else
                ( model, Cmd.none )

        AppsFetched apps ->
            let
                ( models, cmds, lmsg ) =
                    Helpers.unzip3
                        (List.map
                            (App.init model.floor
                                model.floorI
                                model.ceiling
                                model.ceilingI
                                model.globalLevel
                                model.store
                                (start model)
                                (end model)
                            )
                            apps
                        )
            in
                ( { model
                    | apps = RD.Success (Array.fromList models)
                  }
                , Cmd.batch (imap (\( i, cmd ) -> Cmd.map (AppMsg i) cmd) cmds)
                , List.concat lmsg
                )
                    |> handleOutMsgs

        AppsFailed err ->
            ( { model | apps = RD.Failure err }, Cmd.none )

        HideJson ->
            ( { model | json = Nothing }, Cmd.none )

        GraphDataFetched list ->
            ( List.foldr (graphToApp 0) model list, Cmd.none )

        AppMsg idx msg ->
            case model.apps of
                RD.Success apps ->
                    let
                        app =
                            Array.get idx apps

                        res =
                            Maybe.map (\app -> App.update msg app) app
                    in
                        case res of
                            Just ( iapp, icmd, lout ) ->
                                ( { model
                                    | apps =
                                        RD.Success
                                            (Array.set idx iapp apps)
                                  }
                                , Cmd.map (AppMsg idx) icmd
                                , lout
                                )
                                    |> handleOutMsgs

                            Nothing ->
                                Debug.crash "impossible"

                _ ->
                    Debug.crash "impossible"


levelSelector : Model -> Html Msg
levelSelector model =
    if model.globalLevel then
        div [ class [ RCSS.LevelSelector ] ]
            [ div []
                [ label [] [ text "Ceiling" ]
                , input
                    [ value model.ceilingI
                    , onInput OnCeiling
                    , onBlur CommitCeiling
                    , (if model.ceilingE then
                        class [ RCSS.WindowError ]
                       else
                        class []
                      )
                    ]
                    []
                ]
            , div
                [ if model.floorE then
                    class [ RCSS.WindowError ]
                  else
                    class []
                ]
                [ label [] [ text "Floor" ]
                , input
                    [ value model.floorI
                    , onInput OnFloor
                    , onBlur CommitFloor
                    , tabindex -1
                    ]
                    []
                ]
            ]
    else
        text ""


datespec2text : DateSpec -> String
datespec2text ds =
    case ds of
        RelativeDate d c ->
            (toString c) ++ " " ++ (toString d)

        AbsoluteDate d ->
            (toString d)


windowLink : Duration -> Int -> Model -> Html.Html Msg
windowLink d count model =
    let
        selected =
            case model.window.start of
                RelativeDate d1 c1 ->
                    d1 == d && c1 == count

                _ ->
                    False
    in
        a
            ([ onClick
                (SetWindow
                    { start = RelativeDate d count
                    , end = RelativeDate Duration.Minute 0
                    }
                )
             ]
                ++ if selected then
                    [ class [ RCSS.WindowSelected ] ]
                   else
                    []
            )
            [ text <| (duration2text d count) ++ " → now" ]


windowSelector : Model -> Html Msg
windowSelector model =
    if model.windowSelectorOpen then
        div [ class [ RCSS.WindowSelector ] ]
            [ windowLink Duration.Minute -10 model
            , windowLink Duration.Hour -1 model
            , windowLink Duration.Hour -6 model
            , windowLink Duration.Day -1 model
            , windowLink Duration.Day -2 model
            , windowLink Duration.Day -7 model
            , form [ onSubmit CommitWindow ]
                [ label [] [ text "Start", input [ onInput SetStart, value model.startI ] [] ]
                , label [] [ text "End", input [ onInput SetEnd, value model.endI ] [] ]
                , input [ type' "submit", value " ", class [ RCSS.Hidden ] ]
                    []
                ]
            ]
    else
        text ""


duration2text : Duration -> Int -> String
duration2text d count =
    if count == 0 then
        "now"
    else
        (toString count)
            ++ " "
            ++ case d of
                Duration.Millisecond ->
                    "millisecond"

                Duration.Second ->
                    "second"

                Duration.Minute ->
                    "minute"

                Duration.Hour ->
                    "hour"

                Duration.Day ->
                    "day"

                Duration.Week ->
                    "week"

                Duration.Month ->
                    "month"

                Duration.Year ->
                    "year"

                _ ->
                    Debug.crash "impossible"


windowText : Model -> Html Msg
windowText model =
    let
        ( start, end ) =
            win2strs model.window
    in
        text (start ++ " → " ++ end)


view : Model -> Html Msg
view model =
    let
        jsoncontent =
            case model.json of
                Nothing ->
                    text ""

                Just json ->
                    div [] [ text json, div [ onClick HideJson ] [ text "X" ] ]

        content =
            case model.apps of
                RD.Success apps ->
                    (imap
                        (\( i, a ) -> Html.App.map (AppMsg i) (App.view a))
                        (Array.toList apps)
                    )

                RD.Loading ->
                    [ text "loading.." ]

                RD.NotAsked ->
                    [ text "Not asked" ]

                RD.Failure err ->
                    [ text (toString err) ]
    in
        div [ class [ RCSS.Main ] ]
            ([ div [ class [ RCSS.Header ] ]
                [ h1 [] [ text "rtime: Coverfox" ]
                , div [ class [ RCSS.HMenu ] ]
                    [ a
                        [ onClick ToggleWindowSelector
                        , class
                            ([ RCSS.Link ]
                                ++ (if model.windowSelectorOpen then
                                        [ RCSS.ALink ]
                                    else
                                        []
                                   )
                            )
                        ]
                        [ windowText model ]
                    , windowSelector model
                    , input
                        [ type' "checkbox"
                        , checked model.timer
                        , onClick TimerToggle
                        ]
                        []
                    , a [ onClick TimerToggle ]
                        [ text
                            (if model.timer then
                                toString
                                    (model.timerPeriod - model.timerCurrent)
                             else
                                "paused"
                            )
                        ]
                    , input
                        [ type' "checkbox"
                        , onClick ToggleGlobalLevel
                        , checked model.globalLevel
                        ]
                        []
                    , levelSelector model
                    ]
                ]
             ]
                ++ content
                ++ [ jsoncontent ]
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        (if model.timer then
            Time.every Time.second Tick
         else
            Sub.none
        )
            :: [ Ports.graphsData GraphDataFetched ]
