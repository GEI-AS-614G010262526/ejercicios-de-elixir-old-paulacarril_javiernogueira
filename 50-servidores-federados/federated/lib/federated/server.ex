defmodule Federated.Server do
  @moduledoc"""

  """

  use GenServer
  alias Federated.{Actor, Network}

  #################
  ## Public API
  #################
  def start_link(name) do
    GenServer.start_link(__MODULE__, %{name: name, actors: %{}}, name: via(name))
  end

  def add_actor(server, %Actor{} = actor) do
    GenServer.call(via(server), {:add_actor, actor})
  end

  def get_profile(requestor, actor_id) do
    req_normalized = normalize_actor(requestor)
    actor_normalized = normalize_actor(actor_id)
    GenServer.call(via(Actor.server_name(actor_normalized)), {:get_profile, req_normalized, actor_normalized})
  end

  def post_message(sender, receiver, msg) do
    sender_normalized = normalize_actor(sender)
    receiver_normalized = normalize_actor(receiver)
    GenServer.call(via(Actor.server_name(sender_normalized)), {:post_message, sender_normalized, receiver_normalized, msg})
  end

  def retrieve_messages(actor) do
    actor_normalized = normalize_actor(actor)
    GenServer.call(via(Actor.server_name(actor_normalized)), {:retrieve_messages, actor_normalized})
  end

  #################
  ## Callbacks
  #################
  def init(state), do: {:ok, state}

  def handle_call({:add_actor, actor}, _from, state) do
    username = Actor.username(actor)
    {:reply, :ok, put_in(state.actors[username], actor)}
  end

  def handle_call({:get_profile, requestor, actor}, _from, state) do
    with true <- registered?(state, requestor),
         username <- Actor.username(actor) do
      cond do
        Actor.server_name(actor) == state.name ->
          {:reply, Map.fetch(state.actors, username), state}
        true ->
          {:reply, Network.forward_get_profile(state.name, Actor.server_name(actor), actor.id), state}
      end
    else
      _ -> {:reply, {:error, :unknown_requestor}, state}
    end
  end

  def handle_call({:post_message, sender, receiver, msg}, _from, state) do
    with true <- registered?(state, sender),
        true <- registered?(state, receiver),
        username <- Actor.username(receiver) do
      cond do
        Actor.server_name(receiver) == state.name ->
          new_inbox = [%{from: sender.id, content: msg, timestamp: DateTime.utc_now()} | Map.get(state.actors, username).inbox]
          updated_actor = %{Map.get(state.actors, username) | inbox: new_inbox}
          new_state = put_in(state.actors[username], updated_actor)
          {:reply, :ok, new_state}
        true ->
          {:reply, Network.forward_post_message(state.name, Actor.server_name(receiver), receiver, msg), state}
      end
    else
      _ -> {:reply, {:error, :unknown_sender}, state}
    end
  end

  def handle_call({:retrieve_messages, actor}, _from, state) do
    with true <- registered?(state, actor),
        username <- Actor.username(actor) do
      cond do
        Actor.server_name(actor) == state.name ->
          {:reply, Map.get(state.actors, username).inbox, state}
        true ->
          {:reply, {:error, :incorrect_server}, state}
      end
    else
      _ -> {:reply, {:error, :unknown_user}, state}
    end
  end

  #################
  ## Auxiliar functions
  #################
  defp via(name), do: {:via, Registry, {Federated.Registry, name}}

  defp registered?(state, %Actor{} = actor) do
    username = Actor.username(actor)
    Map.has_key?(state.actors, username)
  end

  defp normalize_actor(%Actor{} = actor), do: actor
  defp normalize_actor(id) when is_binary(id) do
    username = String.split(id, "@") |> Enum.at(0)
    %Actor{id: id, name: username, avatar: nil, inbox: []}
  end
end
