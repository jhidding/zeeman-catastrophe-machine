-- ------ language="Elm" file="src/Machine.elm"
module Machine exposing (Machine, renderMachine)

-- ------ begin <<import-svg>>[0]
import Svg exposing (..)
import Svg.Attributes exposing (..)

import Html exposing (Html)
import MouseMove exposing (onMouseMove)
-- ------ end
import String exposing (fromFloat, fromInt)

import Msg exposing (Msg(..), Position)

-- ------ begin <<machine-datatype>>[0]
type alias Machine =
    { pointer : Position
    , angle   : Float
    }
-- ------ end

-- ------ begin <<machine-render>>[0]
renderMachine : Machine -> Html Msg
renderMachine m =
    svg [ width "100%"
        , viewBox "-4000 -1200 8000 2400"
        , onMouseMove (\ x y -> MouseMove (Position x y)) ]
        [ g [ pointerEvents "all" ]
            [ rect [ x "-4000", y "-1200", width "8000", height "2400"
                   , fill "none" ] [] ]
        , g [ pointerEvents "none", transform "scale(1000)" ]
            [ rect [ x "-3", y "-1", width "6", height "2"
                   , stroke "black", strokeWidth "0.01", fill "white" ] []
            , circle [ cx (fromFloat <| m.pointer.x - 4.0)
                     , cy (fromFloat <| m.pointer.y - 1.2), r "0.1", fill "red" ] [] ] ]
-- ------ end
-- ------ end
