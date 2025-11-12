defmodule MicroBankTest do
  use ExUnit.Case

  setup do
    # Nos aseguramos de detener el proceso servidor
    if Process.whereis(MicroBank) do
      GenServer.stop(MicroBank)
    end

    # Iniciamos el GenServer
    case MicroBank.start_link([]) do
      {:ok, _pid} -> :ok
      # Si da error porque aun no se ha parado seguimos adelante
      {:error, {:already_started, _pid}} -> :ok
      other -> raise "Unexpected result from start_link: #{inspect(other)}"
    end

    on_exit(fn ->
      if Process.whereis(MicroBank) do
        GenServer.stop(MicroBank)
      end
    end)

    :ok
  end

  test "deposit creates a new account with the given balance" do
    assert {:ok, 100} == MicroBank.deposit("Alice", 100)
    assert {:ok, 100} == MicroBank.ask("Alice")
  end

  test "deposit adds to an existing balance" do
    MicroBank.deposit("Bob", 50)
    assert {:ok, 80} == MicroBank.deposit("Bob", 30)
  end

  test "ask returns 0 for a non-existing account" do
    assert {:ok, 0} == MicroBank.ask("Ghost")
  end

  test "withdraw returns new balance if funds are sufficient" do
    MicroBank.deposit("Carol", 200)
    assert {:ok, 150} == MicroBank.withdraw("Carol", 50)
  end

  test "withdraw returns error if funds are insufficient" do
    MicroBank.deposit("Dave", 20)
    assert {:error, :insufficient_funds} == MicroBank.withdraw("Dave", 50)
    assert {:ok, 20} == MicroBank.ask("Dave")
  end
end
