module Helpers exposing (..)

-- core

import List.Extra exposing (zip)
import Array exposing (Array)


-- extra

import Html.CssHelpers
import RemoteData as RD


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


cmap : (a -> Bool) -> (a -> b) -> List a -> List b
cmap pred fn list =
    List.map fn (Debug.log "filtered" (List.filter pred list))


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


iamap : (( Int, a ) -> b) -> Array a -> List b
iamap fn array =
    let
        length =
            Array.length array
    in
        List.map fn (zip (range 0 length 1) (Array.toList array))


twomap : (( a, a ) -> b) -> List a -> List b
twomap fn list =
    twomap0 fn list []


twomap0 : (( a, a ) -> b) -> List a -> List b -> List b
twomap0 fn lista listb =
    case lista of
        [] ->
            listb

        e1 :: [] ->
            listb

        e1 :: e2 :: tail ->
            twomap0 fn (e2 :: tail) (fn ( e1, e2 ) :: listb)


{ id, class, classList } =
    Html.CssHelpers.withNamespace ""
