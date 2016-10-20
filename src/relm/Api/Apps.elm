module Api.Apps exposing (..)

-- elm.core

import Json.Decode as JD exposing (string, list, int, (:=))
import Json.Decode.Extra exposing ((|:))
import Http
import Task
import Date exposing (Date)


type alias App =
    String


type alias View =
    String


type alias ViewData =
    { timings : List Int
    , id : String
    }


viewdata : JD.Decoder ViewData
viewdata =
    JD.succeed ViewData
        |: ("timings" := list int)
        |: ("id" := string)


getAppList : (Http.Error -> a) -> (List App -> a) -> Cmd a
getAppList failed success =
    Http.get (JD.at [ "result" ] (list string)) "/apps"
        |> Task.perform failed success


getViewList : String -> (Http.Error -> a) -> (List View -> a) -> Cmd a
getViewList app failed success =
    (Http.get (JD.at [ "result" ] (list string)) <|
        Http.url
            "/views"
            [ ( "app", app ) ]
    )
        |> Task.perform failed success


getViewData :
    App
    -> View
    -> Date
    -> Date
    -> Int
    -> Int
    -> (Http.Error -> a)
    -> (ViewData -> a)
    -> Cmd a
getViewData app view start end floor ceiling failed succeed =
    (Http.get (JD.at [ "result" ] viewdata) <|
        Http.url
            "/view"
            [ ( "app", app )
            , ( "view", view )
            , ( "start", (toString <| Date.toTime start) )
            , ( "end", (toString <| Date.toTime end) )
            , ( "floor", (toString floor) )
            , ( "ceiling", (toString ceiling) )
            ]
    )
        |> Task.perform failed succeed
