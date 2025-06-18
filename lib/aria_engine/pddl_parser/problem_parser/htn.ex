# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.ProblemParser.Htn do
  @moduledoc """
  Parses the HTN section of a PDDL problem string.
  """
  alias AriaEngine.Pddl.Problem.Goal.Task
  alias AriaEngine.Pddl.Domain.Parameter # For parsing parameters within tasks
  alias AriaEngine.PddlParser.Core

  @type parsed_task_item :: Task.t()

  @spec parse_htn_subtasks(String.t()) :: [parsed_task_item()]
  def parse_htn_subtasks(htn_content) do
    case Core.parse_pddl_block(htn_content, ":subtasks") do
      {:ok, subtasks_and_content} ->
        # subtasks_and_content will be like "and (task0 ...) (task1 ...)"
        # We need to trim "and " and then split by top-level parentheses
        subtasks_str = String.trim_leading(subtasks_and_content, "and ")
        subtasks_str
        |> String.split(~r/\)\s*\(/, trim: true)
        |> Enum.map(fn task_str ->
          task_str = String.trim(task_str, "()")
          parts = String.split(task_str, " ", trim: true)
          parse_task(parts)
        end)
      _ ->
        [] # No subtasks found or malformed
    end
  end

  @spec parse_task([String.t()]) :: parsed_task_item()
  defp parse_task([task_name | args]) do
    # Assuming tasks are simple (task_name arg1 arg2 ...)
    # Convert args to Parameter structs, defaulting to :object type
    parameters = Enum.map(args, fn arg_name ->
      Parameter.new(String.to_atom(arg_name), :object)
    end)
    Task.new(String.to_atom(task_name), parameters)
  end
end
