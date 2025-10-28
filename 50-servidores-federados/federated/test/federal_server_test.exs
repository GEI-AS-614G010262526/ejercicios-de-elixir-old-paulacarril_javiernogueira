defmodule FederalServerTest do
  use ExUnit.Case
  doctest FederalServer

  test "greets the world" do
    assert FederalServer.hello() == :world
  end
end
