module Pages.Index exposing (..)

import Html exposing (Html, text)
import RemoteData as RD
import Api.Apps as Apps


type alias Model =
    { apps : RD.WebData (List Apps.App)
    }


init : Model
init =
    { apps = RD.NotAsked }


type Msg
    = Viewed


view : Model -> Html Msg
view model =
    text "index page"
