port module RCSS exposing (..)

import Css.File exposing (..)
import Html exposing (text)
import Html.App as Html
import Css
    exposing
        ( hex
        , color
        , children
        , (.)
        , stylesheet
        , margin2
        , px
        , rgb
        , dashed
        , border3
        , height
        )
import Css.Elements exposing (div, h2)
import Css.Namespace exposing (namespace)


type CssClasses
    = App
    | Main
    | Graph


css : Css.Stylesheet
css =
    (stylesheet << namespace "")
        [ (.) Main [ margin2 (px 0) (px 20) ]
        , (.) App
            [ children
                [ h2
                    [ color (hex "333") ]
                ]
            ]
        , (.) Graph
            [ -- border3 (px 1) dashed (rgb 11 14 17)
              height (px 130)
            ]
        ]


port files : CssFileStructure -> Cmd msg


cssFiles : CssFileStructure
cssFiles =
    toFileStructure [ ( "styles.css", compile [ css ] ) ]


main : Program Never
main =
    Html.program
        { init = ( (), files cssFiles )
        , view = \_ -> (text "")
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }
