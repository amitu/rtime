module Pages.Index exposing (Model, Msg(..), init, update, view, subscriptions)

import Html exposing (Html, text, ul, li, a, h1, div, input)
import Html.Attributes exposing (type', checked)
import Html.Events exposing (onClick)
import Html.App
import RemoteData as RD
import Http
import Array exposing (Array)
import Time


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
    }


init : Model
init =
    { apps = RD.NotAsked
    , timer = False
    , timerPeriod = 30
    , timerCurrent = 0
    , json = Nothing
    }


type Msg
    = Viewed
    | AppsFetched (List Apps.App)
    | AppsFailed Http.Error
    | AppMsg Int App.Msg
    | TimerToggle
    | Tick Time.Time
    | HideJson


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "P.Index" msg of
        Viewed ->
            ( { model | apps = RD.Loading }
            , Cmd.batch
                [ Apps.getAppList AppsFailed AppsFetched
                , Ports.title "Index"
                ]
            )

        TimerToggle ->
            ( { model | timer = not model.timer }, Cmd.none )

        Tick _ ->
            if model.timer then
                let
                    current =
                        model.timerCurrent + 1
                in
                    if current == model.timerPeriod then
                        ( { model | timerCurrent = 0 }, Ports.reload "" )
                    else
                        ( { model | timerCurrent = current }, Cmd.none )
            else
                ( model, Cmd.none )

        AppsFetched apps ->
            let
                ( models, cmds ) =
                    List.unzip (List.map App.init apps)
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
                                            | apps = RD.Success (Array.set idx iapp apps)
                                          }
                                        , Cmd.map (AppMsg idx) icmd
                                        )

                                    Just (Out.ShowJson j) ->
                                        ( { model
                                            | apps = RD.Success (Array.set idx iapp apps)
                                            , json = Just j
                                          }
                                        , Cmd.map (AppMsg idx) icmd
                                        )

                            Nothing ->
                                Debug.crash "impossible"

                _ ->
                    Debug.crash "impossible"


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
                    , input [ type' "checkbox", checked model.timer, onClick TimerToggle ] []
                    , a [ onClick TimerToggle ]
                        [ text
                            (if model.timer then
                                ((toString (model.timerPeriod - model.timerCurrent)) ++ "s")
                             else
                                "paused"
                            )
                        ]
                    , input [ type' "checkbox" ] []
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
                            (\( i, a ) -> Sub.map (AppMsg i) (App.subscriptions a))
                            apps
                        )

                    _ ->
                        []
               )
        )
