# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui do
  @moduledoc """
  AriaTui provides a modern Terminal User Interface for the Aria Character Core system.

  This module serves as the main entry point for TUI functionality, providing
  a clean, grid-based interface for interacting with the Timestrike game.
  """

  alias AriaTui.Client

  @doc """
  Start the TUI client with an optional initial game state.
  """
  def start(initial_game_state \\ nil) do
    Client.start(initial_game_state)
  end

  @doc """
  Hello world example function - can be removed in production.
  """
  def hello do
    :world
  end
end
