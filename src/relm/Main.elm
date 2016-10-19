module Main exposing (..)

-- elm.core

import Html.App
import Navigation
import Html exposing (Html, div, text)


-- ours

import Routing
import Ports
import Pages.Index as Index
import Pages.App as App
import Pages.View as View


type alias Flags =
    { csrf : String
    }


type Msg
    = IndexMsg Index.Msg
    | AppMsg App.Msg
    | ViewMsg View.Msg


type alias Model =
    { csrf : String
    , route : Routing.Route
    , index : Index.Model
    , app : App.Model
    , view : View.Model
    }


initialModel : Routing.Route -> String -> Model
initialModel route csrf =
    { csrf = csrf
    , route = route
    , index = Index.init
    , app = App.init
    , view = View.init
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
                let
                    ( imodel, icmd ) =
                        Index.update Index.Viewed model.index
                in
                    ( { model | index = imodel }, Cmd.map IndexMsg icmd )

            Routing.AppRoute app ->
                let
                    ( imodel, icmd ) =
                        App.update (App.Viewed app) model.app
                in
                    ( { model | app = imodel }, Cmd.map AppMsg icmd )

            Routing.ViewRoute app view ->
                let
                    ( imodel, icmd ) =
                        View.update (View.Viewed app view) model.view
                in
                    ( { model | view = imodel }, Cmd.map ViewMsg icmd )

            Routing.NotFoundRoute ->
                ( model, Ports.title "page not found" )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        IndexMsg msg ->
            let
                ( imodel, icmd ) =
                    Index.update msg model.index
            in
                ( { model | index = imodel }, Cmd.map IndexMsg icmd )

        AppMsg msg ->
            let
                ( imodel, icmd ) =
                    App.update msg model.app
            in
                ( { model | app = imodel }, Cmd.map AppMsg icmd )

        ViewMsg msg ->
            let
                ( imodel, icmd ) =
                    View.update msg model.view
            in
                ( { model | view = imodel }, Cmd.map ViewMsg icmd )


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

                Routing.AppRoute _ ->
                    App.view model.app
                        |> Html.App.map AppMsg

                Routing.ViewRoute _ _ ->
                    View.view model.view
                        |> Html.App.map ViewMsg

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
