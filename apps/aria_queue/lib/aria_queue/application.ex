# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # The queue repository
      AriaData.QueueRepo,
      # Oban supervisor
      {Oban, Application.fetch_env!(:aria_queue, Oban)}
    ]

    opts = [strategy: :one_for_one, name: AriaQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
