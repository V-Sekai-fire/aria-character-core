# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain do
  @moduledoc """
  Represents a planning domain in the GTPhop planner (Elixir port of GTPyhop).

  A domain contains:
  - Actions: Named functions that modify the world state
  - Task methods: Named functions that decompose tasks into subtasks
  - Unigoal methods: Named functions that achieve single goals
  - Multigoal methods: Named functions that achieve multiple goals simultaneously

  This implementation aligns with GTPyhop's approach where:
  - Actions are stored as name -> function mappings
  - Methods are stored as task_name -> list of {name, function} tuples
  - Method names are preserved for logging, blacklisting, and error reporting

  Example:
  ```elixir
  domain = AriaEngine.Domain.new("logistics")
  |> AriaEngine.Domain.add_action(:move, &move_action/2)
  |> AriaEngine.Domain.add_task_methods("transport", [
       {"transport", &transport_by_truck/2},
       {"transport", &transport_by_plane/2}
     ])
  ```
  """

  require Logger

  alias AriaEngine.Domain.Actions
  alias AriaEngine.Domain.Core
  alias AriaEngine.Domain.Methods
  alias AriaEngine.Domain.Utils

  @type t :: Core.t()
  @type action_name :: Core.action_name()
  @type task_name :: Core.task_name()
  @type method_name :: Core.method_name()
  @type action_fn :: Core.action_fn()
  @type task_method_fn :: Core.task_method_fn()
  @type goal_method_fn :: Core.goal_method_fn()
  @type named_method :: Core.named_method()
  @type durative_action_name :: Core.durative_action_name()
  @type durative_action :: Core.durative_action()
  @type state :: State.t()

  @spec new(String.t()) :: t()
  def new(name) do
    Core.new(name)
  end

  @spec from_module(module()) :: t()
  def from_module(domain_module) do
    # Use the domain module's build/0 function if it exists
    if function_exported?(domain_module, :build, 0) do
      domain_module.build()
    else
      # Fallback to the old method for backward compatibility
      domain_name = domain_module |> Module.split() |> List.last() |> String.downcase()
      Logger.error("Creating domain: #{domain_name}")
      domain = Core.new(domain_name)

      actions = domain_module.actions()
      methods = domain_module.methods()

      Logger.error("Actions: #{inspect(actions)}")
      Logger.error("Methods: #{inspect(methods)}")

      domain =
        Enum.reduce(actions, domain, fn action_name, domain ->
          Logger.error("Adding action: #{action_name}")

          add_action(domain, action_name, fn state, args ->
            apply(domain_module, action_name, [state | args])
          end)
        end)

      Enum.reduce(methods, domain, fn method_name, domain ->
        Logger.error("Adding method: #{method_name}")

        cond do
          String.starts_with?(method_name, "solve_multigoal") ->
            Logger.error("Adding multigoal method: #{method_name}")

            add_multigoal_method(domain, method_name, fn state, args ->
              apply(domain_module, :solve_multigoal, [state | args])
            end)

          String.starts_with?(method_name, "achieve_goal") ->
            Logger.error("Adding unigoal method: #{method_name}")

            add_unigoal_method(domain, "status", method_name, fn state, args ->
              apply(domain_module, :achieve_goal, [state | args])
            end)

          true ->
            Logger.error("Adding task method: #{method_name}")

            add_task_method(domain, method_name, method_name, fn state, args ->
              apply(domain_module, String.to_atom(method_name), [state | args])
            end)
        end
      end)
    end
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  defdelegate validate(domain), to: Core

  @spec add_action(t(), action_name(), action_fn(), map()) :: t()
  defdelegate add_action(domain, name, action_fn, metadata \\ %{}), to: Actions

  @spec add_actions(t(), map()) :: t()
  defdelegate add_actions(domain, new_actions), to: Actions

  @spec get_action(t(), action_name()) :: action_fn() | nil
  defdelegate get_action(domain, name), to: Actions

  @spec get_action_metadata(t(), action_name()) :: map() | nil
  defdelegate get_action_metadata(domain, name), to: Actions

  @spec has_action?(t(), action_name()) :: boolean()
  defdelegate has_action?(domain, name), to: Actions

  @spec execute_action(t(), state(), action_name(), list()) :: state() | false
  defdelegate execute_action(domain, state, action_name, args), to: Actions

  @spec add_task_method(t(), task_name(), method_name(), task_method_fn()) :: t()
  defdelegate add_task_method(domain, task_name, method_name, method_fn), to: Methods

  @spec add_task_method(t(), task_name(), task_method_fn()) :: t()
  defdelegate add_task_method(domain, task_name, method_fn), to: Methods

  @spec add_task_methods(t(), task_name(), list()) :: t()
  defdelegate add_task_methods(domain, task_name, method_tuples_or_functions), to: Methods

  @spec add_unigoal_method(t(), String.t(), method_name(), goal_method_fn()) :: t()
  defdelegate add_unigoal_method(domain, goal_type, method_name, method_fn), to: Methods

  @spec add_unigoal_method(t(), String.t(), goal_method_fn()) :: t()
  defdelegate add_unigoal_method(domain, goal_type, method_fn), to: Methods

  @spec add_unigoal_methods(t(), String.t(), [named_method()]) :: t()
  defdelegate add_unigoal_methods(domain, goal_type, method_tuples), to: Methods

  @spec add_multigoal_method(t(), method_name(), goal_method_fn()) :: t()
  defdelegate add_multigoal_method(domain, method_name, method_fn), to: Methods

  @spec add_multigoal_method(t(), goal_method_fn()) :: t()
  defdelegate add_multigoal_method(domain, method_fn), to: Methods

  @spec get_task_methods(t(), task_name()) :: [named_method()]
  defdelegate get_task_methods(domain, task_name), to: Methods

  @spec get_unigoal_methods(t(), String.t()) :: [named_method()]
  defdelegate get_unigoal_methods(domain, goal_type), to: Methods

  @spec get_multigoal_methods(t()) :: [named_method()]
  defdelegate get_multigoal_methods(domain), to: Methods

  @spec get_goal_methods(t(), String.t()) :: [named_method()]
  defdelegate get_goal_methods(domain, predicate), to: Methods

  @spec get_method(t(), method_name()) :: {task_method_fn() | goal_method_fn()} | nil
  defdelegate get_method(domain, method_name), to: Methods

  @spec has_task_methods?(t(), task_name()) :: boolean()
  defdelegate has_task_methods?(domain, task_name), to: Methods

  @spec has_unigoal_methods?(t(), String.t()) :: boolean()
  defdelegate has_unigoal_methods?(domain, goal_type), to: Methods

  @doc """
  Resolves an action or task method name with strict separation.

  GTpyHOP Design Principles:
  - Action atoms (e.g., :move) resolve ONLY to {:action, action_fn}
  - Task method strings (e.g., "move") resolve ONLY to {:task_method, method_fn}
  - NO automatic conversion between actions and tasks

  This implements strict action/task separation from ADR-144.
  """
  @spec resolve(atom() | String.t(), t()) ::
          {:action, action_fn()} | {:task_method, task_method_fn()} | nil
  def resolve(name, domain) when is_atom(name) do
    # Actions only: Check for action atoms, no fallback to tasks
    case get_action(domain, name) do
      nil -> nil
      action_fn -> {:action, action_fn}
    end
  end

  def resolve(name, domain) when is_binary(name) do
    # Tasks only: Check for task methods, no fallback to actions
    case get_task_methods(domain, name) do
      [] -> nil
      [method | _] -> {:task_method, elem(method, 1)}
    end
  end

  @spec verify_goal(state(), method_name(), term(), list(), list(), integer(), boolean()) ::
          boolean()
  defdelegate verify_goal(state, method_name, state_var, args, desired_values, depth, verbose),
    to: Utils

  @spec summary(t()) :: String.t()
  defdelegate summary(domain), to: Utils

  @spec infer_method_name(function()) :: String.t()
  defdelegate infer_method_name(fun), to: Utils

  # Behaviour callbacks
  @spec actions(t()) :: %{action_name() => action_fn()}
  def actions(%Core{actions: actions}), do: actions

  @spec task_methods(t()) :: %{task_name() => [named_method()]}
  def task_methods(%Core{task_methods: task_methods}), do: task_methods

  @spec unigoal_methods(t()) :: %{String.t() => [named_method()]}
  def unigoal_methods(%Core{unigoal_methods: unigoal_methods}), do: unigoal_methods

  @spec multigoal_methods(t()) :: [named_method()]
  def multigoal_methods(%Core{multigoal_methods: multigoal_methods}), do: multigoal_methods

  @spec durative_actions(t()) :: %{durative_action_name() => durative_action()}
  def durative_actions(%Core{durative_actions: durative_actions}), do: durative_actions

  @spec get_durative_action(t(), durative_action_name()) :: durative_action() | nil
  defdelegate get_durative_action(domain, name), to: Core
end
