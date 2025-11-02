defmodule Federated.Seeder do
  @moduledoc """
  Helper module to seed actors into a Federated.Server for testing and development.
  """

  alias Federated.{Actor, Server}

  @doc """
  Seeds a server with predefined actors.

  ## Examples

      iex> Federated.Seeder.seed("enterprise")
      {:ok, "Added 6 actors to enterprise"}

      iex> Federated.Seeder.seed("enterprise", custom_actors())
      {:ok, "Added 3 actors to enterprise"}
  """
  def seed(server_name, actors \\ default_actors()) do
    results =
      Enum.map(actors, fn actor ->
        Server.add_actor(server_name, actor)
      end)

    success_count = Enum.count(results, &match?(:ok, &1))

    IO.puts("\n Successfully added #{success_count} actors to #{server_name}:")
    Enum.each(actors, fn actor ->
      IO.puts("  - #{actor.name} (#{actor.id})")
    end)

    {:ok, "Added #{success_count} actors to #{server_name}"}
  end

  @doc """
  Seeds a server with actors and adds messages between them.

  ## Examples

      iex> Federated.Seeder.seed_with_messages("enterprise")
      {:ok, "Added 6 actors and 8 messages to enterprise"}
  """
  def seed_with_messages(server_name, actors \\ default_actors()) do

    # First, seed all actors
    {:ok, actor_message} = seed(server_name, actors)

    # Add messages between actors
    messages = default_messages(server_name)
    message_results =
      Enum.map(messages, fn {sender_id, receiver_id, msg} ->
        IO.puts("\n Enviando mensaje")
        Server.post_message(sender_id, receiver_id, msg)
      end)

    success_count = Enum.count(message_results, &match?(:ok, &1))

    {:ok, "Added #{length(actors)} actors and #{success_count} messages to #{server_name}"}
  end

  @doc """
  Returns a list of default actors for a given server.
  """
  def default_actors() do
    [
      Actor.new("mia", "Mia Wallace", "https://avatar.example.com/mia.png"),
      Actor.new("vincent", "Vincent Vega", "https://avatar.example.com/vincent.png"),
      Actor.new("jules", "Jules Winnfield", "https://avatar.example.com/jules.png"),
      Actor.new("butch", "Butch Coolidge", "https://avatar.example.com/butch.png"),
      Actor.new("marsellus", "Marsellus Wallace", "https://avatar.example.com/marsellus.png"),
      Actor.new("winston", "Winston Wolf", "https://avatar.example.com/winston.png")
    ]
  end

  @doc """
  Returns a list of default messages between actors.
  """
  def default_messages(server_name) do
    [
      {"mia@#{server_name}", "vincent@#{server_name}", "Hey Vincent, how's it going?"},
      {"vincent@#{server_name}", "mia@#{server_name}", "Not much, just finished a job"},
      {"jules@#{server_name}", "vincent@#{server_name}", "You two need to talk"},
      {"vincent@#{server_name}", "jules@#{server_name}", "About what?"},
      {"mia@#{server_name}", "butch@#{server_name}", "I heard about your situation"},
      {"butch@#{server_name}", "mia@#{server_name}", "Yeah, it's complicated"},
      {"winston@#{server_name}", "marsellus@#{server_name}", "Everything is handled"},
      {"marsellus@#{server_name}", "winston@#{server_name}", "Good work, as always"}
    ]
  end

  @doc """
  Seeds multiple servers at once.

  ## Examples

      iex> Federated.Seeder.seed_all(["enterprise", "voyager"])
      [:ok, :ok]
  """
  def seed_all(server_names) do
    Enum.map(server_names, &seed/1)
  end

  @doc """
  Seeds multiple servers at once with actors and messages.

  ## Examples

      iex> Federated.Seeder.seed_all_with_messages(["enterprise", "voyager"])
      [:ok, :ok]
  """
  def seed_all_with_messages(server_names) do
    Enum.map(server_names, &seed_with_messages/1)
  end

  @doc """
  Quick seed function for IEx - starts server and seeds it in one call.

  ## Examples

      iex> Federated.Seeder.quick_start("enterprise")
      {:ok, pid, "Added 6 actors"}
  """
  def quick_start(server_name) do
    case Server.start_link(server_name) do
      {:ok, pid} ->
        {:ok, message} = seed(server_name)
        {:ok, pid, message}

      {:error, {:already_started, pid}} ->
        IO.puts("Server already running, just seeding actors...")
        {:ok, message} = seed(server_name)
        {:ok, pid, message}

      error ->
        error
    end
  end

  @doc """
  Quick seed function for IEx - starts server and seeds it with messages in one call.

  ## Examples

      iex> Federated.Seeder.quick_start_with_messages("enterprise")
      {:ok, pid, "Added 6 actors and 8 messages"}
  """
  def quick_start_with_messages(server_name) do
    case Server.start_link(server_name) do
      {:ok, pid} ->
        {:ok, message} = seed_with_messages(server_name)
        {:ok, pid, message}

      {:error, {:already_started, pid}} ->
        IO.puts("Server already running, just seeding actors and messages...")
        {:ok, message} = seed_with_messages(server_name)
        {:ok, pid, message}

      error ->
        error
    end
  end
end
