# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain.Utils do
  @moduledoc """
  Provides utility functions for the planning domain.
  """

  alias AriaEngine.StateV2
  alias AriaEngine.Actions

  @type t :: AriaEngine.Domain.Core.t()
  @type action_name :: atom()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type goal_method_fn :: (StateV2.t(), list() -> list() | false)

  @doc """
  Validates that a goal is satisfied in the given state.

  This is used for goal verification during planning.
  """
  @spec verify_goal(StateV2.t(), String.t(), String.t(), list(), StateV2.fact_value(), integer(), integer()) :: StateV2.fact_value() | false
  def verify_goal(%StateV2{} = state, _method_name, state_var, args, desired_values, _depth, _verbose) do
    # This is a placeholder for goal verification logic
    # In the original C++ code, this would check if a goal is satisfied
    case StateV2.get_fact(state, List.first(args) || "", state_var) do
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

  @doc  """
  Adds Porcelain-based actions to the domain.

  This convenience method adds all the external process actions from AriaEngine.Actions.
  """
  @spec add_porcelain_actions(t()) :: t()
  def add_porcelain_actions(%{} = domain) do
    porcelain_actions = %{
      execute_command: &Actions.execute_command/2,
      copy_file: &Actions.copy_file/2,
      move_file: &Actions.move_file/2,
      create_directory: &Actions.create_directory/2,
      remove_path: &Actions.remove_path/2,
      download_file: &Actions.download_file/2,
      change_permissions: &Actions.change_permissions/2
    }

    AriaEngine.Domain.Actions.add_actions(domain, porcelain_actions)
  end

  @doc """
  Creates a complete domain with all Porcelain-based actions and methods.

  This is a convenience method for creating a fully-featured domain with basic actions.
  Domain-specific methods should be added by the respective domain modules.
  """
  @spec create_complete_domain(String.t()) :: t()
  def create_complete_domain(name \\ "complete") do
    AriaEngine.Domain.Core.new(name)
    |> add_porcelain_actions()
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
