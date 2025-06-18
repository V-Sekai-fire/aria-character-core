# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Types do
  @moduledoc """
  Parses the types section of a PDDL domain string.
  """
  alias AriaEngine.Pddl.Domain.Type

  @type parsed_type :: Type.t()

  @spec parse_types(String.t()) :: [parsed_type()]
  def parse_types(types_str) do
    types_str
    |> String.split("\n", trim: true) # Split by lines
    |> Enum.map(fn line ->
      split_result = Regex.split(~r/\s+-\s+/, line, parts: 2, trim: true)
      case split_result do # Use Regex.split
        [names_str, parent_type_str] ->
          names = String.split(names_str, " ", trim: true)
          parent_type = String.to_atom(parent_type_str)
          Enum.map(names, fn name -> Type.new(String.to_atom(name), parent_type) end)
        [names_str] -> # No supertype specified, default to :object
          names = String.split(names_str, " ", trim: true)
          Enum.map(names, fn name -> Type.new(String.to_atom(name), :object) end)
        _ -> # Handle empty or unexpected lines
          []
      end
    end)
    |> List.flatten() # Flatten the list of lists of types
    |> Enum.filter(&(&1 != nil)) # Filter out nil results from map
  end
end
