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
    }

init : Model
init = Model (Machine (Position 0 0) 0.0)

update : Msg -> Model -> Model
update (MouseMove p) m =
    let x = p.x / 1000.0
        y = p.y / 1000.0
        oldMachine = m.machine
    in { m | machine = { oldMachine | pointer = Position x y } }

view : Model -> Html Msg
view m = div [] [ text ((fromFloat m.machine.pointer.x) ++ " , "
                        ++ (fromFloat m.machine.pointer.y))
                , renderMachine m.machine ]

