defmodule LittlechatWeb.Stun do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  @doc """
  Starts the erlang stun server at port 3478.
  """
  def init(_) do
    :stun_listener.add_listener(3478, :udp, [])

    {:ok, []}
  end
end
