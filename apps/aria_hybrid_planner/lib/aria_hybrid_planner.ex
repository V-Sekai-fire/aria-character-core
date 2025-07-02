# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner do
  @moduledoc """
  AriaHybridPlanner provides core temporal planning and execution capabilities.

  ## Usage

      # Plan and execute in one step (recommended)
      {:ok, {final_state, solution_tree}} = AriaHybridPlanner.run_lazy(domain, state, todos)

      # Plan first, then execute separately
      {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, opts)
      {:ok, {final_state, updated_tree}} = AriaHybridPlanner.run_lazy_tree(domain, state, plan.solution_tree)

      # Advanced planning with options
      {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, verbose: 2, max_depth: 15)

  ## Key Features

  - HTN (Hierarchical Task Network) planning
  - Temporal constraint handling
  - Solution tree generation and execution
  - Automatic failure recovery
  - Entity-based resource management

  ## API Functions

  ### Primary API
  - `plan/4` - Planning with options, returns detailed plan structure
  - `run_lazy/3` - Planning + execution, returns final state and solution tree
  - `run_lazy_tree/3` - Execute pre-made plan, returns final state and updated tree

  ### State Management
  - `new_state/0`, `new_state/1` - Create new planning states
  - `set_fact/4`, `get_fact/3`, `has_subject?/3`, etc. - State manipulation
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
  Plan using the existing planning infrastructure with proper HTN decomposition.
  """
  @spec plan(term(), State.t(), [term()], keyword()) :: {:ok, map()} | {:error, String.t()}
  def plan(domain, initial_state, todos, opts \\ []) do
    try do
      verbose = Keyword.get(opts, :verbose, 0)
      max_depth = Keyword.get(opts, :max_depth, 10)

      if verbose > 1 do
        Logger.debug("HTN Planning: Starting with #{length(todos)} todos")
      end

      # Create initial solution tree using existing infrastructure
      solution_tree = Utils.create_initial_solution_tree(todos, initial_state)

      # Expand the root node with todos
      {:ok, expanded_tree} = Plan.NodeExpansion.expand_root_node(solution_tree, solution_tree.root_id, todos, initial_state)

      # Perform HTN planning by expanding non-primitive nodes
      case plan_recursive(domain, expanded_tree, initial_state, opts, 0, max_depth) do
        {:ok, final_tree} ->
          plan = %{
            solution_tree: final_tree,
            metadata: %{
              created_at: System.system_time(:millisecond),
              domain: domain,
              planning_depth: max_depth
            }
          }

          if verbose > 1 do
            stats = Utils.tree_stats(final_tree)
            Logger.debug("HTN Planning: Completed with #{stats.total_nodes} nodes, #{stats.action_count} actions")
          end

          {:ok, plan}

        {:error, reason} ->
          {:error, reason}
      end

    rescue
      e ->
        error_msg = "Planning error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  # Recursive HTN planning implementation
  defp plan_recursive(domain, solution_tree, state, opts, depth, max_depth) do
    verbose = Keyword.get(opts, :verbose, 0)

    if depth >= max_depth do
      if verbose > 1 do
        Logger.debug("HTN Planning: Reached maximum depth #{max_depth}")
      end
      {:ok, solution_tree}
    else
      # Find nodes that need expansion
      unexpanded_nodes = find_unexpanded_nodes(solution_tree)

      if Enum.empty?(unexpanded_nodes) do
        # All nodes are expanded or primitive
        {:ok, solution_tree}
      else
        # Expand the first unexpanded node
        [node_id | _] = unexpanded_nodes
        node = solution_tree.nodes[node_id]

        case expand_node_by_type(domain, solution_tree, node_id, node, state, opts) do
          {:ok, updated_tree} ->
            # Continue planning recursively
            plan_recursive(domain, updated_tree, state, opts, depth + 1, max_depth)

          {:error, reason} ->
            {:error, reason}

          :failure ->
            # Mark node as primitive if no methods available
            case Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id) do
              {:ok, updated_tree} ->
                plan_recursive(domain, updated_tree, state, opts, depth + 1, max_depth)
              {:error, reason} ->
                {:error, reason}
            end
        end
      end
    end
  end

  # Find nodes that need expansion (not primitive and not expanded)
  defp find_unexpanded_nodes(solution_tree) do
    solution_tree.nodes
    |> Enum.filter(fn {_id, node} -> not node.is_primitive and not node.expanded end)
    |> Enum.map(fn {id, _node} -> id end)
  end

  # Expand a node based on its task type
  defp expand_node_by_type(domain, solution_tree, node_id, node, state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    case node.task do
      # Handle multigoals
      %AriaEngineCore.Multigoal{} = multigoal ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Expanding multigoal node #{node_id}")
        end
        Plan.NodeExpansion.expand_multigoal_node(domain, state, solution_tree, node_id, multigoal, verbose)

      # Handle regular tasks
      {task_name, _args} when is_binary(task_name) ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Expanding task node #{node_id}: #{task_name}")
        end
        expand_task_node(domain, solution_tree, node_id, node, state, opts)

      # Handle goals (predicate, subject, value)
      {predicate, _subject, _value} when is_binary(predicate) ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Expanding goal node #{node_id}: #{predicate}")
        end
        expand_goal_node(domain, solution_tree, node_id, node, state, opts)

      # Handle primitive actions (atom, args)
      {action_name, _args} when is_atom(action_name) ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Marking action node #{node_id} as primitive: #{action_name}")
        end
        Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)

      _ ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Unknown task type for node #{node_id}, marking as primitive")
        end
        Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)
    end
  end

  # Expand a task node using domain methods
  defp expand_task_node(domain, solution_tree, node_id, node, _state, opts) do
    {task_name, _args} = node.task
    verbose = Keyword.get(opts, :verbose, 0)

    # Check if domain has methods for this task
    case Domain.Core.get_task_methods(domain, task_name) do
      [] ->
        if verbose > 2 do
          Logger.debug("HTN Planning: No methods found for task #{task_name}, marking as primitive")
        end
        :failure

      methods ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Found #{length(methods)} methods for task #{task_name}")
        end
        # For now, mark as primitive since we don't have method execution logic
        # In a full implementation, this would try each method
        Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)
    end
  end

  # Expand a goal node using domain unigoal methods
  defp expand_goal_node(domain, solution_tree, node_id, node, _state, opts) do
    {predicate, _subject, _value} = node.task
    verbose = Keyword.get(opts, :verbose, 0)

    # Check if domain has unigoal methods for this predicate
    case Domain.Core.get_unigoal_methods(domain, predicate) do
      [] ->
        if verbose > 2 do
          Logger.debug("HTN Planning: No unigoal methods found for predicate #{predicate}, marking as primitive")
        end
        :failure

      methods ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Found #{length(methods)} unigoal methods for predicate #{predicate}")
        end
        # For now, mark as primitive since we don't have method execution logic
        # In a full implementation, this would try each method
        Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)
    end
  end

  # Execute a plan using the existing execution infrastructure.
  @spec execute(term(), State.t(), map(), keyword()) :: {:ok, State.t()} | {:error, String.t()}
  defp execute(domain, initial_state, plan, opts \\ []) do
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

  # Plan and execute in one step.
  defp plan_and_execute(domain, state, goals, opts \\ []) do
    case plan(domain, state, goals, opts) do
      {:ok, plan} ->
        execute(domain, state, plan, opts)
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Simple API functions (using direct implementations)


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
