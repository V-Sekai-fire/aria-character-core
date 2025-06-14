# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.GameSupervisor do
  @moduledoc """
  Supervisor for game-related processes.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Game state agent for global state storage
      %{
        id: :game_state_store,
        start: {Agent, :start_link, [fn -> %{} end, [name: :game_state_store]]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
