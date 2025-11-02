
# test/federated/seeder_test.exs
defmodule Federated.SeederTest do
  use ExUnit.Case, async: false
  alias Federated.{Seeder, Server, Actor}

  setup do
    server_name = "seed_test_#{:rand.uniform(100000)}"
    
    case Server.start_link(server_name) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      other -> raise "Unexpected result from start_link: #{inspect(other)}"
    end

    {:ok, server: server_name}
  end

  describe "default_actors/0" do
    test "returns a list of 6 default actors" do
      actors = Seeder.default_actors()
      assert 6 == length(actors)
    end

    test "default actors have correct structure" do
      actors = Seeder.default_actors()
      
      assert Enum.all?(actors, fn actor ->
        is_binary(actor.id) and is_binary(actor.name) and is_binary(actor.avatar)
      end)
    end

    test "default actors include expected characters" do
      actors = Seeder.default_actors()
      names = Enum.map(actors, & &1.name)
      
      assert "Mia Wallace" in names
      assert "Vincent Vega" in names
      assert "Jules Winnfield" in names
    end
  end

  describe "default_messages/1" do
    test "returns a list of default messages" do
      messages = Seeder.default_messages("test_server")
      assert 8 == length(messages)
    end

    test "messages have correct structure with sender, receiver, and content" do
      messages = Seeder.default_messages("test_server")
      
      assert Enum.all?(messages, fn {sender, receiver, content} ->
        is_binary(sender) and is_binary(receiver) and is_binary(content)
      end)
    end

    test "messages use provided server name" do
      server = "custom_server"
      messages = Seeder.default_messages(server)
      
      assert Enum.all?(messages, fn {sender, receiver, _content} ->
        String.contains?(sender, "@#{server}") and String.contains?(receiver, "@#{server}")
      end)
    end
  end

  describe "seed/2" do
    test "seeds server with default actors", %{server: server} do
      assert {:ok, message} = Seeder.seed(server)
      assert message =~ "Added 6 actors to #{server}"
    end

    test "seeds server with custom actors", %{server: server} do
      custom_actors = [
        Actor.new("test1", "Test One", "img://test1"),
        Actor.new("test2", "Test Two", "img://test2")
      ]

      assert {:ok, message} = Seeder.seed(server, custom_actors)
      assert message =~ "Added 2 actors to #{server}"
    end

    test "actors are actually added to the server", %{server: server} do
      Seeder.seed(server)
      
      assert {:ok, _actor} = Server.get_profile("mia@#{server}", "vincent@#{server}")
    end
  end

  describe "seed_with_messages/2" do
    test "seeds server with actors and messages", %{server: server} do
      assert {:ok, message} = Seeder.seed_with_messages(server)
      assert message =~ "Added 6 actors and 8 messages to #{server}"
    end

    test "messages are actually delivered to actors", %{server: server} do
      Seeder.seed_with_messages(server)
      
      messages = Server.retrieve_messages("mia@#{server}")
      assert length(messages) > 0
    end
  end

  describe "seed_all/1" do
    test "seeds multiple servers" do
      server1 = "multi_test_1_#{:rand.uniform(100000)}"
      server2 = "multi_test_2_#{:rand.uniform(100000)}"
      
      Server.start_link(server1)
      Server.start_link(server2)

      results = Seeder.seed_all([server1, server2])
      
      assert 2 == length(results)
      assert Enum.all?(results, fn {:ok, _msg} -> true end)
    end
  end

  describe "seed_all_with_messages/1" do
    test "seeds multiple servers with messages" do
      server1 = "multi_msg_1_#{:rand.uniform(100000)}"
      server2 = "multi_msg_2_#{:rand.uniform(100000)}"
      
      Server.start_link(server1)
      Server.start_link(server2)

      results = Seeder.seed_all_with_messages([server1, server2])
      
      assert 2 == length(results)
      assert Enum.all?(results, fn {:ok, _msg} -> true end)
    end
  end

  describe "quick_start/1" do
    test "starts a new server and seeds it" do
      server_name = "quick_#{:rand.uniform(100000)}"
      
      assert {:ok, pid, message} = Seeder.quick_start(server_name)
      assert Process.alive?(pid)
      assert message =~ "Added 6 actors"
      
      GenServer.stop(pid)
    end

    test "handles already started server" do
      server_name = "already_started_#{:rand.uniform(100000)}"
      {:ok, pid} = Server.start_link(server_name)
      
      assert {:ok, ^pid, message} = Seeder.quick_start(server_name)
      assert message =~ "Added 6 actors"
      
      GenServer.stop(pid)
    end
  end

  describe "quick_start_with_messages/1" do
    test "starts a new server and seeds it with messages" do
      server_name = "quick_msg_#{:rand.uniform(100000)}"
      
      assert {:ok, pid, message} = Seeder.quick_start_with_messages(server_name)
      assert Process.alive?(pid)
      assert message =~ "Added 6 actors and 8 messages"
      
      GenServer.stop(pid)
    end

    test "handles already started server with messages" do
      server_name = "already_msg_#{:rand.uniform(100000)}"
      {:ok, pid} = Server.start_link(server_name)
      
      assert {:ok, ^pid, message} = Seeder.quick_start_with_messages(server_name)
      assert message =~ "Added 6 actors and 8 messages"
      
      GenServer.stop(pid)
    end
  end
end
