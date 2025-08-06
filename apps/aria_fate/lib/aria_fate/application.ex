defmodule AriaFate.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Define workers and child supervisors to be supervised
      # {AriaFate.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaFate.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
