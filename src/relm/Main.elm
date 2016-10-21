module Main exposing (..)

-- elm.core

import Html.App
import Html exposing (Html, div, text)


-- ours

import Ports


type alias Flags =
    { csrf : String
    }


type Msg
    = Nothing


type alias Model =
    { csrf : String
    }


init : Flags -> ( Model, Cmd Msg )
init flag =
    ( { csrf = flag.csrf }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div [] [ text "hello" ]


main : Program Flags
main =
    Html.App.programWithFlags
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }
