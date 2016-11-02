module Pages.Index exposing (Model, Msg(..), init, update, view, subscriptions)

import Html exposing (Html, text, ul, li, a, h1, div, input, label)
import Html.Attributes exposing (type', checked, value, tabindex)
import Html.Events exposing (onClick, onBlur, onInput)
import Html.App
import RemoteData as RD
import Http
import Array exposing (Array)
import Time exposing (Time)
import Date exposing (Date)
import Dict exposing (Dict)
import Date.Extra.Duration as Duration exposing (Duration, zeroDelta)
import String
import Task
import Basics.Extra exposing (never)


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
    , absoluteWindow :
        -- this decides if start or start0 + now is to be used
        Bool
    , start : Maybe Date
    , end : Maybe Date
    , startO : Duration
    , endO : Duration
    , now : Maybe Date
    , store : Dict String String
    }


init : List ( String, String ) -> Model
init store =
    { apps = RD.NotAsked
    , timer = False
    , timerPeriod = 5
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


readKey : String -> (String -> Model -> Model) -> Model -> Model
readKey key fn model =
    case Dict.get ("index__" ++ key) model.store of
        Just v ->
            fn v model

        Nothing ->
            model


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


updateWindow : Model -> ( Model, Cmd Msg )
updateWindow model =
    let
        ( start, end ) =
            window model
    in
        updateApps (App.updateWindow start end) model Cmd.none


refreshGraphs : Model -> ( Model, Cmd Msg )
refreshGraphs model =
    ( model, Cmd.none )


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
            let
                nowd =
                    Date.fromTime now
            in
                ( { model
                    | now = Just nowd
                    , start = Just (Duration.add model.startO 1 nowd)
                    , end = Just nowd
                  }
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
                        refreshGraphs
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
                ( models, cmds ) =
                    List.unzip
                        (List.map
                            (App.init model.floor
                                model.floorI
                                model.ceiling
                                model.ceilingI
                                model.globalLevel
                                model.store
                                (withCrash model.start)
                                (withCrash model.end)
                                model.startO
                                model.endO
                                model.absoluteWindow
                                (withCrash model.now)
                            )
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


levelSelector : Model -> Html Msg
levelSelector model =
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
                    , tabindex -1
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
                    , levelSelector model
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
