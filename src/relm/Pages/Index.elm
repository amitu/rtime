module Pages.Index exposing (..)

import Html exposing (Html, text, ul, li, a)
import Html.Attributes exposing (href)
import RemoteData as RD
import Http


-- ours

import Api.Apps as Apps
import Ports


type alias Model =
    { apps : RD.WebData (List Apps.App)
    }


init : Model
init =
    { apps = RD.NotAsked }


type Msg
    = Viewed
    | AppsFetched (List Apps.App)
    | AppsFailed Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "P.Index" msg of
        Viewed ->
            ( { model | apps = RD.Loading }
            , Cmd.batch
                [ Apps.getAppList AppsFailed AppsFetched
                , Ports.title "Index"
                ]
            )

        AppsFetched apps ->
            ( { model | apps = RD.Success apps }, Cmd.none )

        AppsFailed err ->
            ( { model | apps = RD.Failure err }, Cmd.none )


liview : String -> Html Msg
liview app =
    li [] [ a [ href ("#app/" ++ app) ] [ text app ] ]


view : Model -> Html Msg
view model =
    case model.apps of
        RD.Success list ->
            ul [] <| List.map liview list

        RD.Loading ->
            text "loading.."

        RD.NotAsked ->
            text "Not asked"

        RD.Failure err ->
            text (toString err)
