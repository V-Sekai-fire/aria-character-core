# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Tui do
  @moduledoc """
  Mix task to start the Aria TUI client.

  ## Usage

      mix tui

  This will start the Terminal User Interface for the Timestrike game
  with enhanced grid-based layout and responsive controls.
  """

  use Mix.Task

  @shortdoc "Start the Aria TUI client"

  def run(_args) do
    # Ensure all applications are started
    Mix.Task.run("app.start")

    # Start the TUI client
    AriaTui.start()
  end
end
