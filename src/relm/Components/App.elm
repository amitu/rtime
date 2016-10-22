module Components.App exposing (..)

import Html exposing (Html, text, ul, li, a, h2)
import Array exposing (Array)


-- ours

import Api.Apps as Apps
import Components.View as View


type alias Model =
    { name : String
    , views : Array View.Model
    }


init : Apps.App -> Model
init app =
    { name = app.name
    , views = Array.fromList (List.map (View.init app.name) app.views)
    }


type Msg
    = ViewMsg Int View.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    h2 [] [ text model.name ]
