# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Methods.Ordering do
  @moduledoc """
  Parses the ordering of a method.
  """

  @type parsed_ordering :: {atom(), [atom()]}

  @spec parse_method_ordering(String.t()) :: [parsed_ordering()]
  def parse_method_ordering(content) do
    ordering_regex = ~r/:ordering\s+\(and\s+([\s\S]+?)\)/
    case Regex.run(ordering_regex, content) do
      [_, ordering_str] ->
        ordering_str
        |> String.split(~r/\)\s*\(/, trim: true)
        |> Enum.map(fn order_str ->
          order_str = String.trim(order_str, "()")
          [head | tail] = String.split(order_str, " ", trim: true)
          {String.to_atom(head), Enum.map(tail, &String.to_atom/1)}
        end)
      _ -> []
    end
  end
end
