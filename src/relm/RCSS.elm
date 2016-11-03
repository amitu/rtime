port module RCSS exposing (..)

import Css.File
import Html
import Html.App as Html
import Css exposing (..)
import Css.Elements exposing (div, h1, h2, h3, body, input)
import Css.Namespace exposing (namespace)


type CssClasses
    = App
    | Main
    | Graph
    | HMenu
    | Header
    | View
    | LevelSelector
    | WindowSelector
    | WindowError
    | PlusMore


css : Css.Stylesheet
css =
    (stylesheet << namespace "")
        [ body
            [ color (hex "4A4A4A")
            , margin zero
            , padding zero
            , fontFamilies [ "Verdana" ]
            ]
        , (.) Main [ margin zero, padding zero ]
        , (.) Header
            [ borderBottom3 (px 1) solid (hex "979797")
            , children
                [ h1
                    [ fontSize (px 21)
                    , fontWeight (int 200)
                    , margin2 (px 8) (px 30)
                    , display inlineBlock
                    ]
                ]
            ]
        , (.) HMenu
            [ position absolute
            , top zero
            , right zero
            , paddingTop (px 12)
            , paddingRight (px 10)
            , fontSize (px 14)
            , children
                [ input [ display inlineBlock, margin4 zero (px 7) zero (px 15) ]
                ]
            ]
        , (.) App
            [ marginLeft (px 30)
            , descendants
                [ h2
                    [ fontSize (px 21)
                    , margin2 (px 8) zero
                    , paddingRight (px 2)
                    , paddingBottom (px 4)
                    , display inlineBlock
                    , borderBottom3 (px 1) solid (hex "979797")
                    ]
                , input [ display inlineBlock, marginRight (px 10) ]
                ]
            ]
        , (.) View
            [ descendants
                [ h3 [ marginTop (px 5), marginBottom (px 5) ]
                ]
            ]
        , (.) Graph
            [ marginTop (px 5)
              --            , marginLeft (px 30)
            , height (px 130)
            ]
        , (.) PlusMore [ fontSize (px 14) ]
        , (.) WindowError
            [ border3 (px 1) solid (hex "ff0000")
            ]
        , (.) LevelSelector
            [ display inlineBlock
            , right zero
            , top (px 37)
            , position absolute
            , textAlign right
            , border3 (px 1) solid (hex "979797")
            , paddingTop (px 10)
            , paddingLeft (px 26)
            , paddingRight (px 23)
            , paddingBottom (px 10)
            , descendants
                [ input
                    [ display inlineBlock
                    , width (px 50)
                    , marginLeft (px 6)
                    , textAlign right
                    ]
                ]
            ]
        ]


port files : Css.File.CssFileStructure -> Cmd msg


cssFiles : Css.File.CssFileStructure
cssFiles =
    Css.File.toFileStructure [ ( "styles.css", Css.File.compile [ css ] ) ]


main : Program Never
main =
    Html.program
        { init = ( (), files cssFiles )
        , view = \_ -> (Html.text "")
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }
