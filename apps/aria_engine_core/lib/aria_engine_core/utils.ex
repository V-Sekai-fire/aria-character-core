# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Utils do
  @moduledoc """
  Mock implementation of AriaEngineCore.Utils for compilation.

  This module provides utility functions for AriaEngineCore.
  Currently mocked with basic functionality to enable compilation.
  """

  @doc """
  Normalize duration to a standard format.
  """
  @spec normalize_duration(term()) :: number()
  def normalize_duration(duration) when is_number(duration) do
    duration
  end

  def normalize_duration(duration) when is_binary(duration) do
    # Try to parse string as number
    case Float.parse(duration) do
      {value, _} -> value
      :error -> 1.0  # Default duration
    end
  end

  def normalize_duration(_), do: 1.0  # Default duration
end
