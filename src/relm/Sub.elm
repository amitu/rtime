module Sub exposing (..)


all : a -> Bool
all a =
    True


everyone : a -> Bool
everyone =
    all



--map :
--    m
--    -> (m -> List a)
--    -> (a -> Bool)
--    -> (a -> ( a, Cmd b ))
--    -> (Cmd b -> Cmd c)
--    -> (( m, List a ) -> m)
--    -> ( m, Cmd c )
--map model fn1 pred update cmdmap fn2 =
--    List.map
--        (\child ->
--            if pred child then
--                update child
--            else
--                ( child, Cmd.none )
--        )
-- rdmap
