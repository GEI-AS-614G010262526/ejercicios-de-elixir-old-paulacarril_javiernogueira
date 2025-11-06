defmodule Federated.Network do
  @moduledoc"""
  Maneja la comunicación entre nodos distribuidos.
  """
  alias Federated.Server

  def forward_get_profile(from_server, remote_server, actor_id) do
    case resolve_node(remote_server) do
      {:ok, node} ->
        :rpc.call(node, Server, :remote_get_profile, [from_server, actor_id])
      {:error, reason} ->
        {:error, reason}
    end
  end

  def forward_post_message(sender_id, remote_server, receiver_id, msg) do
    case resolve_node(remote_server) do
      {:ok, node} ->
        :rpc.call(node, Server, :remote_post_message, [sender_id, receiver_id, msg])
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp resolve_node(server_name) do
    matching_node = 
      [Node.self() | Node.list()]
      |> Enum.find(fn node ->
        node
        |> Atom.to_string()
        |> String.starts_with?(server_name <> "@")
      end)
    
    case matching_node do
      nil -> {:error, :node_not_found}
      node -> {:ok, node}
    end
  end
end