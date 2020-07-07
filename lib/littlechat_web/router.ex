defmodule LittlechatWeb.Router do
  use LittlechatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LittlechatWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LittlechatWeb do
    pipe_through :browser

    get "/", PageController, :index

    scope "/room", as: :room do
      live "/new", Room.NewLive, :new
      live "/:slug", Room.ShowLive, :show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", LittlechatWeb do
  #   pipe_through :api
  # end
end
