# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Stubs do
  @moduledoc """
  Stub implementations for missing modules to prevent compilation warnings.

  These modules provide basic implementations to allow compilation to succeed
  when the actual modules are not available. During testing, these can be
  replaced with Mox mocks for behavioral testing.
  """
end

# Only define these modules if they don't already exist
unless Code.ensure_loaded?(AriaHybridPlanner.Core) do
  defmodule AriaHybridPlanner.Core do
    @moduledoc "Stub module for AriaHybridPlanner.Core"

    def new_coordinator(_opts) do
      %{coordinator_id: "stub-coordinator"}
    end

    def plan(_coordinator, _domain, _state, _goals, _opts) do
      {:ok, %{
        coordinator_id: "stub-coordinator",
        created_at: DateTime.utc_now(),
        domain: nil,
        goals: [],
        initial_state: nil,
        options: [],
        status: :planned,
        steps: []
      }}
    end

    def execute(_coordinator, _domain, _state, _plan, _opts) do
      {:ok, %{
        coordinator_id: "stub-coordinator",
        domain: nil,
        executed_at: DateTime.utc_now(),
        execution_steps: [],
        final_state: nil,
        options: [],
        plan_id: "stub-plan",
        status: :completed
      }}
    end

    def validate_plan(_coordinator, _domain, _state, _plan), do: {:ok, :valid}
    def replan(_coordinator, _domain, _state, _plan, _fail_node_id, _opts), do: {:ok, %{}}
    def plan_and_execute(_coordinator, _domain, _state, _goals, _opts), do: {:ok, %{}}
  end
end

unless Code.ensure_loaded?(AriaCore) do
  defmodule AriaCore do
    @moduledoc "Stub module for AriaCore"

    # Legacy domain functions
    def new_legacy_domain, do: %{name: "stub-domain"}
    def new_legacy_domain(name), do: %{name: name}
    def validate_legacy_domain(_domain), do: {:ok, :valid}
    def add_action_to_legacy_domain(domain, _action_name, _action), do: domain
    def get_durative_action_from_legacy_domain(_domain, _action_name), do: nil
    def set_entity_registry(domain, _registry), do: domain
    def get_entity_registry(_domain), do: %{}
    def set_temporal_specifications(domain, _specs), do: domain
    def get_temporal_specifications(_domain), do: %{}
    def add_task_method_to_domain(domain, _task_name, _method_name, _method_fn), do: domain
    def add_unigoal_method_to_domain(domain, _predicate, _method_name, _method_fn), do: domain
    def add_unigoal_method_to_domain(domain, _predicate, _method_fn), do: domain
    def add_multigoal_method_to_domain(domain, _method_name, _method_fn), do: domain
    def add_multitodo_method_to_domain(domain, _method_name, _method_fn), do: domain
    def get_task_methods_from_domain(_domain, _task_name), do: []
    def get_unigoal_methods_from_domain(_domain, _predicate), do: []
    def get_multigoal_methods_from_domain(_domain), do: []
    def get_multitodo_methods_from_domain(_domain), do: []
    def execute_action_in_domain(_domain, _state, _action_name, _args), do: {:ok, %{}}
    def get_action_metadata_from_domain(_domain, _action_name), do: %{}
    def add_method_to_domain(domain, _method_name, _method_spec), do: domain
    def get_all_actions_with_metadata_from_domain(_domain), do: []
    def execute_action(_domain, _state, _action_name, _args), do: {:ok, %{}}
  end
end

unless Code.ensure_loaded?(AriaCore.Domain) do
  defmodule AriaCore.Domain do
    @moduledoc "Stub module for AriaCore.Domain"

    def new(_name), do: %{name: "stub-domain"}
    def enable_solution_tree(domain, _enabled), do: domain
  end
end

unless Code.ensure_loaded?(AriaState.RelationalState) do
  defmodule AriaState.RelationalState do
    @moduledoc "Stub module for AriaState.RelationalState"

    def has_subject?(_state, _predicate, _subject), do: false
    def remove_fact(state, _predicate, _subject), do: state
  end
end

unless Code.ensure_loaded?(Membrane.Pipeline) do
  defmodule Membrane.Pipeline do
    @moduledoc "Stub module for Membrane.Pipeline"

    def notify_child(_pipeline_pid, _child_name, _message), do: :ok
  end
end
