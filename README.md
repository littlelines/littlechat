# Littlechat

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
    * You may have trouble installing `stun` due to OpenSSL. If so, you'll want to set your headers in your environment. [Try this GitHub issue comment for a fix.](https://github.com/processone/ejabberd/issues/1107#issuecomment-217828211)
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

Littlechat is configured to use distillery for deployments. It's configured for an easy deployment via [Gigalixir](https://gigalixir.com/):

```bash
$ git clone https://github.com:littlelines/littlechat.git
$ cd littlechat
$ gigalixir create
$ gigalixir pg:create --free # Remove --free if you need a beefier DB.
$ gigalixir git:remote
$ git push gigalixir master
# ...deployed!
```

The main thing you'll want to watch out for in deployments is that most browsers require HTTPS for WebRTC unless you're at localhost, so make sure you're using HTTPS.

If you'd rather deploy on your own box, you'll just need to adjust some of the values in `prod.exs` accordingly and you'll be on your way.

## Resources

* https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Connectivity
* https://www.pkc.io/blog/untangling-the-webrtc-flow/
* https://www.html5rocks.com/en/tutorials/webrtc/infrastructure/
