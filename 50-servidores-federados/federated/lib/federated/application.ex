defmodule Federated.Application do
  @moduledoc"""

  """
  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Federated.Registry}
    ]

    opts = [strategy: :one_for_one, name: Federated.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
