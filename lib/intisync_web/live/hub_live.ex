defmodule IntisyncWeb.HubLive do
  alias Intisync.SessionPubSub
  use IntisyncWeb, :live_view

  alias IntisyncWeb.LiveViewMonitor
  alias Intisync.SessionsSupervisor
  alias Intisync.SessionServer

  @config Application.compile_env!(:intisync, __MODULE__)

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:remote_controller_status, nil)
      |> assign(:intiface_client_status, nil)
      |> assign(:devices, %{})
      |> assign(:session_id, nil)
      |> assign(:share_url, nil)

    {:ok, socket}
  end

  def handle_params(%{"id" => session_id}, _uri, socket) do
    if connected?(socket),
      do: handle_connected(session_id, socket),
      else: {:noreply, socket}
  end

  defp handle_connected(session_id, socket) do
    socket =
      socket
      |> assign(:remote_controller_status, :disconnected)
      |> assign(:intiface_client_status, :disconnected)
      |> assign(:session_id, session_id)
      |> assign(:share_url, share_url(session_id))

    if exists_session?(session_id) do
      socket = socket |> put_flash(:error, "Unauthorized") |> redirect(to: "/")
      {:noreply, socket}
    else
      {:ok, pid} = SessionsSupervisor.start_session(session_id)
      enable_subscriptions(session_id)
      LiveViewMonitor.monitor(self(), __MODULE__, {pid})
      {:noreply, assign(socket, :session_server_pid, pid)}
    end
  end

  def unmount(_reason, {session_server_pid}) do
    SessionsSupervisor.close_session(session_server_pid)
  end

  defp exists_session?(session_id) do
    case SessionsSupervisor.whereis(session_id) do
      nil ->
        false

      _ ->
        true
    end
  end

  defp enable_subscriptions(session_id) do
    SessionPubSub.subscribe!(session_id, "remote", "connected")
    SessionPubSub.subscribe!(session_id, "remote", "disconnected")
    SessionPubSub.subscribe!(session_id, "devices", "vibrate")
  end

  defp share_url(session_id), do: IntisyncWeb.Endpoint.url() <> ~p"/sessions/#{session_id}/remote"

  ############################
  # Remote controller events #
  ############################

  def handle_info(%{topic: "remote:connected:" <> _session_id}, socket) do
    {:noreply, assign(socket, :remote_controller_status, :connected)}
  end

  def handle_info(%{topic: "remote:disconnected:" <> _session_id}, socket) do
    {:noreply, assign(socket, :remote_controller_status, :disconnected)}
  end

  def handle_info(
        %{
          topic: "devices:vibrate:" <> _session_id,
          payload: %{index: index, vibration: vibration}
        },
        socket
      ) do
    devices = SessionServer.get_devices(socket.assigns.session_server_pid)

    socket =
      socket
      |> assign(:devices, devices)
      |> push_event("vibrate", %{index: index, vibration: vibration})

    {:noreply, socket}
  end

  #############
  # UI events #
  #############

  def handle_event("url_shared", %{}, socket) do
    {:noreply, put_flash(socket, :info, "Session shared! :)")}
  end

  def handle_event("url_copied", %{}, socket) do
    {:noreply, put_flash(socket, :info, "Url copied! :)")}
  end

  def handle_event("url_share_error", %{"error" => error}, socket) do
    {:noreply, put_flash(socket, :error, "Failed to share session. #{error}")}
  end

  ##########################
  # Intiface Client events #
  ##########################

  def handle_event("connect", %{}, socket) do
    socket = push_event(socket, "connect", %{url: @config[:connect_url]})
    {:noreply, socket}
  end

  def handle_event("connected", %{}, socket) do
    {:noreply, assign(socket, :intiface_client_status, :connected)}
  end

  def handle_event("disconnected", %{}, socket) do
    socket =
      socket
      |> assign(:intiface_client_status, :disconnected)
      |> assign(:devices, %{})

    :ok = SessionServer.empty_devices(socket.assigns.session_server_pid)

    {:noreply, socket}
  end

  def handle_event("connect_error", _params, socket) do
    {:noreply, put_flash(socket, :error, "Failed to connect to Intiface Central. Try again!")}
  end

  def handle_event("device_connected", %{"index" => index, "name" => name}, socket)
      when socket.assigns.intiface_client_status == :connected do
    :ok =
      SessionServer.device_connected(socket.assigns.session_server_pid, index, %{
        name: name,
        vibration: 0
      })

    devices = SessionServer.get_devices(socket.assigns.session_server_pid)
    {:noreply, assign(socket, :devices, devices)}
  end

  def handle_event("device_disconnected", %{"index" => index}, socket)
      when socket.assigns.intiface_client_status == :connected do
    :ok = SessionServer.device_disconnected(socket.assigns.session_server_pid, index)
    devices = SessionServer.get_devices(socket.assigns.session_server_pid)
    {:noreply, assign(socket, :devices, devices)}
  end

  def handle_event("device_connected", _params, socket), do: {:noreply, socket}
  def handle_event("device_disconnected", _params, socket), do: {:noreply, socket}
end
