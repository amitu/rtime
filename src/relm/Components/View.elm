module Components.View
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , view
        , subscriptions
        , updateLevels
        , updateWindow
        )

-- elm.core

import Html exposing (Html, text, ul, li, a, h3, div, input, span)
import Html.Attributes exposing (style, type', checked)
import Html.Events exposing (onClick)
import Svg as S exposing (svg)
import Svg.Attributes as S
import Svg.Events as S
import Date exposing (Date)
import RemoteData as RD
import Http
import Basics.Extra exposing (never)
import Task


-- extra

import Date.Extra.Period as DP


-- ours

import Api.Apps as Apps
import Ports
import Out
import Helpers exposing (class, twoimap)
import RCSS


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
    , checked : Bool
    , trap : Maybe Int
    , start : Maybe Date
    , end : Maybe Date
    , floor : Int
    , ceiling : Int
    , globalFloor : Int
    , globalFloorI : String
    , globalCeiling : Int
    , globalCeilingI : String
    , globalLevels : Bool
    }


init :
    Int
    -> String
    -> Int
    -> String
    -> Bool
    -> String
    -> Apps.View
    -> ( Model, Cmd Msg )
init floor floorI ceiling ceilingI global app view =
    ( { data = RD.NotAsked
      , app = app
      , name = view.name
      , hosts = view.hosts
      , graph = False
      , checked = False
      , trap = Nothing
      , start = Nothing
      , end = Nothing
      , floor = 0
      , ceiling = 0
      , globalFloor = floor
      , globalFloorI = floorI
      , globalCeiling = ceiling
      , globalCeilingI = ceilingI
      , globalLevels = global
      }
    , Cmd.batch
        (List.map
            (\f -> Ports.get_key (f app view.name))
            [ key1, key2 ]
        )
    )


key1 : String -> String -> String
key1 a n =
    "key_" ++ a ++ "_" ++ n ++ "_1"


key2 : String -> String -> String
key2 a n =
    "key_" ++ a ++ "_" ++ n ++ "_2"


type Msg
    = ToggleGraph
    | ToggleCheck
    | DateFetched Date.Date
    | ViewDataFetched ( String, ( String, String, String ), ( Int, Int ), List ( Int, Int ) )
    | KeyData ( String, ( Bool, String ) )
    | LineClick Int
    | GotJson Apps.JsonResp
    | JsonFailed Http.Error
    | TrapMouseIn Int
    | TrapMouseOut Int


updateLevels : Int -> String -> Int -> String -> Bool -> Model -> ( Model, Cmd Msg )
updateLevels floor floorI ceiling ceilingI global model =
    ( { model
        | globalFloor = floor
        , globalFloorI = floorI
        , globalCeiling = ceiling
        , globalCeilingI = ceilingI
        , globalLevels = global
      }
      -- TODO refresh the graph
    , Cmd.none
    )


updateWindow : Date -> Date -> Model -> ( Model, Cmd Msg )
updateWindow start end model =
    ( { model | start = Just start, end = Just end }
      -- TODO refresh the graph
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg, Maybe Out.Msg )
update msg model =
    case Debug.log "P.View" msg of
        ToggleCheck ->
            ( { model | checked = not model.checked }
            , (Ports.set_key
                ( key1 model.app model.name
                , if model.checked then
                    ""
                  else
                    "open"
                )
              )
            , Nothing
            )

        LineClick ts ->
            case model.data of
                RD.Success data ->
                    ( model
                    , Apps.getJson model.app model.name data.id ts JsonFailed GotJson
                    , Just (Out.ShowJson "loading...")
                    )

                _ ->
                    Debug.crash "impossible"

        GotJson resp ->
            ( model, Cmd.none, Just (Out.ShowJson resp.json) )

        JsonFailed err ->
            ( model, Cmd.none, Just (Out.ShowJson (toString err)) )

        TrapMouseIn ts ->
            ( { model | trap = Just ts }, Cmd.none, Nothing )

        TrapMouseOut ts ->
            ( { model | trap = Nothing }, Cmd.none, Nothing )

        ToggleGraph ->
            if model.graph then
                ( { model | graph = False }
                , Ports.set_key ( key2 model.app model.name, "" )
                , Nothing
                )
            else
                ( { model | graph = True }
                , case model.data of
                    RD.NotAsked ->
                        Cmd.batch
                            [ Task.perform never DateFetched Date.now
                            , Ports.set_key ( key2 model.app model.name, "open" )
                            ]

                    _ ->
                        Ports.set_key ( key2 model.app model.name, "open" )
                , Nothing
                )

        KeyData ( k, ( ok, v ) ) ->
            if not ok || v == "" then
                ( model, Cmd.none, Nothing )
            else if k == key1 model.app model.name then
                update ToggleCheck model
            else if k == key2 model.app model.name then
                update ToggleGraph model
            else
                ( model, Cmd.none, Nothing )

        DateFetched date ->
            ( { model | data = RD.Loading }
            , (Ports.getGraph
                model.app
                model.name
                ""
                (DP.add DP.Minute -10 date)
                date
                model.globalFloor
                model.globalCeiling
              )
            , Nothing
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
                        , Nothing
                        )

                    msg ->
                        ( { model | data = RD.Failure (Http.UnexpectedPayload msg) }
                        , Cmd.none
                        , Nothing
                        )
            else
                -- no es para mi
                ( model, Cmd.none, Nothing )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ Ports.graphData ViewDataFetched, Ports.keyData KeyData ]


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
            S.circle [ cx t, cy 0, r 1, S.stroke "#6" ] []

        v ->
            S.g [ S.onClick (LineClick t) ]
                [ S.line
                    [ x1 t
                    , y1 -0.5
                    , x2 t
                    , y2 65
                    , S.stroke "white"
                    , S.strokeWidth "1"
                    ]
                    []
                , S.line
                    [ x1 t
                    , y1 -0.5
                    , x2 t
                    , y2 v
                    , S.stroke "black"
                    , S.strokeWidth "1"
                    ]
                    []
                ]


