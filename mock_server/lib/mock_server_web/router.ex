#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServerWeb.Router do
  use MockServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MockServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug MockServerWeb.Plug.ValidateAuthKey
  end

  scope "/", MockServerWeb do
    pipe_through :browser

    live "/", MessageListLive
  end

  scope "/2010-04-01", MockServerWeb.Api do
    pipe_through :api

    post "/Accounts/:account_sid/Messages.json", MessagesController, :create
    get "/Accounts/:account_sid/Messages/:id", MessagesController, :show
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:mock_server, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MockServerWeb.Telemetry
    end
  end
end
