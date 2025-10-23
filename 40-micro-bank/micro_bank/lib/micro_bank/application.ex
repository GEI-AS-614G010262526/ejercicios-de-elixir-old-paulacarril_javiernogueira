defmodule MicroBank.Application do
  use Application

  @moduledoc """
    Módulo de aplicación del Micro Bank.
    
    Gestiona el inicio de la aplicación y configura el árbol de supervisión.
    Implementa la estrategia "let it fail": si el servidor del banco falla,
    el supervisor lo reinicia automáticamente.
  """

  #################
  ## Callbacks de Application
  #################

  @doc """
    Inicia la aplicación del Micro Bank.

    Configura y arranca el árbol de supervisión con el servidor del banco
    como hijo. Utiliza la estrategia `:one_for_one`, que reinicia únicamente
    el proceso que falla, sin afectar a otros procesos hermanos.

    ## Parámetros
      - `_type`: tipo de inicio de la aplicación (no se utiliza).
      - `_args`: argumentos adicionales (no se utilizan).

  """
  @impl true
  @spec start(Application.start_type(), term()) :: {:ok, pid()} | {:error, term()}
  def start(_type, _args) do
    children = [MicroBank]
    opts = [strategy: :one_for_one, name: MicroBank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end