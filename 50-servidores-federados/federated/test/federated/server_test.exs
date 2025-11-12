
# test/federated/server_test.exs
defmodule Federated.ServerTest do
  use ExUnit.Case, async: false
  alias Federated.{Server, Actor}

  setup do
    server_name = "test_server_#{:rand.uniform(100000)}"

    case Server.start_link(server_name) do
      {:ok, pid} -> {:ok, server: server_name, pid: pid}
      {:error, {:already_started, pid}} -> {:ok, server: server_name, pid: pid}
      other -> raise "Unexpected result from start_link: #{inspect(other)}"
    end
  end

  describe "start_link/1" do
    test "starts a server with given name" do
      server_name = "new_server_#{:rand.uniform(100000)}"

      assert {:ok, pid} = Server.start_link(server_name)
      assert Process.alive?(pid)

      GenServer.stop(pid)
    end
  end

  describe "add_actor/2" do
    test "adds an actor to the server", %{server: server} do
      actor = Actor.new("test@#{server}", "Test User", "img://test")
      assert :ok == Server.add_actor(server, actor)
    end

    test "can add multiple actors", %{server: server} do
      actor1 = Actor.new("user1@#{server}", "User One", "img://user1")
      actor2 = Actor.new("user2@#{server}", "User Two", "img://user2")

      assert :ok == Server.add_actor(server, actor1)
      assert :ok == Server.add_actor(server, actor2)
    end
  end

  describe "get_profile/2" do
    test "retrieves profile of an actor on the same server", %{server: server} do
      actor = Actor.new("test@#{server}", "Test User", "img://test")
      requestor = Actor.new("requestor@#{server}", "Requestor", "img://req")

      Server.add_actor(server, actor)
      Server.add_actor(server, requestor)

      assert {:ok, retrieved_actor} = Server.get_profile("requestor@#{server}", "test@#{server}")
      assert "Test User" == retrieved_actor.name
    end

    test "returns error when requestor is not registered", %{server: server} do
      actor = Actor.new("test@#{server}", "Test User", "img://test")
      Server.add_actor(server, actor)

      assert {:error, :unknown_requestor} == Server.get_profile("unknown@#{server}", "test@#{server}")
    end

    test "returns error when actor does not exist", %{server: server} do
      requestor = Actor.new("requestor@#{server}", "Requestor", "img://req")
      Server.add_actor(server, requestor)

      assert :error == Server.get_profile("requestor@#{server}", "nonexistent@#{server}")

    end
  end

  describe "post_message/3" do
    test "posts a message from one actor to another on same server", %{server: server} do
      sender = Actor.new("sender@#{server}", "Sender", "img://sender")
      receiver = Actor.new("receiver@#{server}", "Receiver", "img://receiver")

      Server.add_actor(server, sender)
      Server.add_actor(server, receiver)

      assert :ok == Server.post_message("sender@#{server}", "receiver@#{server}", "Hello!")
    end

    test "returns error when sender is not registered", %{server: server} do
      receiver = Actor.new("receiver@#{server}", "Receiver", "img://receiver")
      Server.add_actor(server, receiver)

      assert {:error, :unknown_sender} ==
        Server.post_message("unknown@#{server}", "receiver@#{server}", "Hello!")
    end

    test "returns error when receiver is not registered", %{server: server} do
      sender = Actor.new("sender@#{server}", "Sender", "img://sender")
      Server.add_actor(server, sender)

      assert {:error, :unknown_receiver} ==
        Server.post_message("sender@#{server}", "unknown@#{server}", "Hello!")
    end
  end

  describe "retrieve_messages/1" do
    test "retrieves messages from actor's inbox", %{server: server} do
      sender = Actor.new("sender@#{server}", "Sender", "img://sender")
      receiver = Actor.new("receiver@#{server}", "Receiver", "img://receiver")

      Server.add_actor(server, sender)
      Server.add_actor(server, receiver)

      Server.post_message("sender@#{server}", "receiver@#{server}", "Message 1")
      Server.post_message("sender@#{server}", "receiver@#{server}", "Message 2")

      messages = Server.retrieve_messages("receiver@#{server}")
      assert 2 == length(messages)
      assert Enum.any?(messages, fn msg -> msg.content == "Message 1" end)
      assert Enum.any?(messages, fn msg -> msg.content == "Message 2" end)
    end

    test "returns empty list for actor with no messages", %{server: server} do
      actor = Actor.new("test@#{server}", "Test", "img://test")
      Server.add_actor(server, actor)

      assert [] == Server.retrieve_messages("test@#{server}")
    end

    test "returns error when actor is not registered", %{server: server} do
      assert {:error, :unknown_user} == Server.retrieve_messages("unknown@#{server}")
    end

    test "messages have correct structure with from, content and timestamp", %{server: server} do
      sender = Actor.new("sender@#{server}", "Sender", "img://sender")
      receiver = Actor.new("receiver@#{server}", "Receiver", "img://receiver")

      Server.add_actor(server, sender)
      Server.add_actor(server, receiver)

      Server.post_message("sender@#{server}", "receiver@#{server}", "Test message")

      [message | _] = Server.retrieve_messages("receiver@#{server}")

      assert "sender@#{server}" == message.from
      assert "Test message" == message.content
      assert %DateTime{} = message.timestamp
    end
  end
end
