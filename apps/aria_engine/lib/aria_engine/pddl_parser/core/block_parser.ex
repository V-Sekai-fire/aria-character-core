# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.Core.BlockParser do
  @moduledoc """
  Functions for parsing top-level PDDL blocks.
  """

  @type pddl_string :: String.t()
  @type block_name :: String.t()
  @type parse_result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Parses a PDDL string to extract the content of a specific block.
  """
  @spec parse_pddl_block(pddl_string(), block_name()) :: parse_result()
  def parse_pddl_block(pddl_string, block_name) do
    search_term = "(#{block_name}"
    case String.split(pddl_string, search_term, parts: 2) do
      [before, _after] ->
        start_index = String.length(before)
        content_start_index = start_index + String.length(search_term)
        find_matching_paren(pddl_string, content_start_index, 0, content_start_index)
      _ -> # No match, or empty string
        {:error, "Block '#{block_name}' not found."}
    end
  end

  @doc """
  Recursively finds the matching parenthesis for a given starting index.
  """
  @spec find_matching_paren(pddl_string(), integer(), integer(), integer()) :: parse_result()
  def find_matching_paren(pddl_string, current_index, balance, content_start_index) do
    if current_index >= String.length(pddl_string) do
      {:error, "Mismatched parentheses."}
    else
      char = String.at(pddl_string, current_index)
      new_balance = case char do
        "(" -> balance + 1
        ")" -> balance - 1
        _ -> balance
      end

      if new_balance < 0 do # Found the matching closing parenthesis
        content = String.slice(pddl_string, content_start_index, current_index - content_start_index)
        {:ok, String.trim(content)}
      else
        find_matching_paren(pddl_string, current_index + 1, new_balance, content_start_index)
      end
    end
  end

  @doc """
  Parses a PDDL string to extract the content of all occurrences of a specific block.
  """
  @spec parse_pddl_blocks(pddl_string(), block_name()) :: [String.t()]
  def parse_pddl_blocks(pddl_string, block_name) do
    do_parse_pddl_blocks(pddl_string, block_name, [])
  end

  @spec do_parse_pddl_blocks(pddl_string(), block_name(), [String.t()]) :: [String.t()]
  defp do_parse_pddl_blocks(pddl_string, block_name, acc) do
    search_term = "(#{block_name}"
    case String.split(pddl_string, search_term, parts: 2) do
      [before, _after] ->
        start_index = String.length(before)
        content_start_index = start_index + String.length(search_term)
        case find_matching_paren(pddl_string, content_start_index, 0, content_start_index) do
          {:ok, content} ->
            # Calculate the end of the current block to slice the remaining string
            # +1 for the closing parenthesis of the block itself
            block_end_index = content_start_index + String.length(content) + 1
            remaining_string = if block_end_index >= String.length(pddl_string) do
              ""
            else
              String.slice(pddl_string, block_end_index..-1//1)
            end
            do_parse_pddl_blocks(remaining_string, block_name, [content | acc])
          _ ->
            # If a block is found but parsing fails, return what we have so far
            Enum.reverse(acc)
        end
      _ ->
        Enum.reverse(acc)
    end
  end
end
