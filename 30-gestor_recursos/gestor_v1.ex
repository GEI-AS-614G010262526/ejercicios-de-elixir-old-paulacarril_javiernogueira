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
  end

  @doc """

  """
  def stop() do
    send(:gestor, {:stop, from})
    receive do
      :stopped -> :ok
    end
  end

  @doc """

  """
  @spec alloc() :: {:ok, atom()}
  def alloc() do

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
      {:alloc, from} ->
        [rs | rest] = free_resources
        send(from, rs)
        loop([{rs, from} | busy_resources], rest)
      {:release, from, resource} ->

        loop(resources)
      {:avail, from} ->
        send(from, length(free_resources))
        loop(busy_resources, free_resources)
      {:stop, from} ->
        send(from, :stopped)
    end
  end
end
