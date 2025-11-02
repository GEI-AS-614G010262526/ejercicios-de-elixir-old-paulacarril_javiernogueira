# test/federated/actor_test.exs
defmodule Federated.ActorTest do
  use ExUnit.Case, async: true
  alias Federated.Actor

  describe "new/3" do
    test "creates a new actor with id, name and avatar" do
      actor = Actor.new("spock@enterprise", "Spock", "img://spock")

      assert actor.id == "spock@enterprise"
      assert actor.name == "Spock"
      assert actor.avatar == "img://spock"
      assert actor.inbox == []
    end

    test "initializes inbox as empty list" do
      actor = Actor.new("test@server", "Test", "img://test")
      assert [] == actor.inbox
    end
  end

  describe "server_name/1" do
    test "extracts server name from actor id" do
      actor = Actor.new("spock@enterprise", "Spock", "img://spock")
      assert "enterprise" == Actor.server_name(actor)
    end

    test "extracts server name from different server" do
      actor = Actor.new("janeway@voyager", "Janeway", "img://janeway")
      assert "voyager" == Actor.server_name(actor)
    end
  end

  describe "username/1" do
    test "extracts username from actor id" do
      actor = Actor.new("spock@enterprise", "Spock", "img://spock")
      assert "spock" == Actor.username(actor)
    end

    test "extracts username from different actor" do
      actor = Actor.new("janeway@voyager", "Janeway", "img://janeway")
      assert "janeway" == Actor.username(actor)
    end
  end
end