decals : Model -> ViewData -> List (Html Msg)
decals model data =
    [ -- y axis
      S.line [ x1 0, y1 -0.5, x2 1026, y2 -0.5, (S.stroke "#ccc"), (S.strokeWidth "1") ] []
      -- x axis
    , S.line [ x1 0, y1 0, x2 0, y2 65, (S.stroke "#ccc"), (S.strokeWidth "2") ] []
      -- ceiling tick
    , S.line [ x1 0, y1 64, x2 7, y2 60, (S.stroke "#ccc"), (S.strokeWidth "2") ] []
    , S.text' [ x 9, y 58 ] [ S.text model.globalCeilingI ]
      -- floor
    , S.line [ x1 7, y1 3.5, x2 0, y2 -0.5, (S.stroke "#ccc"), (S.strokeWidth "2") ] []
    , S.text' [ x 9, y 2 ] [ S.text model.globalFloorI ]
    ]


s : a -> String
s =
    toString


trapezoid : Maybe Int -> ( Int, ( Int, Int ), ( Int, Int ) ) -> Html Msg
trapezoid selected ( current, ( t1, v1o ), ( t2, v2o ) ) =
    let
        v1 =
            (64 - v1o) * 2

        v2 =
            (64 - v2o) * 2

        points =
            ((s t1) ++ ",130 " ++ (s t2) ++ ",130 " ++ (s t2) ++ "," ++ (s v2) ++ " " ++ (s t1) ++ "," ++ (s v1))

        fill =
            case selected of
                Just selected ->
                    if selected == current then
                        S.fill "red"
                    else
                        S.fill "blue"

                Nothing ->
                    S.fill "blue"
    in
        S.g []
            [ S.polygon
                [ S.points points
                , fill
                  -- , S.onMouseOver (TrapMouseIn current)
                  -- , S.onMouseOut (TrapMouseOut current)
                ]
                []
              -- , S.circle
              --    [ cx t2, cy v2o, r 1, S.stroke "#ff0000", S.fill "#ff0000" ]
              --    []
            , S.line
                [ x1 t2
                , y1 -0.5
                , x2 t2
                , y2 v2o
                , S.stroke "red"
                , S.strokeWidth "1"
                , S.onClick (LineClick t2)
                ]
                []
            ]


graph : Model -> Html Msg
graph model =
    case model.data of
        RD.Success data ->
            S.svg [ S.class "Graph", S.width "1026", S.height "130", S.viewBox "0 0 1026 130" ] <|
                (decals model data
                    ++ if List.length data.timings < 2 then
                        List.map libar data.timings
                       else
                        twoimap (trapezoid model.trap) data.timings
                )

        RD.Loading ->
            text "loading.."

        RD.NotAsked ->
            text "Not asked"

        RD.Failure err ->
            text (toString err)


view : Model -> Html Msg
view model =
    div [ class [ RCSS.View ] ]
        [ h3 []
            [ input [ type' "checkbox", onClick ToggleCheck, checked model.checked ] []
            , input [ type' "checkbox", onClick ToggleGraph, checked model.graph ] []
            , span [ onClick ToggleGraph ] [ text model.name ]
            ]
        , (if model.graph then
            graph model
           else
            text ""
          )
        ]
