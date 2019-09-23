-- ------ language="Elm" file="src/Machine.elm"
module Machine exposing
    ( Machine
    , renderMachine
    , fromPosition
    , minimizeMachine
    , dPotential
    , d2Potential )

-- ------ begin <<import-svg>>[0]
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)

import Html exposing (Html)
import MouseMove exposing (onMouseMove)
-- ------ end
import String exposing (fromFloat, fromInt)

import Msg exposing (Msg(..), Position)

-- ------ begin <<machine-datatype>>[0]
type alias Machine =
    { f     : Position
    , p     : Position
    , theta : Float
    }

-- ------ begin <<potential>>[0]
potential : Machine -> Float
potential { f, p, theta } =
    let l_a = elasticLength f theta
        l_b = elasticLength p theta
    in ((l_a - 1)^2 + (l_b - 1)^2) / 2
-- ------ end
-- ------ begin <<elastic-length>>[0]
elasticLength : Position -> Float -> Float
elasticLength p theta =
    sqrt <| (cos theta - p.x)^2 + (sin theta - p.y)^2
-- ------ end
-- ------ begin <<derivatives>>[0]
dPotential : Machine -> Float
dPotential { f, p, theta } =
    let l_a  = elasticLength f theta
        l_b  = elasticLength p theta
        d_a = (f.x * sin theta - f.y * cos theta) / l_a
        d_b = (p.x * sin theta - p.y * cos theta) / l_b
    in (l_a - 1) * d_a + (l_b - 1) * d_b
-- ------ end
-- ------ begin <<derivatives>>[1]
d2Potential : Machine -> Float
d2Potential { f, p, theta } =
    let l_a   = elasticLength f theta
        l_b   = elasticLength p theta
        d_a   = (f.x * sin theta - f.y * cos theta) / l_a
        d_b   = (p.x * sin theta - p.y * cos theta) / l_b
        dd_a  = (f.x * cos theta + f.y * cos theta - d_a^2) / l_a
        dd_b  = (p.x * cos theta + p.y * cos theta - d_b^2) / l_b
    in d_a^2 + (l_a - 1) * dd_a + d_b^2 + (l_b - 1) * dd_b
-- ------ end
-- ------ end
-- ------ begin <<brentish>>[0]
epsilon : Float
epsilon = 0.001
-- ------ end
-- ------ begin <<brentish>>[1]
signOf : Float -> Float
signOf x = if x > 0 then 1 else if x < 0 then -1 else 0
-- ------ end
-- ------ begin <<brentish>>[2]
type IterationMethod = Guess | Bisect | Newton
type alias Phase = { x : Float, y : Float, dy : Float }
type alias MinState =
    { f    : Float -> Float
    , df   : Float -> Float
    , a    : Phase
    , b    : Phase
    , last : IterationMethod }
-- ------ end
-- ------ begin <<brentish>>[3]
phase : MinState -> Float -> Phase
phase s x = Phase x (s.f x) (s.df x)
-- ------ end
-- ------ begin <<brentish>>[4]
intersect : MinState -> Phase -> MinState
intersect s p =
    if p.y * s.a.y < 0 then
        {s | b = p }
    else
        {s | a = s.b, b = p }
-- ------ end
-- ------ begin <<brentish>>[5]
bisection : MinState -> MinState
bisection ({ f, df, a, b } as s) =
    let x = a.x - a.y * (b.x - a.x) / (b.y - a.y)
    in intersect { s | last = Bisect } <| phase s x
-- ------ end
-- ------ begin <<brentish>>[6]
inside : MinState -> Float -> Bool
inside { a, b } x =
    let d = abs (b.x - a.x)
    in abs (x - a.x) < d && abs (x - b.x) < d

newton : MinState -> MinState
newton ({ b } as s) =
    let sign       = signOf b.y
        x          = b.x - sign * abs (b.y / b.dy)
    in if inside s x then
        intersect { s | last = Newton } <| phase s x
    else
        bisection s
-- ------ end
-- ------ begin <<brentish>>[7]
findRoot : MinState -> Float
findRoot ({ b } as s) =
    if abs b.y < epsilon then
        b.x
    else
        findRoot (newton s)
-- ------ end
-- ------ begin <<brentish>>[8]
bracket : MinState -> List Float -> Maybe MinState
bracket ({ f, df, a, b } as s) qs = case qs of
    []        -> Nothing
    (x :: xs) -> if a.y * b.y < 0 && a.dy * b.dy > 0 then
                    Just s
                 else
                    bracket { s | a = b, b = phase s x } xs
-- ------ end
-- ------ begin <<brentish>>[9]
allAngles : List Float
allAngles = List.map (\ i -> (toFloat i) * 2.0 * pi / 100) (List.range 0 100)
-- ------ end
-- ------ begin <<brentish>>[10]
initMin : (Float -> Float) -> (Float -> Float) -> Float -> Maybe MinState
initMin f df x =
    let a = Phase x (f x) (df x)
        s = MinState f df a a Guess
        sign = signOf a.y
    in bracket s <| List.map (\ theta -> x - sign * theta) allAngles
