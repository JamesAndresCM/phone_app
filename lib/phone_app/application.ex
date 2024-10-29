defmodule PhoneApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PhoneAppWeb.Telemetry,
      # Start the Ecto repository
      PhoneApp.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: PhoneApp.PubSub},
      # Start Finch
      {Finch, name: PhoneApp.Finch},
      # Oban
      {Oban, Application.fetch_env!(:phone_app, Oban)},
      # Start the Endpoint (http/https)
      PhoneAppWeb.Endpoint
      # Start a worker by calling: PhoneApp.Worker.start_link(arg)
      # {PhoneApp.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoneApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhoneAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
