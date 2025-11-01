defmodule Trabajador do
  @moduledoc """
    Trabajadores para el _Servidor_
  """

  @spec start() :: pid()
  def start() do
    spawn(fn -> loop() end)
  end

  defp loop() do
    receive do
      {:trabajo, from, {func, n}} ->
        result = work(func)
        send(from, {:resultado, self(), {result, n}})
        loop()

      {:stop, server} ->
        send(server, {:worker_stopped, self()})
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
