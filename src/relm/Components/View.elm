module Components.View exposing (..)

-- elm.core

import Html exposing (Html, text, ul, li, a, h3, div)
import Html.Attributes exposing (style, class)
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
    { timings : List ( Int, Int )
    , id : String
    , ceiling : Int
    }


type alias Model =
    { data : RD.WebData ViewData
    , app : String
    , name : String
    , hosts : List String
    }


init : String -> Apps.View -> ( Model, Cmd Msg )
init app view =
    ( { data = RD.NotAsked, app = app, name = view.name, hosts = view.hosts }
    , Cmd.none
    )


type Msg
    = Viewed
    | DateFetched Date.Date
    | ViewDataFetched ( String, String, Int, List ( Int, Int ) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "P.App" msg of
        Viewed ->
            ( model, Task.perform never DateFetched Date.now )

        DateFetched date ->
            ( { model | data = RD.Loading }
            , (Ports.getGraph
                model.app
                model.name
                ""
                (DP.add DP.Minute -10 date)
                date
                0
                0
              )
            )

        ViewDataFetched ( err, id, ceiling, list ) ->
            case err of
                "" ->
                    ( { model
                        | data =
                            RD.Success
                                { id = id
                                , timings = list
                                , ceiling = ceiling
                                }
                      }
                    , Cmd.none
                    )

                msg ->
                    ( { model | data = RD.Failure (Http.UnexpectedPayload msg) }
                    , Cmd.none
                    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.graphData ViewDataFetched


libar : ( Int, Int ) -> Html Msg
libar ( t, v ) =
    li
        [ style
            [ ( "left", ((toString t) ++ "px") )
            , ( "height", ((toString (v * 2)) ++ "px") )
            ]
        ]
        []


graph : Model -> Html Msg
graph model =
    case model.data of
        RD.Success data ->
            ul [ class "graph" ] (List.map libar data.timings)

        RD.Loading ->
            text "loading.."

        RD.NotAsked ->
            text "Not asked"

        RD.Failure err ->
            text (toString err)


view : Model -> Html Msg
view model =
    div [ class "view" ] [ h3 [] [ text model.name ], graph model ]
