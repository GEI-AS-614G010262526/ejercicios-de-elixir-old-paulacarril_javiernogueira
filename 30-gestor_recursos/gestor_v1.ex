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
      {:error, :sin_recursos} ->
        {:error, :sin_recursos}
    end
  end

  @doc """

  """
  @spec release() :: :ok
  def release() do

  end

  @doc """

  """
  @spec avail() :: integer()
  def avail() do

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

        loop(busy_resources, free_resources)
      {:avail, from} ->
        send(from, length(free_resources))
        loop(busy_resources, free_resources)
      {:stop, from} ->
        send(from, :stopped)
    end
  end
end
