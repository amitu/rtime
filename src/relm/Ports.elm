port module Ports exposing (..)

-- elm.core

import Date exposing (Date)


-- extra

import Date.Extra.Format as DE
import Date.Extra.Config.Config_en_us as English


port title : String -> Cmd a


port reload : String -> Cmd a


fdate : Date -> String
fdate d =
    DE.format English.config DE.isoMsecFormat d


getGraphs :
    List ( String, String, String )
    -> Date
    -> Date
    -> Int
    -> Int
    -> Cmd a
getGraphs specs start end floor ceiling =
    get_graphs ( specs, (fdate start), (fdate end), floor, ceiling )


port get_graphs : ( List ( String, String, String ), String, String, Int, Int ) -> Cmd a


port get_keys : List String -> Cmd a


port get_key : String -> Cmd a


port set_key : ( String, String ) -> Cmd a


port set_keys : List ( String, String ) -> Cmd a


port clear_key : String -> Cmd a


port keyData : (( String, ( Bool, String ) ) -> msg) -> Sub msg


port keysData : (List ( String, ( Bool, String ) ) -> msg) -> Sub msg


port graphsData :
    (List ( String, String, String, ( Int, Int ), List ( Int, Int ) ) -> msg)
    -> Sub msg
