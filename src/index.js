import "./code-editor.js";
import { Elm } from "./Editor.elm";

const app = Elm.Editor.init({
  node: document.getElementById("elm-node"),
});

app.ports.compileCode.subscribe(function (gameCode) {
  window.ipcRenderer
    .invoke("compile-game-code", gameCode)
    .then(() => {
      app.ports.compileComplete.send({
        ok: true,
        timestamp: Math.floor(Date.now() / 1000),
      });
    })
    .catch((err) => {
      app.ports.compileComplete.send({
        ok: false,
        err,
        timestamp: Math.floor(Date.now() / 1000),
      });
    });
});

// const app = Elm.Main.init({
//   node: document.getElementById("elm-node"),
//   flags: { devicePixelRatio: window.devicePixelRatio },
// });

// window.addEventListener("touchstart", (event) => {
//   app.ports.touchStart.send(getTouchEvents(event.changedTouches));
// });

// window.addEventListener("touchmove", (event) => {
//   app.ports.touchMove.send(getTouchEvents(event.changedTouches));
// });

// window.addEventListener("touchend", (event) => {
//   app.ports.touchEnd.send(getTouchEvents(event.changedTouches));
// });

// window.addEventListener("touchcancel", (event) => {
//   app.ports.touchCancel.send(getTouchEvents(event.changedTouches));
// });

// // touch
// function getTouchEvents(touches) {
//   const a = [];
//   for (let i = 0; i < touches.length; i++) {
//     a.push({
//       identifier: touches[i].identifier,
//       pageX: touches[i].pageX,
//       pageY: touches[i].pageY,
//     });
//   }
//   return a;
// }
