module Main exposing (main)

import Color exposing (black, blue, darkGray, gray, green, hsl, hsla, lightBlue, red, white, yellow)
import Html exposing (Html)
import Illuminance
import LuminousFlux
import Playground3d exposing (Computer, Shape, block, configurations, gameWithConfigurations, getFloat, group, line, moveX, moveY, moveZ, rotateAround, rotateX, rotateY, rotateZ, scale, scaleAround, wave, waveWithDelay)
import Playground3d.Camera exposing (Camera, perspective)
import Playground3d.Light as Light
import Playground3d.Scene as Scene
import Scene3d
import Scene3d.Light
import Temperature


main =
    gameWithConfigurations view update initialConfigurations init


type alias Model =
    {}



-- INIT


init : Computer -> Model
init computer =
    {}


initialConfigurations =
    configurations
        [ ( "number of blocks", ( 10, 25, 60 ) )
        , ( "frequency", ( 1, 10, 20 ) )
        , ( "minWidth", ( 0, 35, 45 ) )
        , ( "a", ( 0, 1, 3 ) )
        , ( "maxWidth", ( 10, 37, 50 ) )
        , ( "period", ( 0.5, 5, 10 ) )
        , ( "lux", ( 2, 5, 5 ) )
        , ( "intensity above", ( 0, 60, 300 ) )
        , ( "intensity below", ( 0, 290, 300 ) )
        ]
        []



-- UPDATE


update : Computer -> Model -> Model
update computer model =
    model



-- VIEW


view : Computer -> Model -> Html Never
view computer model =
    let
        firstLight =
            Light.point
                { position = { x = -45, y = 30, z = 45 }
                , chromaticity = Scene3d.Light.incandescent
                , intensity = LuminousFlux.lumens 6000
                }

        secondLight =
            Light.point
                { position = { x = -45, y = -30, z = 45 }
                , chromaticity = Scene3d.Light.fluorescent
                , intensity = LuminousFlux.lumens 6000
                }

        thirdLight =
            Light.directional
                { azimuth = getFloat "azimuth for third light" computer
                , elevation = getFloat "elevation for third light" computer
                , chromaticity = Scene3d.Light.colorTemperature (Temperature.kelvins 2000)
                , intensity = Illuminance.lux (10 ^ getFloat "lux" computer)
                }

        fourthLight =
            Light.soft
                { azimuth = getFloat "azimuth for fourth light" computer
                , elevation = getFloat "elevation for fourth light" computer
                , chromaticity = Scene3d.Light.fluorescent
                , intensityAbove = Illuminance.lux (getFloat "intensity above" computer)
                , intensityBelow = Illuminance.lux (getFloat "intensity below" computer)
                }
    in
    Scene.custom
        { screen = computer.screen
        , camera = camera computer
        , lights =
            Scene3d.fourLights
                firstLight
                secondLight
                thirdLight
                fourthLight
        , clipDepth = 0.1
        , exposure = Scene3d.exposureValue 6
        , toneMapping = Scene3d.hableFilmicToneMapping -- See ExposureAndToneMapping.elm for details
        , whiteBalance = Scene3d.Light.fluorescent
        , antialiasing = Scene3d.multisampling
        , backgroundColor = gray
        }
        (shapes computer model)


camera : Computer -> Camera
camera computer =
    perspective
        { focalPoint = { x = 0, y = 0, z = 0 }
        , eyePoint =
            { x = 10
            , y = wave -20 20 20 computer.time
            , z = 60
            }
        , upDirection = { x = 0, y = 1, z = 0 }
        }


shapes : Computer -> Model -> List Shape
shapes computer model =
    [ yellowBlocks computer
    ]


yellowBlocks computer =
    let
        wavy i =
            waveWithDelay (0.1 * toFloat i) 0 1 4 computer.time

        oneBlock i =
            block (hsl (wavy i) 0.6 0.8) ( 1, 3, 1 )
                |> scale (getFloat "a" computer * toFloat i)
                |> moveX (getFloat "a" computer * toFloat i)
                |> rotateY (wavy i)
                |> rotateX (wavy i)
                |> rotateZ (wavy i)
                |> moveX (1.4 * toFloat i)
    in
    group
        (List.range -10 10
            |> List.map oneBlock
        )