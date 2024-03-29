defmodule IntisyncWeb.LobbyLive do
  use IntisyncWeb, :live_view

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_event("create_session", _params, socket) do
    session_id = Intisync.Puid.generate()

    {:noreply, redirect(socket, to: ~p"/sessions/#{session_id}")}
  end
end
