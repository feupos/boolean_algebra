defmodule BooleanAlgebra.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BooleanAlgebraWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:boolean_algebra, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BooleanAlgebra.PubSub},
      # Start a worker by calling: BooleanAlgebra.Worker.start_link(arg)
      # {BooleanAlgebra.Worker, arg},
      # Start to serve requests, typically the last entry
      BooleanAlgebraWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BooleanAlgebra.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BooleanAlgebraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
