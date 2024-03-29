// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
import topbar from "topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

let socketConfig = {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
};

export { socketConfig };
