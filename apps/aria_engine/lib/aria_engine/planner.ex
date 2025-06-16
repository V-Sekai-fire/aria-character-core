# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Planner do
  @moduledoc """
  STN-based temporal planner with HTN solution tree integration.

  This module provides a bridge between STN-based temporal planning and 
  IPyHOP-style hierarchical task network planning with solution trees.

  ## STN Bridge Architecture

  Non-temporal HTN operations (method selection, goal decomposition, blacklisting) are
  implemented as STN bridge actions - instantaneous decision points that separate
  temporal execution segments while maintaining constraint propagation.

  ## Features

  - IPyHOP-style HTN planning with solution trees
  - STN temporal constraint management
  - Bridge actions for non-temporal decisions
  - Reentrant planning from failure points
  - Run-Lazy-Refineahead execution with replanning
  - Goal-task network decomposition
  - Blacklisting and alternative method selection

  ## Bridge Action Types

  - **Method Selection**: Bridge between goal and selected method execution
  - **Goal Decomposition**: Bridge from composite goals to subgoal sequences
  - **Blacklist Check**: Bridge for alternative method selection on failure
  - **State Validation**: Bridge for precondition checking and state updates

  Example:
  ```elixir
  # Create domain with actions and methods
  domain = AriaEngine.Domain.new("example")
  |> AriaEngine.Domain.add_action(:move, &move_action/2)

  # Create initial state
  initial_state = AriaEngine.State.new()
  |> AriaEngine.State.set_object("location", "robot", "room1")

  # Create goals
  goals = [{"location", "robot", "room2"}]

  # Initial planning with temporal constraints
  case AriaEngine.Planner.plan(domain, initial_state, goals, [], 0) do
    {:ok, solution_tree} ->
      # Execute plan with replanning on failure
      AriaEngine.Planner.run_lazy_refineahead(domain, initial_state, solution_tree)
    {:error, reason} ->
      IO.puts("Planning failed: \#{reason}")
  end
  ```
  """

  alias AriaEngine.{Domain, State, Multigoal}
  alias AriaEngine.TemporalPlanner.{STNPlanner, STNMethod, STNAction}

  # Core planner types (maintained for compatibility)
  @type planner_opts :: keyword()
  @type planner_result :: {:ok, solution_tree()} | {:error, String.t()}
  @type execution_result :: {:ok, State.t()} | {:error, String.t()}
  @type replan_result :: {:ok, solution_tree()} | {:error, String.t()} | :failure

  # Domain interface types (maintained for compatibility)
  @type domain_interface :: %{
    actions: %{atom() => function()},
    task_methods: %{String.t() => [function()]},
    unigoal_methods: %{String.t() => [function()]},
    multigoal_methods: [function()]
  }

  # Solution tree types (core HTN planning)
  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), any()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}

  # Solution tree node structure (IPyHOP-style)
  @type node_id :: String.t()
  @type solution_node :: %{
    id: node_id(),
    task: todo_item(),
    parent_id: node_id() | nil,
    children_ids: [node_id()],
    state: State.t() | nil,
    visited: boolean(),
    expanded: boolean(),
    method_tried: String.t() | nil,
    blacklisted_methods: [String.t()],
    is_primitive: boolean()
  }

  @type solution_tree :: %{
    root_id: node_id(),
    nodes: %{node_id() => solution_node()},
    blacklisted_commands: MapSet.t(),
    goal_network: %{node_id() => [node_id()]}  # Goal-task network dependencies
  }

  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}

  @default_max_depth 100
  @default_verbose 0

  @doc """
  Plan goals using STN-based temporal planning with HTN bridge compatibility.

  This function maintains the original API while using STN bridges for non-temporal
  HTN operations and falls back to the original Plan module for actual planning
  while adding temporal validation through STN consistency checking.

  ## Parameters
  - `domain_interface`: Map containing actions and methods
  - `initial_state`: Starting state for planning
  - `goals`: List of goals to achieve
  - `opts`: Planning options (max_depth, verbose, etc.)
  - `current_time`: Optional current time for temporal planning (defaults to nil)

  ## Returns
  - `{:ok, solution_tree}`: Complete solution tree compatible with original API
  - `{:error, reason}`: Planning failure
  """
  @spec plan(domain_interface(), State.t(), [Plan.todo_item()], planner_opts(), integer() | nil) :: planner_result()
  def plan(domain_interface, %State{} = initial_state, goals, opts \\ [], current_time \\ nil) when is_list(goals) do
    set_logger_level_from_opts(opts)
    
    # Convert domain interface to Domain struct for compatibility
    domain = interface_to_domain(domain_interface)
    
    # Add temporal information to planning options if provided
    temporal_opts = if current_time do
      Keyword.put(opts, :current_time, current_time)
    else
      opts
    end

    # Use native solution tree implementation with STN bridge validation
    case plan_with_solution_tree(domain, initial_state, goals, temporal_opts) do
      {:ok, solution_tree} ->
        # Validate temporal consistency using STN bridges
        case validate_solution_with_stn_bridges(solution_tree, domain, current_time || 0) do
          :ok -> {:ok, solution_tree}
          {:error, reason} -> {:error, "Temporal validation failed: #{reason}"}
        end
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Execute a solution tree with Run-Lazy-Refineahead using STN temporal coordination.

  This maintains the original execution API while using STN for temporal validation
  and coordination during execution.
  """
  @spec execute(domain_interface(), State.t(), Plan.solution_tree(), planner_opts(), integer() | nil) :: execution_result()
  def execute(domain_interface, %State{} = initial_state, solution_tree, opts \\ [], current_time \\ nil) do
    set_logger_level_from_opts(opts)
    
    # Convert domain interface to Domain struct
    domain = interface_to_domain(domain_interface)
    
    # Add temporal information to execution options if provided
    temporal_opts = if current_time do
      Keyword.put(opts, :current_time, current_time)
    else
      opts
    end

    # Validate temporal consistency before execution
    case validate_solution_with_stn_bridges(solution_tree, domain, current_time || 0) do
      :ok ->
        # Use the existing Plan module for execution
        AriaEngine.Plan.run_lazy_refineahead(domain, initial_state, solution_tree, temporal_opts)
      
      {:error, reason} ->
        {:error, "Cannot execute temporally inconsistent plan: #{reason}"}
    end
  end

  @doc """
  Replan from a failure point using STN bridge-based replanning.

  Maintains the original replanning API while using STN bridges for method
  blacklisting and alternative selection.
  """
  @spec replan(domain_interface(), State.t(), Plan.solution_tree(), String.t(), planner_opts(), integer() | nil) :: replan_result()
  def replan(domain_interface, %State{} = current_state, solution_tree, fail_node_id, opts \\ [], current_time \\ nil) do
    set_logger_level_from_opts(opts)
    
    # Convert domain interface to Domain struct
    domain = interface_to_domain(domain_interface)
    
    # Add temporal information to replanning options if provided
    temporal_opts = if current_time do
      Keyword.put(opts, :current_time, current_time)
    else
      opts
    end

    # Use the existing Plan module for replanning with STN bridge support
    case AriaEngine.Plan.replan(domain, current_state, solution_tree, fail_node_id, temporal_opts) do
      {:ok, new_solution_tree} ->
        # Validate temporal consistency of new plan
        case validate_solution_with_stn_bridges(new_solution_tree, domain, current_time || 0) do
          :ok -> {:ok, new_solution_tree}
          {:error, reason} -> {:error, "Replanned solution is temporally inconsistent: #{reason}"}
        end
      
      {:error, reason} -> {:error, reason}
      :failure -> :failure
    end
  end

  @doc """
  Validate a plan against the domain and initial state using STN consistency checking.
  """
  @spec validate_plan(domain_interface(), State.t(), Plan.solution_tree()) ::
    {:ok, State.t()} | {:error, String.t()}
  def validate_plan(domain_interface, initial_state, solution_tree) do
    domain = interface_to_domain(domain_interface)
    
    # First validate using original Plan module
    case AriaEngine.Plan.validate_plan(domain, initial_state, solution_tree) do
      {:ok, final_state} ->
        # Additional STN temporal consistency validation
        case validate_solution_with_stn_bridges(solution_tree, domain, 0) do
          :ok -> {:ok, final_state}
          {:error, reason} -> {:error, "Temporal validation failed: #{reason}"}
        end
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Extract primitive actions from a solution tree (maintained for compatibility).
  """
  @spec extract_actions(Plan.solution_tree()) :: [Plan.plan_step()]
  def extract_actions(solution_tree) do
    AriaEngine.Plan.get_primitive_actions_dfs(solution_tree)
  end

  @doc """
  Get statistics about a solution tree (maintained for compatibility).
  """
  @spec tree_stats(Plan.solution_tree()) :: map()
  def tree_stats(solution_tree) do
    AriaEngine.Plan.tree_stats(solution_tree)
  end

  @doc """
  Calculate the cost (number of primitive actions) of a solution tree.
  """
  @spec plan_cost(Plan.solution_tree()) :: non_neg_integer()
  def plan_cost(solution_tree) do
    AriaEngine.Plan.plan_cost(solution_tree)
  end

  @doc """
  Create a domain interface from an AriaEngine.Domain struct (maintained for compatibility).
  """
  @spec domain_to_interface(Domain.t()) :: domain_interface()
  def domain_to_interface(%Domain{} = domain) do
    %{
      actions: domain.actions,
      task_methods: domain.task_methods,
      unigoal_methods: domain.unigoal_methods,
      multigoal_methods: domain.multigoal_methods
    }
  end

  ## Private STN Bridge Implementation

  # Validate solution tree using STN bridge-based temporal consistency checking
  @spec validate_solution_with_stn_bridges(Plan.solution_tree(), Domain.t(), integer()) :: 
    :ok | {:error, String.t()}
  defp validate_solution_with_stn_bridges(solution_tree, domain, current_time) do
    try do
      # Convert solution tree to STN methods with bridge actions
      stn_methods = solution_tree_to_stn_methods_with_bridges(solution_tree, domain, current_time)
      
      # Create STN planner for validation
      goal_id = "validation_#{:erlang.system_time(:millisecond)}"
      planner = STNPlanner.new(goal_id, :hierarchical, methods: stn_methods)
      
      # Check temporal consistency
      if STNPlanner.consistent?(planner) do
        :ok
      else
        {:error, "STN temporal constraints are inconsistent"}
      end
    rescue
      e -> {:error, "STN validation error: #{Exception.message(e)}"}
    end
  end

  # Convert solution tree to STN methods with bridge actions for validation
  @spec solution_tree_to_stn_methods_with_bridges(Plan.solution_tree(), Domain.t(), integer()) :: [STNMethod.t()]
  defp solution_tree_to_stn_methods_with_bridges(solution_tree, domain, current_time) do
    # Extract primitive actions from solution tree
    primitive_actions = AriaEngine.Plan.get_primitive_actions_dfs(solution_tree)
    
    # Group actions into temporal segments separated by bridge actions
    action_segments = group_actions_into_temporal_segments(primitive_actions)
    
    # Convert each segment to STN method with bridges
    action_segments
    |> Enum.with_index()
    |> Enum.map(fn {segment, index} ->
      create_stn_method_with_bridges(segment, index, domain, current_time)
    end)
  end

  # Group primitive actions into temporal segments
  @spec group_actions_into_temporal_segments([Plan.plan_step()]) :: [[Plan.plan_step()]]
  defp group_actions_into_temporal_segments(primitive_actions) do
    # For now, treat each action as its own segment with bridge separation
    # This creates maximum temporal flexibility
    Enum.map(primitive_actions, fn action -> [action] end)
  end

  # Create STN method with bridge actions for a segment of primitive actions
  @spec create_stn_method_with_bridges([Plan.plan_step()], integer(), Domain.t(), integer()) :: STNMethod.t()
  defp create_stn_method_with_bridges(action_segment, segment_index, domain, current_time) do
    method_id = "segment_#{segment_index}"
    
    # Create bridge actions for HTN operations
    bridge_actions = [
      # Method selection bridge
      %{
        action_id: "select_method_#{method_id}",
        type: :decision,
        duration: :instantaneous,
        metadata: %{
          htn_operation: :method_selection,
          segment_index: segment_index,
          timestamp: current_time
        }
      },
      # State validation bridge
      %{
        action_id: "validate_state_#{method_id}",
        type: :condition,
        duration: :instantaneous,
        metadata: %{
          htn_operation: :state_validation,
          segment_index: segment_index,
          timestamp: current_time
        }
      }
    ]
    
    # Create temporal STN actions for primitive actions
    stn_actions = action_segment
    |> Enum.with_index()
    |> Enum.map(fn {{action_name, args}, action_index} ->
      create_temporal_stn_action_from_primitive(action_name, args, segment_index, action_index, domain)
    end)
    
    # Create method with sequential decomposition (maintains original execution order)
    STNMethod.new(method_id, :sequential, stn_actions,
      bridge_actions: bridge_actions,
      metadata: %{
        segment_index: segment_index,
        primitive_actions: action_segment,
        domain_name: domain.name
      }
    )
  end

  # Create temporal STN action from primitive action
  @spec create_temporal_stn_action_from_primitive(atom(), list(), integer(), integer(), Domain.t()) :: STNAction.t()
  defp create_temporal_stn_action_from_primitive(action_name, args, segment_index, action_index, domain) do
    action_id = "#{action_name}_#{segment_index}_#{action_index}"
    
    # Determine duration based on action metadata or use default
    duration = get_action_duration(action_name, domain)
    
    STNAction.new(action_id,
      duration: duration,
      preconditions: [],
      effects: [],
      metadata: %{
        primitive_action: {action_name, args},
        segment_index: segment_index,
        action_index: action_index,
        domain_action: true
      }
    )
  end

  # Get action duration from domain or use default
  @spec get_action_duration(atom(), Domain.t()) :: {integer(), integer()}
  defp get_action_duration(action_name, domain) do
    # Check if domain has temporal metadata for this action
    case Map.get(domain.actions, action_name) do
      nil -> {1, 5}  # Default duration range
      _action_fn ->
        # For now, use default duration
        # TODO: Extract actual duration constraints from action metadata
        {1, 5}
    end
  end

  ## Core solution tree planning functions migrated from AriaEngine.Plan

  @doc """
  Create a solution tree from todos and execute it with replanning on failure.

  This implements the Run-Lazy-Refineahead algorithm from the IPyHOP paper.
  """
  @spec plan_with_solution_tree(Domain.t(), State.t(), [todo_item()], keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  def plan_with_solution_tree(%Domain{} = domain, %State{} = state, todos, opts \\ []) do
    # Create initial solution tree with goal-task network
    solution_tree = create_initial_solution_tree(todos, state)
    
    # Run IPyHOP algorithm
    ipyhop(domain, state, solution_tree, opts)
  end

  @doc """
  Replan from a specific failure node in the solution tree.
  """
  @spec replan_solution_tree(Domain.t(), State.t(), solution_tree(), node_id(), keyword()) :: 
    {:ok, solution_tree()} | {:error, String.t()} | :failure
  def replan_solution_tree(%Domain{} = domain, %State{} = state, solution_tree, fail_node_id, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)

    if verbose > 2 do
      IO.puts("Replanning from failure node: #{fail_node_id}")
    end

    # Find the task node that produced this action (walk up the tree)
    case find_responsible_task_node(solution_tree, fail_node_id, verbose) do
      nil ->
        {:error, "Could not find responsible task node for failed action"}

      task_node_id ->
        if verbose > 2 do
          IO.puts("Found responsible task node: #{task_node_id}")
        end

        # Update cached states to current execution state
        updated_tree = update_cached_states(solution_tree, state)

        # Try alternative method for the responsible task
        case try_alternative_method_for_task(updated_tree, task_node_id, verbose) do
          {:ok, new_tree} ->
            # Resume planning from the updated tree
            ipyhop(domain, state, new_tree, opts)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Blacklist a command to prevent it from being tried again.
  """
  @spec blacklist_command(solution_tree(), todo_item()) :: solution_tree()
  def blacklist_command(solution_tree, command) do
    %{solution_tree |
      blacklisted_commands: MapSet.put(solution_tree.blacklisted_commands, command)
    }
  end

  @doc """
  Run-Lazy-Refineahead: Execute plan with replanning on failure.
  """
  @spec run_lazy_refineahead(Domain.t(), State.t(), solution_tree(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()}
  def run_lazy_refineahead(%Domain{} = domain, %State{} = initial_state, solution_tree, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)

    if verbose > 2 do
      IO.puts("Starting Run-Lazy-Refineahead execution")
    end

    # Initialize execution state
    current_state = initial_state
    current_tree = solution_tree

    # Main execution loop
    run_execution_loop(domain, current_state, current_tree, opts)
  end

  # Core IPyHOP Algorithm implementation
  @spec ipyhop(Domain.t(), State.t(), solution_tree(), keyword()) :: 
    {:ok, solution_tree()} | {:error, String.t()}
  defp ipyhop(%Domain{} = domain, %State{} = current_state, solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)
    max_depth = Keyword.get(opts, :max_depth, @default_max_depth)

    # IPyHOP main loop
    ipyhop_loop(domain, current_state, solution_tree, 0, max_depth, verbose)
  end

  # IPyHOP main loop implementation
  @spec ipyhop_loop(Domain.t(), State.t(), solution_tree(), integer(), integer(), integer()) :: 
    {:ok, solution_tree()} | {:error, String.t()}
  defp ipyhop_loop(%Domain{} = domain, current_state, solution_tree, depth, max_depth, verbose) do
    if depth >= max_depth do
      {:error, "Maximum planning depth exceeded"}
    else
      # Find next unexpanded node
      case find_next_node(solution_tree) do
        nil ->
          # All nodes expanded - check if solution is complete
          if solution_complete?(solution_tree) do
            {:ok, solution_tree}
          else
            {:error, "No complete solution found"}
          end

        node_id ->
          # Try to expand this node
          case try_expand_node(domain, current_state, solution_tree, node_id, verbose) do
            {:ok, new_tree} ->
              ipyhop_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)

            {:error, reason} ->
              {:error, reason}

            :failure ->
              # Backtrack and try alternatives
              case backtrack_and_retry(domain, current_state, solution_tree, node_id, depth, max_depth, verbose) do
                {:ok, new_tree} ->
                  ipyhop_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)

                {:error, reason} ->
                  {:error, reason}
              end
          end
      end
    end
  end

  # Create initial solution tree
  @spec create_initial_solution_tree([todo_item()], State.t()) :: solution_tree()
  defp create_initial_solution_tree(todos, initial_state) do
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
      is_primitive: false
    }

    %{
      root_id: root_id,
      nodes: %{root_id => root_node},
      blacklisted_commands: MapSet.new(),
      goal_network: %{}
    }
  end

  # Find next unexpanded node using depth-first search
  @spec find_next_node(solution_tree()) :: node_id() | nil
  defp find_next_node(solution_tree) do
    find_next_node_dfs(solution_tree, solution_tree.root_id)
  end

  @spec find_next_node_dfs(solution_tree(), node_id()) :: node_id() | nil
  defp find_next_node_dfs(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil -> nil
      
      node ->
        cond do
          not node.expanded and not node.is_primitive ->
            # This node needs expansion
            node_id
            
          node.children_ids == [] ->
            # Leaf node - no children to explore
            nil
            
          true ->
            # Search children
            Enum.find_value(node.children_ids, fn child_id ->
              find_next_node_dfs(solution_tree, child_id)
            end)
        end
    end
  end

  # Try to expand a specific node
  @spec try_expand_node(Domain.t(), State.t(), solution_tree(), node_id(), integer()) :: 
    {:ok, solution_tree()} | {:error, String.t()} | :failure
  defp try_expand_node(domain, state, solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}
        
      node ->
        case node.task do
          {:root, todos} ->
            expand_root_node(solution_tree, node_id, todos, state)
            
          {task_name, args} when is_binary(task_name) ->
            expand_task_node(domain, state, solution_tree, node_id, task_name, args, verbose)
            
          {predicate, subject, object} ->
            expand_goal_node(domain, state, solution_tree, node_id, predicate, subject, object, verbose)
            
          %Multigoal{} = multigoal ->
            expand_multigoal_node(domain, state, solution_tree, node_id, multigoal, verbose)
            
          _ ->
            {:error, "Unknown task type: #{inspect(node.task)}"}
        end
    end
  end

  # Expand root node with todos
  @spec expand_root_node(solution_tree(), node_id(), [todo_item()], State.t()) :: {:ok, solution_tree()}
  defp expand_root_node(solution_tree, root_id, todos, state) do
    # Create child nodes for each todo
    {child_nodes, child_ids} = 
      Enum.map_reduce(todos, [], fn todo, acc_ids ->
        child_id = generate_node_id()
        
        child_node = %{
          id: child_id,
          task: todo,
          parent_id: root_id,
          children_ids: [],
          state: state,
          visited: false,
          expanded: false,
          method_tried: nil,
          blacklisted_methods: [],
          is_primitive: false
        }
        
        {child_node, [child_id | acc_ids]}
      end)
    
    child_ids = Enum.reverse(child_ids)
    
    # Update solution tree
    updated_nodes = 
      child_nodes
      |> Enum.reduce(solution_tree.nodes, fn child_node, acc ->
        Map.put(acc, child_node.id, child_node)
      end)
      |> Map.update!(root_id, fn root_node ->
        %{root_node | children_ids: child_ids, expanded: true}
      end)
    
    {:ok, %{solution_tree | nodes: updated_nodes}}
  end

  # Expand task node with methods
  @spec expand_task_node(Domain.t(), State.t(), solution_tree(), node_id(), String.t(), list(), integer()) :: 
    {:ok, solution_tree()} | {:error, String.t()} | :failure
  defp expand_task_node(domain, state, solution_tree, node_id, task_name, args, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}
        
      node ->
        # Get available methods for this task
        available_methods = Domain.get_task_methods(domain, task_name)

        # Filter out blacklisted methods
        usable_methods = Enum.reject(available_methods, fn method_name ->
          Enum.member?(node.blacklisted_methods, method_name)
        end)
        
        case usable_methods do
          [] ->
            if verbose > 2 do
              IO.puts("No usable methods for task: #{task_name}")
            end
            :failure
            
          [method | _] ->
            # Try first available method
            case method do
              nil ->
                {:error, "Method not found: #{inspect(method)}"}
                
              method_fn ->
                # Apply method to get subtasks
                case apply_method_to_task(method_fn, args, verbose) do
                  {:ok, subtasks} ->
                    # Decomposed into subtasks
                    new_tree =
                      create_subtask_nodes(solution_tree, node_id, subtasks, method)

                    {:ok, new_tree}
                    
                  {:error, reason} ->
                    # Blacklist this method and try next
                    blacklisted_node = %{node | blacklisted_methods: [method | node.blacklisted_methods]}
                    updated_tree = %{solution_tree | nodes: Map.put(solution_tree.nodes, node_id, blacklisted_node)}
                    
                    if verbose > 2 do
                      IO.puts("Method #{method} failed: #{reason}")
                    end
                    
                    expand_task_node(domain, state, updated_tree, node_id, task_name, args, verbose)
                end
            end
        end
    end
  end

  # Expand goal node
  @spec expand_goal_node(Domain.t(), State.t(), solution_tree(), node_id(), String.t(), String.t(), any(), integer()) :: 
    {:ok, solution_tree()} | {:error, String.t()} | :failure
  defp expand_goal_node(domain, state, solution_tree, node_id, predicate, subject, object, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}
        
      node ->
        # Check if goal is already satisfied
        if State.matches?(state, predicate, subject, object) do
          # Goal already satisfied - mark as primitive (no action needed)
          mark_as_primitive(solution_tree, node_id)
        else
          # Find methods that can achieve this goal
          goal_methods = Domain.get_goal_methods(domain, predicate)
          
          # Filter out blacklisted methods
          usable_methods = Enum.reject(goal_methods, fn method_name ->
            Enum.member?(node.blacklisted_methods, method_name)
          end)
          
          case usable_methods do
            [] ->
              if verbose > 2 do
                IO.puts("No usable methods for goal: #{predicate} #{subject} #{object}")
              end
              :failure
              
            [method_name | _] ->
              case Domain.get_method(domain, method_name) do
                nil ->
                  {:error, "Method not found: #{method_name}"}
                  
                method_fn ->
                  # Apply method to get subtasks
                  case apply_method_to_goal(method_fn, predicate, subject, object, verbose) do
                    {:ok, subtasks} ->
                      # Decomposed into subtasks
                      new_tree =
                        create_subtask_nodes(solution_tree, node_id, subtasks, method_name)

                      {:ok, new_tree}

                    {:error, reason} ->
                      # Blacklist this method and try next
                      blacklisted_node = %{node | blacklisted_methods: [method_name | node.blacklisted_methods]}
                      updated_tree = %{solution_tree | nodes: Map.put(solution_tree.nodes, node_id, blacklisted_node)}
                      
                      if verbose > 2 do
                        IO.puts("Method #{method_name} failed for goal: #{reason}")
                      end
                      
                      expand_goal_node(domain, state, updated_tree, node_id, predicate, subject, object, verbose)
                  end
              end
          end
        end
    end
  end

  # Expand multigoal node
  @spec expand_multigoal_node(Domain.t(), State.t(), solution_tree(), node_id(), Multigoal.t(), integer()) :: 
    {:ok, solution_tree()}
  defp expand_multigoal_node(_domain, _state, solution_tree, node_id, multigoal, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}
        
      _node ->
        # Extract individual goals from multigoal
        individual_goals = Multigoal.to_goals(multigoal)
        
        if verbose > 2 do
          IO.puts("Expanding multigoal with #{length(individual_goals)} individual goals")
        end
        
        # Create child nodes for each individual goal
        create_subtask_nodes(solution_tree, node_id, individual_goals, "multigoal_expansion")
    end
  end

  # Create subtask nodes for a parent
  @spec create_subtask_nodes(solution_tree(), node_id(), [todo_item()], String.t()) :: {:ok, solution_tree()}
  defp create_subtask_nodes(solution_tree, parent_id, subtasks, method_name) do
    parent_node = solution_tree.nodes[parent_id]
    
    # Create child nodes for subtasks
    {child_nodes, child_ids} = 
      Enum.map_reduce(subtasks, [], fn subtask, acc_ids ->
        child_id = generate_node_id()
        
        child_node = %{
          id: child_id,
          task: subtask,
          parent_id: parent_id,
          children_ids: [],
          state: parent_node.state,
          visited: false,
          expanded: false,
          method_tried: nil,
          blacklisted_methods: [],
          is_primitive: false
        }
        
        {child_node, [child_id | acc_ids]}
      end)
    
    child_ids = Enum.reverse(child_ids)
    
    # Update solution tree
    updated_nodes = 
      child_nodes
      |> Enum.reduce(solution_tree.nodes, fn child_node, acc ->
        Map.put(acc, child_node.id, child_node)
      end)
      |> Map.update!(parent_id, fn parent_node ->
        %{parent_node | children_ids: child_ids, expanded: true, method_tried: method_name}
      end)
    
    {:ok, %{solution_tree | nodes: updated_nodes}}
  end

  # Mark node as primitive (leaf action)
  @spec mark_as_primitive(solution_tree(), node_id()) :: {:ok, solution_tree()}
  defp mark_as_primitive(solution_tree, node_id) do
    updated_nodes = Map.update!(solution_tree.nodes, node_id, fn node ->
      %{node | is_primitive: true, expanded: true}
    end)
    
    {:ok, %{solution_tree | nodes: updated_nodes}}
  end

  # Check if solution is complete
  @spec solution_complete?(solution_tree()) :: boolean()
  defp solution_complete?(solution_tree) do
    # All leaf nodes must be primitive (actions)
    solution_tree.nodes
    |> Map.values()
    |> Enum.filter(fn node -> node.children_ids == [] end)  # Leaf nodes
    |> Enum.all?(fn node -> node.is_primitive end)
  end

  # Backtrack and try alternatives
  @spec backtrack_and_retry(Domain.t(), State.t(), solution_tree(), node_id(), integer(), integer(), integer()) :: 
    {:ok, solution_tree()} | {:error, String.t()}
  defp backtrack_and_retry(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose) do
    if verbose > 2 do
      IO.puts("Backtracking from failed node: #{failed_node_id}")
    end
    
    case find_backtrack_point(solution_tree, failed_node_id, verbose) do
      nil ->
        {:error, "No backtrack point available"}
        
      parent_id ->
        case backtrack_to_alternative_method(solution_tree, parent_id, failed_node_id, verbose) do
          {:ok, new_tree} ->
            ipyhop_loop(domain, state, new_tree, depth, max_depth, verbose)
            
          :no_alternatives ->
            # Continue backtracking up the tree
            case solution_tree.nodes[parent_id] do
              nil -> {:error, "Parent node not found"}
              parent_node -> 
                backtrack_and_retry(domain, state, solution_tree, parent_node.parent_id, depth, max_depth, verbose)
            end
        end
    end
  end

  # Find a good backtrack point
  @spec find_backtrack_point(solution_tree(), node_id(), integer()) :: node_id() | nil
  defp find_backtrack_point(solution_tree, failed_node_id, verbose) do
    case solution_tree.nodes[failed_node_id] do
      nil -> nil
      node -> 
        if verbose > 2 do
          IO.puts("Looking for backtrack point from: #{failed_node_id}")
        end
        node.parent_id
    end
  end

  # Try alternative method at backtrack point
  @spec backtrack_to_alternative_method(solution_tree(), node_id(), node_id(), integer()) :: 
    {:ok, solution_tree()} | {:error, String.t()}
  defp backtrack_to_alternative_method(solution_tree, parent_id, _failed_child_id, verbose) do
    case solution_tree.nodes[parent_id] do
      nil ->
        {:error, "Parent node not found: #{parent_id}"}
        
      parent_node ->
        # Remove children and mark as unexpanded to try different method
        cleared_parent = %{parent_node | 
          children_ids: [], 
          expanded: false,
          blacklisted_methods: case parent_node.method_tried do
            nil -> parent_node.blacklisted_methods
            method -> [method | parent_node.blacklisted_methods]
          end,
          method_tried: nil
        }
        
        # Remove child nodes from tree
        updated_nodes = 
          parent_node.children_ids
          |> Enum.reduce(solution_tree.nodes, fn child_id, acc ->
            remove_subtree(acc, child_id)
          end)
          |> Map.put(parent_id, cleared_parent)
        
        if verbose > 2 do
          IO.puts("Cleared children of node #{parent_id} for alternative method")
        end
        
        {:ok, %{solution_tree | nodes: updated_nodes}}
    end
  end

  # Remove entire subtree rooted at node_id
  @spec remove_subtree(map(), node_id()) :: map()
  defp remove_subtree(nodes, node_id) do
    case nodes[node_id] do
      nil -> nodes
      node ->
        # Recursively remove children
        updated_nodes = 
          Enum.reduce(node.children_ids, nodes, fn child_id, acc ->
            remove_subtree(acc, child_id)
          end)
        
        # Remove this node
        Map.delete(updated_nodes, node_id)
    end
  end

  # Helper functions for method application
  @spec apply_method_to_task(function(), list(), integer()) :: {:ok, [todo_item()]} | {:error, String.t()}
  defp apply_method_to_task(method_fn, args, verbose) do
    try do
      case method_fn.(args) do
        {:ok, subtasks} -> {:ok, subtasks}
        subtasks when is_list(subtasks) -> {:ok, subtasks}
        error -> {:error, "Method returned: #{inspect(error)}"}
      end
    rescue
      error -> 
        if verbose > 2 do
          IO.puts("Method application failed: #{inspect(error)}")
        end
        {:error, "Method exception: #{inspect(error)}"}
    end
  end

  @spec apply_method_to_goal(function(), String.t(), String.t(), any(), integer()) :: 
    {:ok, [todo_item()]} | {:error, String.t()}
  defp apply_method_to_goal(method_fn, predicate, subject, object, verbose) do
    try do
      case method_fn.(predicate, subject, object) do
        {:ok, subtasks} -> {:ok, subtasks}
        subtasks when is_list(subtasks) -> {:ok, subtasks}
        error -> {:error, "Method returned: #{inspect(error)}"}
      end
    rescue
      error -> 
        if verbose > 2 do
          IO.puts("Goal method application failed: #{inspect(error)}")
        end
        {:error, "Method exception: #{inspect(error)}"}
    end
  end

  # Find the task node responsible for producing a failed action
  @spec find_responsible_task_node(solution_tree(), node_id(), integer()) :: node_id() | nil
  defp find_responsible_task_node(solution_tree, fail_node_id, verbose) do
    case solution_tree.nodes[fail_node_id] do
      nil ->
        nil

      node ->
        # Walk up the tree to find a task node (not a primitive action)
        find_parent_task_node(solution_tree, node.parent_id, verbose)
    end
  end

  # Recursively find the first parent that is a task node (not primitive)
  @spec find_parent_task_node(solution_tree(), nil, integer()) :: nil
  defp find_parent_task_node(_solution_tree, nil, _verbose), do: nil

  @spec find_parent_task_node(solution_tree(), node_id(), integer()) :: node_id() | nil
  defp find_parent_task_node(solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil -> nil

      node ->
        case node.task do
          {task_name, _args} when is_binary(task_name) ->
            # This is a task node - this is what we're looking for
            if verbose > 2 do
              IO.puts("Found task node: #{node_id} with task: #{task_name}")
            end
            node_id

          {:root, _} ->
            # Skip root node, continue searching
            find_parent_task_node(solution_tree, node.parent_id, verbose)

          _ ->
            # Goal or other node type, continue searching
            find_parent_task_node(solution_tree, node.parent_id, verbose)
        end
    end
  end

  # Try alternative method for a specific task node
  @spec try_alternative_method_for_task(solution_tree(), node_id(), integer()) :: 
    {:ok, solution_tree()} | {:error, String.t()}
  defp try_alternative_method_for_task(solution_tree, task_node_id, verbose) do
    case solution_tree.nodes[task_node_id] do
      nil ->
        {:error, "Task node not found: #{task_node_id}"}

      node ->
        case node.task do
          {task_name, _args} when is_binary(task_name) ->
            # Clear the node's children and blacklist the current method
            cleared_node = %{node |
              children_ids: [],
              expanded: false,
              blacklisted_methods: case node.method_tried do
                nil -> node.blacklisted_methods
                method -> [method | node.blacklisted_methods]
              end,
              method_tried: nil
            }

            # Remove child nodes from tree
            updated_nodes = 
              node.children_ids
              |> Enum.reduce(solution_tree.nodes, fn child_id, acc ->
                remove_subtree(acc, child_id)
              end)
              |> Map.put(task_node_id, cleared_node)

            if verbose > 2 do
              IO.puts("Prepared task node #{task_node_id} for alternative method")
            end

            {:ok, %{solution_tree | nodes: updated_nodes}}

          _ ->
            {:error, "Node is not a task: #{inspect(node.task)}"}
        end
    end
  end

  # Update cached states in solution tree
  @spec update_cached_states(solution_tree(), State.t()) :: solution_tree()
  defp update_cached_states(solution_tree, current_state) do
    # For now, just update the root state
    # In a more sophisticated implementation, we'd update states throughout the tree
    updated_nodes = Map.update!(solution_tree.nodes, solution_tree.root_id, fn root_node ->
      %{root_node | state: current_state}
    end)
    
    %{solution_tree | nodes: updated_nodes}
  end

  # Main execution loop for Run-Lazy-Refineahead
  @spec run_execution_loop(Domain.t(), State.t(), solution_tree(), keyword()) :: 
    {:ok, State.t()} | {:error, String.t()}
  defp run_execution_loop(domain, current_state, current_tree, opts) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)
    
    case get_next_primitive_action(current_tree) do
      nil ->
        # No more actions to execute
        {:ok, current_state}
        
      {action_node_id, action_name, action_args} ->
        if verbose > 2 do
          IO.puts("Executing action: #{action_name} with args: #{inspect(action_args)}")
        end
        
        # Try to execute the action
        case Domain.execute_action(domain, current_state, action_name, action_args) do
          {:ok, new_state} ->
            # Action succeeded - continue with next action
            updated_tree = mark_action_completed(current_tree, action_node_id)
            run_execution_loop(domain, new_state, updated_tree, opts)
            
          {:error, reason} ->
            if verbose > 2 do
              IO.puts("Action failed: #{reason}")
            end
            
            # Action failed - try to replan
            case replan_solution_tree(domain, current_state, current_tree, action_node_id, opts) do
              {:ok, new_tree} ->
                run_execution_loop(domain, current_state, new_tree, opts)
                
              {:error, replan_reason} ->
                {:error, "Execution failed: #{reason}, replanning failed: #{replan_reason}"}
            end
        end
    end
  end

  # Get next primitive action to execute
  @spec get_next_primitive_action(solution_tree()) :: {node_id(), atom(), list()} | nil
  defp get_next_primitive_action(solution_tree) do
    get_next_primitive_action_dfs(solution_tree, solution_tree.root_id)
  end

  @spec get_next_primitive_action_dfs(solution_tree(), node_id()) :: {node_id(), atom(), list()} | nil
  defp get_next_primitive_action_dfs(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil -> nil
      
      node ->
        cond do
          node.is_primitive and node.task != {:root, []} ->
            # This is a primitive action
            case node.task do
              {action_name, args} -> {node_id, action_name, args}
              _ -> nil
            end
            
          node.children_ids == [] ->
            # Leaf node but not primitive - shouldn't happen in a complete plan
            nil
            
          true ->
            # Search children in order
            Enum.find_value(node.children_ids, fn child_id ->
              get_next_primitive_action_dfs(solution_tree, child_id)
            end)
        end
    end
  end

  # Mark action as completed in the solution tree
  @spec mark_action_completed(solution_tree(), node_id()) :: solution_tree()
  defp mark_action_completed(solution_tree, action_node_id) do
    updated_nodes = Map.update!(solution_tree.nodes, action_node_id, fn node ->
      %{node | visited: true}
    end)
    
    %{solution_tree | nodes: updated_nodes}
  end

  # Generate unique node ID
  @spec generate_node_id() :: String.t()
  defp generate_node_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  ## Helper Functions (maintained for compatibility)

  # Convert domain interface to Domain struct
  @spec interface_to_domain(domain_interface()) :: Domain.t()
  defp interface_to_domain(interface) do
    %Domain{
      name: "stn_bridge_domain",
      actions: Map.get(interface, :actions, %{}),
      task_methods: Map.get(interface, :task_methods, %{}),
      unigoal_methods: Map.get(interface, :unigoal_methods, %{}),
      multigoal_methods: Map.get(interface, :multigoal_methods, [])
    }
  end

  # Set Logger level from opts (internal planner verbosity)
  @spec set_logger_level_from_opts(keyword()) :: :ok
  defp set_logger_level_from_opts(opts) do
    cond do
      Keyword.has_key?(opts, :log_level) ->
        Logger.configure(level: Keyword.get(opts, :log_level))
      Keyword.get(opts, :verbose, false) ->
        Logger.configure(level: :debug)
      true ->
        Logger.configure(level: :info)
    end
  end
end
