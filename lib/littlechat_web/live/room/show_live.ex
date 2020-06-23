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
    <script>
    window.roomSlug = "<%= @room.slug %>";
    </script>

    <h1><%= @room.title %></h1>

    <p>Me: <%= @user.uuid %></p>

    <h3>Connected Users:</h3>
    <ul>
    <%= for uuid <- @connected_users do %>
      <li><%= uuid %></li>
    <% end %>
    </ul>

    <video id="local-video" playsinline autoplay muted width="500"></video>

    <%= for uuid <- @connected_users do %>
      <video id="video-remote-<%= uuid %>" data-user-uuid="<%= uuid %>" playsinline autoplay width="500" phx-hook="InitUser"></video>
    <% end %>

    <div id="sdp-offers">
      <%= for sdp_offer <- @sdp_offers do %>
        <span phx-hook="HandleSdpOffer" data-from-user-uuid="<%= sdp_offer["from_user"] %>" data-sdp="<%= sdp_offer["description"]["sdp"] %>"></span>
      <% end %>
    </div>

    <div id="sdp-answers">
      <%= for answer <- @answers do %>
        <span phx-hook="HandleAnswer" data-from-user-uuid="<%= answer["from_user"] %>" data-sdp="<%= answer["description"]["sdp"] %>"></span>
      <% end %>
    </div>

    <div id="ice-candidates">
      <%= for ice_candidate_offer <- @ice_candidate_offers do %>
        <span phx-hook="HandleIceCandidateOffer" data-from-user-uuid="<%= ice_candidate_offer["from_user"] %>" data-ice-candidate="<%= Jason.encode!(ice_candidate_offer["candidate"]) %>"></span>
      <% end %>
    </div>

    <div id="offer-requests">
      <%= for request <- @offer_requests do %>
        <span phx-hook="HandleOfferRequest" data-from-user-uuid="<%= request.from_user.uuid %>"></span>
      <% end %>
    </div>

    <div>
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
      |> assign(:user, user)
      |> assign(:ice_candidate_offers, [])
      |> assign(:sdp_offers, [])
      |> assign(:answers, [])
      |> assign(:offer_requests, [])
      |> assign(:connected_users, [])
      |> assign(:room, Organizer.get_room(slug))
    }
  end

  @impl true
  def handle_event("start_call", params, socket) do
    {:noreply, socket}
  end

  @impl true
  @doc """
  Called when the user clicks the "Join Call" button. This sends a request to
  each of the `@connected_users` with the event "request_offers".
  """
  def handle_event("join_call", _params, socket) do
    for user <- socket.assigns.connected_users do
      send_direct_message(
        socket.assigns.slug,
        user,
        "request_offers",
        %{
          from_user: socket.assigns.user
        }
      )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_call", _params, socket) do
    {:noreply, socket}
  end

  @doc """
  Passes along the ICE candidate sent by the JS callback to the user on the
  other end. It also adds the current user's UUID to the message.
  """
  @impl true
  def handle_event("new_ice_candidate", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.user.uuid})
    send_direct_message(socket.assigns.slug, payload["toUser"], "new_ice_candidate", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_sdp_offer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.user.uuid})

    send_direct_message(socket.assigns.slug, payload["toUser"], "new_sdp_offer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_answer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.user.uuid})

    send_direct_message(socket.assigns.slug, payload["toUser"], "new_answer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "request_offers", payload: request}, socket) do
    {:noreply,
      socket
      |> assign(:offer_requests, socket.assigns.offer_requests ++ [request])
    }
  end

  @doc """
  See `handle_event("new_ice_candidate", params, socket)` for the sender of this
  message. This function handles reception of a "new_ice_candidate" message and
  tells the client about the ICE candidate.
  """
  @impl true
  def handle_info(%Broadcast{event: "new_ice_candidate", payload: payload}, socket) do
    {:noreply,
      socket
      |> assign(:ice_candidate_offers, socket.assigns.ice_candidate_offers ++ [payload])
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "new_sdp_offer", payload: payload}, socket) do
    {:noreply,
      socket
      |> assign(:sdp_offers, socket.assigns.ice_candidate_offers ++ [payload])
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "new_answer", payload: payload}, socket) do
    {:noreply,
      socket
      |> assign(:answers, socket.assigns.answers ++ [payload])
    }
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
    |> List.delete(socket.assigns.user.uuid)
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
