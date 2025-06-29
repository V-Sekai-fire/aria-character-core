# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Domain do
  @moduledoc "Represents a planning domain in the GTPhop planner (Elixir port of GTPyhop).\n\nA domain contains:\n- Actions: Named functions that modify the world state\n- Task methods: Named functions that decompose tasks into subtasks\n- Unigoal methods: Named functions that achieve single goals\n- Multigoal methods: Named functions that achieve multiple goals simultaneously\n\nThis implementation aligns with GTPyhop's approach where:\n- Actions are stored as name -> function mappings\n- Methods are stored as task_name -> list of {name, function} tuples\n- Method names are preserved for logging, blacklisting, and error reporting\n\nExample:\n```elixir\ndomain = AriaEngineCore.Domain.new(\"logistics\")\n|> AriaEngineCore.Domain.add_action(:move, &move_action/2)\n|> AriaEngineCore.Domain.add_task_methods(\"transport\", [\n     {\"transport\", &transport_by_truck/2},\n     {\"transport\", &transport_by_plane/2}\n   ])\n```\n"
  require Logger
  alias AriaEngineCore.Domain.Core
  alias AriaEngineCore.Domain.Actions
  alias AriaEngineCore.Domain.Methods
  alias AriaEngineCore.Domain.Utils
  alias AriaEngineCore.Domain.BehaviourImpl
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
  defdelegate add_multitodo_method(domain, method_name, method_fn), to: Methods # Added
  defdelegate get_task_methods(domain, task_name), to: Methods
  defdelegate get_unigoal_methods(domain, goal_type), to: Methods
  defdelegate get_multigoal_methods(domain), to: Methods
  defdelegate get_multitodo_methods(domain), to: Methods # Added
  defdelegate get_goal_methods(domain, predicate), to: Methods
  defdelegate get_method(domain, method_name), to: Methods
  defdelegate has_task_methods?(domain, task_name), to: Methods
  defdelegate has_unigoal_methods?(domain, goal_type), to: Methods
  defdelegate set_entity_registry(domain, registry), to: Core
  defdelegate get_entity_registry(domain), to: Core
  defdelegate set_temporal_specifications(domain, specs), to: Core
  defdelegate get_temporal_specifications(domain), to: Core

  defdelegate verify_goal(state, method_name, state_var, args, desired_values, depth, verbose),
    to: Utils

  defdelegate summary(domain), to: Utils
  defdelegate add_porcelain_actions(domain), to: Utils
  defdelegate create_complete_domain(name \\ "complete"), to: Utils
  defdelegate infer_method_name(fun), to: Utils
  defdelegate actions(domain), to: BehaviourImpl
  defdelegate task_methods(domain), to: BehaviourImpl
  defdelegate unigoal_methods(domain), to: BehaviourImpl
  defdelegate multigoal_methods(domain), to: BehaviourImpl
  defdelegate durative_actions(domain), to: BehaviourImpl
  defdelegate get_durative_action(domain, name), to: Core
end
