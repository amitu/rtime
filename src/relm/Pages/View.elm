module Pages.View exposing (..)

import Html exposing (Html, text, ul, li, a)
import Date
import RemoteData as RD
import Http
import Basics.Extra exposing (never)
import Task


-- ours

import Api.Apps as Apps
import Ports


type alias Model =
    { data : RD.WebData Apps.ViewData
    , app : Apps.App
    , view : Apps.View
    }


init : Model
init =
    { data = RD.NotAsked, app = "", view = "" }


type Msg
    = Viewed Apps.App Apps.View
    | ViewDataFetched Apps.ViewData
    | ViewDataFailed Http.Error
    | DateFetched Date.Date


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "P.App" msg of
        Viewed app view ->
            ( { model
                | data = RD.Loading
                , app = Http.uriDecode app
                , view = Http.uriDecode view
              }
            , Cmd.batch
                [ Ports.title (app ++ " -> " ++ view)
                , Task.perform never DateFetched Date.now
                ]
            )

        DateFetched date ->
            ( model
            , (Apps.getViewData
                model.app
                model.view
                date
                date
                0
                0
                ViewDataFailed
                ViewDataFetched
              )
            )

        ViewDataFetched data ->
            ( { model | data = RD.Success data }, Cmd.none )

        ViewDataFailed err ->
            ( { model | data = RD.Failure err }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.data of
        RD.Success data ->
            ul [] [ text (toString data) ]

        RD.Loading ->
            text "loading.."

        RD.NotAsked ->
            text "Not asked"

        RD.Failure err ->
            text (toString err)
