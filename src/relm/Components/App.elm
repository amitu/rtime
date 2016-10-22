module Components.App exposing (..)

import Html exposing (Html, text, ul, li, a, h2, div)
import Html.Attributes exposing (class)
import Array exposing (Array)
import Html.App


-- ours

import Api.Apps as Apps
import Components.View as View
import Helpers exposing (imap)


type alias Model =
    { name : String
    , views : Array View.Model
    }


init : Apps.App -> ( Model, Cmd Msg )
init app =
    ( { name = app.name
      , views = Array.fromList (List.map (View.init app.name) app.views)
      }
    , Cmd.none
    )


type Msg
    = ViewMsg Int View.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [ class "app" ]
        ([ h2 [] [ text model.name ]
         ]
            ++ (imap
                    (\( i, v ) -> Html.App.map (ViewMsg i) (View.view v))
                    (Array.toList model.views)
               )
        )
