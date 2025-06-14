# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.ContentProvider do
  @moduledoc """
  Behaviour for providing content to the TUI display system.

  Implementations of this behaviour can provide game-specific or domain-specific
  content formatting for the TUI renderer while keeping the core TUI system
  generic and reusable.
  """

  @doc """
  Generate main content lines for single-column display.

  ## Parameters
  - `state`: The current game/application state
  - `width`: Available content width in characters
  - `height`: Available content height in lines

  ## Returns
  A list of strings representing the content lines to display.
  """
  @callback get_main_content(state :: map(), width :: integer(), height :: integer()) :: [String.t()]

  @doc """
  Generate left panel content for multi-column display.

  ## Parameters
  - `state`: The current game/application state
  - `width`: Available panel width in characters
  - `height`: Available panel height in lines

  ## Returns
  A list of strings representing the left panel content.
  """
  @callback get_left_panel_content(state :: map(), width :: integer(), height :: integer()) :: [String.t()]

  @doc """
  Generate right panel content for multi-column display.

  ## Parameters
  - `state`: The current game/application state
  - `width`: Available panel width in characters
  - `height`: Available panel height in lines

  ## Returns
  A list of strings representing the right panel content.
  """
  @callback get_right_panel_content(state :: map(), width :: integer(), height :: integer()) :: [String.t()]

  @doc """
  Generate header content for the display.

  ## Parameters
  - `state`: The current game/application state
  - `layout`: The current layout configuration

  ## Returns
  A list of strings representing the header content.
  """
  @callback get_header_content(state :: map(), layout :: map()) :: [String.t()]

  @doc """
  Generate footer/controls content for the display.

  ## Parameters
  - `state`: The current game/application state
  - `layout`: The current layout configuration

  ## Returns
  A list of strings representing the footer/controls content.
  """
  @callback get_footer_content(state :: map(), layout :: map()) :: [String.t()]

  @optional_callbacks [get_header_content: 2, get_footer_content: 2]
end
