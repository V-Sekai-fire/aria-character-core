# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Timestrike do
  @moduledoc """
  CLI client for Aria Timestrike game.
  
  ## Usage
  
      mix timestrike
  
  This starts the terminal-based Timestrike game interface.
  """
  
  use Mix.Task
  
  alias AriaTimestrike.GameEngine
  alias AriaTimestrike.CliClient
  
  @shortdoc "Start the Timestrike CLI game client"
  
  def run(_args) do
    Mix.Task.run("app.start")
    
    IO.puts("🎯 Aria Timestrike - Terminal Interface")
    IO.puts("=====================================")
    IO.puts("")
    
    # Start the game
    {:ok, game_state} = GameEngine.start_game()
    
    # Start the CLI client
    CliClient.start(game_state)
  end
end
