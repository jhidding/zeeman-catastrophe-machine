import Browser
import Html exposing (..)
import Html.Events exposing (onClick, onCheck)
import Html.Attributes exposing (type_, style)
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
    , displayOptions : DisplayOptions
    }

init : Model
init = Model (minimizeMachine
                { f = Position -3 0
                , p = Position 3 -0.5
                , theta = 0.0 })
             False
             { showPotential = False }

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
    TogglePotential v ->
        let opt = m.displayOptions
        in { m | displayOptions = { opt | showPotential = v } }

view : Model -> Html Msg
view m = div [ style "background" "white" ]
    [ renderMachine m.displayOptions m.machine
    , table [ style "border" "solid thin black"
            , style "padding" "5pt"
            , style "width" "100%" ]
        [ caption [] [ text "Options" ]
        , tr []
            [ td [] [ input [ type_ "checkbox", onCheck TogglePotential ] []]
                    , text "show slope of potential" ]
        ]
    ]

