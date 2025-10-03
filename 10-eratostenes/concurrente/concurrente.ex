defmodule Concurrente do
  @moduledoc """
  Documentation for `Concurrente`.
  """

  @doc """
    Obtain all the prime numbers between 2 and 'n'.

  ## Examples

      iex> Concurrente.primos(10)
      [1, 2, 3, 5, 7]

  """
  def primos(n) do
    pid = spawn(fn -> filtro(2, nil) end)
    send_numbers(3, n, pid)
    send(pid, {:stop, [], self()})
    receive do
      {:message_type, acc} ->
        Enum.reverse(acc)
    end
  end

  defp send_numbers(n, n, pid) do
    send(pid, {:number, n})
  end

  defp send_numbers(num, n, pid) do
    send(pid, {:number, num})
    send_numbers(num + 1, n, pid)
  end

  defp filtro(n, next_pid) do
    receive do
      {:number, m} when rem(m, n) != 0 ->
        case next_pid do
          nil ->
            new_pid = spawn(fn -> filtro(m, nil) end)
            filtro(n, new_pid)
          _ ->
            send(next_pid, {:number, m})
            filtro(n, next_pid)
        end
      {:number, _m} ->
        filtro(n, next_pid)
      {:stop, acc, master} when next_pid != nil ->
        send(next_pid, {:stop, [n | acc], master})
      {:stop, acc, master} ->
        send(master, {:message_type, [n | acc]})
    end
  end
end
