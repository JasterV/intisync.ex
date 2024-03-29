defmodule Intisync.SessionsSupervisor do
  @moduledoc """
    DynamicSupervisor responsible to manage SessionServers
  """
  use DynamicSupervisor

  alias Intisync.SessionServer
  alias Intisync.SessionPubSub

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_session(session_id) do
    child_spec = {SessionServer, {session_id}}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def whereis(session_id) do
    GenServer.whereis({:global, "session:#{session_id}"})
  end

  def close_session(pid) do
    session_id = SessionServer.get_id(pid)
    SessionPubSub.broadcast!(session_id, "session", "closed", %{})
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  # Nice utility method to check which processes are under supervision
  def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  # Nice utility method to check which processes are under supervision
  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
