# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Methods.Constraints do
  @moduledoc """
  Parses the constraints of a method.
  """

  @type parsed_constraint :: {atom(), [atom()]}

  @spec parse_method_constraints(String.t()) :: [parsed_constraint()]
  def parse_method_constraints(content) do
    constraints_regex = ~r/:constraints\s+\(and\s+([\s\S]+?)\)/
    case Regex.run(constraints_regex, content) do
      [_, constraints_str] ->
        constraints_str
        |> String.split(~r/\)\s*\(/, trim: true)
        |> Enum.map(fn constraint_str ->
          constraint_str = String.trim(constraint_str, "()")
          [head | tail] = String.split(constraint_str, " ", trim: true)
          {String.to_atom(head), Enum.map(tail, &String.to_atom/1)}
        end)
      _ -> []
    end
  end
end
