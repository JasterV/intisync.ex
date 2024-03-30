defmodule IntisyncWeb.HubLiveTest do
  use IntisyncWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Intisync.SessionsSupervisor

  defp generate_session_id(_) do
    %{session_id: Intisync.Puid.generate()}
  end

  setup [:generate_session_id]

  test "A new session gets created when user access the hub with an available ID", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, _view, _html} = live(conn, ~p"/sessions/#{session_id}")

    assert SessionsSupervisor.whereis(session_id) != nil
  end

  test "session gets removed when hub disconnects", %{conn: conn, session_id: session_id} do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    assert view |> element("#nav-home-btn") |> render_click() |> follow_redirect(conn)

    assert SessionsSupervisor.whereis(session_id) == nil
  end

  test "User can't host a session that is already being hosted", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, _view, _html} = live(conn, ~p"/sessions/#{session_id}")

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/sessions/#{session_id}")
  end

  test "Intiface central status is set as disconnected when creating a session", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    assert view |> element("#intiface-client-disconnected-badge") |> has_element?()
    refute view |> element("#intiface-client-connected-badge") |> has_element?()
  end

  test "Intiface central status is set as connected when receiving a connected event from client",
       %{conn: conn, session_id: session_id} do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    render_click(view, "connected", %{})

    assert view |> element("#intiface-client-connected-badge") |> has_element?()
    refute view |> element("#intiface-client-disconnected-badge") |> has_element?()
  end

  test "Intiface central status is set back to disconnected when receiving disconnected event from client",
       %{
         conn: conn,
         session_id: session_id
       } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    render_click(view, "connected", %{})

    assert view |> element("#intiface-client-connected-badge") |> has_element?()
    refute view |> element("#intiface-client-disconnected-badge") |> has_element?()

    render_click(view, "disconnected", %{})

    assert view |> element("#intiface-client-disconnected-badge") |> has_element?()
    refute view |> element("#intiface-client-connected-badge") |> has_element?()
  end

  test "Remote controller status is set as disconnected when creating a session", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    assert view |> element("#remote-controller-disconnected-badge") |> has_element?()
    refute view |> element("#remote-controller-connected-badge") |> has_element?()
  end

  test "Remote controller status is set to connected when controller connects", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")
    {:ok, _remote_view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")

    assert view |> element("#remote-controller-connected-badge") |> has_element?()
    refute view |> element("#remote-controller-disconnected-badge") |> has_element?()
  end

  test "Remote controller status is set back to disconnected when controller disconnects", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")
    {:ok, remote_view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")

    assert remote_view |> element("#nav-home-btn") |> render_click() |> follow_redirect(conn)

    assert view |> element("#remote-controller-disconnected-badge") |> has_element?()
    refute view |> element("#remote-controller-connected-badge") |> has_element?()
  end

  test "The connect buttons section gets replaced by the devices section when intiface client connects",
       %{conn: conn, session_id: session_id} do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    assert view |> element("#intiface-connect-button") |> has_element?()
    refute view |> element("#connected-devices-section") |> has_element?()

    render_click(view, "connected", %{})

    refute view |> element("#intiface-connect-button") |> has_element?()
    assert view |> element("#connected-devices-section") |> has_element?()
  end

  test "The devices section gets replaced by the connect buttons section when intiface client disconnects",
       %{conn: conn, session_id: session_id} do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    render_click(view, "connected", %{})

    refute view |> element("#intiface-connect-button") |> has_element?()
    assert view |> element("#connected-devices-section") |> has_element?()

    render_click(view, "disconnected", %{})

    assert view |> element("#intiface-connect-button") |> has_element?()
    refute view |> element("#connected-devices-section") |> has_element?()
  end

  test "Clicking the connect button fires a connect event that gets send back to the intiface client",
       %{conn: conn, session_id: session_id} do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    assert view |> element("#intiface-connect-button") |> has_element?()

    assert view |> element("#intiface-connect-button") |> render_click()

    assert_push_event(view, "connect", %{})
  end

  test "A device connected event is ignored if intiface central is not connected", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    render_click(view, "device_connected", %{index: 0, name: "My dummy device"})

    render_click(view, "connected", %{})

    assert view |> element("#connected-devices-section") |> has_element?()

    refute view |> element("#device-0") |> has_element?()
  end

  test "A device is shown when received a device connected event", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    render_click(view, "connected", %{})

    assert view |> element("#connected-devices-section") |> has_element?()

    render_click(view, "device_connected", %{index: 0, name: "My dummy device"})

    assert view |> element("#device-0") |> render() =~ "My dummy device"
  end

  test "A device starts with vibration to 0 when connected", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    render_click(view, "connected", %{})

    assert view |> element("#connected-devices-section") |> has_element?()

    render_click(view, "device_connected", %{index: 0, name: "My dummy device"})

    assert view |> element("#device-0") |> render() =~ "value=\"0\""
  end

  test "A device is removed from the UI when received a device disconnected event", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    render_click(view, "connected", %{})

    assert view |> element("#connected-devices-section") |> has_element?()

    render_click(view, "device_connected", %{index: 0, name: "My dummy device"})

    assert view |> element("#device-0") |> has_element?()

    render_click(view, "device_disconnected", %{index: 0})

    refute view |> element("#device-0") |> has_element?()
  end

  test "When intiface client disconnects and connects back, the devices list is empty", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")

    render_click(view, "connected", %{})

    assert view |> element("#connected-devices-section") |> has_element?()

    render_click(view, "device_connected", %{index: 0, name: "My dummy device"})
    render_click(view, "device_connected", %{index: 1, name: "My second device"})

    assert view |> element("#device-0") |> has_element?()
    assert view |> element("#device-1") |> has_element?()

    render_click(view, "disconnected", %{})

    assert view |> element("#intiface-connect-button") |> has_element?()
    refute view |> element("#connected-devices-section") |> has_element?()

    render_click(view, "connected", %{})

    assert view |> element("#connected-devices-section") |> has_element?()

    refute view |> element("#device-0") |> has_element?()
    refute view |> element("#device-1") |> has_element?()
  end

  test "When a controller updates the vibration of a device, the hub updates the view and sends the event down to intiface client",
       %{
         conn: conn,
         session_id: session_id
       } do
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}")
    {:ok, remote_view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")

    render_click(view, "connected", %{})
    render_click(view, "device_connected", %{index: 0, name: "My dummy device"})

    assert view |> element("#device-0") |> render() =~ "value=\"0\""

    render_change(remote_view, "vibrate_device:0", %{"vibration" => "45"})

    assert view |> element("#device-0") |> render() =~ "value=\"45\""
  end
end
