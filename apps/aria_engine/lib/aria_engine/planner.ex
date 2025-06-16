# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Planner do
  @moduledoc """
  STN-based temporal planner with backward compatibility for IPyHOP-style HTN planning.

  This module provides a bridge between the original AriaEngine.Planner API and the new
  STN-based temporal planner. All original features are maintained using STN bridge actions:

  - IPyHOP-style HTN planning with solution trees
  - Reentrant planning from failure points
  - Run-Lazy-Refineahead execution with replanning
  - Goal-task network decomposition
  - Blacklisting and alternative method selection

  ## STN Bridge Architecture

  Non-temporal HTN operations (method selection, goal decomposition, blacklisting) are
  implemented as STN bridge actions - instantaneous decision points that separate
  temporal execution segments while maintaining constraint propagation.

  ## Bridge Action Types

  - **Method Selection**: Bridge between goal and selected method execution
  - **Goal Decomposition**: Bridge from composite goals to subgoal sequences
  - **Blacklist Check**: Bridge for alternative method selection on failure
  - **State Validation**: Bridge for precondition checking and state updates
  """

  alias AriaEngine.{Domain, State, Plan}
  alias AriaEngine.TemporalPlanner.{STNPlanner, STNMethod, STNAction}

  # Core planner types (maintained for compatibility)
  @type planner_opts :: keyword()
  @type planner_result :: {:ok, Plan.solution_tree()} | {:error, String.t()}
  @type execution_result :: {:ok, State.t()} | {:error, String.t()}
  @type replan_result :: {:ok, Plan.solution_tree()} | {:error, String.t()} | :failure

  # Domain interface types (maintained for compatibility)
  @type domain_interface :: %{
    actions: %{atom() => function()},
    task_methods: %{String.t() => [function()]},
    unigoal_methods: %{String.t() => [function()]},
    multigoal_methods: [function()]
  }

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

    # Use the existing Plan module for actual planning with STN bridge validation
    case Plan.plan(domain, initial_state, goals, temporal_opts) do
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
        Plan.run_lazy_refineahead(domain, initial_state, solution_tree, temporal_opts)
      
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
    case Plan.replan(domain, current_state, solution_tree, fail_node_id, temporal_opts) do
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
    case Plan.validate_plan(domain, initial_state, solution_tree) do
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
    Plan.get_primitive_actions_dfs(solution_tree)
  end

  @doc """
  Get statistics about a solution tree (maintained for compatibility).
  """
  @spec tree_stats(Plan.solution_tree()) :: map()
  def tree_stats(solution_tree) do
    Plan.tree_stats(solution_tree)
  end

  @doc """
  Calculate the cost (number of primitive actions) of a solution tree.
  """
  @spec plan_cost(Plan.solution_tree()) :: non_neg_integer()
  def plan_cost(solution_tree) do
    Plan.plan_cost(solution_tree)
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
    primitive_actions = Plan.get_primitive_actions_dfs(solution_tree)
    
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
