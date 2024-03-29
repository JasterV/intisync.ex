defmodule IntisyncWeb.RemoteLiveTest do
  use IntisyncWeb.ConnCase
  import Phoenix.LiveViewTest

  defp generate_session_id(_) do
    %{session_id: Intisync.Puid.generate()}
  end

  setup [:generate_session_id]

  test "A remote can join a fresh new session", %{conn: conn, session_id: session_id} do
    {:ok, _hub_view, _html} = live(conn, ~p"/sessions/#{session_id}")
    {:ok, _view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")
  end

  test "A remote can't join a session that already has a controller", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, _hub_view, _html} = live(conn, ~p"/sessions/#{session_id}")
    {:ok, _view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/sessions/#{session_id}/remote")
  end

  test "A remote can't join a non existing session", %{conn: conn, session_id: session_id} do
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/sessions/#{session_id}/remote")
  end

  test "Renders a device card when a device connected event is received", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, hub_view, _html} = live(conn, ~p"/sessions/#{session_id}")
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")

    render_click(hub_view, "connected", %{})

    render_click(hub_view, "device_connected", %{index: 0, name: "My dummy device"})

    assert view |> element("#device-0") |> render() =~ "My dummy device"
  end

  test "Removes a device card when a device disconnected event is received", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, hub_view, _html} = live(conn, ~p"/sessions/#{session_id}")
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")

    render_click(hub_view, "connected", %{})

    render_click(hub_view, "device_connected", %{index: 0, name: "My dummy device"})

    assert view |> element("#device-0") |> has_element?()

    render_click(hub_view, "device_disconnected", %{index: 0})

    refute view |> element("#device-0") |> has_element?()
  end

  test "Updates device vibration when sliding the device vibration bar", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, hub_view, _html} = live(conn, ~p"/sessions/#{session_id}")
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")

    render_click(hub_view, "connected", %{})

    render_click(hub_view, "device_connected", %{index: 0, name: "My dummy device"})

    assert view |> element("#device-0") |> has_element?()

    render_change(view, "vibrate_device:0", %{"vibration" => "45"})

    assert view |> element("#device-0") |> render() =~ "value=\"45\""
  end

  test "When a devices empty event is received, all devices are removed from the view", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, hub_view, _html} = live(conn, ~p"/sessions/#{session_id}")
    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")

    render_click(hub_view, "connected", %{})

    render_click(hub_view, "device_connected", %{index: 0, name: "My dummy device"})
    render_click(hub_view, "device_connected", %{index: 1, name: "My dummy device"})

    assert view |> element("#device-0") |> has_element?()
    assert view |> element("#device-1") |> has_element?()

    render_click(hub_view, "disconnected", %{})

    refute view |> element("#device-0") |> has_element?()
    refute view |> element("#device-1") |> has_element?()
  end

  test "Shows all the connected devices when joining a session with already connected devices", %{
    conn: conn,
    session_id: session_id
  } do
    {:ok, hub_view, _html} = live(conn, ~p"/sessions/#{session_id}")

    render_click(hub_view, "connected", %{})

    render_click(hub_view, "device_connected", %{index: 0, name: "My dummy device"})
    render_click(hub_view, "device_connected", %{index: 1, name: "My dummy device"})

    {:ok, view, _html} = live(conn, ~p"/sessions/#{session_id}/remote")

    assert view |> element("#device-0") |> has_element?()
    assert view |> element("#device-1") |> has_element?()
  end
end
