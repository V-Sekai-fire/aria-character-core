# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Methods.Subtasks do
  @moduledoc """
  Parses the subtasks of a method.
  """
  alias AriaEngine.Pddl.Domain.Task
  alias AriaEngine.Pddl.Domain.Parameter # Assuming parameters are parsed here

  @type parsed_subtask :: Task.t()

  @spec parse_method_subtasks(String.t()) :: [parsed_subtask()]
  def parse_method_subtasks(content) do
    subtasks_regex = ~r/:subtasks\s+\(and\s+([\s\S]+?)\)/
    case Regex.run(subtasks_regex, content) do
      [_, subtasks_str] ->
        subtasks_str
        |> String.split(~r/\)\s*\(/, trim: true)
        |> Enum.map(fn task_str ->
          task_str = String.trim(task_str, "()")
          parts = String.split(task_str, " ", trim: true)
          name = List.first(parts)
          parameters = Enum.map(List.delete_at(parts, 0), fn param_name ->
            Parameter.new(String.to_atom(param_name), :object) # Default to :object type
          end)
          Task.new(String.to_atom(name), parameters)
        end)
      _ -> []
    end
  end
end
