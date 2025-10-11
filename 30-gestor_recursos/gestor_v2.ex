defmodule Gestor_D do
  @moduledoc """
  Gestor de recursos Distribuido.
  Permite que clientes en distintos nodos reserven y liberen recursos
  a través de un proceso gestor registrado globalmente.
  """

  @doc """
  Inicia el gestor con una lista de recursos disponibles y lo registra globalmente.

  ## Parámetros
    - `resources`: lista de recursos (átomos).

  ## Ejemplo
      iex> Gestor_D.start([:r1, :r2, :r3])
      :iniciated
  """
  @spec start(list()) :: :iniciated
  def start(resources) do
    pid = spawn(fn -> init(resources) end)
    :global.register_name(:gestor, pid)
    :iniciated
  end

  @doc """
  Detiene el gestor distribuido.

  Envía un mensaje al proceso gestor y espera confirmación.
  """
  @spec stop() :: :stopped
  def stop() do
    send(:global.whereis_name(:gestor), {:stop, self()})
    receive do
      :stopped -> :stopped
    end
  end

  @doc """
  Solicita la asignación de un recurso libre.

  Si no hay recursos disponibles, devuelve `{:error, :sin_recursos}`.
  """
  @spec alloc() :: {:ok, atom()} | {:error, atom()}
  def alloc() do
    send(:global.whereis_name(:gestor), {:alloc, self()})
    receive do
      {:ok, recurso} -> {:ok, recurso}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Libera un recurso previamente asignado.

  Verifica que el proceso solicitante sea quien lo reservó.
  """
  @spec release(atom()) :: :ok | {:error, atom()}
  def release(resource) do
    send(:global.whereis_name(:gestor), {:release, self(), resource})
    receive do
      :ok -> :ok
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Consulta el número de recursos libres disponibles actualmente.
  """
  @spec avail() :: integer()
  def avail() do
    send(:global.whereis_name(:gestor), {:avail, self()})
    receive do
      {:avail, n} -> n
    end
  end

  #################
  ## Gestor Interno
  #################
  defp init(resources) do
    loop([], resources)
  end

  defp loop(busy_resources, free_resources) do
    receive do
      {:alloc, from} when free_resources == [] ->
        send(from, {:error, :sin_recursos})
        loop(busy_resources, free_resources)

      {:alloc, from} ->
        [rs | rest] = free_resources
        send(from, {:ok, rs})
        loop([{rs, from} | busy_resources], rest)

      {:release, from, resource} ->
        case Enum.member?(busy_resources, {resource, from}) do
          true ->
            busy = List.delete(busy_resources, {resource, from})
            send(from, :ok)
            loop(busy, [resource | free_resources])

          false ->
            send(from, {:error, :recurso_no_reservado})
            loop(busy_resources, free_resources)
        end

      {:avail, from} ->
        send(from, {:avail, length(free_resources)})
        loop(busy_resources, free_resources)

      {:stop, from} ->
        send(from, :stopped)
    end
  end
end
