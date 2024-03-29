defmodule IntisyncWeb.DeviceCardComponent do
  @moduledoc """
    Renders a device card
  """
  use Phoenix.Component
  import IntisyncWeb.CoreComponents

  attr :id, :string, required: true
  attr :device, :map, required: true
  attr :disabled, :boolean, default: false

  def view(assigns) do
    ~H"""
    <div
      id={@id}
      class="text-zinc-600 max-w-md border-solid border-2 rounded-lg border-indigo-500 p-4 "
    >
      <p class="font-semibold text-2xl mb-4">
        <.icon name="hero-link-solid" class="mr-1" />
        <%= @device.name %>
      </p>
      <input
        type="range"
        min="0"
        max="100"
        name="vibration"
        value={@device.vibration}
        disabled={@disabled}
        class="w-full h-3 cursor-pointer"
      />
    </div>
    """
  end
end
