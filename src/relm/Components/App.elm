module Components.App exposing (..)

import Html exposing (Html, text, ul, li, a, h2, div, input, span)
import Html.Attributes exposing (type', checked)
import Html.Events exposing (onClick)
import Array exposing (Array)
import Html.App


-- ours

import Api.Apps as Apps
import Components.View as View
import Helpers exposing (imap, iamap, class)
import RCSS


type VisibilityState
    = Open
    | Closed
    | Checked


type alias Model =
    { name : String
    , views : Array View.Model
    , state : VisibilityState
    , checkbox : Bool
    }


init : Apps.App -> ( Model, Cmd Msg )
init app =
    let
        ( models, cmds ) =
            List.unzip (List.map (View.init app.name) app.views)
    in
        ( { name = app.name, views = Array.fromList models, state = Open, checkbox = False }
        , Cmd.batch <|
            Cmd.none
                :: (imap (\( i, cmd ) -> Cmd.map (ViewMsg i) cmd) cmds)
        )


type Msg
    = ViewMsg Int View.Msg
    | CheckboxToggle
    | AppToggle


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "C.App" msg of
        CheckboxToggle ->
            let
                checkbox =
                    not model.checkbox
            in
                if checkbox then
                    ( { model | checkbox = checkbox, state = Checked }, Cmd.none )
                else
                    ( { model | checkbox = checkbox, state = Closed }, Cmd.none )

        AppToggle ->
            case model.state of
                Open ->
                    ( { model | state = Closed, checkbox = False }, Cmd.none )

                Closed ->
                    ( { model | state = Checked, checkbox = True }, Cmd.none )

                Checked ->
                    ( { model | state = Open, checkbox = False }, Cmd.none )

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
            [ input
                [ type' "checkbox"
                , onClick CheckboxToggle
                , checked model.checkbox
                ]
                []
            , span [ onClick AppToggle ] [ text model.name ]
            ]
         ]
            ++ (case model.state of
                    Open ->
                        (imap
                            (\( i, v ) -> Html.App.map (ViewMsg i) (View.view v))
                            (Array.toList model.views)
                        )

                    Closed ->
                        []

                    Checked ->
                        (imap
                            (\( i, v ) -> Html.App.map (ViewMsg i) (View.view v))
                            (List.filter (.checked) (Array.toList model.views))
                        )
                            ++ (let
                                    len =
                                        (List.length (List.filter (.checked >> not) (Array.toList model.views)))
                                in
                                    if len > 0 then
                                        [ span [ class [ RCSS.PlusMore ] ] [ text ("+ " ++ (toString len) ++ " more") ] ]
                                    else
                                        [ text "" ]
                               )
               )
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        (iamap (\( i, v ) -> Sub.map (ViewMsg i) (View.subscriptions v)) model.views)
