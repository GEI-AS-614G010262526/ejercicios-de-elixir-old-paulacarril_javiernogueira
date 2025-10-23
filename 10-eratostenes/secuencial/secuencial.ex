defmodule Secuencial do
  @moduledoc """
  Documentation for `Secuencial`.
  """

  @doc """
  Obtain all the prime numbers between 2 and 'n'.

  ## Examples

      iex> Secuencial.primos(10)
      [1, 2, 3, 5, 7]

  """
  def primos(n) do
    list = rango(2, n)
    criba(list)
  end

  defp criba(list), do: criba(list, [])

  defp criba([], acc), do: Enum.reverse(acc)

  defp criba([h | t], acc) do
    filtered = Enum.filter(t, fn x -> rem(x, h) != 0 end)
    criba(filtered, [h | acc])
  end

  defp rango(n, n), do: [n]

  defp rango(n, m) do
    [n | rango(n + 1, m)]
  end
end
