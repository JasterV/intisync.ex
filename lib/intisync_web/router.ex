defmodule IntisyncWeb.Router do
  use IntisyncWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {IntisyncWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :hub do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {IntisyncWeb.Layouts, :hub_root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", IntisyncWeb do
    pipe_through :browser

    live "/", LobbyLive
    live "/sessions/:id/remote", RemoteLive
  end

  scope "/", IntisyncWeb do
    pipe_through :hub
    live "/sessions/:id", HubLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", IntisyncWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:intisync, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: IntisyncWeb.Telemetry
    end
  end
end
