# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.Core do
  @moduledoc """
  Core parsing helpers for PDDL.
  """

  alias AriaEngine.PddlParser.Core.BlockParser
  alias AriaEngine.PddlParser.Core.ExpressionParser
  alias AriaEngine.PddlParser.Core.Utils

  @type pddl_string :: String.t()
  @type block_name :: String.t()
  @type parse_result :: {:ok, String.t()} | {:error, String.t()}
  @type literal_value :: atom() | integer() | float()

  @doc """
  Parses a PDDL string to extract the content of a specific block.
  """
  @spec parse_pddl_block(pddl_string(), block_name()) :: parse_result()
  def parse_pddl_block(pddl_string, block_name) do
    BlockParser.parse_pddl_block(pddl_string, block_name)
  end

  @doc """
  Recursively finds the matching parenthesis for a given starting index.
  """
  @spec find_matching_paren(pddl_string(), integer(), integer(), integer()) :: parse_result()
  def find_matching_paren(pddl_string, current_index, balance, content_start_index) do
    BlockParser.find_matching_paren(pddl_string, current_index, balance, content_start_index)
  end

  @doc """
  Parses a PDDL string to extract the content of all occurrences of a specific block.
  """
  @spec parse_pddl_blocks(pddl_string(), block_name()) :: [String.t()]
  def parse_pddl_blocks(pddl_string, block_name) do
    BlockParser.parse_pddl_blocks(pddl_string, block_name)
  end

  @doc """
  Parses a PDDL expression string into a list representation.
  """
  @spec parse_expression(String.t()) :: list()
  def parse_expression(expr_str_original) do
    ExpressionParser.parse_expression(expr_str_original)
  end

  @doc """
  Parses a string into an atom, integer, or float based on its content.
  Handles PDDL variables (starting with '?').
  """
  @spec parse_literal(String.t()) :: literal_value()
  def parse_literal(str) do
    Utils.parse_literal(str)
  end
end
