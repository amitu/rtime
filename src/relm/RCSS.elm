port module RCSS exposing (..)

import Css.File
import Html
import Html.App as Html
import Css exposing (..)
import Css.Elements exposing (a, div, h1, h2, h3, body, input, label, form)
import Css.Namespace exposing (namespace)


type CssClasses
    = App
    | Main
    | Graph
    | HMenu
    | Header
    | View
    | Link
    | ALink
    | Hidden
    | LevelSelector
    | WindowSelector
    | WindowSelectorOdd
    | WindowSelected
    | WindowError
    | PlusMore


zIndex : Int -> Mixin
zIndex i =
    property "z-index" <| toString i


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
            , paddingRight (px 10)
            , fontSize (px 14)
            , children
                [ input [ display inlineBlock, margin4 zero (px 7) zero (px 15) ]
                ]
            ]
        , (.) Link
            [ cursor pointer
            , lineHeight (px 37)
            , display inlineBlock
            , paddingLeft (px 5)
            , paddingRight (px 5)
            , hover [ backgroundColor (hex "D8D8D8") ]
            ]
        , (.) ALink [ backgroundColor (hex "D8D8D8") ]
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
        , (.) WindowSelector
            [ display inlineBlock
            , backgroundColor (hex "FFFFFF")
            , right zero
            , top (px 37)
            , width (px 443)
            , position absolute
            , border3 (px 1) solid (hex "979797")
            , zIndex 100
            , children
                [ a
                    [ borderBottom3 (px 1) solid (hex "979797")
                    , textAlign center
                    , display inlineBlock
                    , width (pct 50)
                    , padding (px 8)
                    , cursor pointer
                    , nthChild "odd"
                        [ borderRight3 (px 1) solid (hex "979797")
                        ]
                    , hover
                        [ backgroundColor (hex "D8D8D8") ]
                    ]
                , form
                    [ paddingTop (px 12)
                    , descendants
                        [ label
                            [ display block, textAlign right, marginLeft (px 15) ]
                        , input
                            [ height (px 27)
                            , width (px 303)
                            , display inlineBlock
                            , marginLeft (px 13)
                            , marginRight (px 50)
                            , marginBottom (px 12)
                            , textAlign left
                            ]
                        ]
                    ]
                ]
            ]
        , (.) WindowSelected [ backgroundColor (hex "D8D8D8") ]
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
        , (.) Hidden [ display none, position absolute, top (px -2000) ]
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
