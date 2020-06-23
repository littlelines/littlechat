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
import regeneratorRuntime from "regenerator-runtime"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

var peerConnections = [];
var localStream = null;

var createPeerConnection = (lv, targetUser) => {
  let newPeerConnection = new RTCPeerConnection({
    iceServers: [
      { urls: "stun:stun.l.google.com:19302" }
    ]
  })

  // Add new peer connection to our peer connections array.
  peerConnections.push(newPeerConnection)

  newPeerConnection.onicecandidate = async ({candidate}) => {
    console.log(candidate, targetUser)
    lv.pushEvent("send_ice_candidate", {candidate, targetUser})
  }

  newPeerConnection.onnegotiationneeded = async () => {
    try {
      await newPeerConnection.setLocalDescription(await newPeerConnection.createOffer())
      let sdp = newPeerConnection.localDescription()
      lv.pushEvent("send_video_offer", {targetUser, sdp})
    }
    catch (error) { 
      console.log(error)
    }
  }

  newPeerConnection.ontrack = async (event) => {
    document.getElementById(`video-remote-${targetUser}`).srcObject = event.streams[0]
  }

  // Add each local track to the RTCPeerConnection.
  // localStream.getTracks().forEach(track => newPeerConnection.addTrack(track, localStream))

  return newPeerConnection;
}

// Add each local track to the given RTCPeerConnection.
var addTracksToPeerConnection = (peerConnection) => {
  localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream))
}

let Hooks = {}
Hooks.StartCall = {
  mounted() {
    this.el.addEventListener("click", e => {
      // let myConnection = createPeerConnection()
      // Grabs local stream from the local computer.
      window.navigator.mediaDevices.getUserMedia({audio: true, video: true})
        .then(stream => {
          localStream = stream;
          document.getElementById("local-video").srcObject = stream
          // Add each local track to the RTCPeerConnection.
          // stream.getTracks().forEach(track => myConnection.addTrack(track, stream))
          // Create the offer
          // myConnection.createOffer()
          //   .then(offer => {
          //     // Sends ICE candidate SDP info to the server to be passed on to the other users.
          //     myConnection.setLocalDescription(offer)
          //     this.pushEvent("send_video_offer", {sdp: offer.sdp, targetUser: "test"})
          //   })
          //   .catch(err => { console.log(err) })
        })
        .catch(reason => {
          console.log(reason)
        })
    })
  }
}

Hooks.JoinCall = {

}

Hooks.SetupPeer = {

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