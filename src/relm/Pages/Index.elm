module Pages.Index exposing (..)

import Html exposing (Html, text, ul, li, a, h1)
import Html.App
import RemoteData as RD
import Http
import Array exposing (Array)


-- ours

import Api.Apps as Apps
import Components.App as App
import Helpers exposing (imap, rdpimap)
import Ports


type alias Model =
    { apps : RD.WebData (Array App.Model)
    }


init : Model
init =
    { apps = RD.NotAsked }


type Msg
    = Viewed
    | AppsFetched (List Apps.App)
    | AppsFailed Http.Error
    | AppMsg Int App.Msg


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

        AppsFetched apps ->
            ( { model
                | apps =
                    RD.Success
                        (Array.fromList
                            (List.map
                                (\a -> { app = a, views = RD.NotAsked })
                                apps
                            )
                        )
              }
            , Cmd.none
            )

        AppsFailed err ->
            ( { model | apps = RD.Failure err }, Cmd.none )

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
                            Just ( iapp, icmd ) ->
                                ( { model
                                    | apps = RD.Success (Array.set idx iapp apps)
                                  }
                                , Cmd.map (AppMsg idx) icmd
                                )

                            Nothing ->
                                Debug.crash "impossible"

                _ ->
                    Debug.crash "impossible"


view : Model -> Html Msg
view model =
    case model.apps of
        RD.Success apps ->
            ul []
                ([ h1 [] [ text "rtime" ] ]
                    ++ (imap
                            (\( i, a ) -> Html.App.map (AppMsg i) (App.view a))
                            (Array.toList apps)
                       )
                )

        RD.Loading ->
            text "loading.."

        RD.NotAsked ->
            text "Not asked"

        RD.Failure err ->
            text (toString err)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