-- ------ end
-- ------ begin <<brentish>>[11]
modulo : Float -> Float -> Float
modulo x m = x - (toFloat <| floor <| x / m) * m

minimizeMachine : Machine -> Machine
minimizeMachine m =
    let f  = \ theta -> dPotential { m | theta = theta }
        df = \ theta -> d2Potential { m | theta = theta }
        ms  = initMin f df m.theta
    in case ms of
        Just s  -> { m | theta = modulo (findRoot s) (2 * pi) }
        Nothing -> m
-- ------ end
-- ------ begin <<machine-render>>[0]
fromPosition : Position -> String
fromPosition { x, y } = (fromFloat x) ++ "," ++ (fromFloat y)

wheelPosition : Float -> Position
wheelPosition theta = { x = cos theta, y = sin theta }

elasticPathString : Machine -> String
elasticPathString { f, p, theta } =
    (fromPosition f) ++ " "
    ++ (fromPosition <| wheelPosition theta) ++ " "
    ++ (fromPosition p)

pathString : List (Float, Float) -> String
pathString pts = String.join " "
    <| List.map (\ (x, y) -> (fromFloat x) ++ "," ++ (fromFloat y)) pts

potentialPathString : Machine -> String
potentialPathString m =
    let pts = List.map (\ t -> fromPolar (1 + dPotential { m | theta = t }, t)) allAngles
    in pathString pts

discDecoration : Machine -> Svg Msg
discDecoration m =
    let outerRim t = List.map (\ i -> (0.9, t + (toFloat i)*2*pi/80)) (List.range 1 19)
        innerRim t = List.map (\ i -> (0.1, t + (toFloat i)*2*pi/20)) (List.range 1 4)
        path t = List.append (List.reverse <| innerRim t) (outerRim t)
        pts t = List.map fromPolar (path t)
        art t = polygon [ fill "#ffffffcc", stroke "black", strokeWidth "0.01"
                        , points <| pathString <| pts t ] []
    in g [] [ art <| m.theta
            , art <| m.theta + pi/2
            , art <| m.theta + pi
            , art <| m.theta + 3*pi/2 ]

crossHair : Position -> Svg Msg
crossHair { x, y } =
    g [] [ line [ x1 (fromFloat <| x - 0.15), y1 (fromFloat <| y)
                , x2 (fromFloat <| x + 0.15), y2 (fromFloat <| y)
                , stroke "black", strokeWidth "0.04" ] []
         , line [ x1 (fromFloat <| x), y1 (fromFloat <| y - 0.15)
                , x2 (fromFloat <| x), y2 (fromFloat <| y + 0.15)
                , stroke "black", strokeWidth "0.04" ] []
         , line [ x1 (fromFloat <| x - 0.14), y1 (fromFloat <| y)
                , x2 (fromFloat <| x + 0.14), y2 (fromFloat <| y)
                , stroke "white", strokeWidth "0.01" ] []
         , line [ x1 (fromFloat <| x), y1 (fromFloat <| y - 0.14)
                , x2 (fromFloat <| x), y2 (fromFloat <| y + 0.14)
                , stroke "white", strokeWidth "0.01" ] []
         ]

renderMachine : Machine -> Html Msg
renderMachine m =
    svg [ width "100%"
        , viewBox "-3500 -1500 8000 3000"
        , onMouseMove (\ x y -> MouseMove (Position x y))
        , onClick MouseClick ]
        [ g [ pointerEvents "bounding-box" ]
            [ rect [ x "-3500", y "-1500", width "8000", height "3000"
                   , fill "none" ] [] ]
        , g [ pointerEvents "none", transform "scale(1000)" ]
            [ rect [ x "-3.5", y "-1.5", width "8", height "3"
                   , stroke "black", strokeWidth "0.01", fill "white" ] []
            , circle [ cx "0", cy "0", r "1", fill "#ffcc88", stroke "black"
                     , strokeWidth "0.01" ] []
            , discDecoration m
            , polyline [ fill "none", stroke "white", strokeWidth "0.08"
                       , points <| elasticPathString m ] []
            , polyline [ fill "none", stroke "black", strokeWidth "0.05"
                       , points <| elasticPathString m ] []
            , polyline [ fill "#00000022", stroke "black", strokeWidth "0.01"
                       , points <| potentialPathString m ] []
            , crossHair m.p
            , circle [ cx (fromFloat <| (wheelPosition m.theta).x)
                     , cy (fromFloat <| (wheelPosition m.theta).y)
                     , r "0.07", fill "#ffaa88", strokeWidth "0.01", stroke "black" ] []
            , circle [ cx (fromFloat <| m.f.x), strokeWidth "0.01", stroke "black"
                     , cy (fromFloat <| m.f.y), r "0.07", fill "#ffaa88" ] []
            ]
        ]
-- ------ end
-- ------ end
