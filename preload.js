const { ipcRenderer, contextBridge } = require("electron");

contextBridge.exposeInMainWorld("ipcRenderer", {
  invoke: ipcRenderer.invoke,
});
