defmodule Federated do
  @moduledoc """
  Documentation for `Federated`.
  """
  alias Federated.{Server, Actor}

  def setup_demo() do
    {:ok, _} = Server.start_link("enterprise")
    {:ok, _} = Server.start_link("voyager")

    Server.add_actor("enterprise", Actor.new("spock@enterprise", "Spock", "img://spock"))
    Server.add_actor("voyager", Actor.new("janeway@voyager", "Janeway", "img://janeway"))
  end
end
