# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Domain do
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
  domain = Domain.new("logistics")
  |> Domain.add_action(:move, &move_action/2)
  |> Domain.add_task_methods("transport", [
       {"transport", &transport_by_truck/2},
       {"transport", &transport_by_plane/2}
     ])
  ```
  """

  require Logger

  alias Domain.Actions
  alias Domain.BehaviourImpl
  alias Domain.Core
  alias Domain.Methods
  alias Domain.Utils

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
  @type state :: AriaEngine.StateV2.t()

  @spec new(String.t()) :: t()
  defdelegate new(name), to: Core
  
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

  @spec verify_goal(state(), method_name(), term(), list(), list(), integer(), boolean()) :: boolean()
  defdelegate verify_goal(state, method_name, state_var, args, desired_values, depth, verbose),
    to: Utils

  @spec summary(t()) :: String.t()
  defdelegate summary(domain), to: Utils
  
  @spec add_porcelain_actions(t()) :: t()
  defdelegate add_porcelain_actions(domain), to: Utils
  
  @spec create_complete_domain(String.t()) :: t()
  defdelegate create_complete_domain(name \\ "complete"), to: Utils
  
  @spec infer_method_name(function()) :: String.t()
  defdelegate infer_method_name(fun), to: Utils

  # Behaviour callbacks
  @spec actions(t()) :: %{action_name() => action_fn()}
  defdelegate actions(domain), to: BehaviourImpl
  
  @spec task_methods(t()) :: %{task_name() => [named_method()]}
  defdelegate task_methods(domain), to: BehaviourImpl
  
  @spec unigoal_methods(t()) :: %{String.t() => [named_method()]}
  defdelegate unigoal_methods(domain), to: BehaviourImpl
  
  @spec multigoal_methods(t()) :: [named_method()]
  defdelegate multigoal_methods(domain), to: BehaviourImpl
  
  @spec durative_actions(t()) :: %{durative_action_name() => durative_action()}
  defdelegate durative_actions(domain), to: BehaviourImpl

  @spec get_durative_action(t(), durative_action_name()) :: durative_action() | nil
  defdelegate get_durative_action(domain, name), to: Core
end
