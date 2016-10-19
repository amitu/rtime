module Main exposing (..)

-- elm.core

import Html.App
import Navigation
import Html exposing (Html, div, text)


-- ours

import Routing
import Ports
import Pages.Index as Index


type alias Flags =
    { csrf : String
    }


type Msg
    = IndexMsg Index.Msg


type alias Model =
    { csrf : String
    , route : Routing.Route
    , index : Index.Model
    }


initialModel : Routing.Route -> String -> Model
initialModel route csrf =
    { csrf = csrf
    , route = route
    , index = Index.init
    }


init : Flags -> Result String Routing.Route -> ( Model, Cmd Msg )
init flags result =
    let
        currentRoute =
            Routing.routeFromResult result

        imodel =
            initialModel currentRoute flags.csrf

        ( model, cmd ) =
            urlUpdate result imodel
    in
        ( model, cmd )


urlUpdate : Result String Routing.Route -> Model -> ( Model, Cmd Msg )
urlUpdate result imodel =
    let
        route =
            Routing.routeFromResult result

        model =
            { imodel | route = route }
    in
        case Debug.log "urlUpdate" route of
            Routing.IndexRoute ->
                ( model, Ports.title "Home" )

            Routing.NotFoundRoute ->
                ( model, Ports.title "page not found" )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    let
        content =
            case model.route of
                Routing.IndexRoute ->
                    Index.view model.index
                        |> Html.App.map IndexMsg

                Routing.NotFoundRoute ->
                    text "page not found"
    in
        div [] [ content ]


main : Program Flags
main =
    Navigation.programWithFlags Routing.parser
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        , urlUpdate = urlUpdate
        }
