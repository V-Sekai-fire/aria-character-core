# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Display.Colors do
  @moduledoc """
  Color definitions and utilities for the Aria TUI system.
  """

  # ANSI color constants
  @colors %{
    reset: "\e[0m",
    bright_cyan: "\e[96m",
    bright_white: "\e[97m",
    cyan: "\e[36m",
    bright_green: "\e[92m",
    bright_red: "\e[91m",
    bright_yellow: "\e[93m",
    green: "\e[32m",
    red: "\e[31m",
    yellow: "\e[33m",
    gray: "\e[37m",
    white: "\e[37m",
    bright_blue: "\e[94m"
  }

  @doc """
  Get all available colors.
  """
  def colors, do: @colors

  @doc """
  Get a specific color by key.
  """
  def get(color_key) when is_atom(color_key) do
    Map.get(@colors, color_key, "")
  end

  @doc """
  Apply color to text.
  """
  def colorize(text, color_key) when is_atom(color_key) do
    color = get(color_key)
    reset = get(:reset)
    "#{color}#{text}#{reset}"
  end

  @doc """
  Count ANSI escape sequences in a string for accurate length calculation.
  """
  def count_ansi_chars(string) do
    # Count ANSI escape sequences
    ansi_regex = ~r/\e\[[0-9;]*m/
    matches = Regex.scan(ansi_regex, string)
    matches
    |> Enum.reduce(0, fn [match], acc -> acc + String.length(match) end)
  end

  @doc """
  Calculate the visual length of a string (excluding ANSI codes).
  """
  def visual_length(string) do
    String.length(string) - count_ansi_chars(string)
  end
end
