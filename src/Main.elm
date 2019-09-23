import Browser
import Html exposing (..)
import Html.Events exposing (onClick)
import String exposing (fromFloat)

import Machine exposing (..)
import Msg exposing (Msg(..), Position)

main = Browser.sandbox { init = init, update = update, view = view }

type Options
    = ShowPotential
    | ShowManifold

type alias Model =
    { machine : Machine
    , pointerLock : Bool
    }

init : Model
init = Model { f = Position -3 0, p = Position 0 0, theta = 0.0 }
             False

update : Msg -> Model -> Model
update msg m = case msg of
    (MouseMove p) ->
        if not m.pointerLock then
            let x = p.x / 100.0 - 3.5
                y = p.y / 100.0 - 1.5
                oldMachine = m.machine
            in { m | machine = minimizeMachine { oldMachine | p = Position x y } }
        else
            m
    MouseClick ->
        { m | pointerLock = not m.pointerLock }

view : Model -> Html Msg
view m = div [] [ renderMachine m.machine ]

