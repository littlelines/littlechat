# Littlechat

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

# Notes

* https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Connectivity
* https://www.pkc.io/blog/untangling-the-webrtc-flow/
* https://www.html5rocks.com/en/tutorials/webrtc/infrastructure/

# I'm a user who wants to start a call.

. I need to press a button to start thi call.
. I need to offer a Peer Connection to every user currently connected.
  * I can get this through `Presence.list`
  * If a user joins after this, what do they do? See below.

# I'm a user who wants to join a call.

. Check if the call is already started. If yes, continue.
. Send a request to the server requesting to join the call.
. The server should ask each user's session to create an offer and send it back to the server.
. The server sends each of these directed offers back to the requesting user.
. The user should respond to each of these requests by setting their remote description and tracks to the given info.
  * Upon receiving this info, how do we trigger the JS?

## What will be the mechanism for keeping track of who sent what to who?
