# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Methods.Task do
  @moduledoc """
  Parses the task of a method.
  """
  alias AriaEngine.Pddl.Domain.Task
  alias AriaEngine.Pddl.Domain.Parameter # Assuming parameters are parsed here

  @type parsed_method_task :: Task.t() | nil

  @spec parse_method_task(String.t()) :: parsed_method_task()
  def parse_method_task(content) do
    task_regex = ~r/:task\s+\(([\s\S]+?)\)/
    case Regex.run(task_regex, content) do
      [_, task_str] ->
        task_str = String.trim(task_str, "()")
        parts = String.split(task_str, " ", trim: true)
        name = List.first(parts)
        parameters = Enum.map(List.delete_at(parts, 0), fn param_name ->
          # Assuming parameters are just names for now, not typed
          Parameter.new(String.to_atom(param_name), :object) # Default to :object type
        end)
        Task.new(String.to_atom(name), parameters)
      _ -> nil
    end
  end
end
