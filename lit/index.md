---
title: Zeeman's catastrophe machine
author: Johan Hidding
---

# Introduction

This is a demo of Christopher Zeeman's catastrophe machine. Zeeman was a British mathematician who is known for his work on singularity theory. He popularised a lot of the fundamental ideas put forward by René Thom on *catastrophe theory*.

Catastrophe theory describes how in dynamical systems, small changes in parameters can lead to large and sudden changes in the resulting behaviour. In particular, a system that is completely described by a smooth potential (continuous differentiable) can exert jumpy behaviour. This type of behaviour is found in many physical applications like the stability of ships, but also in optics.

The theory became quite popular in fields such as sociology and ecology. These areas of science are not normally associated with the mathematical rigour that we find in physics. It is mainly due to the complexity of the systems found in nature that these topics have defied exact mathematical descriptions, an idea that was also noted by Rene Thom in is foundational work "Structural Stability and Morphogenesis".

Zeeman's catastrophe machine illustrates catastrophic behaviour in a way that everyone should be able to understand. Here it is:

<div id="machine"></div>
<script src="zeeman.js"></script>
<script>
  Elm.Main.init({ node: document.getElementById("machine") });
</script>

## Literate programming

This demo is written in a style of *literate programming* [@Knuth1984]. The combined code-blocks in this demo compose the compilable source code. For didactic reasons we don't always give the listing of an entire source file in one go. In stead, we use a system of references known as *noweb* [@Ramsey1994].

Inside source fragments you may encounter a line with `<<...>>` marks like in this C++ example,

``` {.cpp #literate-example}
#include <cstdlib>
#include <iostream>

<<example-main-function>>
```

which is then elsewhere specified. Order doesn't matter,

``` {.cpp #hello-world}
std::cout << "Hello, World!" << std::endl;
```

So we can reference the `<<hello-world>>` code block later on.

``` {.cpp #example-main-function}
int main(int argc, char **argv) {
  <<hello-world>>
}
```

A definition can be appended with more code as follows (in this case, order does matter!):

``` {.cpp #hello-world}
return EXIT_SUCCESS;
```

These blocks of code can be *tangled* into source files.

# Problem

We have disk of radius $R$ at the origin, a pin on the edge of this disk at angle $\theta$, an elastic $a$ from the pin to a fixed point on the $x$-axis, and another elastic $b$ from the pin to a free moving pointer, see +@fig:system.

