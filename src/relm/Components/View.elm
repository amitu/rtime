module Components.View exposing (..)

-- elm.core

import Html exposing (Html, text, ul, li, a, h3, div)
import Html.Attributes exposing (style, class)
import Html.Events exposing (onClick)
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
    , graph : Bool
    }


init : String -> Apps.View -> ( Model, Cmd Msg )
init app view =
    ( { data = RD.NotAsked
      , app = app
      , name = view.name
      , hosts = view.hosts
      , graph = False
      }
    , Cmd.none
    )


type Msg
    = ToggleGraph
    | DateFetched Date.Date
    | ViewDataFetched ( String, ( String, String, String ), Int, List ( Int, Int ) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "P.App" msg of
        ToggleGraph ->
            case model.graph of
                True ->
                    ( { model | graph = False }, Cmd.none )

                False ->
                    ( { model | graph = True }
                    , case model.data of
                        RD.NotAsked ->
                            Task.perform never DateFetched Date.now

                        _ ->
                            Cmd.none
                    )

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

        ViewDataFetched ( err, ( id, app, view ), ceiling, list ) ->
            if ( app, view ) == ( model.app, model.name ) then
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
            else
                -- no es para mi
                ( model, Cmd.none )


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
    div [ class "view" ]
        [ h3 [ onClick ToggleGraph ] [ text model.name ]
        , (if model.graph then
            graph model
           else
            text ""
          )
        ]
