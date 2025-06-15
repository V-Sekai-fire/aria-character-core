# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Timestrike do
  @moduledoc """
  TUI client for Aria Timestrike game.

  ## Usage

      mix timestrike

  This starts the modern terminal-based Timestrike game interface using Raxol TUI.
  """

  use Mix.Task

  alias AriaTimestrike.GameEngine
  # TUI functionality moved to AriaTui app

  @shortdoc "Start the Timestrike TUI game client"

  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("🎯 Aria Timestrike - Game Engine")
    IO.puts("==================================")
    IO.puts("TUI functionality has been moved to the AriaTui app.")
    IO.puts("Use 'mix tui' to start the TUI interface.")
    IO.puts("Loading game engine...")
    Process.sleep(1000)

    # Start the game engine
    {:ok, game_state} = GameEngine.start_game()

    IO.puts("Game engine started successfully!")
    IO.inspect(game_state, label: "Game State")
  end
end
