port module Editor exposing (main)

import Browser
import Element exposing (..)
import Element.Input as Input
import Element.Lazy
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Time exposing (Posix)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Model =
    { code : String
    , sourceCodeState : ( Posix, Result String () )
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( { code = ""
      , sourceCodeState = ( Time.millisToPosix 0, Err "" )
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    compileComplete CompileComplete


port compileComplete : (Value -> msg) -> Sub msg


type Msg
    = NoOp
    | CodeChange String
    | CompileCode
    | CompileComplete Value


port compileCode : String -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        CodeChange code ->
            ( { model | code = code }, Cmd.none )

        CompileCode ->
            ( model, compileCode model.code )

        CompileComplete response ->
            let
                newSourceCodeState =
                    case Json.Decode.decodeValue decodeCompileResponse response of
                        Err err ->
                            ( Tuple.first model.sourceCodeState
                                |> Time.posixToMillis
                                |> (+) 1
                                |> Time.millisToPosix
                            , Err (Json.Decode.errorToString err)
                            )

                        Ok maybeCompileErr ->
                            maybeCompileErr
            in
            ( { model | sourceCodeState = newSourceCodeState }
            , Cmd.none
            )


decodeCompileResponse : Decoder ( Posix, Result String () )
decodeCompileResponse =
    Json.Decode.map2 Tuple.pair
        (Json.Decode.field "timestamp" Json.Decode.int
            |> Json.Decode.map Time.millisToPosix
        )
        (Json.Decode.field "ok" Json.Decode.bool)
        |> Json.Decode.andThen
            (\( timestamp, isOk ) ->
                if isOk then
                    Json.Decode.succeed ( timestamp, Ok () )

                else
                    Json.Decode.map (\err -> ( timestamp, Err err ))
                        (Json.Decode.field "err" Json.Decode.string)
            )


view : Model -> Html Msg
view model =
    layout [ width fill, height fill ] (viewBody model)


viewBody : Model -> Element Msg
viewBody model =
    column
        [ width fill, height fill ]
        [ row
            []
            [ text "Elmgine"
            , Input.button
                []
                { onPress = Just CompileCode
                , label = text "Compile"
                }
            ]
        , codeEditor CodeChange
        , case model.sourceCodeState of
            ( timestamp,Err  err ) ->
                text err

            ( timestamp,Ok  () ) ->
                Element.Lazy.lazy gamePreview timestamp
        ]


codeEditor : (String -> Msg) -> Element Msg
codeEditor onChange =
    Html.node "code-editor"
        [ Html.Events.on "change"
            (Json.Decode.map onChange
                (Json.Decode.field "detail" Json.Decode.string)
            )
        ]
        []
        |> html
        |> el [ width fill ]


gamePreview : Posix -> Element Msg
gamePreview timestamp =
    Html.iframe
        [ Html.Attributes.src ("game-code/index.html?timestamp=" ++ String.fromInt (Time.posixToMillis timestamp)) ]
        []
        |> html
        |> el [ width fill, height fill ]
