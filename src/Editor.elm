port module Editor exposing (main)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Lazy
import Html exposing (Html, a)
import Html.Attributes
import Html.Events
import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Theme.Color
import Theme.Input as Input
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
    , sourceCodeState : RemoteData String Posix
    }


type RemoteData e a
    = NotAsked
    | Loading (Maybe a)
    | Failure e
    | Success a


init : () -> ( Model, Cmd Msg )
init () =
    ( { code = ""
      , sourceCodeState = NotAsked
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
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
            ( { model
                | sourceCodeState =
                    case model.sourceCodeState of
                        NotAsked ->
                            Loading Nothing

                        Failure _ ->
                            Loading Nothing

                        Success timestamp ->
                            Loading (Just timestamp)

                        Loading maybeSuccess ->
                            Loading maybeSuccess
              }
            , compileCode model.code
            )

        CompileComplete response ->
            let
                newSourceCodeState =
                    case Json.Decode.decodeValue decodeCompileResponse response of
                        Err err ->
                            Failure (Json.Decode.errorToString err)

                        Ok (Ok timestamp) ->
                            Success timestamp

                        Ok (Err err) ->
                            Failure err
            in
            ( { model | sourceCodeState = newSourceCodeState }
            , Cmd.none
            )


decodeCompileResponse : Decoder (Result String Posix)
decodeCompileResponse =
    Json.Decode.field "ok" Json.Decode.bool
        |> Json.Decode.andThen
            (\isOk ->
                if isOk then
                    Json.Decode.field "timestamp" Json.Decode.int
                        |> Json.Decode.map (Time.millisToPosix >> Ok)

                else
                    Json.Decode.map Err
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
            [ spacing 8
            , padding 8
            , Background.color Theme.Color.orange
            , width fill
            ]
            [ el [ Font.color Theme.Color.black ] <| text "Elmgine"
            , Input.button
                { onPress = Just CompileCode
                , label =
                    case model.sourceCodeState of
                        NotAsked ->
                            text "Compile"

                        Loading _ ->
                            text "Compiling"

                        Failure _ ->
                            text "Compiling"

                        Success _ ->
                            text "Compile"
                }
            ]
        , codeEditor CodeChange
        , case model.sourceCodeState of
            NotAsked ->
                text "Write some code and press \"Compile\" to see the results"

            Loading Nothing ->
                text "Compiling"

            Loading (Just timestamp) ->
                Element.Lazy.lazy gamePreview timestamp

            Failure err ->
                text err

            Success timestamp ->
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
