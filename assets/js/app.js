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
import adapter from "webrtc-adapter"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

var users = {}
var peerConnections = []
var localStream = null

async function initStream() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({audio: true, video: true, width: "1280"})
    localStream = stream;
    document.getElementById("local-video").srcObject = stream
  } catch (e) {
    console.log(e)
  }
}

var addUserConnection = (userUuid) => {
  if (users[userUuid] === undefined && userUuid != window.userUuid) {
    users[userUuid] = {
      peerConnection: null
    }
  }

  return users;
}

var removeUserConnection = (userUuid) => {
  delete users[userUuid]

  return users
}

var createPeerConnection = (lv, fromUser, sdp) => {
  let newPeerConnection = new RTCPeerConnection({
    iceServers: [
      { urls: "stun:stun.l.google.com:19302" }
    ]
  })
  users[fromUser].peerConnection = newPeerConnection;

  // Add each local track to the RTCPeerConnection.
  localStream.getTracks().forEach(track => newPeerConnection.addTrack(track, localStream))

  // If creating an answer, rather than an initial offer.
  if (sdp != undefined) {
    newPeerConnection.setRemoteDescription({type: "offer", sdp: sdp})
    newPeerConnection.createAnswer()
      .then((answer) => { 
        newPeerConnection.setLocalDescription(answer)
        console.log("Sending this ANSWER to the requester:", answer)
        lv.pushEvent("new_answer", {toUser: fromUser, description: answer})
      })
      .catch((err) => console.log(err))
  }

  newPeerConnection.onicecandidate = async ({candidate}) => {
    // fromUser is the new value for toUser because we're sending this data back
    // to the sender
    lv.pushEvent("new_ice_candidate", {toUser: fromUser, candidate})
  }

  newPeerConnection.onnegotiationneeded = async () => {
    try {
      newPeerConnection.createOffer()
        .then((offer) => { 
          newPeerConnection.setLocalDescription(offer)
          console.log("Sending this offer to the requester:", offer)
          lv.pushEvent("new_sdp_offer", {toUser: fromUser, description: offer})
        })
        .catch((err) => console.log(err))
      // newPeerConnection.setLocalDescription(await newPeerConnection.createOffer())
      // let description = newPeerConnection.localDescription
      // console.log(description)
      // lv.pushEvent("new_sdp_offer", {toUser: fromUser, description})
    }
    catch (error) { 
      console.log(error)
    }
  }

  newPeerConnection.ontrack = async (event) => {
    console.log("Track received:", event)
    document.getElementById(`video-remote-${fromUser}`).srcObject = event.streams[0]
  }

  return newPeerConnection;
}

// Add each local track to the given RTCPeerConnection.
var addTracksToPeerConnection = (peerConnection) => {
  localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream))
}

let Hooks = {}
Hooks.JoinCall = {
  mounted () {
    initStream()
    // this.el.addEventListener("click", e => {
    // })
  }
}

Hooks.HandleOfferRequest = {
  mounted () {
    console.log("new offer request from", this.el.dataset.fromUserUuid)
    let fromUser = this.el.dataset.fromUserUuid
    // 1. Create peer connection with the requesting user.
    // 2. Adds current tracks to the peer connection.
    // 3. Adds the peer connection to the users array for the given user.
    // 4. Creates an offer for the given peer connection.
    // 5. Sends all offer and ICE candidate info to the requesting user via
    //    the `new-offer` topic.
    createPeerConnection(this, fromUser)
  }
}

Hooks.HandleIceCandidateOffer = {
  mounted () {
    let data = this.el.dataset
    let fromUser = data.fromUserUuid
    let iceCandidate = JSON.parse(data.iceCandidate)
    let peerConnection = users[fromUser].peerConnection

    console.log("new ice candidate from", fromUser, iceCandidate)

    peerConnection.addIceCandidate(iceCandidate)
  }
}

Hooks.HandleSdpOffer = {
  mounted () {
    let data = this.el.dataset
    let fromUser = data.fromUserUuid
    let sdp = data.sdp

    if (sdp != "") {
      console.log("new sdp OFFER from", data.fromUserUuid, data.sdp)
      
      createPeerConnection(this, fromUser, sdp)
    }
  }
}

Hooks.HandleAnswer = {
  mounted () {
    let data = this.el.dataset
    let fromUser = data.fromUserUuid
    let sdp = data.sdp
    let peerConnection = users[fromUser].peerConnection

    if (sdp != "") {
      console.log("new sdp ANSWER from", fromUser, sdp)
      peerConnection.setRemoteDescription({type: "answer", sdp: sdp})
    }
  }
}

Hooks.InitUser = {
  mounted () {
    addUserConnection(this.el.dataset.userUuid)
  },

  destroyed () {
    removeUserConnection(this.el.dataset.userUuid)
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