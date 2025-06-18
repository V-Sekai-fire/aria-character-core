# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.Core.ExpressionParser do
  @moduledoc """
  Functions for parsing PDDL expressions.
  """
  alias AriaEngine.PddlParser.Core.Utils

  @type pddl_string :: String.t()
  @type literal_value :: atom() | integer() | float()

  @doc """
  Parses a PDDL expression string into a list representation.
  """
  @spec parse_expression(String.t()) :: list()
  def parse_expression(expr_str_original) do
    # This is a highly simplified parser for PDDL expressions.
    # It attempts to parse nested parentheses and convert atoms/numbers.
    # It does NOT handle full PDDL syntax (e.g., quantifiers, complex fluents).

    # Remove outer parentheses if present
    expr_str = if String.starts_with?(expr_str_original, "(") and String.ends_with?(expr_str_original, ")") do
      String.trim(expr_str_original, "()")
    else
      expr_str_original
    end

    # Split by top-level parentheses or spaces
    # This is a very naive split and will likely fail on complex nested structures
    parts = Regex.split(~r/\s+(?![^()]*\))/, expr_str) |> Enum.filter(&(&1 != ""))

    parse_parts(parts)
  end

  @spec parse_parts([String.t()]) :: list()
  defp parse_parts(parts) do
    case parts do
      [] -> []
      [head | tail] ->
        if String.starts_with?(head, "(") do
          # This is a nested expression
          {parsed_expr, remaining_tail} = parse_nested_expression([head | tail])
          [parsed_expr | parse_parts(remaining_tail)]
        else
          # This is an atom or a literal
          [Utils.parse_literal(head) | parse_parts(tail)]
        end
    end
  end

  @spec parse_nested_expression([String.t()]) :: {list(), [String.t()]}
  defp parse_nested_expression(parts) do
    # This is a very simplified approach to parsing nested expressions.
    # It assumes well-formed parentheses and will likely break on malformed PDDL.
    buffer = []
    open_count = 0
    _parsed_parts_unused = [] # Mark as used
    remaining_parts = parts

    for part <- parts do
      open_count = open_count + String.length(String.replace(part, ~r/[^()]/, ""))
      buffer = buffer ++ [part]
      if open_count == 0 do
        parsed_expr_str = Enum.join(buffer, " ")
        parsed_expr = parse_list_expression(parsed_expr_str)
        remaining_parts = Enum.drop(remaining_parts, length(buffer))
        {parsed_expr, remaining_parts} # Implicit return
      end
    end
    {nil, []} # Should not reach here if PDDL is well-formed
  end

  @spec parse_list_expression(String.t()) :: list()
  defp parse_list_expression(list_str) do
    list_str = String.trim(list_str, "()")
    parts = Regex.split(~r/\s+(?![^()]*\))/, list_str) |> Enum.filter(&(&1 != ""))
    Enum.map(parts, &Utils.parse_literal/1)
  end
end
