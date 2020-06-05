defmodule LittlechatWeb.Presence do
  use Phoenix.Presence,
    otp_app: :littlechat,
    pubsub_server: Littlechat.PubSub
end
