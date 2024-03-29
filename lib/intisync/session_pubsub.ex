defmodule Intisync.SessionPubSub do
  def broadcast!(session_id, topic, event, payload) do
    topic = "#{topic}:#{event}:#{session_id}"
    payload = %{payload: payload, topic: topic}

    Phoenix.PubSub.broadcast!(Intisync.PubSub, topic, payload)
  end

  def subscribe!(session_id, topic, event) do
    :ok = Phoenix.PubSub.subscribe(Intisync.PubSub, "#{topic}:#{event}:#{session_id}")
  end
end
