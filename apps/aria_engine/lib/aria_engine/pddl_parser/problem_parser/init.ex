# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.ProblemParser.Init do
  @moduledoc """
  Parses the init section of a PDDL problem string.
  """
  alias AriaEngine.Pddl.Problem.InitFact
  alias AriaEngine.Pddl.Problem.InitFact.{Predicate, Function}
  alias AriaEngine.PddlParser.Core

  @type parsed_fact :: InitFact.t() | {:error, String.t()}

  @spec parse_init(String.t()) :: [parsed_fact()]
  def parse_init(init_str) do
    # This split is still problematic for nested, but let's assume it gives us top-level facts for now
    init_str
    |> String.split(~r/\)\s*\(/, trim: true)
    |> Enum.map(fn fact_content_raw ->
      fact_content = String.trim(fact_content_raw, "()") # Remove outer parentheses

      # Check if it's an assignment fact
      if String.starts_with?(fact_content, "= ") do
        # Expected format: "= (func_name args) value"
        # Find the start of the function call: after "= "
        func_call_start_index = String.length("= ")

        # Find the end of the function call using find_matching_paren
        case Core.find_matching_paren(fact_content, func_call_start_index + 1, 0, func_call_start_index + 1) do # Corrected call
          {:ok, func_call_inner_content} ->
            # func_call_inner_content is "func_name args"
            # The full function call string is "(func_call_inner_content)"
            # The value starts after the closing parenthesis of the function call and a space
            value_start_index = func_call_start_index + String.length(func_call_inner_content) + 3 # +3 for '() '

            value_str = String.trim(String.slice(fact_content, value_start_index..-1//1)) # Added //1

            func_parts = String.split(func_call_inner_content, " ", trim: true)
            func_name = String.to_atom(List.first(func_parts))
            func_args = Enum.map(tl(func_parts), &String.to_atom/1)
            value = Core.parse_literal(value_str)
            Function.new(func_name, func_args, value)
          _ ->
            # Fallback for malformed assignment
            {:error, "Malformed assignment fact: #{fact_content}"}
        end
      else
        # Simple predicate-argument parsing.
        parts = String.split(fact_content, " ", trim: true)
        predicate = List.first(parts)
        args = tl(parts)
        Predicate.new(String.to_atom(predicate), Enum.map(args, &String.to_atom/1))
      end
    end)
  end
end
