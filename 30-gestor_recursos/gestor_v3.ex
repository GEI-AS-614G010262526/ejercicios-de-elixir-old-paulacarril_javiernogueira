defmodule Gestor_TF do
  @moduledoc """
    Gestor de recursos Tolerante a Fallos.
  """

  @doc """
    Inicia el gestor con una lista de recursos disponibles.

    Registra el proceso globalmente bajo el nombre `:gestor`.

    ## Parámetros
      - `resources`: lista de recursos (átomos) que el gestor podrá asignar.

    ## Ejemplo
        iex> Gestor_TF.start([:res1, :res2, :res3])
        :iniciated
  """
  @spec start(list()) :: :iniciated
  def start(resources) do
    pid = spawn(fn -> init(resources) end)
    :global.register_name(:gestor, pid)
    :iniciated
  end

  @doc """
    Detiene el gestor de recursos.

    Envía un mensaje para detener el proceso y espera confirmación.

    ## Ejemplo
        iex> Gestor_TF.stop()
        :stopped
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

    Envía una petición para asignar un recurso disponible al proceso gestor.

    ## Ejemplo
        iex> Gestor_TF.alloc()
        :res1
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

    Envía una petición para liberar un recurso y espera confirmación.

    ## Parámetros
      - `resource`: átomo que representa el recurso a liberar.

    ## Ejemplo
        iex> Gestor_TF.release(:res1)
        :ok
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

    ## Ejemplo
        iex> Gestor_TF.avail()
        2
  """
  @spec avail() :: integer()
  def avail() do
    send(:global.whereis_name(:gestor), {:avail, self()})
    receive do
      {:avail, n} -> n
    end
  end

  #################
  ## Gestor
  #################
  defp init(resources) do
    Process.flag(:trap_exit, true)
    loop([], resources)
  end

  defp loop(busy_resources, free_resources) do
    
    receive do
      {:alloc, from} when free_resources == [] ->
        send(from, {:error, :sin_recursos})
        loop(busy_resources, free_resources)

      {:alloc, from} ->
        [rs | rest] = free_resources
        Process.link(from)
        Node.monitor(node(from), true)
        send(from, {:ok, rs})
        loop([{rs, from} | busy_resources], rest)

      {:release, from, resource} ->
        case Enum.member?(busy_resources, {resource, from}) do
          true ->
            busy = List.delete(busy_resources, {resource, from})
            Process.unlink(from)
            send(from, :ok)
            loop(busy, [resource | free_resources])
          false ->
            send(from, {:error, :recurso_no_reservado})
            loop(busy_resources, free_resources)
        end

      {:avail, from} ->
        send(from, {:avail, length(free_resources)})
        loop(busy_resources, free_resources)

      {:EXIT, pid_caido, _reason} ->
        recursos_a_liberar = get_process_resources(pid_caido, busy_resources)
        recursos_de_otros = remove_process_resources(pid_caido, busy_resources)
        loop(recursos_de_otros, recursos_a_liberar ++ free_resources)

      {:nodedown, nodo_caido} ->
        recursos_a_liberar = get_node_resources(nodo_caido, busy_resources)
        recursos_de_otros = remove_node_resources(nodo_caido, busy_resources)
        loop(recursos_de_otros, recursos_a_liberar ++ free_resources)
        
      {:stop, from} ->
        send(from, :stopped)
    end
  end

defp get_process_resources(_pid, []), do: []

defp get_process_resources(pid, [{recurso, pid_recurso} | tail]) when pid == pid_recurso do
  [recurso | get_process_resources(pid, tail)]
end

defp get_process_resources(pid, [_ | tail]) do
  get_process_resources(pid, tail)
end

defp remove_process_resources(_pid, []), do: []

defp remove_process_resources(pid, [{_recurso, pid_recurso} | tail]) when pid == pid_recurso do
  remove_process_resources(pid, tail)
end

defp remove_process_resources(pid, [head | tail]) do
  [head | remove_process_resources(pid, tail)]
end

defp get_node_resources(_nodo, []), do: []

defp get_node_resources(nodo, [{recurso, pid_recurso} | tail]) when node(pid_recurso) == nodo do
  [recurso | get_node_resources(nodo, tail)]
end

defp get_node_resources(nodo, [_ | tail]) do
  get_node_resources(nodo, tail)
end

defp remove_node_resources(_nodo, []), do: []

defp remove_node_resources(nodo, [{_recurso, pid_recurso} | tail]) when node(pid_recurso) == nodo do
  remove_node_resources(nodo, tail)
end

defp remove_node_resources(nodo, [head | tail]) do
  [head | remove_node_resources(nodo, tail)]
end
end