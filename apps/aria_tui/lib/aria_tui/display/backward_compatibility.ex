# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Display.BackwardCompatibility do
  @moduledoc """
  Backward compatibility layer for tests that expect functions 
  to be directly available from the Grid module.
  """

  alias AriaTui.Display.Renderer

  @doc """
  Draw single column content from Grid module (backward compatibility).
  """
  def draw_single_column_content(state, layout) do
    Renderer.draw_single_column_content(state, layout)
  end

  @doc """
  Draw two column content from Grid module (backward compatibility).
  """
  def draw_two_column_content(state, layout) do
    Renderer.draw_two_column_content(state, layout)
  end

  @doc """
  Draw side by side panels from Grid module (backward compatibility).
  """
  def draw_side_by_side_panels(left_content, right_content, left_width, right_width, height) do
    Renderer.draw_side_by_side_panels(left_content, right_content, left_width, right_width, height)
  end
end
