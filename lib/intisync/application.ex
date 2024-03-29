defmodule Intisync.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      IntisyncWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:intisync, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Intisync.PubSub},
      # Start a worker by calling: Intisync.Worker.start_link(arg)
      # {Intisync.Worker, arg},
      # Start to serve requests, typically the last entry
      IntisyncWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Intisync.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IntisyncWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
