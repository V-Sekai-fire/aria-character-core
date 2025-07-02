# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner do
  @moduledoc """
  AriaHybridPlanner provides core temporal planning and execution capabilities.

  ## Usage

      # Plan and execute in one step (recommended)
      {:ok, {final_state, solution_tree}} = AriaHybridPlanner.run_lazy(domain, state, todos)

      # Plan first, then execute separately
      {:ok, solution_tree} = AriaHybridPlanner.plan_simple(domain, state, todos)
      {:ok, {final_state, updated_tree}} = AriaHybridPlanner.run_lazy_tree(domain, state, solution_tree)

      # Advanced usage with options
      {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, opts)
      {:ok, final_state} = AriaHybridPlanner.execute(domain, state, plan, opts)

  ## Key Features

  - HTN (Hierarchical Task Network) planning
  - Temporal constraint handling
  - Solution tree generation and execution
  - Automatic failure recovery
  - Entity-based resource management

  ## API Functions

  ### Simple API (recommended for most use cases)
  - `plan_simple/3` - Planning only, returns solution tree
  - `run_lazy/3` - Planning + execution, returns final state and solution tree
  - `run_lazy_tree/3` - Execute pre-made plan, returns final state and updated tree

  ### Advanced API (for fine-grained control)
  - `plan/4` - Planning with options
  - `execute/4` - Execution with options
  - `plan_and_execute/4` - Combined planning and execution with options
  """

  # Type definitions
  @type domain :: AriaHybridPlanner.Domain.t()
  @type state :: AriaHybridPlanner.State.t()
  @type todo_item :: term()
  @type solution_tree :: map()

  # Core planning and execution functions (direct implementation)
  require Logger
  alias AriaHybridPlanner.State
  alias Plan.{Utils, ReentrantExecutor, Blacklisting}

  @doc """
  Plan using the existing planning infrastructure.
  """
  @spec plan(term(), State.t(), [term()], keyword()) :: {:ok, map()} | {:error, String.t()}
  def plan(_domain, initial_state, todos, _opts \\ []) do
    try do
      # Create initial solution tree using existing infrastructure
      solution_tree = Utils.create_initial_solution_tree(todos, initial_state)

      # Create enhanced solution tree
      enhanced_solution_tree = case todos do
        [] ->
          # No goals to achieve
          %{solution_tree | nodes: Map.put(solution_tree.nodes, solution_tree.root_id,
            %{solution_tree.nodes[solution_tree.root_id] | expanded: true})}

        _ ->
          # Create primitive action nodes for each todo
          {updated_tree, child_ids} = Enum.reduce(todos, {solution_tree, []}, fn todo, {tree, child_ids} ->
            child_id = Utils.generate_node_id()

            child_node = %{
              id: child_id,
              task: todo,
              parent_id: tree.root_id,
              children_ids: [],
              state: initial_state,
              visited: true,
              expanded: true,
              method_tried: nil,
              blacklisted_methods: [],
              is_primitive: Utils.is_primitive_task?(todo),
              is_durative: false
            }

            updated_nodes = Map.put(tree.nodes, child_id, child_node)
            updated_tree = %{tree | nodes: updated_nodes}
            {updated_tree, [child_id | child_ids]}
          end)

          # Update root node with children
          root_node = updated_tree.nodes[updated_tree.root_id]
          updated_root = %{root_node | children_ids: Enum.reverse(child_ids), expanded: true}
          %{updated_tree | nodes: Map.put(updated_tree.nodes, updated_tree.root_id, updated_root)}
      end

      plan = %{
        solution_tree: enhanced_solution_tree,
        metadata: %{
          created_at: System.system_time(:millisecond)
        }
      }

      {:ok, plan}

    rescue
      e ->
        error_msg = "Planning error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Execute a plan using the existing execution infrastructure.
  """
  @spec execute(term(), State.t(), map(), keyword()) :: {:ok, State.t()} | {:error, String.t()}
  def execute(domain, initial_state, plan, opts \\ []) do
    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format - missing solution tree"}
      else
        # Extract or create blacklist state from plan metadata
        blacklist_state = case Keyword.get(opts, :blacklist_state) do
          nil ->
            case get_in(plan, [:metadata, :blacklist_state]) do
              nil -> Blacklisting.new()
              existing -> existing
            end
          provided -> provided
        end

        enhanced_opts = opts
        |> Keyword.put(:domain, domain)
        |> Keyword.put(:blacklist_state, blacklist_state)

        case ReentrantExecutor.execute_plan_lazy(solution_tree, initial_state, enhanced_opts) do
          {:ok, final_state} ->
            {:ok, final_state}
          {:error, reason} ->
            Logger.error("Execution failed: #{reason}")
            {:error, reason}
        end
      end
    rescue
      e ->
        error_msg = "Execution error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Plan and execute in one step.
  """
  def plan_and_execute(domain, state, goals, opts \\ []) do
    case plan(domain, state, goals, opts) do
      {:ok, plan} ->
        execute(domain, state, plan, opts)
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Simple API functions (using direct implementations)

  @doc """
  Plan only (no execution).
  Returns solution tree for the given todos.
  """
  def plan_simple(domain, state, todos) do
    case plan(domain, state, todos, []) do
      {:ok, plan} ->
        solution_tree = Map.get(plan, :solution_tree, %{})
        {:ok, solution_tree}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Plan and execute with lazy execution.
  """
  def run_lazy(domain, state, todos) do
    case plan_and_execute(domain, state, todos) do
      {:ok, final_state} ->
        # Get solution tree from the plan
        case plan(domain, state, todos, []) do
          {:ok, plan} ->
            solution_tree = Map.get(plan, :solution_tree, %{})
            {:ok, {final_state, solution_tree}}
          {:error, _} ->
            {:ok, {final_state, %{}}}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Execute a pre-made solution tree.
  """
  def run_lazy_tree(domain, state, solution_tree) do
    plan = %{solution_tree: solution_tree}
    case execute(domain, state, plan) do
      {:ok, final_state} ->
        {:ok, {final_state, solution_tree}}
      {:error, reason} -> {:error, reason}
    end
  end

  # State Management API - Delegate to internal State module
  defdelegate new_state(), to: AriaHybridPlanner.State, as: :new
  defdelegate new_state(data), to: AriaHybridPlanner.State, as: :new
  defdelegate get_fact(state, predicate, subject), to: AriaHybridPlanner.State
  defdelegate set_fact(state, predicate, subject, value), to: AriaHybridPlanner.State
  defdelegate has_subject?(state, predicate, subject), to: AriaHybridPlanner.State
  defdelegate remove_fact(state, predicate, subject), to: AriaHybridPlanner.State
  defdelegate get_subjects_with_fact(state, predicate, value), to: AriaHybridPlanner.State


  @spec version() :: String.t()
  @doc """
  Returns the version of the AriaHybridPlanner application.
  """
  def version do
    case Application.spec(:aria_hybrid_planner, :vsn) do
      vsn when is_list(vsn) -> List.to_string(vsn)
      _ -> "unknown"
    end
  end
end
