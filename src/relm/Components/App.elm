module Components.App
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , view
        , subscriptions
        , updateLevels
        , updateWindow
        )

import Html exposing (Html, text, ul, li, a, h2, div, input, span)
import Html.Attributes exposing (type', checked)
import Html.Events exposing (onClick)
import Array exposing (Array)
import Html.App
import Date exposing (Date)
import Dict exposing (Dict)


-- ours

import Api.Apps as Apps
import Components.View as View
import Out
import Helpers exposing (imap, iamap, class)
import RCSS
import Ports


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


init :
    Int
    -> String
    -> Int
    -> String
    -> Bool
    -> Dict String String
    -> Apps.App
    -> ( Model, Cmd Msg )
init floor floorI ceiling ceilingI global store app =
    let
        ( models, cmds ) =
            List.unzip
                (List.map
                    (View.init floor floorI ceiling ceilingI global app.name)
                    app.views
                )
    in
        ( { name = app.name
          , views = Array.fromList models
          , state = Open
          , checkbox = False
          }
            |> readState store
        , Cmd.batch (imap (\( i, cmd ) -> Cmd.map (ViewMsg i) cmd) cmds)
        )


readState : Dict String String -> Model -> Model
readState store model =
    case Dict.get (key model.name) store of
        Just v ->
            case v of
                "Open" ->
                    { model | checkbox = False, state = Open }

                "Closed" ->
                    { model | checkbox = False, state = Closed }

                "Checked" ->
                    { model | checkbox = True, state = Checked }

                v ->
                    Debug.crash ("unknown value: " ++ v)

        Nothing ->
            model


type Msg
    = ViewMsg Int View.Msg
    | CheckboxToggle
    | AppToggle
    | ShowAll


key : String -> String
key n =
    "app__" ++ n


updateViews :
    (View.Model -> ( View.Model, Cmd View.Msg ))
    -> Model
    -> ( Model, Cmd Msg )
updateViews fn model =
    let
        result =
            (Array.map fn model.views)
    in
        ( { model | views = Array.map fst result }
        , Cmd.batch (iamap (\( i, ( a, c ) ) -> Cmd.map (ViewMsg i) c) result)
        )


updateLevels :
    Int
    -> String
    -> Int
    -> String
    -> Bool
    -> Model
    -> ( Model, Cmd Msg )
updateLevels floor floorI ceiling ceilingI global model =
    updateViews (View.updateLevels floor floorI ceiling ceilingI global) model


updateWindow : Date -> Date -> Model -> ( Model, Cmd Msg )
updateWindow start end model =
    updateViews (View.updateWindow start end) model


update : Msg -> Model -> ( Model, Cmd Msg, Maybe Out.Msg )
update msg model =
    case msg of
        CheckboxToggle ->
            let
                checkbox =
                    not model.checkbox
            in
                if checkbox then
                    ( { model | checkbox = checkbox, state = Checked }
                    , Ports.set_key ( key model.name, "Checked" )
                    , Nothing
                    )
                else
                    ( { model | checkbox = checkbox, state = Closed }
                    , Ports.set_key ( key model.name, "Closed" )
                    , Nothing
                    )

        ShowAll ->
            ( { model | state = Open, checkbox = False }
            , Ports.set_key ( key model.name, "Open" )
            , Nothing
            )

        AppToggle ->
            case model.state of
                Open ->
                    ( { model | state = Closed, checkbox = False }
                    , Ports.set_key ( key model.name, "Closed" )
                    , Nothing
                    )

                Closed ->
                    ( { model | state = Checked, checkbox = True }
                    , Ports.set_key ( key model.name, "Checked" )
                    , Nothing
                    )

                Checked ->
                    ( { model | state = Open, checkbox = False }
                    , Ports.set_key ( key model.name, "Open" )
                    , Nothing
                    )

        ViewMsg idx msg ->
            let
                view =
                    Array.get idx model.views

                res =
                    Maybe.map (\view -> View.update msg view) view
            in
                case res of
                    Just ( iview, icmd, omsg ) ->
                        ( { model
                            | views = Array.set idx iview model.views
                          }
                        , Cmd.map (ViewMsg idx) icmd
                        , omsg
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
                        [ span [ class [ RCSS.PlusMore ] ]
                            [ text
                                ((toString (Array.length model.views))
                                    ++ " hidden"
                                )
                            ]
                        ]

                    Checked ->
                        (iamap
                            (\( i, v ) ->
                                if v.checked then
                                    Html.App.map (ViewMsg i) (View.view v)
                                else
                                    text ""
                            )
                            model.views
                        )
                            ++ (let
                                    len =
                                        (List.length
                                            (List.filter
                                                (.checked >> not)
                                                (Array.toList model.views)
                                            )
                                        )
                                in
                                    if len > 0 then
                                        [ span
                                            [ class [ RCSS.PlusMore ]
                                            , onClick ShowAll
                                            ]
                                            [ text
                                                ("+ "
                                                    ++ (toString len)
                                                    ++ " more"
                                                )
                                            ]
                                        ]
                                    else
                                        [ text "" ]
                               )
               )
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        (iamap
            (\( i, v ) -> Sub.map (ViewMsg i) (View.subscriptions v))
            model.views
        )
