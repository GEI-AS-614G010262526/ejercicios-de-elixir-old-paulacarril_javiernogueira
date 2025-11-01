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

    IO.puts("\n✓ Successfully added #{success_count} actors to #{server_name}:")
    Enum.each(actors, fn actor ->
      IO.puts("  - #{actor.name} (#{actor.id})")
    end)

    {:ok, "Added #{success_count} actors to #{server_name}"}
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
  Seeds multiple servers at once.

  ## Examples

      iex> Federated.Seeder.seed_all(["enterprise", "voyager"])
      [:ok, :ok]
  """
  def seed_all(server_names) do
    Enum.map(server_names, &seed/1)
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
end
