module Api.Apps exposing (..)

-- elm.core

import Json.Decode as JD exposing (string, list, int, (:=))
import Json.Decode.Extra exposing ((|:))
import Http
import Task
import Date exposing (Date)


type alias App =
    { name : String
    , views : List View
    }


type alias View =
    { name : String
    , hosts : List String
    }


view : JD.Decoder View
view =
    JD.succeed View
        |: ("name" := string)
        |: ("hosts" := list string)


app : JD.Decoder App
app =
    JD.succeed App
        |: ("name" := string)
        |: ("views" := list view)


getAppList : (Http.Error -> a) -> (List App -> a) -> Cmd a
getAppList failed success =
    Http.get (JD.at [ "result" ] (list app)) "/apps"
        |> Task.perform failed success



--getViewList : String -> (Http.Error -> a) -> (List View -> a) -> Cmd a
--getViewList app failed success =
--    (Http.get (JD.at [ "result" ] (list string)) <|
--        Http.url
--            "/views"
--            [ ( "app", app ) ]
--    )
--        |> Task.perform failed success
