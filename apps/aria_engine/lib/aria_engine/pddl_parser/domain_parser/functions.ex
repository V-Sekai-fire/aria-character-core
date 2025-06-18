# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Functions do
  @moduledoc """
  Parses the functions section of a PDDL domain string.
  """

  @type parsed_function :: {atom(), [atom()]}

  @spec parse_functions(String.t()) :: [parsed_function()]
  def parse_functions(funs_str) do
    # Regex to find all ( ... ) blocks
    Regex.scan(~r/\(([^()]*?)\)/, funs_str, capture: :all_but_first)
    |> Enum.map(fn [fun_content] ->
      # fun_content is "fuel ?r - rocket"
      parts = String.split(fun_content, " ", trim: true)
      [head | tail] = parts
      {String.to_atom(head), Enum.map(tail, &String.to_atom/1)}
    end)
  end
end
