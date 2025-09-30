defmodule Servidor do
  @moduledoc """
    Servidor para realizar _Trabajos_
  """

  Code.require_file("worker.ex")


  @doc """
    Start the server with n workers.

  ## Example
      iex> Servidor.start(5)
      Iniciando el servidor...
      #PID<0.193.0>
  """
  @spec start(integer()) :: {:ok, pid()}
  def start(n) do
    IO.puts("Iniciando el servidor...")
    workers = start_workers(n)
    {:ok, spawn(fn -> server(workers) end)}
  end

  @doc """

  """
  @spec run_batch(pid(), list()) :: list()
  def run_batch(_master, _jobs) do
    raise("Not implemented yet")
  end

  @doc """
    Stop the server using its pid.

  ## Example
      iex> Servidor.stop(pid)
      Deteniendo el servidor...
      :ok
  """
  @spec stop(pid()) :: :ok
  def stop(master) do
    IO.puts("Deteniendo el servidor...")
    send(master, {:stop, self()})
    receive do
      :stopped ->
        :ok
    end

  end

  ###############
  ## Server
  ###############
  defp server(workers) do
    receive do
      {:trabajos, _from, _trabajos} ->
        IO.puts("Trabaja...")
      {:stop, from} ->
        Enum.each(workers, fn worker ->
          send(worker, {:stop, self()})
        end)
        wait_for_workers(length(workers))
        send(from, :stopped)
    end
  end

  ###############
  ## Wait for workers
  ###############
  defp wait_for_workers(0), do: :ok

  defp wait_for_workers(n) do
    receive do
      {:worker_stopped, _w_pid} ->
        wait_for_workers(n-1)
    end
  end


  ###############
  ## Start_workers
  ###############
  defp start_workers(0), do: :ok

  defp start_workers(n) do
    t_pid = Trabajador.start()
    [t_pid | start_workers(n - 1)]
  end
end
