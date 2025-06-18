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

  alias Domain.Core
  alias Domain.Actions
  alias Domain.Methods
  alias Domain.Utils
  alias Domain.BehaviourImpl

  @type t :: Core.t()

  defdelegate new(name), to: Core
  defdelegate validate(domain), to: Core

  defdelegate add_action(domain, name, action_fn, metadata \\ %{}), to: Actions
  defdelegate add_actions(domain, new_actions), to: Actions
  defdelegate get_action(domain, name), to: Actions
  defdelegate get_action_metadata(domain, name), to: Actions
  defdelegate has_action?(domain, name), to: Actions
  defdelegate execute_action(domain, state, action_name, args), to: Actions

  defdelegate add_task_method(domain, task_name, method_name, method_fn), to: Methods
  defdelegate add_task_method(domain, task_name, method_fn), to: Methods
  defdelegate add_task_methods(domain, task_name, method_tuples_or_functions), to: Methods
  defdelegate add_unigoal_method(domain, goal_type, method_name, method_fn), to: Methods
  defdelegate add_unigoal_method(domain, goal_type, method_fn), to: Methods
  defdelegate add_unigoal_methods(domain, goal_type, method_tuples), to: Methods
  defdelegate add_multigoal_method(domain, method_name, method_fn), to: Methods
  defdelegate add_multigoal_method(domain, method_fn), to: Methods
  defdelegate get_task_methods(domain, task_name), to: Methods
  defdelegate get_unigoal_methods(domain, goal_type), to: Methods
  defdelegate get_multigoal_methods(domain), to: Methods
  defdelegate get_goal_methods(domain, predicate), to: Methods
  defdelegate get_method(domain, method_name), to: Methods
  defdelegate has_task_methods?(domain, task_name), to: Methods
  defdelegate has_unigoal_methods?(domain, goal_type), to: Methods

  defdelegate verify_goal(state, method_name, state_var, args, desired_values, depth, verbose), to: Utils
  defdelegate summary(domain), to: Utils
  defdelegate add_porcelain_actions(domain), to: Utils
  defdelegate create_complete_domain(name \\ "complete"), to: Utils
  defdelegate infer_method_name(fun), to: Utils

  # Behaviour callbacks
  defdelegate actions(domain), to: BehaviourImpl
  defdelegate task_methods(domain), to: BehaviourImpl
  defdelegate unigoal_methods(domain), to: BehaviourImpl
  defdelegate multigoal_methods(domain), to: BehaviourImpl
  defdelegate durative_actions(domain), to: BehaviourImpl

  defdelegate add_durative_action(domain, name, durative_action), to: Core
  defdelegate get_durative_action(domain, name), to: Core






end
