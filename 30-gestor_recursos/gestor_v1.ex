defmodule Gestor_ND do
  @moduledoc """
    Gestor de recursos No Distribuido.
  """

  @doc """
    Inicia el gestor con una lista de recursos disponibles.

    Registra el proceso bajo el nombre `:gestor`.

    ## Parámetros
      - `resources`: lista de recursos (átomos) que el gestor podrá asignar.

    ## Ejemplo
        iex> Gestor_ND.start([:res1, :res2, :res3])
        :iniciated
  """
  @spec start(list()) :: :iniciated
  def start(resources) do
    pid = spawn(fn -> init(resources) end)
    Process.register(pid, :gestor)
    :iniciated
  end

  @doc """
    Detiene el gestor de recursos.

    Envía un mensaje para detener el proceso y espera confirmación.

    ## Ejemplo
        iex> Gestor_ND.stop()
        :stopped
  """
  @spec stop() :: :stopped
  def stop() do
    send(:gestor, {:stop, self()})
    receive do
      :stopped -> :stopped
    end
  end

  @doc """
    Solicita la asignación de un recurso libre.

    Envía una petición para asignar un recurso disponible al proceso gestor.

    ## Ejemplo
        iex> Gestor_ND.alloc()
        :res1
  """
  @spec alloc() :: {:ok, atom()} | {:error, atom()}
  def alloc() do
    send(:gestor, {:alloc, self()})
    receive do
      {:ok, recurso} ->
        {:ok, recurso}
      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
    Libera un recurso previamente asignado.

    Envía una petición para liberar un recurso y espera confirmación.

    ## Parámetros
      - `resource`: átomo que representa el recurso a liberar.

    ## Ejemplo
        iex> Gestor_ND.release(:res1)
        :ok
  """
  @spec release(atom()) :: :ok | {:error, atom()}
  def release(resource) do
    send(:gestor, {:release, self(), resource})
    receive do
      :ok -> :ok
      {:error, err} ->
        {:error, err}
    end

  end

  @doc """
    Consulta el número de recursos libres disponibles actualmente.

    ## Ejemplo
        iex> Gestor_ND.avail()
        2
  """
  @spec avail() :: integer()
  def avail() do
    send(:gestor, {:avail, self()})
    receive do
      {:avail, n} ->
        n
    end

  end

  #################
  ## Gestor
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
