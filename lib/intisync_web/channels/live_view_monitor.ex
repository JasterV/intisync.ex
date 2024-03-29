defmodule IntisyncWeb.LiveViewMonitor do
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
    mref = Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, {view_module, meta, mref})}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    {{module, meta, mref}, new_views} = Map.pop(state.views, pid)

    Task.start(fn -> module.unmount(reason, meta) end)

    Process.demonitor(mref)

    {:noreply, %{state | views: new_views}}
  end
end
