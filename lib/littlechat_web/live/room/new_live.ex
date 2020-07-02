defmodule LittlechatWeb.Room.NewLive do
  use LittlechatWeb, :live_view

  alias Littlechat.Repo
  alias Littlechat.Room

  @impl true
  def render(assigns) do
    ~L"""
    <main class="main main--new-room">
      <%= form_for @changeset, "#", [phx_change: "validate", phx_submit: "save", class: "form"], fn f -> %>
        <%= img_tag(Routes.static_path(@socket, "/images/littlechat-logo.svg"), class: "logo logo--large") %>

        <label class="label">
          Room Name:
          <%= text_input f, :title, placeholder: "Example Room", class: "input" %>
          <%= error_tag f, :title %>
        </label>

        <label class="label">
          Room ID:
          <%= text_input f, :slug, placeholder: "my-room-123", class: "input" %>
          <%= error_tag f, :slug %>
        </label>

        <%= submit "Start Call", class: "button" %>
      <% end %>
    </main>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> put_changeset()
    }
  end

  @impl true
  def handle_event("validate", %{"room" => room_params}, socket) do
    {:noreply,
      socket
      |> put_changeset(room_params)
    }
  end

  def handle_event("save", _, %{assigns: %{changeset: changeset}} = socket) do
    case Repo.insert(changeset) do
      {:ok, room} ->
        {
          :noreply,
          push_redirect(
            socket,
            to: Routes.room_show_path(socket, :show, room.slug)
          )
        }
      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> put_flash(:error, "Could not save the room.")
        }
    end
  end

  defp put_changeset(socket, params \\ %{}) do
    socket
    |> assign(:changeset, Room.changeset(%Room{}, params))
  end
end
