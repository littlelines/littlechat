defmodule LittlechatWeb.Room.ShowLive do
  @moduledoc """
  A LiveView for creating and joining chat rooms.
  """

  use LittlechatWeb, :live_view

  alias Littlechat.Organizer
  alias Littlechat.ConnectedUser

  alias LittlechatWeb.Presence
  alias Phoenix.Socket.Broadcast

  @impl true
  def render(assigns) do
    ~L"""
    <script>window.roomSlug = "<%= @room.slug %>"</script>

    <h1><%= @room.title %></h1>

    <h3>Connected Users:</h3>
    <ul>
    <%= for uuid <- @connected_users do %>
      <li><%= uuid %></li>
    <% end %>
    </ul>

    <video id="local-video" playsinline autoplay muted width="500"></video>

    <%= for uuid <- @connected_users do %>
      <video id="video-remote-<%= uuid %>" playsinline autoplay width="500"></video>
    <% end %>

    <div>
      <button phx-click="start_call" phx-hook="StartCall">Start Call</button>
      <button phx-click="join_call" phx-hook="JoinCall">Join Call</button>
      <button phx-click="leave_call">Hang Up</button>
    </div>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    # User presence tracking.
    user = create_connected_user()

    # This PubSub subscription will also handle other events from the users.
    Phoenix.PubSub.subscribe(Littlechat.PubSub, "room:" <> slug)

    # This PubSub subscription will allow the user to receive messages from
    # other users.
    Phoenix.PubSub.subscribe(Littlechat.PubSub, "room:" <> slug <> ":" <> user.uuid)

    # Track the connecting user with the `room:slug` topic.
    {:ok, _} = Presence.track(self(), "room:" <> slug, user.uuid, %{})

    {:ok,
      socket
      |> assign(:slug, slug)
      |> assign(:user, create_connected_user())
      |> assign(:connected_users, [])
      |> assign(:room, Organizer.get_room(slug))
    }
  end

  @impl true
  def handle_event("start_call", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("join_call", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_call", _params, socket) do
    {:noreply, socket}
  end


  @doc """
  Message sent from the client's JS once an offer.
  """
  def handle_event("send_video_offer", %{"sdp" => sdp, "targetUser" => target_user}, socket) do
    send_direct_message(
      socket.assigns.slug,
      target_user,
      "incoming_video_offer",
      %{
        sdp: sdp,
        from_user: socket.assigns.user,
        to_user: target_user
      }
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_video_answer", %{"sdp" => sdp, "targetUser" => target_user}, socket) do
    send_direct_message(
      socket.assigns.slug,
      target_user,
      "send_video_answer",
      %{
        sdp: sdp,
        from_user: socket.assigns.user,
        to_user: target_user
      }
    )
  end

  @impl true
  def handle_event("incoming_video_answer", %{}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "incoming_video_offer", payload: %{sdp: sdp, from_user: from_user} = offer}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "incoming_video_answer", payload: %{sdp: sdp, from_user: from_user} = offer}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply,
      socket
      |> assign(:connected_users, list_present(socket))}
  end

  defp create_connected_user do
    %ConnectedUser{uuid: UUID.uuid4()}
  end

  defp list_present(socket) do
    Presence.list("room:" <> socket.assigns.slug)
    |> Enum.map(fn {k, _} -> k end)
  end

  defp send_direct_message(slug, to_user, event, payload) do
    LittlechatWeb.Endpoint.broadcast_from(
      self(),
      "room:" <> slug <> ":" <> to_user,
      event,
      payload
    )
  end
end
