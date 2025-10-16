defmodule MicroBank.SupervisionTest do
  use ExUnit.Case

  setup do
    if !Process.whereis(MicroBank) do
      start_supervised!(MicroBank)
    end
    :ok
  end

  test "server is restarted if it crashes" do
    old_pid = Process.whereis(MicroBank)
    assert is_pid(old_pid)
    assert Process.alive?(old_pid)

    # Simular fallo del proceso del banco
    Process.exit(old_pid, :kill)

    # Espera a que el supervisor lo reinicie
    :timer.sleep(100)

    new_pid = Process.whereis(MicroBank)
    assert is_pid(new_pid)
    assert Process.alive?(new_pid)
    refute old_pid == new_pid
  end
end
