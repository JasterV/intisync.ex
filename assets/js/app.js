import { socketConfig } from "./setup";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const liveSocket = new LiveSocket("/live", Socket, socketConfig);

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
