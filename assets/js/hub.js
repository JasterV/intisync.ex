import { socketConfig } from "./setup";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import HubHook from "./hubHook";

const Hooks = {
  HubHook: HubHook(
    "ws://127.0.0.1:12345/buttplug",
    "ws://192.168.1.45:12345/buttplug",
  ),
};

const liveSocket = new LiveSocket("/live", Socket, {
  ...socketConfig,
  hooks: Hooks,
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
