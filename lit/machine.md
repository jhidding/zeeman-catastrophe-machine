---
title: The catastrophe machine
---

``` {.elm file=src/Machine.elm}
module Machine exposing (Machine, renderMachine)

<<import-svg>>
import String exposing (fromFloat, fromInt)

import Msg exposing (Msg(..), Position)

<<machine-datatype>>

<<machine-render>>
```

# The math

## Problem

We have disk of radius $R$ at the origin, a pin on the edge of this disk at angle $\theta$,
an elastic from the pin to a point on the $x$-axis, and another elastic from the pin to a free moving pointer, see +@fig:system.

![Zeeman's catastrophe machine](system.svg){#fig:system}

We define the machine model by the position of the pointer and the angle of the disc.

``` {.elm #machine-datatype}
type alias Machine =
    { pointer : Position
    , angle   : Float
    }
```

At each time we need to minimize the potential given the pointer position, taking the current angle as the initial guess. To compute the potential, we model the elastics as linear springs, with a relaxed length of 1.

$$l_a^2 = \sin^2 \theta + (\cos \theta - 2.0)^2$$
$$l_b^2 = (\cos \theta - x)^2 + (\sin \theta - y)^2$$
$$V \sim \left[ (l_a - 1)^2 + (l_b - 1)^2 \right]$$

To compute the minimum  it is convenient to have the derivative of the potential.

$$\frac{\partial l_a}{\partial \theta} = \frac{2.0 \sin\theta}{l_a},$$
$$\frac{\partial l_b}{\partial \theta} = \frac{x\sin\theta - y\cos\theta}{l_b},$$
$$\frac{\partial V}{\partial l_a} \sim 2 (l_a - 1),$$

and similar for $\partial V / \partial l_b$, which is then enough to construct a function computing $\partial V / \partial \theta$.

## Numerical methods

``` {.elm #newton-raphson}

```

# Appendix

``` {.julia #plot-system}
using Gadfly

t = collect(0.:0.05:2pi)
push!(t, t[1])

phi = 3*pi/5
u, v = cos(phi), sin(phi)
p, q = 2.0, 0.5

disc = layer(
    x=cos.(t), y = sin.(t), Geom.polygon(fill=true), Geom.path,
    order=-1, Theme(alphas=[0.4]))
angle = layer(
    x=[1, 0, u], y=[0, 0, v], Geom.path,
    Theme(default_color=colorant"black"))
labels = layer(
    x=[0.1, p + 0.1], y=[0.4, q], label=["θ", "q"], Geom.label,
    Theme(point_label_font_size=10pt))
elastic = layer(
    x=[-2, u, p], y=[0.0, v, q], Geom.path, Geom.point,
    Theme(default_color=colorant"teal", line_width=2pt, point_size=3pt),
    order=2)

plt = plot(disc, angle, elastic, labels,
     Coord.cartesian(xmin=-2.5, xmax=2.5, ymin=-1.2, ymax=1.2, fixed=true),
     Theme(
        panel_fill=colorant"gray90", key_position=:none,
        grid_color=colorant"gray30"),
     Guide.xticks(ticks=[-2, -1, 0, 1, 2]))

img = SVG("system.svg", 14cm, 7cm)
draw(img, plt)
```

## Rendering

``` {.elm #import-svg}
import Svg exposing (..)
import Svg.Attributes exposing (..)

import Html exposing (Html)
import MouseMove exposing (onMouseMove)
```

``` {.elm #machine-render}
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
```
