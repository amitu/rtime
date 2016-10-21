module Components.App exposing (..)

import Html exposing (Html, text, ul, li, a, h1)
import Html.Attributes exposing (href)
import RemoteData as RD
import Http


-- ours

import Api.Apps as Apps


type alias Model =
    Apps.App


type Msg
    = ViewsFetched (List Apps.View)
    | ViewsFailed Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    h1 [] [ text model.name ]
