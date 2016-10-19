module Routing exposing (..)

import Navigation
import UrlParser exposing (..)
import String


type Route
    = IndexRoute
    | AppRoute String
    | NotFoundRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ format IndexRoute (s "")
        , format AppRoute (s "app" </> string)
        ]


hashParser : Navigation.Location -> Result String Route
hashParser location =
    location.hash
        |> String.dropLeft 1
        |> parse identity matchers


parser : Navigation.Parser (Result String Route)
parser =
    Navigation.makeParser hashParser


routeFromResult : Result String Route -> Route
routeFromResult result =
    case result of
        Ok route ->
            route

        Err str ->
            NotFoundRoute
