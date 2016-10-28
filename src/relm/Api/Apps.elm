module Api.Apps exposing (..)

-- elm.core

import Json.Decode as JD exposing (string, list, int, (:=))
import Json.Decode.Extra exposing ((|:))
import Http
import Task


type alias App =
    { name : String
    , views : List View
    }


type alias View =
    { name : String
    , hosts : List String
    }


type alias JsonResp =
    { ts : String
    , json : String
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


jsonresp : JD.Decoder JsonResp
jsonresp =
    JD.succeed JsonResp
        |: ("ts" := string)
        |: ("json" := string)


getAppList : (Http.Error -> a) -> (List App -> a) -> Cmd a
getAppList failed success =
    Http.get (JD.at [ "result" ] (list app)) "/apps"
        |> Task.perform failed success


getJson : String -> String -> String -> Int -> (Http.Error -> a) -> (JsonResp -> a) -> Cmd a
getJson app view id ts failed success =
    (Http.get (JD.at [ "result" ] jsonresp) <|
        Http.url "/json"
            [ ( "app", app )
            , ( "view", view )
            , ( "id", id )
            , ( "idx", (toString ts) )
            ]
    )
        |> Task.perform failed success



--getViewList : String -> (Http.Error -> a) -> (List View -> a) -> Cmd a
--getViewList app failed success =
--    (Http.get (JD.at [ "result" ] (list string)) <|
--        Http.url
--            "/views"
--            [ ( "app", app ) ]
--    )
--        |> Task.perform failed success
