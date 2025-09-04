defmodule AriaViewer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Phoenix PubSub for WebSocket channels
      {Phoenix.PubSub, name: AriaViewer.PubSub},

      # Start the Endpoint (http/https)
      AriaViewerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaViewer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
