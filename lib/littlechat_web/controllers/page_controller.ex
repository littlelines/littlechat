defmodule LittlechatWeb.PageController do
  use LittlechatWeb, :controller

  def index(conn, _) do
    conn
    |> redirect(to: Routes.room_new_path(conn, :new))
  end
end
