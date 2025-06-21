# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Core do
  @moduledoc """
  Core components and types for the Aria Engine.
  """

  # Core types
  @type domain :: Domain.Core.t()
  @type state :: AriaEngine.StateV2.t()
  @type multigoal :: Multigoal.t()
  @type solution_tree :: Plan.solution_tree()
  @type plan_step :: Plan.plan_step()

  # Goal and task types
  @type goal :: {String.t(), String.t(), AriaEngine.StateV2.fact_value()}
  @type task :: {String.t(), list()}
  # Use fully qualified name
  @type todo_item :: Plan.todo_item()

  # Function types
  @type action_fn :: (AriaEngine.StateV2.t(), list() -> AriaEngine.StateV2.t() | false)
  @type task_method_fn :: (AriaEngine.StateV2.t(), list() -> list() | false)
  @type goal_method_fn :: (AriaEngine.StateV2.t(), list() -> list() | false)

  # Status and execution types
  @type status :: :pending | :planning | :executing | :completed | :failed | :cancelled
  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}
  @type execution_result :: {:ok, t()} | {:error, String.t()}

  # Main AriaEngine definition type
  @type t :: %__MODULE__{
          # Identity
          id: String.t(),
          name: String.t(),
          execution_id: reference() | nil,

          # Domain Capabilities
          actions: %{atom() => action_fn()},
          task_methods: %{String.t() => [task_method_fn()]},
          unigoal_methods: %{String.t() => [goal_method_fn()]},
          multigoal_methods: [goal_method_fn()],

          # Planning Goals
          goals: [todo_item()],

          # Execution State
          current_state: AriaEngine.StateV2.t(),
          initial_state: AriaEngine.StateV2.t(),
          status: status(),
          solution_tree: solution_tree() | nil,

          # Execution Progress
          progress: %{
            total_steps: non_neg_integer(),
            completed_steps: non_neg_integer(),
            current_step: String.t() | nil
          },
          error: term() | nil,

          # Metadata
          documentation: %{atom() => String.t()},
          metadata: %{atom() => term()},
          created_at: DateTime.t(),
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil
        }

  defstruct [
    # Identity
    :id,
    :name,
    execution_id: nil,

    # Domain Capabilities
    actions: %{},
    task_methods: %{},
    unigoal_methods: %{},
    multigoal_methods: [],

    # Planning Goals
    goals: [],

    # Execution State
    current_state: nil,
    initial_state: nil,
    status: :pending,
    solution_tree: nil,

    # Execution Progress
    progress: %{total_steps: 0, completed_steps: 0, current_step: nil},
    error: nil,

    # Metadata
    documentation: %{},
    metadata: %{},
    created_at: nil,
    started_at: nil,
    completed_at: nil
  ]

  @doc """
  Creates a new AriaEngine definition with capabilities and goals.
  """
  @spec new(String.t(), map()) :: t()
  def new(id, definition \\ %{}) do
    now = DateTime.utc_now()
    # Use fully qualified name
    initial_state = Map.get(definition, :initial_state, AriaEngine.StateV2.new())

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
end
