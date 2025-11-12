
# test/federated_integration_test.exs
defmodule Federated.IntegrationTest do
  use ExUnit.Case, async: false
  alias Federated.{Server, Actor, Seeder}

  setup do
    server1 = "integration_1_#{:rand.uniform(100000)}"
    server2 = "integration_2_#{:rand.uniform(100000)}"
    
    Server.start_link(server1)
    Server.start_link(server2)

    {:ok, server1: server1, server2: server2}
  end

  describe "complete workflow" do
    test "actors can communicate within same server", %{server1: server} do
      Seeder.seed(server)
      
      Server.post_message("mia@#{server}", "vincent@#{server}", "Test message")
      
      messages = Server.retrieve_messages("vincent@#{server}")
      
      assert 1 == length(messages)
      assert "Test message" == hd(messages).content
      assert "mia@#{server}" == hd(messages).from
    end

    test "multiple messages preserve order", %{server1: server} do
      actor1 = Actor.new("user1@#{server}", "User 1", "img://1")
      actor2 = Actor.new("user2@#{server}", "User 2", "img://2")
      
      Server.add_actor(server, actor1)
      Server.add_actor(server, actor2)
      
      Server.post_message("user1@#{server}", "user2@#{server}", "First")
      Server.post_message("user1@#{server}", "user2@#{server}", "Second")
      Server.post_message("user1@#{server}", "user2@#{server}", "Third")
      
      messages = Server.retrieve_messages("user2@#{server}")
      
      assert 3 == length(messages)
      assert "Third" == Enum.at(messages, 0).content
      assert "Second" == Enum.at(messages, 1).content
      assert "First" == Enum.at(messages, 2).content
    end

    test "seed_with_messages creates functional setup", %{server1: server} do
      Seeder.seed_with_messages(server)
      
      mia_messages = Server.retrieve_messages("mia@#{server}")
      vincent_messages = Server.retrieve_messages("vincent@#{server}")
      
      assert length(mia_messages) > 0
      assert length(vincent_messages) > 0
    end

    test "conversation between multiple actors", %{server1: server} do
      Seeder.seed(server)
      
      Server.post_message("mia@#{server}", "vincent@#{server}", "Hey Vincent!")
      Server.post_message("vincent@#{server}", "mia@#{server}", "Hi Mia!")
      Server.post_message("mia@#{server}", "vincent@#{server}", "How are you?")
      Server.post_message("vincent@#{server}", "mia@#{server}", "Doing great!")
      
      mia_messages = Server.retrieve_messages("mia@#{server}")
      vincent_messages = Server.retrieve_messages("vincent@#{server}")
      
      assert 2 == length(mia_messages)
      assert 2 == length(vincent_messages)
      
      assert Enum.any?(mia_messages, fn msg -> msg.content == "Hi Mia!" end)
      assert Enum.any?(vincent_messages, fn msg -> msg.content == "Hey Vincent!" end)
    end

    test "actor can get profile of another actor", %{server1: server} do
      Seeder.seed(server)
      
      assert {:ok, profile} = Server.get_profile("mia@#{server}", "vincent@#{server}")
      
      assert "Vincent Vega" == profile.name
      assert "https://avatar.example.com/vincent.png" == profile.avatar
      assert "vincent" == profile.id
    end

    test "timestamps are properly set on messages", %{server1: server} do
      actor1 = Actor.new("sender@#{server}", "Sender", "img://sender")
      actor2 = Actor.new("receiver@#{server}", "Receiver", "img://receiver")
      
      Server.add_actor(server, actor1)
      Server.add_actor(server, actor2)
      
      before_send = DateTime.utc_now()
      Server.post_message("sender@#{server}", "receiver@#{server}", "Timestamped message")
      after_send = DateTime.utc_now()
      
      [message] = Server.retrieve_messages("receiver@#{server}")
      
      assert DateTime.compare(message.timestamp, before_send) in [:gt, :eq]
      assert DateTime.compare(message.timestamp, after_send) in [:lt, :eq]
    end
  end

  describe "error handling" do
    test "cannot send message to non-existent actor", %{server1: server} do
      actor = Actor.new("sender@#{server}", "Sender", "img://sender")
      Server.add_actor(server, actor)
      
      result = Server.post_message("sender@#{server}", "nonexistent@#{server}", "Hello")
      
      assert {:error, :unknown_sender} == result
    end

    test "cannot get profile without being registered", %{server1: server} do
      actor = Actor.new("target@#{server}", "Target", "img://target")
      Server.add_actor(server, actor)
      
      result = Server.get_profile("unknown@#{server}", "target@#{server}")
      
      assert {:error, :unknown_requestor} == result
    end

    test "cannot retrieve messages from wrong server", %{server1: server1, server2: server2} do
      actor = Actor.new("user@#{server1}", "User", "img://user")
      Server.add_actor(server1, actor)
      
      result = Server.retrieve_messages("user@#{server2}")
      
      assert {:error, :unknown_user} == result
    end
  end

  describe "full seeder workflow" do
    test "quick_start creates fully functional server" do
      server_name = "quick_test_#{:rand.uniform(100000)}"
      
      assert {:ok, pid, _message} = Seeder.quick_start_with_messages(server_name)
      
      messages = Server.retrieve_messages("mia@#{server_name}")
      assert length(messages) > 0
      
      Server.post_message("jules@#{server_name}", "mia@#{server_name}", "New message")
      
      updated_messages = Server.retrieve_messages("mia@#{server_name}")
      assert length(updated_messages) > length(messages)
      
      GenServer.stop(pid)
    end
  end
end