// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Alpine from "../vendor/alpinejs"
import { timer as createTimer } from "./timer.js"

window.Alpine = Alpine
Alpine.start()

let Hooks = {}
Hooks.UpdateLitcoins = {
  mounted() {
    this.el.addEventListener("update-litcoins", event => {
      this.pushEvent('update-litcoins', event.detail)
    })
  }
}
Hooks.CreateCover = {
  mounted() {
    this.el.addEventListener("save-to-spaces", event => {
      this.pushEvent('save-to-spaces', event.detail)
    })
  }
}
Hooks.Toggle = {
  mounted() {
    this.el.addEventListener("toggle-change", event => {
      this.pushEvent('toggle-change', event.detail)
    })
  }
}
Hooks.InfiniteScroll = {
  page() {return this.el.dataset.page;},
  loadMore(entries) {
    const target = entries[0];
    if (target.isIntersecting && this.pending == this.page()) {
      this.pending = this.page() + 1;
      this.pushEvent("load-more", {});
    }
  },
  mounted() {
    this.pending = this.page();
    this.observer = new IntersectionObserver(
      (entries) => this.loadMore(entries),
      {
        root: null, // window by default
        rootMargin: "400px",
        threshold: 0.1,
      }
    );
    this.observer.observe(this.el);
  },
  destroyed() {
    this.observer.unobserve(this.el);
  },
  updated() {
    this.pending = this.page();
  },
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to)
      }
    }
  }
})

window.addEventListener("phx:update-description-input", (e) => {
  let el = document.getElementById("description-input")
  if (el) {
    el.value = e.detail.description
  }
})

window.addEventListener("phx:update-litcoins", (e) => {
  let el = document.getElementById(e.detail.id)
  if(el) {
    liveSocket.execJS(el, el.getAttribute("data-update-litcoins"))
  }
})

window.addEventListener("phx:init-relaxed-mode-timer", (e) => {
    let el = document.getElementById(e.detail.id)
    const relaxedTill = e.detail.relaxed_till
    if(el && relaxedTill >= 0) {
        let timer = createTimer(new Date().setMilliseconds(new Date().getMilliseconds() + relaxedTill))
        setInterval(() => {
            timer.setRemaining();
            el.innerText = `${timer.time().minutes}:${timer.time().seconds}`
        }, 1000);
    }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#5B017A"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

