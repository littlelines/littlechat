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
    <h1><%= @room.title %></h1>

    <h3>Connected Users:</h3>
    <ul>
    <%= for {uuid, _} <- @connected_users do %>
      <li><%= uuid %></li>
    <% end %>
    </ul>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    user = create_connected_user()
    Phoenix.PubSub.subscribe(Littlechat.PubSub, "room:" <> slug)
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
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply,
      socket
      |> assign(:connected_users, Presence.list("room:" <> socket.assigns.slug))}
  end

  defp create_connected_user do
    %ConnectedUser{uuid: UUID.uuid4()}
  end
end
