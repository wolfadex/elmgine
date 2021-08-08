// Modules to control application life and create native browser window
const path = require("path");
const fs = require("fs");
const { app, BrowserWindow } = require("electron");
const { ipcMain } = require("electron");
const esbuild = require("esbuild");
const ElmPlugin = require("esbuild-plugin-elm");

function createWindow() {
  // Create the browser window.
  const mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      // nodeIntegration: true,
      preload: path.join(__dirname, "preload.js"),
    },
  });

  // and load the index.html of the app.
  mainWindow.loadFile("index.html");

  // Open the DevTools.
  // mainWindow.webContents.openDevTools();
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(() => {
  createWindow();

  app.on("activate", function () {
    // On macOS it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on("window-all-closed", function () {
  if (process.platform !== "darwin") app.quit();
});

ipcMain.handle("compile-game-code", async function (_, gameCode) {
  console.log("compiling game code");
  try {
    fs.writeFileSync(
      path.join(__dirname, "game-code", "src", "UserGame.elm"),
      gameCode,
      { encoding: "utf-8" }
    );
    process.chdir("./game-code");

    return esbuild
      .build({
        entryPoints: ["game-code/src/index.js"],
        bundle: true,
        outfile: "game-code/dist/bundle.js",
        plugins: [ElmPlugin()],
      })
      .finally(() => {
        process.chdir("..");
      });
  } catch (err) {
    return err;
  }
});
