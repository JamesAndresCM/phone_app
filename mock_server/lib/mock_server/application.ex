#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServer.Application do
  require Logger

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Logger.info("Mock SMS server is starting. Access at the specified URL below.")
    Logger.info("Follow book instructions for basic auth setup. Credentials = (username:mock-key-sid, password:mock-key)")

    children = [
      # Start the Telemetry supervisor
      MockServerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MockServer.PubSub},
      MockServer.Messaging.Server,
      # Start the Endpoint (http/https)
      MockServerWeb.Endpoint
      # Start a worker by calling: MockServer.Worker.start_link(arg)
      # {MockServer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MockServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MockServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
