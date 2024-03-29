defmodule IntisyncWeb.RemoteLive do
  alias Intisync.SessionPubSub
  use IntisyncWeb, :live_view

  alias IntisyncWeb.LiveViewMonitor
  alias Intisync.SessionsSupervisor
  alias Intisync.SessionServer

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :devices, %{})}
  end

  def handle_params(%{"id" => session_id}, _uri, socket) do
    if connected?(socket),
      do: handle_connected(session_id, socket),
      else: {:noreply, socket}
  end

  def unmount(_reason, {session_server_pid}) do
    SessionServer.remote_disconnected(session_server_pid)
  end

  defp handle_connected(session_id, socket) do
    case lookup_session_server(session_id) do
      {:error, :not_found} ->
        socket = socket |> put_flash(:error, "This session expired!") |> redirect(to: "/")
        {:noreply, socket}

      {:error, :unauthorized} ->
        socket = socket |> put_flash(:error, "Unauthorized") |> redirect(to: "/")
        {:noreply, socket}

      {:ok, pid} ->
        enable_subscriptions(session_id)
        LiveViewMonitor.monitor(self(), __MODULE__, {pid})
        SessionServer.remote_connected(pid)
        devices = SessionServer.get_devices(pid)

        socket =
          socket
          |> assign(:session_id, session_id)
          |> assign(:session_server_pid, pid)
          |> assign(:devices, devices)

        {:noreply, socket}
    end
  end

  defp lookup_session_server(session_id) do
    case SessionsSupervisor.whereis(session_id) do
      nil ->
        {:error, :not_found}

      pid ->
        if SessionServer.is_full?(pid) do
          {:error, :unauthorized}
        else
          {:ok, pid}
        end
    end
  end

  defp enable_subscriptions(session_id) do
    SessionPubSub.subscribe!(session_id, "session", "closed")
    SessionPubSub.subscribe!(session_id, "devices", "connected")
    SessionPubSub.subscribe!(session_id, "devices", "disconnected")
    SessionPubSub.subscribe!(session_id, "devices", "empty")
  end

  ##############
  # Hub events #
  ##############
  def handle_info(%{topic: "session:closed:" <> _session_id}, socket) do
    socket = socket |> put_flash(:info, "The host terminated the session") |> redirect(to: "/")
    {:noreply, socket}
  end

  def handle_info(%{topic: "devices:empty:" <> _session_id}, socket) do
    {:noreply, assign(socket, :devices, %{})}
  end

  def handle_info(%{topic: "devices:connected:" <> _session_id}, socket) do
    devices = SessionServer.get_devices(socket.assigns.session_server_pid)
    {:noreply, assign(socket, :devices, devices)}
  end

  def handle_info(%{topic: "devices:disconnected:" <> _session_id}, socket) do
    devices = SessionServer.get_devices(socket.assigns.session_server_pid)
    {:noreply, assign(socket, :devices, devices)}
  end

  ##############
  # UI events #
  ##############

  def handle_event(
        "vibrate_device:" <> index,
        %{"vibration" => vibration},
        socket
      ) do
    vibration = String.to_integer(vibration)
    index = String.to_integer(index)

    :ok = SessionServer.vibrate_device(socket.assigns.session_server_pid, index, vibration)
    devices = SessionServer.get_devices(socket.assigns.session_server_pid)

    {:noreply, assign(socket, :devices, devices)}
  end
end
