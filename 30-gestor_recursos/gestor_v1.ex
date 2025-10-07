defmodule Gestor_ND do
  @moduledoc """
    Gestor de recursos No Distribuido.
  """

  @doc """

  """
  @spec start(list()) :: list()
  def start(resources) do
    pid = spawn(fn -> init(resources) end)
    Process.register(pid, :gestor)
    IO.puts("Gestor registered as : \":gestor\"")
    :iniciated
  end

  @doc """

  """
  def stop() do
    send(:gestor, {:stop, self()})
    receive do
      :stopped -> :stopped
    end
  end

  @doc """

  """
  @spec alloc() :: {:ok, atom()}
  def alloc() do
    send(:gestor, {:alloc, self()})
    receive do
      {:ok, recurso} ->
        recurso
      {:error, err} ->
        {:error, err}
    end
  end

  @doc """

  """
  @spec release(atom()) :: :ok
  def release(resource) do
    send(:gestor, {:release, self(), resource})
    receive do
      :ok -> :ok
      {:error, err} ->
        {:error, err}
    end

  end

  @doc """

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
