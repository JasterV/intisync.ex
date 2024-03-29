defmodule Intisync.SessionServer do
  @moduledoc """
    Contains the business logic of a session.
    It is the source of truth of the session state.
  """
  use GenServer

  alias Intisync.SessionPubSub

  def init(session_id) do
    {:ok,
     %{
       session_id: session_id,
       remote_connection_status: :disconnected,
       devices: %{}
     }}
  end

  def start_link({session_id}) do
    GenServer.start_link(__MODULE__, session_id, name: {:global, "session:#{session_id}"})
  end

  def get_id(pid) do
    GenServer.call(pid, {:get_id})
  end

  def remote_connected(pid) do
    GenServer.cast(pid, {:remote_connected})
  end

  def remote_disconnected(pid) do
    GenServer.cast(pid, {:remote_disconnected})
  end

  def device_connected(pid, index, device) do
    GenServer.call(pid, {:device_connected, index, device})
  end

  def device_disconnected(pid, index) do
    GenServer.call(pid, {:device_disconnected, index})
  end

  def empty_devices(pid) do
    GenServer.call(pid, {:empty_devices})
  end

  def vibrate_device(pid, index, vibration) do
    GenServer.call(pid, {:vibrate_device, index, vibration})
  end

  def get_devices(pid) do
    GenServer.call(pid, {:get_devices})
  end

  def full?(pid) do
    GenServer.call(pid, {:full?})
  end

  def handle_call({:get_id}, _from, state) do
    {:reply, state.session_id, state}
  end

  def handle_call({:get_devices}, _from, state) do
    {:reply, state.devices, state}
  end

  def handle_call({:full?}, _from, state) do
    full? = state.remote_connection_status == :connected

    {:reply, full?, state}
  end

  def handle_call({:device_connected, index, device}, _from, state) do
    new_devices = Map.put_new(state.devices, index, device)

    GenServer.cast(
      self(),
      {:publish, "devices", "connected", %{index: index}}
    )

    {:reply, :ok, %{state | devices: new_devices}}
  end

  def handle_call({:device_disconnected, index}, _from, state) do
    new_devices = Map.delete(state.devices, index)

    GenServer.cast(
      self(),
      {:publish, "devices", "disconnected", %{index: index}}
    )

    {:reply, :ok, %{state | devices: new_devices}}
  end

  def handle_call({:vibrate_device, index, vibration}, _from, state) do
    devices = state.devices
    new_devices = Map.replace!(devices, index, %{devices[index] | vibration: vibration})

    GenServer.cast(
      self(),
      {:publish, "devices", "vibrate", %{index: index, vibration: vibration}}
    )

    {:reply, :ok, %{state | devices: new_devices}}
  end

  def handle_call({:empty_devices}, _from, state) do
    GenServer.cast(self(), {:publish, "devices", "empty", %{}})
    {:reply, :ok, %{state | devices: %{}}}
  end

  def handle_cast({:remote_connected}, state) do
    GenServer.cast(self(), {:publish, "remote", "connected", %{}})
    {:noreply, %{state | remote_connection_status: :connected}}
  end

  def handle_cast({:remote_disconnected}, state) do
    GenServer.cast(self(), {:publish, "remote", "disconnected", %{}})
    {:noreply, %{state | remote_connection_status: :disconnected}}
  end

  def handle_cast({:publish, topic, event, payload}, state) do
    SessionPubSub.broadcast!(state.session_id, topic, event, payload)
    {:noreply, state}
  end
end
