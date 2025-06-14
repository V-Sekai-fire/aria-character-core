// TimeStrike Frontend Application
// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Phoenix LiveView Hooks
let Hooks = {}

// TimeStrike 3D Hook
Hooks.TimeStrike3D = {
  mounted() {
    console.log("TimeStrike3D hook mounted")
    this.initializeThreeJS()
  },
  
  initializeThreeJS() {
    // Wait for Three.js to be available
    if (typeof THREE !== 'undefined' && typeof TimeStrike3D !== 'undefined') {
      this.timeStrike3D = new TimeStrike3D(this.el.id)
      console.log('TimeStrike 3D scene initialized via hook')
    } else {
      // Retry after a short delay
      setTimeout(() => this.initializeThreeJS(), 100)
    }
  },
  
  destroyed() {
    if (this.timeStrike3D) {
      this.timeStrike3D.dispose()
      this.timeStrike3D = null
      console.log('TimeStrike 3D scene disposed via hook')
    }
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
window.liveSocket = liveSocket

// TimeStrike-specific keyboard controls
document.addEventListener("keydown", function(event) {
  if (event.code === "Space") {
    event.preventDefault()
    // Send pause/resume event to LiveView
    liveSocket.execJS(document.querySelector("[phx-click='toggle_pause']"), "phx:click")
  }
  
  if (event.code === "KeyQ") {
    event.preventDefault()
    // Send quit event to LiveView  
    liveSocket.execJS(document.querySelector("[phx-click='quit_game']"), "phx:click")
  }
  
  if (event.code === "KeyC") {
    event.preventDefault()
    // Send change conviction event to LiveView
    liveSocket.execJS(document.querySelector("[phx-click='change_conviction']"), "phx:click")
  }
})

// Three.js Integration for TimeStrike
let timeStrike3D = null;

// Initialize Three.js scene when page loads
window.addEventListener("phx:page-loading-stop", function() {
  // Check if we're on the timestrike page and Three.js is available
  const container = document.getElementById('timestrike-3d-container');
  if (container && typeof THREE !== 'undefined' && !timeStrike3D) {
    // Dynamically load TimeStrike3D class
    if (typeof TimeStrike3D !== 'undefined') {
      timeStrike3D = new TimeStrike3D('timestrike-3d-container');
      console.log('TimeStrike 3D scene initialized');
    } else {
      console.log('Waiting for TimeStrike3D class to load...');
    }
  }
});

// Clean up Three.js on page navigation
window.addEventListener("phx:page-loading-start", function() {
  if (timeStrike3D) {
    timeStrike3D.dispose();
    timeStrike3D = null;
    console.log('TimeStrike 3D scene disposed');
  }
});

// Handle Three.js events from LiveView
window.addEventListener("phx:agent_moved", function(event) {
  console.log('Received agent_moved event:', event.detail);
  if (timeStrike3D) {
    const { agent_id, position, duration } = event.detail;
    timeStrike3D.updateAgentPosition(agent_id, position, duration * 1000);
  }
});
