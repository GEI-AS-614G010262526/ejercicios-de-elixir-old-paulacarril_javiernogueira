defmodule Federated.Actor do
  @moduledoc"""

  """

  defstruct [:id, :name, :avatar, inbox: []]

  def new(id, name, avatar) do
    %__MODULE__{id: id, name: name, avatar: avatar, inbox: []}
  end

  def server_name(%__MODULE__{id: id}), do: String.split(id, "@") |> Enum.at(1)
  def username(%__MODULE__{id: id}), do: String.split(id, "@") |> Enum.at(0)
end