![Zeeman's catastrophe machine](system.svg){#fig:system}

We define the machine model by the position of the pointer and the angle of the disc.

``` {.elm #machine-datatype}
type alias Machine =
    { f     : Position
    , p     : Position
    , theta : Float
    }

<<potential>>
<<elastic-length>>
<<derivatives>>
```

At each time we need to minimize the potential given the pointer position, taking the current angle as the initial guess. To compute the potential, we model the elastics as linear springs, with a relaxed length of 1.

Let the pointer be at position $(x, y)$ and the pinned end at position $(u, v)$, then the total potential energy is

$$V \sim \frac{1}{2} \left[ (l_a - 1)^2 + (l_b - 1)^2 \right],$${#eq:potential-energy}

``` {.elm #potential}
potential : Machine -> Float
potential { f, p, theta } =
    let l_a = elasticLength f theta
        l_b = elasticLength p theta
    in ((l_a - 1)^2 + (l_b - 1)^2) / 2
```

where

$$l_{a}^2 = (\cos \theta - u)^2 + (\sin \theta - v)^2,$${#eq:length-a}
$$l_{b}^2 = (\cos \theta - x)^2 + (\sin \theta - y)^2.$${#eq:length-b}

``` {.elm #elastic-length}
elasticLength : Position -> Float -> Float
elasticLength p theta =
    sqrt <| (cos theta - p.x)^2 + (sin theta - p.y)^2
```

To compute the minimum  it is convenient to have the derivative of the potential.

$$\frac{\partial l_a}{\partial \theta} = \frac{u\sin\theta - v\cos\theta}{l_a},$${#eq:pd-la}
$$\frac{\partial V}{\partial l_a} \sim l_a - 1,$${#eq:pd-pot}

and similar for $\partial V / \partial l_b$, which is then enough to construct a function computing $\partial V / \partial \theta$.

``` {.elm #derivatives}
dPotential : Machine -> Float
dPotential { f, p, theta } =
    let l_a  = elasticLength f theta
        l_b  = elasticLength p theta
        d_a = (f.x * sin theta - f.y * cos theta) / l_a
        d_b = (p.x * sin theta - p.y * cos theta) / l_b
    in (l_a - 1) * d_a + (l_b - 1) * d_b
```

Since we'll use the Newton method to find the roots in the derivative, we'll also need the second derivative. Noting that,

$$\partial_{t}f = \partial_{a}f \partial_{t}a,$${#eq:chainrule}
$$\partial_{tt}f = \partial_{aa}f(\partial_t a)^2 + \partial_a f \partial_{tt} a,$${#eq:double-chainrule}
$$\frac{\partial^2 l_a}{\partial \theta^2} = \frac{u\cos\theta + v\sin\theta - (\partial l_a / \partial \theta)^2}{l_a},$${#eq:pd2-la}

and

$$\frac{\partial^2 V}{\partial l_a} = 1.$${#eq:pd2-pot}

``` {.elm #derivatives}
d2Potential : Machine -> Float
d2Potential { f, p, theta } =
    let l_a   = elasticLength f theta
        l_b   = elasticLength p theta
        d_a   = (f.x * sin theta - f.y * cos theta) / l_a
        d_b   = (p.x * sin theta - p.y * cos theta) / l_b
        dd_a  = (f.x * cos theta + f.y * cos theta - d_a^2) / l_a
        dd_b  = (p.x * cos theta + p.y * cos theta - d_b^2) / l_b
    in d_a^2 + (l_a - 1) * dd_a + d_b^2 + (l_b - 1) * dd_b
```

# Catastrophe analysis

# Numerical methods

There are two methods that we will use to find the minimum of the potential: Newton and bisection. Newton's method converges faster if we're close to a minimum, but if the we're far away, particularly somewhere where the slope of the potential is shallow, Newton behaves bad. This solution maintains an interval that straps the minimum inside. If the Newton method wants to exit this interval, we revert to bisection.

This method is similar to the Brent method which is a hybrid between bisection and secant method.

For visualisation purposes an $\epsilon$ of $0.001$ should suffice.

``` {.elm #brentish}
epsilon : Float
epsilon = 0.001
```

We make sure that we always move down hill. This way we'll never end up on a maximum. Now and then we have to check the sign of the first derivative to enforce this.

``` {.elm #brentish}
signOf : Float -> Float
signOf x = if x > 0 then 1 else if x < 0 then -1 else 0
```

We keep a minimalisation state inside a record, to prevent overly long lists of function arguments. The two elements $a$ and $b$ always straddle the minimum, where $b$ is the last computed value.

``` {.elm #brentish}
type IterationMethod = Guess | Bisect | Newton
type alias Phase = { x : Float, y : Float, dy : Float }
type alias MinState =
    { f    : Float -> Float
    , df   : Float -> Float
    , a    : Phase
    , b    : Phase
    , last : IterationMethod }
```

The triple $x$, $f(x)$ and $f'(x)$ are dubbed *phase*.

``` {.elm #brentish}
phase : MinState -> Float -> Phase
phase s x = Phase x (s.f x) (s.df x)
```

## Updating the state

The state is updated such that the points $a$ and $b$ always stradle the minimum and $b$ is the last computed point.

``` {.elm #brentish}
intersect : MinState -> Phase -> MinState
intersect s p =
    if p.y * s.a.y < 0 then
        {s | b = p }
    else
        {s | a = s.b, b = p }
```

## Bisection method

``` {.elm #brentish}
bisection : MinState -> MinState
bisection ({ f, df, a, b } as s) =
    let x = a.x - a.y * (b.x - a.x) / (b.y - a.y)
    in intersect { s | last = Bisect } <| phase s x
```

## Newton method

The Newton method is accepted only if the result is inside the interval. Otherwise we revert to bisection. This implementation is different from ordinary root-finding Newton method, in that it only searches in a down-hill direction.

``` {.elm #brentish}
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
```

## Looping

The `findRoot` function is a generic function that keeps iterating on `newton` until a sattisfying result is found. This function is generic and should work for any input function.

``` {.elm #brentish}
findRoot : MinState -> Float
findRoot ({ b } as s) =
    if abs b.y < epsilon then
        b.x
    else
        findRoot (newton s)
```

There is some more specialisation in how we initialise the search, finding an interval that should give us a good result.

## Initialising the search

The first task is to find a pair of numbers $x_a$ and $x_b$ for which there is a root in $f$ for a value between $x_a$ and $x_b$. Second criterium is that the derivatives of $f$ don't change sign in the interval. If we're close to an inflection point, which will happen a lot in this application, no such interval may exist. In that case we don't change anything. Since we operate on a periodic space we'll give a finite list of candidate intervals.

``` {.elm #brentish}
bracket : MinState -> List Float -> Maybe MinState
bracket ({ f, df, a, b } as s) qs = case qs of
    []        -> Nothing
    (x :: xs) -> if a.y * b.y < 0 && a.dy * b.dy > 0 then
                    Just s
                 else
                    bracket { s | a = b, b = phase s x } xs
```

We feed the `bracket` function a list of angles.

``` {.elm #brentish}
allAngles : List Float
allAngles = List.map (\ i -> (toFloat i) * 2.0 * pi / 100) (List.range 0 100)
```

``` {.elm #brentish}
initMin : (Float -> Float) -> (Float -> Float) -> Float -> Maybe MinState
initMin f df x =
    let a = Phase x (f x) (df x)
        s = MinState f df a a Guess
        sign = signOf a.y
    in bracket s <| List.map (\ theta -> x - sign * theta) allAngles
```

## Updating the machine

In updating the machine state, the last step is to retrieve a value between $0$ and $2\pi$. This step is not essential, but it keeps me sane.

``` {.elm #brentish}
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
```

# Appendix

## Plotting the machine in Julia

``` {.julia #plot-system}
using Gadfly
using DataFrames

struct Label
    x :: Float64
    y :: Float64
    text :: String
end

t = collect(0.:0.05:2pi)
push!(t, t[1])

phi = 3*pi/5
u, v = cos(phi), sin(phi)
p, q = 2.0, 0.5

label_data = DataFrame([
    Label(  -2.30,  0.00,  "(u, v)"),
    Label(p + 0.1,     q,  "(x, y)"),
    Label(   0.10,  0.40,  "θ"),
    Label(  -1.30,  0.75,  "a"),
    Label(   1.00,  1.00,  "b")
])

disc = layer(
    x=cos.(t), y = sin.(t), Geom.polygon(fill=true), Geom.path,
    order=-1, Theme(alphas=[0.4]))
angle = layer(
    x=[1, 0, u], y=[0, 0, v], Geom.path,
    Theme(default_color=colorant"black"))
labels = layer(label_data, x=:x, y=:y, label=:text,
    Geom.label, Theme(point_label_font_size=10pt))
elastic = layer(
    x=[-2, u, p], y=[0.0, v, q], Geom.path, Geom.point,
    Theme(default_color=colorant"teal", line_width=2pt, point_size=3pt),
    order=2)

plt = plot(disc, angle, elastic, labels,
     Coord.cartesian(xmin=-2.5, xmax=2.5, ymin=-1.2, ymax=1.2, fixed=true),
     Theme(
        panel_fill=colorant"gray90", key_position=:none,
        grid_color=colorant"gray30", panel_stroke=colorant"black"),
     Guide.xticks(ticks=[-2, -1, 0, 1, 2]))

img = SVG("system.svg", 14cm, 7cm)
draw(img, plt)
```

## Rendering SVG

``` {.elm #import-svg}
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)

import Html exposing (Html)
import MouseMove exposing (onMouseMove)
```

``` {.elm #machine-render}
type alias DisplayOptions =
    { showPotential : Bool }

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

renderMachine : DisplayOptions -> Machine -> Html Msg
renderMachine opt m =
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
            , if opt.showPotential then
                polyline [ fill "#00000022", stroke "black", strokeWidth "0.01"
                         , points <| potentialPathString m ] []
              else g [] []
            , crossHair m.p
            , circle [ cx (fromFloat <| (wheelPosition m.theta).x)
                     , cy (fromFloat <| (wheelPosition m.theta).y)
                     , r "0.07", fill "#ffaa88", strokeWidth "0.01", stroke "black" ] []
            , circle [ cx (fromFloat <| m.f.x), strokeWidth "0.01", stroke "black"
                     , cy (fromFloat <| m.f.y), r "0.07", fill "#ffaa88" ] []
            ]
        ]
```

## Scaffold

``` {.elm file=src/Machine.elm}
module Machine exposing
    ( Machine
    , DisplayOptions
    , renderMachine
    , fromPosition
    , minimizeMachine
    , dPotential
    , d2Potential )

<<import-svg>>
import String exposing (fromFloat, fromInt)

import Msg exposing (Msg(..), Position)

<<machine-datatype>>
<<brentish>>
<<machine-render>>
```

