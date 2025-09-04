defmodule AriaViewerWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel("ik:*", AriaViewerWeb.IKChannel)

  # Socket id
  def id(_socket), do: nil
end
