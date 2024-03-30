defmodule IntisyncWeb.LiveViewMonitor do
  @moduledoc """
    Monitors LiveView processes and calls their `unmount` functions when they die
  """
  use GenServer

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: {:global, __MODULE__})
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end

  def monitor(pid, view_module, meta) do
    server_pid = GenServer.whereis({:global, __MODULE__})
    GenServer.call(server_pid, {:monitor, pid, view_module, meta})
  end

  def handle_call({:monitor, pid, view_module, meta}, _, %{views: views} = state) do
    _ref = Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, {view_module, meta})}}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    {{module, meta}, new_views} = Map.pop(state.views, pid)

    Process.demonitor(ref)

    Task.start(fn -> module.unmount(reason, meta) end)

    {:noreply, %{state | views: new_views}}
  end
end
