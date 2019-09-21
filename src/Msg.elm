module Msg exposing (Msg(..), Position)

type alias Position = { x: Float, y: Float }

type Msg = MouseMove Position

