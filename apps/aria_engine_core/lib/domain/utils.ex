# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain.Utils do
  @moduledoc "Domain utilities and helper functions.\n"
  @type t :: AriaEngine.Domain.Core.t()
  @type action_name :: atom()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type goal_method_fn :: (AriaEngine.State.t(), list() -> list() | false)
  @doc "Validates that a goal is satisfied in the given state.\n\nThis is used for goal verification during planning.\n"
  @spec verify_goal(
          AriaEngine.State.t(),
          String.t(),
          String.t(),
          list(),
          AriaEngine.State.fact_value(),
          integer(),
          integer()
        ) :: AriaEngine.State.fact_value() | false
  def verify_goal(
        %AriaEngine.State{} = state,
        _method_name,
        state_var,
        args,
        desired_values,
        _depth,
        _verbose
      ) do
    case AriaEngine.State.get_fact(state, List.first(args) || "", state_var) do
      ^desired_values -> desired_values
      _ -> false
    end
  end

  @doc "Gets a summary of the domain contents.\n"
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

  @doc "Adds Porcelain-based actions to the domain.\n\nThis convenience method adds all the external process actions from Actions.\n"
  @spec add_porcelain_actions(t()) :: t()
  def add_porcelain_actions(%{} = domain) do
    porcelain_actions = %{
      execute_command: &AriaEngine.Actions.execute_command/2,
      copy_file: &AriaEngine.Actions.copy_file/2,
      move_file: &AriaEngine.Actions.move_file/2,
      create_directory: &AriaEngine.Actions.create_directory/2,
      remove_path: &AriaEngine.Actions.remove_path/2,
      download_file: &AriaEngine.Actions.download_file/2,
      change_permissions: &AriaEngine.Actions.change_permissions/2
    }

    AriaEngine.Domain.Actions.add_actions(domain, porcelain_actions)
  end

  @doc "Creates a complete domain with all Porcelain-based actions and methods.\n\nThis is a convenience method for creating a fully-featured domain with basic actions.\nDomain-specific methods should be added by the respective domain modules.\n"
  @spec create_complete_domain(String.t()) :: t()
  def create_complete_domain(name \\ "complete") do
    AriaEngine.Domain.Core.new(name) |> add_porcelain_actions()
  end

  @doc "Infers a method name from a function reference for tuple-based method storage.\n"
  @spec infer_method_name(function()) :: String.t()
  def infer_method_name(fun) when is_function(fun, 2) do
    fun_string = inspect(fun)

    case Regex.run(~r/&([^\/]+)\/\d+/, fun_string) do
      [_, name] ->
        case String.split(name, ".") do
          [single_name] -> single_name
          parts -> List.last(parts)
        end

      _ ->
        "method_#{:erlang.phash2(fun)}"
    end
  end

  def infer_method_name(fun) when is_function(fun) do
    fun_string = inspect(fun)

    case Regex.run(~r/&([^\/]+)\/\d+/, fun_string) do
      [_, name] ->
        case String.split(name, ".") do
          [single_name] -> single_name
          parts -> List.last(parts)
        end

      _ ->
        "method_#{:erlang.phash2(fun)}"
    end
  end
end
