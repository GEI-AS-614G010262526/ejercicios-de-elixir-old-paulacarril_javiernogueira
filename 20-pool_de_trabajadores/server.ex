defmodule Servidor do
  @moduledoc """
    Servidor para realizar _Trabajos_
  """

  @spec start(integer()) :: {:ok, pid()}
  def start(n) do
  end

  @spec run_batch(pid(), list()) :: list()
  def run_batch(master, jobs) do
  end

  @spec stop(pid()) :: :ok
  def stop(master) do
  end
end
