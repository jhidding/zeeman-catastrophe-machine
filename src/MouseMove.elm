module MouseMove exposing (onMouseMove)

import Svg exposing (Attribute)
import Svg.Events exposing (on)

import Json.Decode as Decode exposing (Decoder)

mouseMoveDecoder : (Float -> Float -> msg) -> Decoder msg
mouseMoveDecoder f =
    Decode.map2 f
        (Decode.field "offsetX" Decode.float)
        (Decode.field "offsetY" Decode.float)

onMouseMove : (Float -> Float -> msg) -> Attribute msg
onMouseMove f = on "mousemove" (mouseMoveDecoder f)

