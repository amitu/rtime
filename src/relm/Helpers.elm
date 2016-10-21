module Helpers exposing (..)

import RemoteData as RD
import List.Extra exposing (zip)


range : Int -> Int -> Int -> List Int
range start stop increment =
    populate [] start stop increment


populate : List Int -> Int -> Int -> Int -> List Int
populate current start stop increment =
    let
        done =
            start >= stop
    in
        case done of
            True ->
                current

            False ->
                populate (current ++ [ start ]) (start + increment) stop increment


pmap : (a -> Bool) -> (a -> a) -> List a -> List a
pmap pred fn list =
    List.map
        (\v ->
            if pred v then
                fn v
            else
                v
        )
        list


rdpmap :
    (a -> Bool)
    -> (a -> a)
    -> RD.RemoteData e (List a)
    -> RD.RemoteData e (List a)
rdpmap pred fn rdlist =
    RD.map (\list -> pmap pred fn list) rdlist


pimap : (Int -> Bool) -> (a -> a) -> List a -> List a
pimap pred fn list =
    imap
        (\( i, v ) ->
            if pred i then
                fn v
            else
                v
        )
        list


rdpimap :
    (Int -> Bool)
    -> (a -> a)
    -> RD.RemoteData e (List a)
    -> RD.RemoteData e (List a)
rdpimap pred fn rdlist =
    RD.map (\list -> pimap pred fn list) rdlist


imap : (( Int, a ) -> b) -> List a -> List b
imap fn list =
    let
        length =
            List.length list
    in
        List.map fn (zip (range 0 length 1) list)
