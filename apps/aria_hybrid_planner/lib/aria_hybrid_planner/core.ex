# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.Core do
  @moduledoc "Core components and types for the Aria Engine.\n"
  @type domain :: AriaEngineCore.Domain.Core.t()
  @type state :: AriaEngineCore.State.t()
  @type multigoal :: AriaEngineCore.Multigoal.t()
  @type solution_tree :: AriaEngineCore.Plan.solution_tree()
  @type plan_step :: AriaEngineCore.Plan.plan_step()
  @type goal :: {String.t(), String.t(), AriaEngineCore.State.fact_value()}
  @type task :: {String.t(), list()}
  @type todo_item :: AriaEngineCore.Plan.todo_item()
  @type action_fn :: (AriaEngineCore.State.t(), list() -> AriaEngineCore.State.t() | false)
  @type task_method_fn :: (AriaEngineCore.State.t(), list() -> list() | false)
  @type goal_method_fn :: (AriaEngineCore.State.t(), list() -> list() | false)
  @type status :: :pending | :planning | :executing | :completed | :failed | :cancelled
  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}
  @type execution_result :: {:ok, t()} | {:error, String.t()}
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          execution_id: reference() | nil,
          actions: %{atom() => action_fn()},
          task_methods: %{String.t() => [task_method_fn()]},
          unigoal_methods: %{String.t() => [goal_method_fn()]},
          multigoal_methods: [goal_method_fn()],
          goals: [todo_item()],
          current_state: AriaEngineCore.State.t(),
          initial_state: AriaEngineCore.State.t(),
          status: status(),
          solution_tree: solution_tree() | nil,
          progress: %{
            total_steps: non_neg_integer(),
            completed_steps: non_neg_integer(),
            current_step: String.t() | nil
          },
          error: term() | nil,
          documentation: %{atom() => String.t()},
          metadata: %{atom() => term()},
          created_at: DateTime.t(),
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil
        }
  defstruct [
    :id,
    :name,
    execution_id: nil,
    actions: %{},
    task_methods: %{},
    unigoal_methods: %{},
    multigoal_methods: [],
    goals: [],
    current_state: nil,
    initial_state: nil,
    status: :pending,
    solution_tree: nil,
    progress: %{total_steps: 0, completed_steps: 0, current_step: nil},
    error: nil,
    documentation: %{},
    metadata: %{},
    created_at: nil,
    started_at: nil,
    completed_at: nil
  ]

  @doc "Creates a new AriaEngine definition with capabilities and goals.\n"
  @spec new(String.t(), map()) :: t()
  def new(id, definition \\ %{}) do
    now = DateTime.utc_now()
    initial_state = Map.get(definition, :initial_state, AriaEngineCore.State.new())

    %__MODULE__{
      id: id,
      name: Map.get(definition, :name, id),
      actions: Map.get(definition, :actions, %{}),
      task_methods: Map.get(definition, :task_methods, %{}),
      unigoal_methods: Map.get(definition, :unigoal_methods, %{}),
      multigoal_methods: Map.get(definition, :multigoal_methods, []),
      goals: Map.get(definition, :goals, []),
      current_state: initial_state,
      initial_state: initial_state,
      documentation: Map.get(definition, :documentation, %{}),
      metadata: Map.get(definition, :metadata, %{}),
      created_at: now
    }
  end

  @doc "Creates a new coordinator with default settings."
  @spec new_coordinator() :: t()
  def new_coordinator do
    new("default_coordinator", %{})
  end

  @doc "Creates a new coordinator with custom options."
  @spec new_coordinator(map()) :: t()
  def new_coordinator(opts) when is_map(opts) do
    id = Map.get(opts, :id, "coordinator_#{System.unique_integer([:positive])}")
    new(id, opts)
  end

  def new_coordinator(opts) when is_list(opts) do
    new_coordinator(Map.new(opts))
  end

  # Stub functions for planning operations (to be implemented)
  def plan(_coordinator, _domain, _state, _goals), do: {:error, "Planning not yet implemented"}
  def plan(_coordinator, _domain, _state, _goals, _opts), do: {:error, "Planning not yet implemented"}
  def execute(_coordinator, _domain, _state, _plan), do: {:error, "Execution not yet implemented"}
  def execute(_coordinator, _domain, _state, _plan, _opts), do: {:error, "Execution not yet implemented"}
  def plan_and_execute(_coordinator, _domain, _state, _goals), do: {:error, "Plan and execute not yet implemented"}
  def plan_and_execute(_coordinator, _domain, _state, _goals, _opts), do: {:error, "Plan and execute not yet implemented"}
  def validate_plan(_coordinator, _domain, _state, _plan), do: {:error, "Plan validation not yet implemented"}
  def replan(_coordinator, _domain, _state, _plan, _fail_node_id, _opts \\ []), do: {:error, "Replanning not yet implemented"}
end
