# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaEngineCore.Plan do
  @moduledoc """
  Planning data structures, utilities, and HTN planning implementation for AriaEngine Core.

  This module defines the authoritative solution tree structure and related
  types used throughout the AriaEngine planning system, implementing the
  R25W1398085 unified durative action specification. It also contains the
  core HTN planning implementation with breadth-first decomposition logic.

  ## Key Types

  - `solution_tree()` - Complete planning result with actions, constraints, and metadata
  - `solution_node()` - Individual nodes within the solution tree
  - `todo_item()` - Work items that can be planned and executed

  ## Planning API

      # Plan using HTN planning with proper backtracking support
      {:ok, plan} = AriaEngineCore.Plan.plan(domain, initial_state, todos)

      # Create initial solution tree
      tree = AriaEngineCore.Plan.create_initial_solution_tree(todos, initial_state)

      # Check if solution is complete
      complete? = AriaEngineCore.Plan.solution_complete?(tree)

      # Extract primitive actions for execution
      actions = AriaEngineCore.Plan.get_primitive_actions_dfs(tree)
  """

  require Logger

  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), AriaState.fact_value()}
  @type todo_item :: task() | goal() | AriaEngineCore.Multigoal.t()
  @type plan_step :: {atom(), list()}
  @type node_id :: String.t()

  @type solution_node :: %{
          id: node_id(),
          task: todo_item(),
          parent_id: node_id() | nil,
          children_ids: [node_id()],
          state: AriaAriaState.t() | nil,
          visited: boolean(),
          expanded: boolean(),
          method_tried: String.t() | nil,
          blacklisted_methods: [String.t()],
          is_primitive: boolean(),
          is_durative: boolean()
        }

  @type solution_tree :: %{
          root_id: node_id(),
          nodes: %{node_id() => solution_node()},
          blacklisted_commands: MapSet.t(),
          goal_network: %{node_id() => [node_id()]}
        }

  # HTN Planning types
  @type domain :: AriaCore.Domain.t() | map()
  @type state :: AriaState.t()
  @type method_name :: String.t()
  @type plan_result :: {:ok, map()} | {:error, String.t()}

  @doc """
  Plan using IPyHOP-style HTN planning with proper backtracking support.
  Uses iterative refinement with state save/restore for backtracking.
  """
  @spec plan(term(), term(), [term()], keyword()) :: {:ok, map()} | {:error, String.t()}
  def plan(domain, initial_state, todos, opts \\ []) do
      verbose = Keyword.get(opts, :verbose, 0)
      max_depth = Keyword.get(opts, :max_depth, 100)

      if verbose > 1 do
        Logger.debug("HTN Planning: Starting with #{length(todos)} todos, max_depth: #{max_depth}")
      end

      # Create initial solution tree using the existing approach
      solution_tree = create_initial_solution_tree(todos, initial_state)

      # Expand the root node to create todo nodes
      case expand_root_node(domain, solution_tree, initial_state, opts) do
        {:ok, expanded_tree} ->
          # Perform HTN planning by expanding nodes one at a time (breadth-first)
          if verbose > 1 do
            Logger.debug("HTN Planning: Starting BFS planning with expanded tree")
            Logger.debug("HTN Planning: Initial tree has #{map_size(expanded_tree.nodes)} nodes")
          end

          case plan_recursive_bfs(domain, expanded_tree, initial_state, opts, 0, max_depth) do
            {:ok, final_tree, final_state} ->
              if verbose > 1 do
                Logger.debug("HTN Planning: BFS planning completed successfully")
              end

              plan = %{
                solution_tree: final_tree,
                metadata: %{
                  created_at: Timex.now() |> Timex.format!("{ISO:Extended}"),
                  domain: domain,
                  final_state: final_state,
                  planning_depth: Keyword.get(opts, :max_depth, 100)
                }
              }

              {:ok, plan}

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          if verbose > 0 do
            Logger.debug("HTN Planning: Failed to expand root: #{inspect(reason)}")
          end
          {:error, reason}
      end
    end

  @doc """
  Creates an initial solution tree for the given todo items and initial AriaState.

  ## Parameters

  - `todos` - List of todo items to be planned
  - `initial_state` - Initial world state

  ## Returns

  A new solution tree with a root node containing the todo items.

  ## Example

      todos = [{:cook_meal, ["pasta"]}, {"location", "chef", "kitchen"}]
      state = AriaEngineCore.AriaState.new()
      tree = AriaEngineCore.Plan.create_initial_solution_tree(todos, state)
  """
  @spec create_initial_solution_tree([todo_item()], AriaAriaState.t()) :: solution_tree()
  def create_initial_solution_tree(todos, initial_state) do
    root_id = generate_node_id()

    root_node = %{
      id: root_id,
      task: {:root, todos},
      parent_id: nil,
      children_ids: [],
      state: initial_state,
      visited: false,
      expanded: false,
      method_tried: nil,
      blacklisted_methods: [],
      is_primitive: false,
      is_durative: false
    }

    %{
      root_id: root_id,
      nodes: %{root_id => root_node},
      blacklisted_commands: MapSet.new(),
      goal_network: %{}
    }
  end

  @doc """
  Generates a unique node identifier.

  ## Returns

  A unique string identifier for a solution tree node.
  """
  @spec generate_node_id() :: String.t()
  def generate_node_id do
    "node_#{:erlang.unique_integer([:positive])}"
  end

  @doc """
  Checks if a solution tree represents a complete solution.

  A solution is complete when all nodes are expanded and either primitive
  or have children (except for the root node).

  ## Parameters

  - `solution_tree` - The solution tree to check

  ## Returns

  `true` if the solution is complete, `false` otherwise.
  """
  @spec solution_complete?(solution_tree()) :: boolean()
  def solution_complete?(solution_tree) do
    Enum.all?(solution_tree.nodes, fn {id, node} ->
      is_root = id == solution_tree.root_id
      node.expanded and (node.is_primitive or not Enum.empty?(node.children_ids) or is_root)
    end)
  end

  @doc """
  Updates all cached states in the solution tree with a new AriaState.

  ## Parameters

  - `solution_tree` - The solution tree to update
  - `new_state` - The new state to cache in all nodes

  ## Returns

  Updated solution tree with new cached states.
  """
  @spec update_cached_states(solution_tree(), AriaAriaState.t()) :: solution_tree()
  def update_cached_states(solution_tree, new_state) do
    updated_nodes =
      Map.new(solution_tree.nodes, fn {id, node} -> {id, %{node | state: new_state}} end)

    %{solution_tree | nodes: updated_nodes}
  end

  @doc """
  Gets all descendant node IDs for a given node.

  ## Parameters

  - `solution_tree` - The solution tree to search
  - `node_id` - The node ID to find descendants for

  ## Returns

  List of all descendant node IDs.
  """
  @spec get_all_descendants(solution_tree(), node_id()) :: [node_id()]
  def get_all_descendants(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        []

      node ->
        direct_children = node.children_ids

        all_descendants =
          Enum.flat_map(direct_children, fn child_id ->
            [child_id | get_all_descendants(solution_tree, child_id)]
          end)

        all_descendants
    end
  end

  @doc """
  Extracts primitive actions from the solution tree using depth-first search.

  This function traverses the solution tree and collects all primitive actions
  in the order they should be executed.

  ## Parameters

  - `solution_tree` - The solution tree to extract actions from

  ## Returns

  List of plan steps representing the primitive actions to execute.
  """
  @spec get_primitive_actions_dfs(solution_tree()) :: [plan_step()]
  def get_primitive_actions_dfs(solution_tree) do
    get_actions_from_node(solution_tree, solution_tree.root_id)
  end

  @spec get_actions_from_node(solution_tree(), node_id()) :: [plan_step()]
  defp get_actions_from_node(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        []

      node ->
        if node.is_primitive and node.expanded do
          case node.task do
            {action_name, args} ->
              # Convert action name to atom for test compatibility
              action_name_atom = case action_name do
                atom when is_atom(atom) -> atom
                string when is_binary(string) -> String.to_atom(string)
                _ -> String.to_atom(to_string(action_name))
              end
              [{action_name_atom, args}]
            _ -> []
          end
        else
          Enum.flat_map(node.children_ids, fn child_id ->
            get_actions_from_node(solution_tree, child_id)
          end)
        end
    end
  end

  @doc """
  Estimates the cost of a plan (simple step count for now).

  ## Parameters

  - `plan_or_tree` - Either a list of plan steps or a solution tree

  ## Returns

  The number of primitive actions in the plan.
  """
  @spec plan_cost([plan_step()] | solution_tree()) :: non_neg_integer()
  def plan_cost(%{root_id: _} = solution_tree) do
    actions = get_primitive_actions_dfs(solution_tree)
    length(actions)
  end

  def plan_cost(plan) when is_list(plan) do
    length(plan)
  end

  @doc """
  Get statistics about the solution tree.

  ## Parameters

  - `solution_tree` - The solution tree to analyze

  ## Returns

  A map containing various statistics about the tree structure.
  """
  @spec tree_stats(solution_tree()) :: %{
          total_nodes: integer(),
          expanded_nodes: integer(),
          primitive_actions: integer(),
          max_depth: integer()
        }
  def tree_stats(solution_tree) do
    nodes = Map.values(solution_tree.nodes)

    %{
      total_nodes: length(nodes),
      expanded_nodes: Enum.count(nodes, & &1.expanded),
      primitive_actions: length(get_primitive_actions_dfs(solution_tree)),
      max_depth: calculate_max_depth(solution_tree, solution_tree.root_id, 0)
    }
  end

  @spec calculate_max_depth(solution_tree(), node_id(), integer()) :: integer()
  defp calculate_max_depth(solution_tree, node_id, current_depth) do
    case solution_tree.nodes[node_id] do
      nil ->
        current_depth

      node ->
        if Enum.empty?(node.children_ids) do
          current_depth
        else
          Enum.map(node.children_ids, fn child_id ->
            calculate_max_depth(solution_tree, child_id, current_depth + 1)
          end)
          |> Enum.max()
        end
    end
  end

  @doc """
  Extracts goals from a solution tree.

  ## Parameters

  - `solution_tree` - The solution tree to extract goals from

  ## Returns

  List of todo items representing the goals.
  """
  @spec get_goals_from_tree(solution_tree()) :: [todo_item()]
  def get_goals_from_tree(solution_tree) do
    case solution_tree.nodes[solution_tree.root_id] do
      nil -> []
      %{task: {:root, todos}} -> todos
      %{task: task} -> [task]
    end
  end

  @doc """
  Creates a solution tree from a list of actions.

  ## Parameters

  - `actions` - List of plan steps (actions)
  - `goals` - Original goals that led to these actions
  - `state` - Initial state

  ## Returns

  A solution tree containing the actions as primitive nodes.
  """
  @spec create_solution_tree_from_actions([plan_step()], [todo_item()], AriaAriaState.t()) :: solution_tree()
  def create_solution_tree_from_actions(actions, goals, state) do
    root_id = generate_node_id()

    # Create root node
    root_node = %{
      id: root_id,
      task: {:root, goals},
      parent_id: nil,
      children_ids: [],
      state: state,
      visited: true,
      expanded: true,
      method_tried: "actions_from_hybrid_planner",
      blacklisted_methods: [],
      is_primitive: false,
      is_durative: false
    }

    # Create action nodes
    {action_nodes, action_ids} =
      Enum.map_reduce(actions, [], fn {action_name, args}, acc_ids ->
        node_id = generate_node_id()

        action_node = %{
          id: node_id,
          task: {action_name, args},
          parent_id: root_id,
          children_ids: [],
          state: state,
          visited: true,
          expanded: true,
          method_tried: nil,
          blacklisted_methods: [],
          is_primitive: true,
          is_durative: false
        }

        {action_node, [node_id | acc_ids]}
      end)

    # Reverse to maintain order
    action_ids = Enum.reverse(action_ids)

    # Update root node with children
    root_node = %{root_node | children_ids: action_ids}

    # Build nodes map
    nodes =
      [root_node | action_nodes]
      |> Enum.map(fn node -> {node.id, node} end)
      |> Map.new()

    %{
      root_id: root_id,
      nodes: nodes,
      blacklisted_commands: MapSet.new(),
      goal_network: %{}
    }
  end

  # Breadth-first HTN planning implementation with IPyHOP-style state management
  @spec plan_recursive_bfs(domain(), solution_tree(), state(), keyword(), non_neg_integer(), non_neg_integer()) ::
    {:ok, solution_tree(), state()} | {:error, String.t()}
  defp plan_recursive_bfs(domain, solution_tree, planning_state, opts, depth, max_depth) do
    verbose = Keyword.get(opts, :verbose, 0)

    if depth >= max_depth do
      if verbose > 1 do
        Logger.debug("HTN Planning: Reached maximum depth #{max_depth}")
      end
      {:ok, solution_tree, planning_state}
    else
      case find_next_unexpanded_node(solution_tree) do
        nil ->
          # All nodes are expanded or primitive
          if verbose > 1 do
            Logger.debug("HTN Planning: No more unexpanded nodes, planning complete")
          end
          {:ok, solution_tree, planning_state}

        node_id ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Expanding node #{node_id} (iteration depth #{depth})")
          end

          case expand_single_node(domain, solution_tree, node_id, planning_state, opts) do
            {:ok, updated_tree, updated_state} ->
              plan_recursive_bfs(domain, updated_tree, updated_state, opts, depth + 1, max_depth)
            {:error, reason} ->
              {:error, reason}
          end
      end
    end
  end

  # Find the next unexpanded node (natural order from map iteration)
  @spec find_next_unexpanded_node(solution_tree()) :: node_id() | nil
  defp find_next_unexpanded_node(solution_tree) do
    Enum.find_value(solution_tree.nodes, fn {id, node} ->
      if not node.expanded and not node.is_primitive do
        id
      else
        nil
      end
    end)
  end

  # Expand a single node based on its type (IPyHOP-style)
  defp expand_single_node(domain, solution_tree, node_id, planning_state, opts) do
    node = solution_tree.nodes[node_id]
    expand_node_by_type(domain, solution_tree, node_id, node, planning_state, opts)
  end

  # Expand a node based on its task type (IPyHOP-style)
  defp expand_node_by_type(domain, solution_tree, node_id, node, planning_state, opts) do
    case node.task do
      # Multigoal expansion
      %AriaEngineCore.Multigoal{} = multigoal ->
        expand_multigoal_node(domain, solution_tree, node_id, multigoal, planning_state, opts)

      # Goal expansion (predicate, subject, value)
      {predicate, subject, value} when is_binary(predicate) ->
        expand_goal_node(domain, solution_tree, node_id, predicate, subject, value, planning_state, opts)

      # Task expansion (task_name, args) - handle both atoms and strings
      {task_name, args} when is_binary(task_name) or is_atom(task_name) ->
        expand_task_node(domain, solution_tree, node_id, to_string(task_name), args, planning_state, opts)

      # Unknown task type - mark as primitive
      _ ->
        case mark_as_primitive(solution_tree, node_id) do
          {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
          error -> error
        end
    end
  end

  # Expand a goal node using unigoal methods (IPyHOP-style)
  defp expand_goal_node(domain, solution_tree, node_id, predicate, subject, value, planning_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    if verbose > 1 do
      Logger.debug("HTN Planning: Expanding goal node #{predicate}(#{subject}, #{value})")
    end

    # Check if goal is already satisfied
    if goal_satisfied?(planning_state, predicate, subject, value) do
      if verbose > 2 do
        Logger.debug("HTN Planning: Goal #{predicate}(#{subject}, #{value}) already satisfied")
      end
      case mark_as_completed(solution_tree, node_id) do
        {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
        error -> error
      end
    else
      # Debug: Check what unigoal methods are available
      if verbose > 1 do
        all_unigoal_methods = AriaCore.list_unigoal_methods(domain)
        Logger.debug("HTN Planning: All unigoal methods in domain: #{inspect(all_unigoal_methods)}")

        predicate_methods = AriaCore.get_unigoal_methods_for_predicate(domain, predicate)
        Logger.debug("HTN Planning: Unigoal methods for predicate '#{predicate}': #{inspect(predicate_methods)}")
      end

      # Try to expand using unigoal methods
      case try_unigoal_methods(domain, planning_state, predicate, subject, value, node.blacklisted_methods, opts) do
        {:ok, []} ->
          # Method returned empty list - goal completed
          if verbose > 1 do
            Logger.debug("HTN Planning: Unigoal method returned empty list - goal completed")
          end
          case mark_as_completed(solution_tree, node_id) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end

        {:ok, subtasks} ->
          # Create child nodes for subtasks
          if verbose > 1 do
            Logger.debug("HTN Planning: Unigoal method returned #{length(subtasks)} subtasks: #{inspect(subtasks)}")
          end
          case create_child_nodes(solution_tree, node_id, subtasks, "unigoal_method", planning_state) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end

        {:error, reason} ->
          # No methods available - mark as primitive
          if verbose > 1 do
            Logger.debug("HTN Planning: No unigoal methods found for #{predicate}: #{inspect(reason)} - marking as primitive")
          end
          case mark_as_primitive(solution_tree, node_id) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end
      end
    end
  end

  # Expand a task node using task methods (IPyHOP-style)
  defp expand_task_node(domain, solution_tree, node_id, task_name, args, planning_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    # Try to expand using task methods
    case try_task_methods(domain, planning_state, task_name, args, node.blacklisted_methods, opts) do
      {:ok, []} ->
        # Method returned empty list - task completed
        if verbose > 2 do
          Logger.debug("HTN Planning: Task #{task_name} completed (empty method result)")
        end
        case mark_as_completed(solution_tree, node_id) do
          {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
          error -> error
        end

      {:ok, subtasks} ->
        # Create child nodes for subtasks
        if verbose > 2 do
          Logger.debug("HTN Planning: Task #{task_name} expanded to #{length(subtasks)} subtasks")
        end
        case create_child_nodes(solution_tree, node_id, subtasks, "task_method", planning_state) do
          {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
          error -> error
        end

      {:error, _reason} ->
        # No methods available - validate as primitive action (IPyHOP-style execution)
        if verbose > 2 do
          Logger.debug("HTN Planning: No methods for task #{task_name}, executing as primitive action")
        end
        execute_primitive_action(domain, solution_tree, node_id, task_name, args, planning_state, opts)
    end
  end

  # Try unigoal methods for a goal
  defp try_unigoal_methods(domain, state, predicate, subject, value, blacklisted_methods, opts) do
    case AriaCore.get_unigoal_methods_for_predicate(domain, predicate) do
      methods when map_size(methods) > 0 ->
        # Try each method that isn't blacklisted
        available_methods = methods
        |> Enum.reject(fn {method_name, _} ->
          method_name_str = case method_name do
            atom when is_atom(atom) -> Atom.to_string(atom)
            string when is_binary(string) -> string
            other -> to_string(other)
          end
          method_name_str in blacklisted_methods
        end)

        try_methods_sequentially(available_methods, state, {subject, value}, opts)

      _ ->
        {:error, "No unigoal methods found for predicate #{predicate}"}
    end
  end

  # Try task methods for a task
  defp try_task_methods(domain, state, task_name, args, blacklisted_methods, opts) do
    task_atom = String.to_atom(task_name)

    case AriaCore.get_task_methods_from_domain(domain, task_atom) do
      methods when is_list(methods) and length(methods) > 0 ->
        # Try each method that isn't blacklisted
        available_methods = methods
        |> Enum.reject(fn {method_name, _} ->
          method_name_str = case method_name do
            atom when is_atom(atom) -> Atom.to_string(atom)
            string when is_binary(string) -> string
            other -> to_string(other)
          end
          method_name_str in blacklisted_methods
        end)

        try_methods_sequentially(available_methods, state, args, opts)

      _ ->
        {:error, "No task methods found for task #{task_name}"}
    end
  end

  # Try methods sequentially until one succeeds
  defp try_methods_sequentially([], _state, _args, _opts) do
    {:error, "No available methods"}
  end

  defp try_methods_sequentially([{method_name, method_spec} | rest], state, args, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Planning: Trying method #{inspect(method_name)} with args #{inspect(args)}")
    end

    try do
      # Handle different method spec formats
      result = case method_spec do
        # Unigoal method spec with goal_fn
        %{goal_fn: goal_fn} when is_function(goal_fn) ->
          goal_fn.(state, args)

        # Direct function reference (task methods)
        method_fn when is_function(method_fn) ->
          method_fn.(state, args)

        # Other spec formats
        _ ->
          {:error, "Invalid method spec format: #{inspect(method_spec)}"}
      end

      if verbose > 2 do
        Logger.debug("HTN Planning: Method #{inspect(method_name)} returned: #{inspect(result)}")
      end

      case result do
        subtasks when is_list(subtasks) ->
          {:ok, subtasks}
        {:ok, subtasks} when is_list(subtasks) ->
          {:ok, subtasks}
        {:error, reason} ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Method #{inspect(method_name)} failed: #{inspect(reason)}")
          end
          try_methods_sequentially(rest, state, args, opts)
        other ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Method #{inspect(method_name)} returned unexpected result: #{inspect(other)}")
          end
          try_methods_sequentially(rest, state, args, opts)
      end
    rescue
      e ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Method #{inspect(method_name)} raised exception: #{inspect(e)}")
        end
        try_methods_sequentially(rest, state, args, opts)
    end
  end

  # Create child nodes from subtasks (IPyHOP-style - no state progression)
  defp create_child_nodes(solution_tree, parent_node_id, subtasks, method_name, planning_state) do
    parent_node = solution_tree.nodes[parent_node_id]

    # Generate child nodes without state progression (IPyHOP approach)
    {child_nodes, child_ids} = subtasks
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {subtask, index}, {nodes_acc, ids_acc} ->
      child_id = "#{parent_node_id}_#{method_name}_#{index}"

      child_node = %{
        id: child_id,
        task: subtask,
        parent_id: parent_node_id,
        children_ids: [],
        state: planning_state,  # All children start with current planning state
        visited: false,
        expanded: false,
        method_tried: nil,
        blacklisted_methods: [],
        is_primitive: false,
        is_durative: false
      }

      {[{child_id, child_node} | nodes_acc], [child_id | ids_acc]}
    end)

    # Reverse to maintain correct order
    child_nodes = Enum.reverse(child_nodes)
    child_ids = Enum.reverse(child_ids)

    # Update parent node
    updated_parent = %{parent_node |
      method_tried: method_name,
      expanded: true,
      children_ids: child_ids
    }

    # Update solution tree
    updated_nodes = child_nodes
    |> Enum.into(solution_tree.nodes)
    |> Map.put(parent_node_id, updated_parent)

    updated_tree = %{solution_tree | nodes: updated_nodes}
    {:ok, updated_tree}
  end

  # Execute a primitive action during planning (IPyHOP-style)
  defp execute_primitive_action(domain, solution_tree, node_id, task_name, args, planning_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    # Get the action function from the domain
    case AriaCore.get_action_from_domain(domain, task_name) do
      nil ->
        # Action doesn't exist in domain
        if verbose > 1 do
          Logger.debug("HTN Planning: Action #{task_name} not found in domain")
        end
        {:error, "Action #{task_name} not found in domain"}

      action_fn when is_function(action_fn) ->
        # Execute the action during planning (IPyHOP approach)
        if verbose > 2 do
          Logger.debug("HTN Planning: Executing primitive action #{task_name} with args #{inspect(args)}")
        end

        try do
          # Execute the action and get the new state
          case action_fn.(planning_state, args) do
            {:ok, new_state} ->
              # Action succeeded - mark as primitive and return updated state
              if verbose > 2 do
                Logger.debug("HTN Planning: Action #{task_name} succeeded")
              end
              case mark_as_primitive(solution_tree, node_id) do
                {:ok, updated_tree} -> {:ok, updated_tree, new_state}
                error -> error
              end

            {:error, reason} ->
              # Action failed
              if verbose > 1 do
                Logger.debug("HTN Planning: Action #{task_name} failed: #{inspect(reason)}")
              end
              {:error, "Action #{task_name} failed: #{inspect(reason)}"}

            new_state when is_map(new_state) ->
              # Action returned new state directly
              if verbose > 2 do
                Logger.debug("HTN Planning: Action #{task_name} succeeded (direct state return)")
              end
              case mark_as_primitive(solution_tree, node_id) do
                {:ok, updated_tree} -> {:ok, updated_tree, new_state}
                error -> error
              end

            _ ->
              # Unexpected return format
              if verbose > 1 do
                Logger.debug("HTN Planning: Action #{task_name} returned unexpected format")
              end
              {:error, "Action #{task_name} returned unexpected format"}
          end
        rescue
          e ->
            if verbose > 1 do
              Logger.debug("HTN Planning: Action #{task_name} raised exception: #{inspect(e)}")
            end
            {:error, "Action #{task_name} raised exception: #{inspect(e)}"}
        end

      _ ->
        # Unexpected action format
        if verbose > 1 do
          Logger.debug("HTN Planning: Action #{task_name} has unexpected format")
        end
        {:error, "Action #{task_name} has unexpected format"}
    end
  end

  # Check if a goal is satisfied in the current state
  defp goal_satisfied?(state, predicate, subject, value) do
    # Use AriaState to check if the goal is satisfied
    AriaState.matches?(state, predicate, subject, value)
  end

  # Expand the root node to create individual todo nodes
  defp expand_root_node(_domain, solution_tree, initial_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    root_node = solution_tree.nodes[solution_tree.root_id]

    case root_node.task do
      {:root, todos} ->
        if verbose > 1 do
          Logger.debug("HTN Planning: Expanding root node with #{length(todos)} todos")
        end

        # Create child nodes for each todo
        case create_child_nodes(solution_tree, solution_tree.root_id, todos, "root_expansion", initial_state) do
          {:ok, updated_tree} -> {:ok, updated_tree}
          error -> error
        end

      _ ->
        {:error, "Root node does not contain todos"}
    end
  end

  # Mark a node as primitive (completed action)
  defp mark_as_primitive(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node #{node_id} not found"}

      node ->
        updated_node = %{node |
          is_primitive: true,
          expanded: true,
          visited: true
        }

        updated_nodes = Map.put(solution_tree.nodes, node_id, updated_node)
        updated_tree = %{solution_tree | nodes: updated_nodes}
        {:ok, updated_tree}
    end
  end

  # Mark a node as completed (goal satisfied or empty method result)
  defp mark_as_completed(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node #{node_id} not found"}

      node ->
        updated_node = %{node |
          expanded: true,
          visited: true
        }

        updated_nodes = Map.put(solution_tree.nodes, node_id, updated_node)
        updated_tree = %{solution_tree | nodes: updated_nodes}
        {:ok, updated_tree}
    end
  end

  # Expand a multigoal node using IPyHOP-style multigoal methods
  defp expand_multigoal_node(domain, solution_tree, node_id, multigoal, planning_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    if verbose > 1 do
      Logger.debug("HTN Planning: Expanding multigoal node with #{length(multigoal.goals)} goals using IPyHOP pattern")
    end

    # Check if all goals are already satisfied
    if all_multigoal_goals_satisfied?(planning_state, multigoal) do
      if verbose > 2 do
        Logger.debug("HTN Planning: All multigoal goals already satisfied")
      end
      case mark_as_completed(solution_tree, node_id) do
        {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
        error -> error
      end
    else
      # Try multigoal methods from domain (IPyHOP pattern)
      case try_multigoal_methods(domain, planning_state, multigoal, node.blacklisted_methods, opts) do
        {:ok, []} ->
          # Method returned empty list - multigoal completed
          if verbose > 1 do
            Logger.debug("HTN Planning: Multigoal method returned empty list - multigoal completed")
          end
          case mark_as_completed(solution_tree, node_id) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end

        {:ok, subtasks} ->
          # Create child nodes for subtasks returned by multigoal method
          if verbose > 1 do
            Logger.debug("HTN Planning: Multigoal method returned #{length(subtasks)} subtasks: #{inspect(subtasks)}")
          end
          case create_child_nodes(solution_tree, node_id, subtasks, "multigoal_method", planning_state) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end

        {:error, reason} ->
          # No multigoal methods available - use default method
          if verbose > 1 do
            Logger.debug("HTN Planning: No domain multigoal methods found: #{inspect(reason)} - using default method")
          end
          case try_default_multigoal_method(planning_state, multigoal, opts) do
            {:ok, []} ->
              # Default method says multigoal is complete
              case mark_as_completed(solution_tree, node_id) do
                {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
                error -> error
              end

            {:ok, subtasks} ->
              # Default method returned subtasks
              if verbose > 2 do
                Logger.debug("HTN Planning: Default multigoal method returned #{length(subtasks)} subtasks")
              end
              case create_child_nodes(solution_tree, node_id, subtasks, "default_multigoal_method", planning_state) do
                {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
                error -> error
              end

            {:error, default_reason} ->
              # Even default method failed - mark as primitive
              if verbose > 1 do
                Logger.debug("HTN Planning: Default multigoal method failed: #{inspect(default_reason)} - marking as primitive")
              end
              case mark_as_primitive(solution_tree, node_id) do
                {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
                error -> error
              end
          end
      end
    end
  end

  # Try default multigoal method (IPyHOP pattern)
  defp try_default_multigoal_method(state, multigoal, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Planning: Trying default multigoal method")
    end

    try do
      # Use the default multigoal method from AriaCore
      result = AriaCore.DefaultMultigoalMethod.default_multigoal_method(state, multigoal)

      if verbose > 2 do
        Logger.debug("HTN Planning: Default multigoal method returned: #{inspect(result)}")
      end

      {:ok, result}
    rescue
      e ->
        if verbose > 1 do
          Logger.debug("HTN Planning: Default multigoal method raised exception: #{inspect(e)}")
        end
        {:error, "Default multigoal method failed: #{inspect(e)}"}
    end
  end

  # Check if all goals in a multigoal are satisfied
  defp all_multigoal_goals_satisfied?(state, multigoal) do
    Enum.all?(multigoal.goals, fn {predicate, subject, value} ->
      goal_satisfied?(state, predicate, subject, value)
    end)
  end

  # Try multigoal methods from domain (IPyHOP pattern)
  defp try_multigoal_methods(domain, state, multigoal, blacklisted_methods, opts) do
    case AriaCore.get_multigoal_methods_from_domain(domain) do
      methods when is_list(methods) and length(methods) > 0 ->
        # Try each method that isn't blacklisted
        available_methods = methods
        |> Enum.reject(fn {method_name, _} ->
          method_name_str = case method_name do
            atom when is_atom(atom) -> Atom.to_string(atom)
            string when is_binary(string) -> string
            other -> to_string(other)
          end
          method_name_str in blacklisted_methods
        end)

        try_multigoal_methods_sequentially(available_methods, state, multigoal, opts)

      _ ->
        {:error, "No multigoal methods found in domain"}
    end
  end

  # Try multigoal methods sequentially until one succeeds
  defp try_multigoal_methods_sequentially([], _state, _multigoal, _opts) do
    {:error, "No available multigoal methods"}
  end

  defp try_multigoal_methods_sequentially([{method_name, method_fn} | rest], state, multigoal, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Planning: Trying multigoal method #{inspect(method_name)}")
    end

    try do
      # Call multigoal method with state and complete multigoal object (IPyHOP pattern)
      result = method_fn.(state, multigoal)

      if verbose > 2 do
        Logger.debug("HTN Planning: Multigoal method #{inspect(method_name)} returned: #{inspect(result)}")
      end

      case result do
        subtasks when is_list(subtasks) ->
          {:ok, subtasks}
        {:ok, subtasks} when is_list(subtasks) ->
          {:ok, subtasks}
        {:error, reason} ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Multigoal method #{inspect(method_name)} failed: #{inspect(reason)}")
          end
          try_multigoal_methods_sequentially(rest, state, multigoal, opts)
        other ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Multigoal method #{inspect(method_name)} returned unexpected result: #{inspect(other)}")
          end
          try_multigoal_methods_sequentially(rest, state, multigoal, opts)
      end
    rescue
      e ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Multigoal method #{inspect(method_name)} raised exception: #{inspect(e)}")
        end
        try_multigoal_methods_sequentially(rest, state, multigoal, opts)
    end
  end
end
