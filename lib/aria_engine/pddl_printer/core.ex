# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlPrinter.Core do
  @moduledoc """
  Core helper functions for pretty printing PDDL/HDDL structures.
  """
  # Removed alias AriaEngine.PddlParser.Core, as: PddlParserCore # To use PddlParser.Core.literal_value()

  alias AriaEngine.Pddl.Domain.Parameter

  @spec format_parameters([Parameter.t()]) :: String.t()
  def format_parameters(params) do
    Enum.map(params, fn %Parameter{name: name, type: type} ->
      "?#{to_string_if_atom(name)} - #{to_string_if_atom(type)}"
    end) |> Enum.join(" ")
  end

  @spec format_duration(integer() | {atom(), atom()} | {atom(), atom(), atom()} | nil) :: String.t()
  def format_duration(duration) do
    case duration do
      nil -> "1" # Default or placeholder
      val when is_integer(val) -> Integer.to_string(val)
      {func, arg} -> "(#{to_string_if_atom(func)} #{to_string_if_atom(arg)})"
      {func, arg1, arg2} -> "(#{to_string_if_atom(func)} #{to_string_if_atom(arg1)} #{to_string_if_atom(arg2)})"
    end
  end

  @spec format_expression(list() | nil) :: String.t()
  def format_expression(expr) do
    case expr do
      nil -> "()"
      [] -> "()"
      list ->
        "(" <> Enum.map_join(list, " ", fn
          sub_expr when is_list(sub_expr) -> format_expression(sub_expr)
          atom when is_atom(atom) -> Atom.to_string(atom)
          other -> inspect(other) # Fallback for other types
        end) <> ")"
    end
  end

  @spec format_initial_fact_item(AriaEngine.PddlParser.ProblemParser.Init.parsed_fact()) :: String.t()
  def format_initial_fact_item(fact) do
    case fact do
      {:error, msg} -> # Moved to top
        "    ; Error parsing fact: #{msg}"
      {:assign, {func_name, func_args}, value} ->
        "    (= (#{to_string_if_atom(func_name)} #{Enum.map_join(func_args, " ", &to_string_if_atom/1)}) #{inspect(value)})"
      {predicate, args} ->
        "    (#{to_string_if_atom(predicate)} #{Enum.map_join(args, " ", &to_string_if_atom/1)})"
    end
  end

  @spec format_subtasks([AriaEngine.PddlParser.ProblemParser.Htn.parsed_task_item()]) :: String.t()
  def format_subtasks(subtasks) do
    Enum.map_join(subtasks, "\n", fn {task_name, args} ->
      "      (#{to_string_if_atom(task_name)} #{Enum.map_join(args, " ", &to_string_if_atom/1)})"
    end)
  end

  @spec format_ordering([tuple()]) :: String.t()
  def format_ordering(ordering) do
    Enum.map_join(ordering, "\n", fn {order_type, args} ->
      "      (#{to_string_if_atom(order_type)} #{Enum.map_join(args, " ", &to_string_if_atom/1)})"
    end)
  end

  @spec format_constraints([tuple()]) :: String.t()
  def format_constraints(constraints) do
    Enum.map_join(constraints, "\n", fn {constraint_type, args} ->
      "      (#{to_string_if_atom(constraint_type)} #{Enum.map_join(args, " ", &to_string_if_atom/1)})"
    end)
  end

  def to_string_if_atom(val) when is_atom(val), do: Atom.to_string(val)
  def to_string_if_atom(val) when is_binary(val), do: val
  def to_string_if_atom(val), do: inspect(val) # Fallback for other types
end
