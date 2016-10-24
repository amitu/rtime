module Components.View exposing (..)

-- elm.core

import Html exposing (Html, text, ul, li, a, h3, div)
import Html.Attributes exposing (style, class)
import Html.Events exposing (onClick)
import Svg as S exposing (svg)
import Svg.Attributes as S
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
    , floor : Int
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
    | ViewDataFetched ( String, ( String, String, String ), ( Int, Int ), List ( Int, Int ) )


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
                20
                120
              )
            )

        ViewDataFetched ( err, ( id, app, view ), ( floor, ceiling ), list ) ->
            if ( app, view ) == ( model.app, model.name ) then
                case err of
                    "" ->
                        ( { model
                            | data =
                                RD.Success
                                    { id = id
                                    , timings = list
                                    , ceiling = ceiling
                                    , floor = floor
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


maker : (String -> S.Attribute Msg) -> number -> S.Attribute Msg
maker m v =
    m (toString v)


x : Int -> S.Attribute Msg
x =
    maker S.x


x1 : Int -> S.Attribute Msg
x1 =
    maker S.x1


x2 : Int -> S.Attribute Msg
x2 =
    maker S.x2


y : Int -> S.Attribute Msg
y v =
    maker S.y ((64 - v) * 2)


y1 : number -> S.Attribute Msg
y1 v =
    maker S.y1 ((64 - v) * 2)


y2 : number -> S.Attribute Msg
y2 v =
    maker S.y2 ((64 - v) * 2)


r : number -> S.Attribute Msg
r =
    maker S.r


cx : number -> S.Attribute Msg
cx =
    maker S.cx


cy : number -> S.Attribute Msg
cy v =
    maker S.cy ((64 - v) * 2)


libar : ( Int, Int ) -> Html Msg
libar ( t, v ) =
    case v of
        0 ->
            S.circle [ cx t, cy 0, r 1, (S.stroke "#6") ] []

        v ->
            S.line
                [ x1 t, y1 -0.5, x2 t, y2 v, (S.stroke "black"), (S.strokeWidth "1") ]
                []


decals : ViewData -> List (Html Msg)
decals data =
    [ -- y axis
      S.line [ x1 0, y1 -0.5, x2 1026, y2 -0.5, (S.stroke "#ccc"), (S.strokeWidth "1") ] []
      -- x axis
    , S.line [ x1 0, y1 0, x2 0, y2 65, (S.stroke "#ccc"), (S.strokeWidth "2") ] []
      -- ceiling tick
    , S.line [ x1 0, y1 64, x2 7, y2 60, (S.stroke "#ccc"), (S.strokeWidth "2") ] []
    , S.text' [ x 9, y 58 ] [ S.text (toString data.ceiling) ]
      -- floot
    , S.line [ x1 7, y1 3.5, x2 0, y2 -0.5, (S.stroke "#ccc"), (S.strokeWidth "2") ] []
    , S.text' [ x 9, y 2 ] [ S.text (toString data.floor) ]
    ]


graph : Model -> Html Msg
graph model =
    case model.data of
        RD.Success data ->
            S.svg [ S.class "Graph", S.width "1026", S.height "130", S.viewBox "0 0 1026 130" ] <|
                ((decals data) ++ List.map libar data.timings)

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
