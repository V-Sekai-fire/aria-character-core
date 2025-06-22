# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain.Utils do
  @moduledoc """
  Domain utilities and helper functions.
  """
  alias Actions

  @type t :: AriaEngine.Domain.Core.t()
  @type action_name :: atom()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type goal_method_fn :: (State.t(), list() -> list() | false)

  @doc """
  Validates that a goal is satisfied in the given state.

  This is used for goal verification during planning.
  """
  @spec verify_goal(
          State.t(),
          String.t(),
          String.t(),
          list(),
          State.fact_value(),
          integer(),
          integer()
        ) :: State.fact_value() | false
  def verify_goal(
        %State{} = state,
        _method_name,
        state_var,
        args,
        desired_values,
        _depth,
        _verbose
      ) do
    # This is a placeholder for goal verification logic
    # In the original C++ code, this would check if a goal is satisfied
    case State.get_fact(state, List.first(args) || "", state_var) do
      ^desired_values -> desired_values
      _ -> false
    end
  end

  @doc """
  Gets a summary of the domain contents.
  """
  @spec summary(t()) :: %{
          name: String.t(),
          actions: [action_name()],
          task_methods: [task_name()],
          unigoal_methods: [String.t()],
          multigoal_method_count: non_neg_integer()
        }
  def summary(%{} = domain) do
    %{
      name: domain.name,
      actions: Map.keys(domain.actions),
      task_methods: Map.keys(domain.task_methods),
      unigoal_methods: Map.keys(domain.unigoal_methods),
      multigoal_method_count: length(domain.multigoal_methods)
    }
  end

  # Private helper to infer method name from function reference
  @doc """
  Infers a method name from a function reference for tuple-based method storage.
  """
  @spec infer_method_name(function()) :: String.t()
  def infer_method_name(fun) when is_function(fun, 2) do
    # Convert function to string and extract name
    fun_string = inspect(fun)

    case Regex.run(~r/&([^\/]+)\/\d+/, fun_string) do
      [_, name] ->
        # Remove module prefix if present (e.g., "Module.function" -> "function")
        case String.split(name, ".") do
          [single_name] -> single_name
          parts -> List.last(parts)
        end

      _ ->
        # Fallback for anonymous functions or complex cases
        "method_#{:erlang.phash2(fun)}"
    end
  end

  def infer_method_name(fun) when is_function(fun) do
    # Convert function to string and extract name
    fun_string = inspect(fun)

    case Regex.run(~r/&([^\/]+)\/\d+/, fun_string) do
      [_, name] ->
        # Remove module prefix if present (e.g., "Module.function" -> "function")
        case String.split(name, ".") do
          [single_name] -> single_name
          parts -> List.last(parts)
        end

      _ ->
        # Fallback for anonymous functions or complex cases
        "method_#{:erlang.phash2(fun)}"
    end
  end
end
