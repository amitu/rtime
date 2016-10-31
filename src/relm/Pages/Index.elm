module Pages.Index exposing (Model, Msg(..), init, update, view, subscriptions)

import Html exposing (Html, text, ul, li, a, h1, div, input, label)
import Html.Attributes exposing (type', checked, value)
import Html.Events exposing (onClick, onBlur, onInput)
import Html.App
import RemoteData as RD
import Http
import Array exposing (Array)
import Time exposing (Time)
import Date exposing (Date)
import Date.Extra.Duration as Duration exposing (Duration, zeroDelta)
import String


-- extra
-- ours

import Api.Apps as Apps
import Components.App as App
import Helpers exposing (imap, rdpimap, iamap, class)
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
    , absoluteWindow : Bool
    , start : Maybe Date
    , startO : Duration
    , endO : Duration
    , end : Maybe Date
    , now : Maybe Date
    }


init : Model
init =
    { apps = RD.NotAsked
    , timer = False
    , timerPeriod = 30
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
    , end = Nothing
    , start = Nothing
    , absoluteWindow = False
    , startO = Duration.Delta { zeroDelta | minute = -10 }
    , endO = Duration.Delta zeroDelta
    , now = Nothing
    }


type Msg
    = Viewed
    | AppsFetched (List Apps.App)
    | AppsFailed Http.Error
    | AppMsg Int App.Msg
    | TimerToggle
    | Tick Time.Time
    | HideJson
    | KeysData (List ( String, ( Bool, String ) ))
    | ToggleGlobalLevel
    | OnFloor String
    | CommitFloor
    | OnCeiling String
    | CommitCeiling


updateApps :
    (App.Model -> ( App.Model, Cmd App.Msg ))
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
                    Array.map fst result

                cmds =
                    iamap (\( i, ( a, c ) ) -> Cmd.map (AppMsg i) c) result
            in
                ( { model | apps = RD.Success apps }, Cmd.batch (cmd :: cmds) )

        _ ->
            ( model, cmd )


updateLevels : Model -> Cmd Msg -> ( Model, Cmd Msg )
updateLevels model cmd =
    updateApps (App.updateLevels model.floor model.ceiling model.globalLevel) model cmd


updateWindow : Model -> ( Model, Cmd Msg )
updateWindow model =
    let
        ( start, end ) =
            window model
    in
        updateApps (App.updateWindow start end) model Cmd.none


withCrash : Maybe a -> a
withCrash maybe =
    case maybe of
        Just v ->
            v

        Nothing ->
            Debug.crash "Impossible"


window : Model -> ( Date, Date )
window model =
    if model.absoluteWindow then
        ( withCrash model.start, withCrash model.end )
    else
        let
            now =
                withCrash model.now
        in
            ( Duration.add model.startO 1 now, Duration.add model.endO 1 now )


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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "P.Index" msg of
        Viewed ->
            ( { model | apps = RD.Loading }
            , Cmd.batch
                [ Ports.title "welcome"
                , Ports.get_keys
                    [ "index__global_level"
                    , "index__floor"
                    , "index__floor_i"
                    , "index__ceiling"
                    , "index__ceiling_i"
                    , "index__timer"
                    ]
                ]
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
            updateWindow model

        CommitCeiling ->
            updateWindow model

        Tick _ ->
            if model.timer then
                let
                    current =
                        model.timerCurrent + 1
                in
                    if current == model.timerPeriod then
                        -- TODO: not so easy, if windows are abs, then ok, else
                        -- get current time, calcualte new window and then call
                        -- update window
                        updateWindow { model | timerCurrent = 0 }
                    else
                        ( { model | timerCurrent = current }, Cmd.none )
            else
                ( model, Cmd.none )

        AppsFetched apps ->
            let
                ( models, cmds ) =
                    List.unzip
                        (List.map
                            (App.init model.floor model.ceiling model.globalLevel)
                            apps
                        )
            in
                ( { model
                    | apps = RD.Success (Array.fromList models)
                  }
                , Cmd.batch (imap (\( i, cmd ) -> Cmd.map (AppMsg i) cmd) cmds)
                )

        AppsFailed err ->
            ( { model | apps = RD.Failure err }, Cmd.none )

        HideJson ->
            ( { model | json = Nothing }, Cmd.none )

        KeysData list ->
            ( List.foldl
                (\( k, ( ok, v ) ) model ->
                    if not ok || v == "" then
                        model
                    else if k == "index__timer" then
                        { model | timer = v == "True" }
                    else if k == "index__global_level" then
                        { model | globalLevel = v == "True" }
                    else if k == "index__floor" then
                        { model
                            | floor =
                                (String.toInt v
                                    |> Result.toMaybe
                                    |> Maybe.withDefault 0
                                )
                            , floorE = False
                        }
                    else if k == "index__floor_i" then
                        { model | floorI = v }
                    else if k == "index__ceiling" then
                        { model
                            | ceiling =
                                (String.toInt v
                                    |> Result.toMaybe
                                    |> Maybe.withDefault 5000000000
                                )
                            , ceilingE = False
                            , ceilingI = v ++ "ns"
                        }
                    else if k == "index__ceiling_i" then
                        { model | ceilingI = v }
                    else
                        model
                )
                model
                list
            , Apps.getAppList AppsFailed AppsFetched
            )

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
                            Just ( iapp, icmd, iout ) ->
                                case iout of
                                    Nothing ->
                                        ( { model
                                            | apps =
                                                RD.Success
                                                    (Array.set idx iapp apps)
                                          }
                                        , Cmd.map (AppMsg idx) icmd
                                        )

                                    Just (Out.ShowJson j) ->
                                        ( { model
                                            | apps =
                                                RD.Success
                                                    (Array.set idx iapp apps)
                                            , json = Just j
                                          }
                                        , Cmd.map (AppMsg idx) icmd
                                        )

                            Nothing ->
                                Debug.crash "impossible"

                _ ->
                    Debug.crash "impossible"


windowSelector : Model -> Html Msg
windowSelector model =
    if model.globalLevel then
        div [ class [ RCSS.WindowSelector ] ]
            [ div
                [ if model.ceilingE then
                    class [ RCSS.WindowError ]
                  else
                    class []
                ]
                [ label [] [ text "Ceiling" ]
                , input
                    [ value model.ceilingI
                    , onInput OnCeiling
                    , onBlur CommitCeiling
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
                    ]
                    []
                ]
            ]
    else
        text ""


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
                    [ a [] [ text "Last 10 Minutes" ]
                    , input
                        [ type' "checkbox"
                        , checked model.timer
                        , onClick TimerToggle
                        ]
                        []
                    , a [ onClick TimerToggle ]
                        [ text
                            (if model.timer then
                                ((toString
                                    (model.timerPeriod - model.timerCurrent)
                                 )
                                    ++ "s"
                                )
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
                    , windowSelector model
                    ]
                ]
             ]
                ++ content
                ++ [ jsoncontent ]
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ((if model.timer then
            [ (Time.every Time.second Tick) ]
          else
            []
         )
            ++ [ Ports.keysData KeysData ]
            ++ (case model.apps of
                    RD.Success apps ->
                        (iamap
                            (\( i, a ) ->
                                Sub.map (AppMsg i) (App.subscriptions a)
                            )
                            apps
                        )

                    _ ->
                        []
               )
        )
