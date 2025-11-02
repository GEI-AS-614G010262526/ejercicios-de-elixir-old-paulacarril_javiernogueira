defmodule FederatedTest do
  use ExUnit.Case
  doctest FederalServer

  test "greets the world" do
    assert Federated.hello() == :world
  end
end
