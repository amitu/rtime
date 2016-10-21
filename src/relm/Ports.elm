port module Ports exposing (..)

-- elm.core

import Date exposing (Date)


-- extra

import Date.Extra.Format as DE
import Date.Extra.Config.Config_en_us as English


port title : String -> Cmd a


fdate : Date -> String
fdate d =
    DE.format English.config DE.isoMsecFormat d


getGraph :
    String
    -> String
    -> String
    -> Date
    -> Date
    -> Int
    -> Int
    -> Cmd a
getGraph app view host start end floor ceiling =
    get_graph ( app, view, host, (fdate start), (fdate end), floor, ceiling )


port get_graph : ( String, String, String, String, String, Int, Int ) -> Cmd a


port graphData : (( String, String, Int, List ( Int, Int ) ) -> msg) -> Sub msg
