# Elmgine

A modification of [erkal/elm-3d-playground-exploration](https://github.com/erkal/elm-3d-playground-exploration) where a GUI is provided for writing code, modifying configurations, and a WYSIWYG editor for the game world.


## For Development 
First [install yarn](https://classic.yarnpkg.com/en/docs/install/#mac-stable) if you don't have it already.

Clone the repository
```bash
git clone https://github.com/wolfadex/elmgine.git
```
and navigate into it:
```bash
cd elmgine
```

To install all dependencies, type and run
```bash
yarn
```

To compile the editor in dev mode run
```bash
yarn dev
```
To start the editor run
```bash
yarn start
```

## Example

Once the editor is running, paste
```elm
module UserGame exposing (view)

import Html exposing (Html)

view : Html msg
view =
    Html.text "G g g game TIME!!"
```
into the editor and click `Compile`. The running version of your game will display below the code editor.

**Note: The editor currently expects a module named `UserGame` with an exposed function `view : Html msg`. This will be updated as new features were added.**