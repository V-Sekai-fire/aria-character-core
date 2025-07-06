# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Define behaviors for undefined modules that need mocking
defmodule AriaCoreBehaviour do
  @callback new_legacy_domain() :: map()
  @callback new_legacy_domain(binary()) :: map()
  @callback validate_legacy_domain(map()) :: {:ok, :valid} | {:error, term()}
  @callback add_action_to_legacy_domain(map(), term(), term()) :: map()
  @callback get_durative_action_from_legacy_domain(map(), term()) :: term()
  @callback set_entity_registry(map(), map()) :: map()
  @callback get_entity_registry(map()) :: map()
  @callback set_temporal_specifications(map(), map()) :: map()
  @callback get_temporal_specifications(map()) :: map()
  @callback add_task_method_to_domain(map(), term(), term(), term()) :: map()
  @callback add_unigoal_method_to_domain(map(), term(), term(), term()) :: map()
  @callback add_unigoal_method_to_domain(map(), term(), term()) :: map()
  @callback add_multigoal_method_to_domain(map(), term(), term()) :: map()
  @callback add_multitodo_method_to_domain(map(), term(), term()) :: map()
  @callback get_task_methods_from_domain(map(), term()) :: list()
  @callback get_unigoal_methods_from_domain(map(), term()) :: list()
  @callback get_multigoal_methods_from_domain(map()) :: list()
  @callback get_multitodo_methods_from_domain(map()) :: list()
  @callback execute_action_in_domain(map(), map(), term(), list()) :: {:ok, map()} | {:error, term()}
  @callback get_action_metadata_from_domain(map(), term()) :: map()
  @callback add_method_to_domain(map(), term(), term()) :: map()
  @callback get_all_actions_with_metadata_from_domain(map()) :: list()
  @callback execute_action(map(), map(), term(), list()) :: {:ok, map()} | {:error, term()}
end

defmodule AriaCoreDomainBehaviour do
  @callback new(binary()) :: map()
  @callback enable_solution_tree(map(), boolean()) :: map()
end

defmodule AriaHybridPlannerCoreBehaviour do
  @callback new_coordinator(map()) :: map()
  @callback plan(map(), map(), map(), list(), list()) :: {:ok, map()} | {:error, term()}
  @callback execute(map(), map(), map(), map(), list()) :: {:ok, map()} | {:error, term()}
  @callback validate_plan(map(), map(), map(), map()) :: {:ok, :valid} | {:error, term()}
  @callback replan(map(), map(), map(), map(), term(), list()) :: {:ok, map()} | {:error, term()}
  @callback plan_and_execute(map(), map(), map(), list(), list()) :: {:ok, map()} | {:error, term()}
end

defmodule AriaStateRelationalStateBehaviour do
  @callback has_subject?(map(), term(), term()) :: boolean()
  @callback remove_fact(map(), term(), term()) :: map()
end

defmodule MembranePipelineBehaviour do
  @callback notify_child(pid(), atom(), term()) :: :ok
end

# Set up Mox for testing undefined modules
Mox.defmock(MockAriaCore, for: AriaCoreBehaviour)
Mox.defmock(MockAriaHybridPlannerCore, for: AriaHybridPlannerCoreBehaviour)
Mox.defmock(MockAriaStateRelationalState, for: AriaStateRelationalStateBehaviour)
Mox.defmock(MockMembranePipeline, for: MembranePipelineBehaviour)
Mox.defmock(MockAriaCoreDomain, for: AriaCoreDomainBehaviour)

ExUnit.start()

defmodule TestOutput do
  @moduledoc "Conditional test output helpers that respect trace mode.\n\nAccording to INST-006: Passing tests should be silent and produce no log output.\nOnly --trace mode should provide normal logging output.\n"
  require Logger

  @doc "Log debug message only when running in trace mode (mix test --trace).\nSilent during normal test execution.\n"
  def trace_puts(message) do
    if trace_mode?() do
      Logger.debug(message)
    end
  end

  @doc "Inspect and log data only in trace mode.\n"
  def trace_inspect(data, opts \\ []) do
    if trace_mode?() do
      Logger.debug(inspect(data, opts))
      data
    else
      data
    end
  end

  @doc "Check if ExUnit is running in trace mode.\n"
  def trace_mode?() do
    ExUnit.configuration()[:trace] == true
  end

  @doc "Execute a function only in trace mode (for complex output logic).\n"
  def trace_only(func) when is_function(func, 0) do
    if trace_mode?() do
      func.()
    end
  end
end
