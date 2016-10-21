module Pages.View exposing (..)

-- elm.core

import Html exposing (Html, text, ul, li, a)
import Date
import RemoteData as RD
import Http
import Basics.Extra exposing (never)
import Task


-- extra

import Date.Extra.Period as DP


-- ours

import Api.Apps as Apps
import Ports


type alias ViewData =
    { timings : List (Int, Int)
    , id : String
    , ceiling : Int
    }


type alias Model =
    { data : RD.WebData ViewData
    , app : Apps.App
    , view : Apps.View
    }


init : Model
init =
    { data = RD.NotAsked, app = "", view = "" }


type Msg
    = Viewed Apps.App Apps.View
    | DateFetched Date.Date
    | ViewDataFetched ( String, String, Int, List ( Int, Int ) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "P.App" msg of
        Viewed app view ->
            ( { model
                | data = RD.NotAsked
                , app = Http.uriDecode app
                , view = Http.uriDecode view
              }
            , Cmd.batch
                [ Ports.title (app ++ " -> " ++ view)
                , Task.perform never DateFetched Date.now
                ]
            )

        DateFetched date ->
            ( { model | data = RD.Loading }
            , (Ports.getGraph
                model.app
                model.view
                ""
                (DP.add DP.Minute -10 date)
                date
                0
                0
              )
            )

        ViewDataFetched (err, id, ceiling, list) ->
            case err of
                "" ->
                ( { model | data = RD.Success {id = id, timings = list, ceiling = ceiling
                    } }
                , Cmd.none )

                msg ->
                    ({model | data = RD.Failure (Http.UnexpectedPayload msg)}
                    , Cmd.none
                    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.graphData ViewDataFetched

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
