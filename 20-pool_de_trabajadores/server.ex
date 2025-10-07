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
    {:ok, spawn(fn -> init(n) end)}
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
  defp init(n) do
    workers = start_workers(n)
    loop(workers, workers, nil, [], [], 0, 0)
  end

  defp loop(workers, free_workers, client, results, pending_jobs, num_results, num_jobs) do
    receive do
      # Caso: Recibir run_batch -> con menos o igual numero de trabajos que trabajadores libres
      {:trabajos, from, jobs} ->
        ordered_jobs = Enum.with_index(jobs)
        {new_free_workers, remaining_jobs} = send_jobs(free_workers, ordered_jobs)
        loop(workers, new_free_workers, from, results, remaining_jobs, num_results, num_jobs + length(jobs))

      # Caso: Recibir resultado final desde loop y enviar al cliente
      {:resultado, from, result} when num_results == (num_jobs-1) ->
        sorted_results =
          [result | results]
          |> Enum.sort_by(fn {_res, n} -> n end)
          |> Enum.map(fn {res, _n} -> res end)
        send(client ,{:done, sorted_results})
        loop(workers, [from | free_workers], nil, [], [], 0, 0)

      # Caso: Recibir resultados intermedios desde loop y enviar nuevos trabajos si hay pendientes
      {:resultado, from, result} ->
        case pending_jobs do
          [job | rest] ->
             send(from, {:trabajo, self(), job})
             loop(workers, free_workers, client, [result | results], rest, num_results + 1, num_jobs)
           [] ->
             loop(workers, free_workers, client, [result | results], pending_jobs, num_results + 1, num_jobs)
         end

      # Caso: Recibir stop -> parar todos los trabajadores
      {:stop, from} ->
        Enum.each(workers, fn worker ->
          send(worker, {:stop, self()})
        end)
        wait_for_workers(length(workers))
        send(from, :stopped)
    end
  end

  defp send_jobs(workers, []), do: {workers, []}

  defp send_jobs([], jobs), do: {[], jobs}

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
