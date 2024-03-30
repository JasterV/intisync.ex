defmodule Intisync.SessionServerTest do
  use ExUnit.Case, async: true

  alias Intisync.SessionServer

  setup do
    session_id = Intisync.Puid.generate()
    pid = start_supervised!({SessionServer, {session_id}})
    %{session_server_pid: pid, session_id: session_id}
  end

  test "A session starts with the proper initial state", %{
    session_server_pid: pid,
    session_id: session_id
  } do
    assert SessionServer.get_id(pid) == session_id
    assert SessionServer.get_devices(pid) == %{}
    refute SessionServer.full?(pid)
  end

  test "Calling device_connected adds the device to the state", %{
    session_server_pid: pid
  } do
    index = 0
    device = %{name: "Dummy", vibration: 0}
    assert SessionServer.device_connected(pid, index, device) == :ok
    assert SessionServer.get_devices(pid) == %{index => device}
  end

  test "Calling device_disconnected removes the device to the state", %{
    session_server_pid: pid
  } do
    index = 0
    device = %{name: "Dummy", vibration: 0}
    assert SessionServer.device_connected(pid, index, device) == :ok
    assert SessionServer.device_disconnected(pid, index) == :ok
    assert SessionServer.get_devices(pid) == %{}
  end

  test "Calling remote_connected sets the session as full", %{
    session_server_pid: pid
  } do
    SessionServer.remote_connected(pid)
    assert SessionServer.full?(pid)
  end

  test "Calling remote_disconnected sets the session as not full", %{
    session_server_pid: pid
  } do
    SessionServer.remote_connected(pid)
    assert SessionServer.full?(pid)
    SessionServer.remote_disconnected(pid)
    refute SessionServer.full?(pid)
  end

  test "Calling empty_devices resets the devices state", %{
    session_server_pid: pid
  } do
    assert SessionServer.device_connected(pid, 0, %{name: "Dummy", vibration: 0})
    assert SessionServer.device_connected(pid, 1, %{name: "Dummy2", vibration: 0})
    assert map_size(SessionServer.get_devices(pid)) == 2
    assert SessionServer.empty_devices(pid) == :ok
    assert SessionServer.get_devices(pid) == %{}
  end

  test "Calling vibrate device updates the vibration of that device", %{
    session_server_pid: pid
  } do
    assert SessionServer.device_connected(pid, 0, %{name: "Dummy", vibration: 0})
    assert SessionServer.device_connected(pid, 1, %{name: "Dummy2", vibration: 0})
    assert SessionServer.vibrate_device(pid, 0, 45) == :ok
    assert %{0 => %{vibration: 45}, 1 => %{vibration: 0}} = SessionServer.get_devices(pid)
  end
end
