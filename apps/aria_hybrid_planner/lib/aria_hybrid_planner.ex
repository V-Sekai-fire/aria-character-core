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

      # Handle regular tasks (both string and atom task names)
      {task_name, _args} when is_binary(task_name) or is_atom(task_name) ->
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
  defp expand_task_node(domain, solution_tree, node_id, node, state, opts) do
    {task_name, args} = node.task
    verbose = Keyword.get(opts, :verbose, 0)

    # Convert task name to atom for domain lookup
    task_atom = case task_name do
      atom when is_atom(atom) -> atom
      string when is_binary(string) -> String.to_atom(string)
      other -> other
    end

    # Check if domain has methods for this task
    case AriaCore.get_task_methods_from_domain(domain, task_atom) do
      [] ->
        if verbose > 2 do
          Logger.debug("HTN Planning: No methods found for task #{task_name}, marking as primitive")
        end
        :failure

      methods ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Found #{length(methods)} methods for task #{task_name}")
        end

        # Get the first available method from the list
        case methods do
          [] ->
            if verbose > 2 do
              Logger.debug("HTN Planning: No methods available for task #{task_name}")
            end
            :failure

          [{method_name, _method_spec} | _] ->
            case execute_task_method_for_planning(domain, state, task_atom, args, method_name, opts) do
              {:ok, []} ->
                # Method returned empty list - task already completed
                if verbose > 2 do
                  Logger.debug("HTN Planning: Task method #{method_name} returned empty list - task completed")
                end
                Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)

              {:ok, subtasks} ->
                # Method returned subtasks - create child nodes
                if verbose > 2 do
                  Logger.debug("HTN Planning: Task method #{method_name} returned #{length(subtasks)} subtasks")
                end
                case create_child_nodes_for_planning(solution_tree, node_id, subtasks, method_name, opts) do
                  {:ok, updated_tree} -> {:ok, updated_tree}
                  {:error, reason} -> {:error, "Failed to create child nodes: #{reason}"}
                end

              {:error, reason} ->
                if verbose > 2 do
                  Logger.debug("HTN Planning: Task method #{method_name} failed: #{reason}")
                end
                :failure
            end
        end
    end
  end

  # Expand a goal node using domain unigoal methods
  defp expand_goal_node(domain, solution_tree, node_id, node, state, opts) do
    {predicate, subject, value} = node.task

    Logger.debug("HTN Goal Expansion: Starting expansion for goal #{predicate}(#{subject}, #{value}) in node #{node_id}")

    # Convert string predicate to atom for domain lookup
    predicate_atom = if is_binary(predicate), do: String.to_atom(predicate), else: predicate

    # First check if the goal is already satisfied in the current state
    current_value = AriaHybridPlanner.State.get_fact(state, Atom.to_string(predicate_atom), subject)
    Logger.debug("HTN Goal Expansion: Current value for #{predicate}(#{subject}): #{inspect(current_value)}, target: #{inspect(value)}")

    if current_value == value do
      # Goal already satisfied - mark as completed primitive
      Logger.debug("HTN Goal Expansion: Goal #{predicate}(#{subject}, #{value}) already satisfied, marking as primitive")
      Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)
    else
      Logger.debug("HTN Goal Expansion: Goal not satisfied, looking for unigoal methods for predicate #{predicate}")

      # Goal not satisfied - try to find unigoal methods
      case AriaCore.get_unigoal_methods_for_predicate(domain, Atom.to_string(predicate_atom)) do
        methods when map_size(methods) == 0 ->
          Logger.debug("HTN Goal Expansion: No unigoal methods found for predicate #{predicate}, goal cannot be achieved")
          :failure

        methods when is_map(methods) ->
          Logger.debug("HTN Goal Expansion: Found #{map_size(methods)} unigoal methods for predicate #{predicate}: #{inspect(Map.keys(methods))}")

          # Get the first available method from the map
          case Enum.take(methods, 1) do
            [] ->
              Logger.debug("HTN Goal Expansion: No unigoal methods available for predicate #{predicate}")
              :failure

            [{method_name, method_spec}] ->
              Logger.debug("HTN Goal Expansion: Trying unigoal method #{method_name} for goal #{predicate}(#{subject}, #{value})")
              Logger.debug("HTN Goal Expansion: Method spec: #{inspect(method_spec)}")

              case execute_unigoal_method_for_planning(domain, state, predicate_atom, {subject, value}, method_name, opts) do
                {:ok, []} ->
                  # Method returned empty list - goal already satisfied
                  Logger.debug("HTN Goal Expansion: Unigoal method #{method_name} returned empty list, marking as primitive")
                  Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)

                {:ok, subtasks} ->
                  # Method returned subtasks - create child nodes
                  Logger.debug("HTN Goal Expansion: Unigoal method #{method_name} returned #{length(subtasks)} subtasks: #{inspect(subtasks)}")
                  case create_child_nodes_for_planning(solution_tree, node_id, subtasks, method_name, opts) do
                    {:ok, updated_tree} ->
                      Logger.debug("HTN Goal Expansion: Successfully created child nodes for goal #{predicate}(#{subject}, #{value})")
                      {:ok, updated_tree}
                    {:error, reason} ->
                      Logger.debug("HTN Goal Expansion: Failed to create child nodes: #{reason}")
                      {:error, "Failed to create child nodes: #{reason}"}
                  end

                {:error, reason} ->
                  Logger.debug("HTN Goal Expansion: Unigoal method #{method_name} failed: #{reason}")
                  :failure
              end
          end
      end
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
        # Convert string task names to atoms in solution tree before execution
        normalized_tree = normalize_solution_tree_task_names(solution_tree)

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

        case ReentrantExecutor.execute_plan_lazy(normalized_tree, initial_state, enhanced_opts) do
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

  # Normalize task names in solution tree from strings to atoms
  defp normalize_solution_tree_task_names(solution_tree) do
    normalized_nodes = solution_tree.nodes
    |> Enum.map(fn {node_id, node} ->
      normalized_task = case node.task do
        {task_name, args} when is_binary(task_name) ->
          {String.to_atom(task_name), args}
        other ->
          other
      end
      {node_id, %{node | task: normalized_task}}
    end)
    |> Enum.into(%{})

    %{solution_tree | nodes: normalized_nodes}
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
    # Normalize the solution tree before execution
    normalized_tree = normalize_solution_tree_task_names(solution_tree)
    plan = %{solution_tree: normalized_tree}
    case execute(domain, state, plan) do
      {:ok, final_state} ->
        {:ok, {final_state, normalized_tree}}
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


  # Execute a task method during planning to get subtasks.
  defp execute_task_method_for_planning(domain, state, task_name, args, method_name, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Planning: Executing task method #{method_name} for #{task_name}(#{inspect(args)})")
    end

    try do
      # Get task methods for the task name using the unified helper
      case get_task_methods_from_domain(domain, task_name) do
        [] ->
          {:error, "No task methods found for task #{task_name}"}

        methods when is_list(methods) ->
          # Find the method function in the list of tuples
          case find_method_function(methods, method_name) do
            nil ->
              if verbose > 2 do
                Logger.debug("HTN Planning: No method function found for #{method_name}, marking as primitive")
              end
              {:ok, []}

            method_fn when is_function(method_fn, 2) ->
              execute_task_method_function(method_fn, state, args, method_name, verbose)

            _other ->
              {:error, "Invalid method function for #{method_name}"}
          end

        _other ->
          {:error, "Invalid task methods structure for task #{task_name}"}
      end
    rescue
      e ->
        error_msg = "Method execution failed: #{Exception.message(e)}"
        if verbose > 1 do
          Logger.debug("HTN Planning: #{error_msg}")
        end
        {:error, error_msg}
    end
  end

  defp execute_task_method_function(method_fn, state, args, method_name, verbose) do
    case method_fn.(state, args) do
      {:ok, subtasks} when is_list(subtasks) ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Method #{method_name} returned #{length(subtasks)} subtasks")
        end
        {:ok, subtasks}

      subtasks when is_list(subtasks) ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Method #{method_name} returned #{length(subtasks)} subtasks")
        end
        {:ok, subtasks}

      {:error, reason} ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Method #{method_name} failed: #{reason}")
        end
        {:error, reason}

      other_result ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Method #{method_name} returned non-list result: #{inspect(other_result)}")
        end
        {:error, "Method returned non-list result: #{inspect(other_result)}"}
    end
  end

  # Helper functions for planning-time method execution

  # Execute a unigoal method during planning to get subtasks.
  defp execute_unigoal_method_for_planning(domain, state, predicate, {subject, value}, method_name, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Planning: Executing unigoal method #{method_name} for #{predicate}(#{subject}, #{value})")
    end

    try do
      # Get methods for the predicate and use the first available one
      case AriaCore.get_unigoal_methods_for_predicate(domain, Atom.to_string(predicate)) do
        methods when map_size(methods) == 0 ->
          {:error, "No unigoal methods found for predicate #{predicate}"}

        methods when is_map(methods) ->
          # Get the first available method from the map
          case Enum.take(methods, 1) do
            [] ->
              {:error, "No unigoal methods available for predicate #{predicate}"}

            [{method_name_atom, method_spec}] ->
              execute_method_spec(method_spec, state, {subject, value}, method_name_atom, verbose)
          end

        _other ->
          {:error, "Invalid unigoal methods structure for predicate #{predicate}"}
      end
    rescue
      e ->
        error_msg = "Method execution failed: #{Exception.message(e)}"
        if verbose > 1 do
          Logger.debug("HTN Planning: #{error_msg}")
        end
        {:error, error_msg}
    end
  end

  defp execute_method_spec(method_spec, state, goal_args, method_name, verbose) do
    # Extract function from method spec
    method_fn = cond do
      is_function(method_spec, 2) ->
        method_spec

      is_map(method_spec) and Map.has_key?(method_spec, :goal_fn) and is_function(method_spec.goal_fn, 2) ->
        method_spec.goal_fn

      is_map(method_spec) and Map.has_key?(method_spec, :function) and is_function(method_spec.function, 2) ->
        method_spec.function

      true ->
        nil
    end

    case method_fn do
      nil ->
        {:error, "Method #{method_name} has no valid function"}

      method_fn when is_function(method_fn, 2) ->
        # Execute the method with state and goal arguments
        case method_fn.(state, goal_args) do
          {:ok, subtasks} when is_list(subtasks) ->
            if verbose > 2 do
              Logger.debug("HTN Planning: Method #{method_name} returned #{length(subtasks)} subtasks")
            end
            {:ok, subtasks}

          subtasks when is_list(subtasks) ->
            if verbose > 2 do
              Logger.debug("HTN Planning: Method #{method_name} returned #{length(subtasks)} subtasks")
            end
            {:ok, subtasks}

          {:error, reason} ->
            if verbose > 2 do
              Logger.debug("HTN Planning: Method #{method_name} failed: #{reason}")
            end
            {:error, reason}

          other_result ->
            if verbose > 2 do
              Logger.debug("HTN Planning: Method #{method_name} returned non-list result: #{inspect(other_result)}")
            end
            {:error, "Method returned non-list result: #{inspect(other_result)}"}
        end
    end
  end

  # Create child nodes from subtasks during planning.
  defp create_child_nodes_for_planning(solution_tree, parent_node_id, subtasks, method_name, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Planning: Creating #{length(subtasks)} child nodes for parent #{parent_node_id}")
    end

    try do
      # Generate unique IDs for child nodes
      child_data = subtasks
      |> Enum.with_index()
      |> Enum.map(fn {subtask, index} ->
        child_id = "#{parent_node_id}_#{method_name}_#{index}"
        child_node = %{
          id: child_id,
          task: subtask,
          parent_id: parent_node_id,
          children_ids: [],
          expanded: false,
          is_primitive: false,
          is_durative: false,
          method_tried: nil,
          blacklisted_methods: [],
          visited: false,
          state: solution_tree.nodes[parent_node_id].state
        }
        {child_node, child_id}
      end)

      {child_nodes, child_ids} = Enum.unzip(child_data)

      # Update parent node with method and children
      parent_node = solution_tree.nodes[parent_node_id]
      updated_parent = %{parent_node |
        method_tried: method_name,
        expanded: true,
        is_primitive: false,
        children_ids: child_ids
      }

      # Add all child nodes to the solution tree
      updated_nodes = child_nodes
      |> Enum.reduce(solution_tree.nodes, fn child_node, acc_nodes ->
        Map.put(acc_nodes, child_node.id, child_node)
      end)
      |> Map.put(parent_node_id, updated_parent)

      updated_tree = %{solution_tree | nodes: updated_nodes}

      if verbose > 2 do
        Logger.debug("HTN Planning: Successfully created #{length(child_ids)} child nodes")
      end

      {:ok, updated_tree}
    rescue
      e ->
        error_msg = "Failed to create child nodes: #{Exception.message(e)}"
        if verbose > 1 do
          Logger.debug("HTN Planning: #{error_msg}")
        end
        {:error, error_msg}
    end
  end

  # Helper functions for domain compatibility

  # Unified helper to get task methods from domain
  defp get_task_methods_from_domain(domain, task_name) do
    # Use AriaCore.MethodManagement directly
    AriaCore.MethodManagement.get_task_methods(domain, task_name)
  end

  # Find method function in a list of method tuples
  defp find_method_function(methods, method_name) do
    # Convert method_name to string for comparison
    method_name_str = case method_name do
      atom when is_atom(atom) -> Atom.to_string(atom)
      string when is_binary(string) -> string
      other -> to_string(other)
    end

    # Find the method in the list of {name, function} tuples
    case Enum.find(methods, fn {name, _fn} ->
      name_str = case name do
        atom when is_atom(atom) -> Atom.to_string(atom)
        string when is_binary(string) -> string
        other -> to_string(other)
      end
      name_str == method_name_str
    end) do
      {_name, method_fn} -> method_fn
      nil -> nil
    end
  end

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
