module Pages.App exposing (..)

import Html exposing (Html, text, ul, li, a)
import Html.Attributes exposing (href)
import RemoteData as RD
import Http


-- ours

import Api.Apps as Apps
import Ports


type alias Model =
    { views : RD.WebData (List Apps.View)
    , app : String
    }


init : Model
init =
    { views = RD.NotAsked, app = "" }


type Msg
    = Viewed String
    | ViewsFetched (List Apps.View)
    | ViewsFailed Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "P.App" msg of
        Viewed app ->
            ( { model | views = RD.Loading, app = Http.uriDecode app }
            , Cmd.batch
                [ Apps.getViewList app ViewsFailed ViewsFetched
                , Ports.title app
                ]
            )

        ViewsFetched views ->
            ( { model | views = RD.Success views }, Cmd.none )

        ViewsFailed err ->
            ( { model | views = RD.Failure err }, Cmd.none )


liview : Model -> String -> Html Msg
liview model view =
    li []
        [ a
            [ href
                ("#view/"
                    ++ (Http.uriEncode model.app)
                    ++ "/"
                    ++ (Http.uriEncode view)
                )
            ]
            [ text (model.app ++ " -> " ++ view) ]
        ]


view : Model -> Html Msg
view model =
    case model.views of
        RD.Success list ->
            ul [] <| List.map (liview model) list

        RD.Loading ->
            text "loading.."

        RD.NotAsked ->
            text "Not asked"

        RD.Failure err ->
            text (toString err)
