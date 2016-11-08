module Components.App
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , view
        , updateLevels
        , updateWindow
        , graphToViews
        )

import Html exposing (Html, text, ul, li, a, h2, div, input, span)
import Html.Attributes exposing (type', checked)
import Html.Events exposing (onClick)
import Array exposing (Array)
import Html.App
import Date exposing (Date)
import Dict exposing (Dict)
import String.Extra as String


-- ours

import Api.Apps as Apps
import Components.View as View
import Out
import Helpers
    exposing
        ( imap
        , iamap
        , class
        , maybe2list
        , third3
        , withCrash
        , unzip3
        , first3
        , VisibilityState(..)
        )
import RCSS
import Ports


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
    -> Date
    -> Date
    -> Apps.App
    -> ( Model, List Out.Msg )
init floor floorI ceiling ceilingI global store start end app =
    { name = app.name
    , views = Array.fromList []
    , state = Open
    , checkbox = False
    }
        |> readState store
        |> initViews floor floorI ceiling ceilingI global store start end app.views


initViews :
    Int
    -> String
    -> Int
    -> String
    -> Bool
    -> Dict String String
    -> Date
    -> Date
    -> List Apps.View
    -> Model
    -> ( Model, List Out.Msg )
initViews floor floorI ceiling ceilingI global store start end views model =
    let
        ( models, msgs ) =
            List.unzip
                (List.map
                    (View.init
                        floor
                        floorI
                        ceiling
                        ceilingI
                        global
                        model.name
                        store
                        start
                        end
                        model.state
                    )
                    views
                )
    in
        ( { model | views = Array.fromList models }
        , maybe2list msgs
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
    (View.Model -> ( View.Model, Cmd View.Msg, Maybe Out.Msg ))
    -> Model
    -> ( Model, Cmd Msg, List Out.Msg )
updateViews fn model =
    let
        result =
            List.map fn <| Array.toList model.views
    in
        ( { model | views = Array.fromList <| List.map first3 result }
        , Cmd.batch (imap (\( i, ( a, c, m ) ) -> Cmd.map (ViewMsg i) c) result)
        , maybe2list <| List.map third3 result
        )


graphToViews :
    Int
    -> ( String, String, String, ( Int, Int ), List ( Int, Int ) )
    -> Model
    -> Model
graphToViews idx ( spec, err, id, ( floor, ceiling ), points ) model =
    case Array.get idx model.views of
        Just view ->
            if view.name == (String.leftOf ":" spec) then
                { model
                    | views =
                        Array.set idx
                            (View.updateGraph
                                view
                                ( err
                                , id
                                , ( floor, ceiling )
                                , points
                                )
                            )
                            model.views
                }
            else
                graphToViews
                    (idx + 1)
                    ( spec, err, id, ( floor, ceiling ), points )
                    model

        Nothing ->
            model


updateLevels :
    Int
    -> String
    -> Int
    -> String
    -> Bool
    -> Model
    -> ( Model, Cmd Msg, List Out.Msg )
updateLevels floor floorI ceiling ceilingI global model =
    updateViews (View.updateLevels floor floorI ceiling ceilingI global) model


updateWindow :
    Date
    -> Date
    -> Model
    -> ( Model, Cmd Msg, List Out.Msg )
updateWindow start end model =
    updateViews (View.updateWindow start end) model


updateVisibility : Cmd Msg -> Model -> ( Model, Cmd Msg, List Out.Msg )
updateVisibility cmd model =
    let
        ( m2, cmd2, list ) =
            updateViews (View.updateVisibility model.state) model
    in
        ( m2, Cmd.batch [ cmd2, cmd ], list )


update : Msg -> Model -> ( Model, Cmd Msg, List Out.Msg )
update msg model =
    case msg of
        CheckboxToggle ->
            let
                checkbox =
                    not model.checkbox
            in
                if checkbox then
                    { model | checkbox = checkbox, state = Checked }
                        |> updateVisibility (Ports.set_key ( key model.name, "Checked" ))
                else
                    { model | checkbox = checkbox, state = Closed }
                        |> updateVisibility (Ports.set_key ( key model.name, "Closed" ))

        ShowAll ->
            { model | state = Open, checkbox = False }
                |> updateVisibility (Ports.set_key ( key model.name, "Open" ))

        AppToggle ->
            case model.state of
                Open ->
                    { model | state = Closed, checkbox = False }
                        |> updateVisibility (Ports.set_key ( key model.name, "Closed" ))

                Closed ->
                    { model | state = Checked, checkbox = True }
                        |> updateVisibility (Ports.set_key ( key model.name, "Checked" ))

                Checked ->
                    { model | state = Open, checkbox = False }
                        |> updateVisibility (Ports.set_key ( key model.name, "Open" ))

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
                        , (case omsg of
                            Nothing ->
                                []

                            Just a ->
                                [ a ]
                          )
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
