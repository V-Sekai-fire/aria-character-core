# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincExecutor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  @spec start(Application.start_type(), term()) :: {:ok, pid()} | {:ok, pid(), term()} | {:error, term()}
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: AriaMinizincExecutor.Worker.start_link(arg)
      # {AriaMinizincExecutor.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaMinizincExecutor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
