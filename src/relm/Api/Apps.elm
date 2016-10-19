module Api.Apps exposing (..)

-- elm.core

import Json.Decode as JD exposing (string, list)
import Http
import Task


type alias App =
    String


type alias View =
    String


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
