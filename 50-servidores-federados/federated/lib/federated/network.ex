defmodule Federated.Network do
  @moduledoc"""
  """
  alias Federated.Server

  def forward_get_profile(from, remote_server, actor_id) do
    :rpc.call(String.to_atom(remote_server), Server, :remote_get_profile, [from, actor_id])
  end

  def forward_post_message(from, remote_server, receiver, msg) do
    :rpc.call(String.to_atom(remote_server), Server, :remote_post_message, [from, receiver, msg])
  end
end
