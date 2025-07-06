# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaAuth.Application do
  @moduledoc false
  use Application
  @impl true
  def start(_type, _args) do
    children = []
    opts = [strategy: :one_for_one, name: AriaAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
