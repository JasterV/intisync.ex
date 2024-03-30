import { socketConfig } from "./setup";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import HubHook from "./hubHook";
import NativeShareHook from "./nativeShareHook";
import CopyToClipboardHook from "./copyToClipboardHook";

const Hooks = {
  Hub: HubHook(),
  NativeShare: NativeShareHook(),
  CopyToClipboard: CopyToClipboardHook(),
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
