# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaGltf.Application do
  @moduledoc """
  The AriaGltf Application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Define workers and child supervisors to be supervised
      # {AriaGltf.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaGltf.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
