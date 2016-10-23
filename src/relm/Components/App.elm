module Components.App exposing (..)

import Html exposing (Html, text, ul, li, a, h2, div)
import Array exposing (Array)
import Html.App
import Color


-- extra

import FontAwesome as FA


-- ours

import Api.Apps as Apps
import Components.View as View
import Helpers exposing (imap, iamap, class)
import RCSS


type alias Model =
    { name : String
    , views : Array View.Model
    }


init : Apps.App -> ( Model, Cmd Msg )
init app =
    let
        ( models, cmds ) =
            List.unzip (List.map (View.init app.name) app.views)
    in
        ( { name = app.name, views = Array.fromList models }
        , Cmd.batch <|
            Cmd.none
                :: (imap (\( i, cmd ) -> Cmd.map (ViewMsg i) cmd) cmds)
        )


type Msg
    = ViewMsg Int View.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "C.App" msg of
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
        ([ h2 [] [ text model.name ]
         , FA.amazon (Color.rgb 255 0 0) 24
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
