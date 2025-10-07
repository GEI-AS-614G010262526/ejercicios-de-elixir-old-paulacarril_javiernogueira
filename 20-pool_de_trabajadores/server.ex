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
    {:ok, spawn(fn -> server(workers, workers, nil, [], [], 0) end)}
  end

  @doc """
    Send the server a list of jobs to do.
    The results may not be ordered.

  ## Example
      iex> jobs = [fn -> :"1" end , fn -> :"2" end]
      [...]
      iex> Servidor.run_batch(master, jobs)
      [:"1", :"2"]
  """
  @spec run_batch(pid(), list()) :: list()
  def run_batch(master, jobs) do
    send(master, {:trabajos, self(), jobs})
    receive do
      {:done, results} ->
        results
    end
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
  defp server(workers, free_workers, client, resultados, pending_jobs, num_jobs) do
    receive do
      {:trabajos, from, jobs} when length(jobs) <= length(free_workers) and num_jobs == 0->
        free_w = send_jobs(free_workers, jobs)
        server(workers, free_w, from, resultados, [], length(jobs))

      {:trabajos, from, jobs} ->
        {to_send, rest} = Enum.split(jobs, length(free_workers))
        free_w = send_jobs(free_workers, to_send)
        server(workers, free_w, from, resultados, rest, (num_jobs + length(jobs)))

      {:stop, from} ->
        Enum.each(workers, fn worker ->
          send(worker, {:stop, self()})
        end)
        wait_for_workers(length(workers))
        send(from, :stopped)

      {:resultado, from, result} when length(resultados) == (num_jobs-1) ->
        send(client ,{:done, [result | resultados]})
        server(workers, [from | free_workers], nil, [], [], 0)

      {:resultado, from, result} ->
        case pending_jobs do
          [job | rest] ->
            send(from, {:trabajo, self(), job})
            server(workers, free_workers, client, [result | resultados], rest, num_jobs)
          [] ->
            server(workers, free_workers, client, [result | resultados], pending_jobs, num_jobs)
        end
    end
  end

  defp send_jobs(workers, []), do: workers

  defp send_jobs([worker | workers], [job | jobs]) do
    send(worker, {:trabajo, self(), job})
    send_jobs(workers, jobs)
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
  defp start_workers(0), do: []

  defp start_workers(n) do
    t_pid = Trabajador.start()
    [t_pid | start_workers(n - 1)]
  end
end
