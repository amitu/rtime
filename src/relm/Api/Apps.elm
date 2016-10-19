module Api.Apps exposing (..)

-- elm.core

import Json.Decode as JD exposing (string, list, tuple2, int, float, (:=))
import Json.Decode.Extra exposing ((|:))
import Http
import Task
import Date exposing (Date)


type alias App =
    String


type alias View =
    String


type alias ViewData =
    { hosts : List String
    , timings : List ( Date, Int )
    , start : Date
    , end : Date
    }


fdate : Float -> Result String Date
fdate f =
    Ok (Date.fromTime f)


date : JD.Decoder Date
date =
    JD.customDecoder float fdate


viewdata : JD.Decoder ViewData
viewdata =
    JD.succeed ViewData
        |: ("hosts" := list string)
        |: ("timings" := list (tuple2 (,) date int))
        |: ("start" := date)
        |: ("end" := date)


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
    -> (Http.Error -> a)
    -> (ViewData -> a)
    -> Cmd a
getViewData app view start end failed succeed =
    (Http.get (JD.at [ "result" ] viewdata) <|
        Http.url
            "/view"
            [ ( "app", app )
            , ( "view", view )
            , ( "start", (toString <| Date.toTime start) )
            , ( "end", (toString <| Date.toTime end) )
            ]
    )
        |> Task.perform failed succeed
