defmodule Trabajador do
  @moduledoc """
    Trabajdores para el _Servidor_
  """

  @spec start() :: pid()
  def start() do
    spawn(fn -> loop() end)
  end

  defp loop() do
    receive do
      {:trabajo, from, func} ->
        resultado = work(func)
        send(from, {:resultado, self(), resultado})
        loop()

      :stop -> :ok
    end
  end

  defp work(func) do
    try do
      func.()
    rescue
      error -> {:error, error}
    end
  end
end
