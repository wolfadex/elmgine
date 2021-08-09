module Theme.Input exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Theme.Color


button : { onPress : Maybe msg, label : Element msg } -> Element msg
button =
    Input.button
        [ paddingXY 16 8
        , Background.color Theme.Color.green
        , Font.color Theme.Color.white
        ]
