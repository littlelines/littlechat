// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

var onIceCandidate = (connection, e) => {

}

var createRTCPeerConnection = () => {
  return new RTCPeerConnection({})
  // connection.addEventListener("icecandidate", e => onIceCandidate(connection, e))
}

let Hooks = {}
Hooks.Call = {
  mounted() {
    this.el.addEventListener("click", e => {
      let myConnection = createRTCPeerConnection()
      // Grabs local stream from the local computer.
      window.navigator.mediaDevices.getUserMedia({audio: true, video: true})
        .then(stream => {
          document.getElementById("local-video").srcObject = stream
          // Add each local track to the local RTCPeerConnection.
          stream.getTracks().forEach(track => myConnection.addTrack(track, stream))
          // Create the offer
          myConnection.createOffer()
            .then(offer => {
              console.log(offer.sdp)
              this.pushEvent("video-offer", {sdp: offer.sdp})
            })
            .catch(err => { console.log(err) })
        })
        .catch(reason => {
          console.log(reason)
        })

      console.log("clicked")
    })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket

// var socket = new Socket("/socket", {})
// var channel = socket.channel("call:" + window.roomSlug, {})
// channel.join()
//   .receive("ok", resp => { console.log("joined!") })

// channel.on("call-request", payload => {
//   console.log("SENT: call-request")
// })