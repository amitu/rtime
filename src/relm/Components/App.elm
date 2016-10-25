module Components.App exposing (..)

import Html exposing (Html, text, ul, li, a, h2, div, input)
import Html.Attributes exposing (type')
import Html.Events exposing (onClick)
import Array exposing (Array)
import Html.App


-- ours

import Api.Apps as Apps
import Components.View as View
import Helpers exposing (imap, iamap, class)
import RCSS


type alias Model =
    { name : String
    , views : Array View.Model
    , checked : Bool
    , open : Bool
    }


init : Apps.App -> ( Model, Cmd Msg )
init app =
    let
        ( models, cmds ) =
            List.unzip (List.map (View.init app.name) app.views)
    in
        ( { name = app.name, views = Array.fromList models, checked = False, open = False }
        , Cmd.batch <|
            Cmd.none
                :: (imap (\( i, cmd ) -> Cmd.map (ViewMsg i) cmd) cmds)
        )


type Msg
    = ViewMsg Int View.Msg
    | CheckboxToggle


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "C.App" msg of
        CheckboxToggle ->
            ( { model | checked = not model.checked }, Cmd.none )

        ViewMsg idx msg ->
            let
                view =
                    Array.get idx model.views

                res =
                    Maybe.map (\view -> View.update msg view) view
            in
                case res of
                    Just ( iview, icmd ) ->
                        ( { model
                            | views = Array.set idx iview model.views
                          }
                        , Cmd.map (ViewMsg idx) icmd
                        )

                    Nothing ->
                        Debug.crash "impossible"


view : Model -> Html Msg
view model =
    div [ class [ RCSS.App ] ]
        ([ h2 []
            [ input [ type' "checkbox", onClick CheckboxToggle ] []
            , text model.name
            ]
         ]
            ++ (imap
                    (\( i, v ) -> Html.App.map (ViewMsg i) (View.view v))
                    (Array.toList model.views)
               )
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        (iamap (\( i, v ) -> Sub.map (ViewMsg i) (View.subscriptions v)) model.views)
