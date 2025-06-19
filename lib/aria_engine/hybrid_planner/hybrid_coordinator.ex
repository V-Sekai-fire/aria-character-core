# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinator do
  @moduledoc """
  Public API for hybrid goal task reentrant temporal planning.
  
  Coordinates HTN planning with STN temporal validation through
  private, encapsulated engines. All planning, temporal reasoning,
  and execution logic is hidden behind clean public interfaces.
  
  ## Features
  
  - Encapsulated HTN planning engine
  - Private STN temporal validation
  - Coordinated execution with replanning
  - Clean public API with opaque data structures
  
  ## Usage
  
      domain = Domain.new("example")
      initial_state = StateV2.new()
      goals = [{"location", "robot", "room2"}]
      
      case HybridPlanner.HybridCoordinator.plan(domain, initial_state, goals) do
        {:ok, encapsulated_plan} ->
          HybridPlanner.HybridCoordinator.execute(domain, initial_state, encapsulated_plan)
        {:error, error_reason} ->
          Logger.error("Planning failed: \#{error_reason}")
      end
  """

  alias HybridPlanner.DataStructures.{EncapsulatedPlan, PlanningContext}
  alias HybridPlanner.StrategyCoordinator

  require Logger

  # Public API types
  @type plan_result :: {:ok, EncapsulatedPlan.t()} | {:error, String.t()}
  @type execution_result :: {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  @type replan_result :: {:ok, EncapsulatedPlan.t()} | {:error, String.t()} | :failure

  # ==================== PUBLIC API ====================

  @doc """
  Plan goals using coordinated HTN planning with STN temporal validation.
  
  Returns an encapsulated plan that hides all internal complexity.
  Uses Function as Object pattern for maximum flexibility.
  """
  @spec plan(Domain.Core.t(), AriaEngine.StateV2.t(), [term()], keyword()) :: plan_result()
  def plan(domain, %AriaEngine.StateV2{} = state, goals, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    
    if verbose > 0 do
      Logger.info("HybridCoordinator: Starting coordinated planning for #{length(goals)} goals")
    end

    # Get strategy coordinator based on options
    coordinator = get_strategy_coordinator(opts)
    
    # Use Function as Object composition for planning and validation
    case StrategyCoordinator.plan_only(coordinator, domain, state, goals, opts) do
      {:ok, validated_plan} ->
        if verbose > 0 do
          Logger.info("HybridCoordinator: Planning and temporal validation completed successfully")
        end
        
        {:ok, EncapsulatedPlan.new_validated(validated_plan, %{
          goals: goals,
          planning_time: DateTime.utc_now(),
          domain_name: domain.name,
          strategy_coordinator: coordinator.metadata
        })}
      
      {:error, reason} -> 
        Logger.warning("HybridCoordinator: Planning failed - #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Execute an encapsulated plan with coordinated replanning on failure.
  Uses Function as Object pattern for strategy-based execution.
  """
  @spec execute(Domain.Core.t(), AriaEngine.StateV2.t(), EncapsulatedPlan.t(), keyword()) :: execution_result()
  def execute(domain, %AriaEngine.StateV2{} = state, %EncapsulatedPlan{} = encapsulated_plan, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    
    if verbose > 0 do
      Logger.info("HybridCoordinator: Starting coordinated execution")
    end

    # Get strategy coordinator based on options or plan metadata
    coordinator = get_strategy_coordinator(opts)
    
    # Ensure plan is temporally validated before execution
    case EncapsulatedPlan.temporally_validated?(encapsulated_plan) do
      true ->
        # Extract internal plan and execute with strategy coordinator
        internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
        StrategyCoordinator.execute_only(coordinator, domain, state, internal_plan, opts)
      
      false ->
        # Re-validate before execution using strategy coordinator
        internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
        
        case coordinator.temporal_fn.(internal_plan, domain, opts) do
          {:ok, validated_plan} ->
            StrategyCoordinator.execute_only(coordinator, domain, state, validated_plan, opts)
          {:error, reason} ->
            {:error, "Cannot execute temporally invalid plan: #{reason}"}
        end
    end
  end

  @doc """
  Replan from a failure point using coordinated HTN replanning with temporal validation.
  Uses Function as Object pattern for strategy-based replanning.
  """
  @spec replan(Domain.Core.t(), AriaEngine.StateV2.t(), EncapsulatedPlan.t(), String.t(), keyword()) :: replan_result()
  def replan(domain, %AriaEngine.StateV2{} = state, %EncapsulatedPlan{} = plan, fail_node_id, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    
    if verbose > 0 do
      Logger.info("HybridCoordinator: Starting coordinated replanning from failure point #{fail_node_id}")
    end

    # Get strategy coordinator 
    coordinator = get_strategy_coordinator(opts)
    
    # Extract internal plan for replanning
    internal_plan = EncapsulatedPlan.get_internal_plan(plan)
    
    # Use Plan.replan for actual replanning, then validate with strategy coordinator
    case AriaEngine.PlannerAdapter.replan(domain, state, internal_plan, fail_node_id, opts) do
      {:ok, new_htn_plan} ->
        # Validate using strategy coordinator's temporal function
        case coordinator.temporal_fn.(new_htn_plan, domain, opts) do
          {:ok, validated_plan} ->
            original_metadata = EncapsulatedPlan.get_metadata(plan)
            replan_metadata = Map.put(original_metadata, :replanned_at, DateTime.utc_now())
            |> Map.put(:original_fail_node, fail_node_id)
            |> Map.put(:strategy_coordinator, coordinator.metadata)
            
            {:ok, EncapsulatedPlan.new_validated(validated_plan, replan_metadata)}
          
          {:error, reason} -> {:error, "Temporal validation failed during replanning: #{reason}"}
        end
      
      {:error, reason} -> {:error, reason}
      :failure -> :failure
    end
  end

  @doc """
  Validate a plan against the domain and initial state using coordinated validation.
  Uses Function as Object pattern for strategy-based validation.
  """
  @spec validate_plan(Domain.Core.t(), AriaEngine.StateV2.t(), EncapsulatedPlan.t()) :: 
    {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  def validate_plan(domain, %AriaEngine.StateV2{} = initial_state, %EncapsulatedPlan{} = encapsulated_plan) do
    # Use both planning and temporal validation
    internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
    
    case AriaEngine.PlannerAdapter.validate_plan(domain, initial_state, internal_plan) do
      {:ok, final_state} ->
        # Additional temporal consistency validation using strategy coordinator
        coordinator = get_strategy_coordinator([])
        case coordinator.temporal_fn.(internal_plan, domain, []) do
          {:ok, _validated_plan} -> {:ok, final_state}
          {:error, reason} -> {:error, "Temporal validation failed: #{reason}"}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  # ==================== STRATEGY COORDINATOR UTILITIES ====================

  @doc """
  Get a strategy coordinator based on options.
  
  This demonstrates Function as Object flexibility - strategy selection can be 
  completely dynamic based on problem characteristics or user preferences.
  """
  @spec get_strategy_coordinator(keyword()) :: StrategyCoordinator.t()
  def get_strategy_coordinator(opts) do
    case Keyword.get(opts, :strategy, :hybrid_htn_stn) do
      :hybrid_htn_stn -> 
        StrategyCoordinator.hybrid_htn_stn()
      
      :pure_strips -> 
        StrategyCoordinator.pure_strips()
      
      :reactive -> 
        StrategyCoordinator.reactive_planner()
      
      %StrategyCoordinator{} = custom_coordinator -> 
        custom_coordinator
      
      {planning_fn, temporal_fn, execution_fn} when is_function(planning_fn) and is_function(temporal_fn) and is_function(execution_fn) ->
        StrategyCoordinator.new(planning_fn, temporal_fn, execution_fn, %{custom: true})
      
      config when is_map(config) ->
        case StrategyCoordinator.from_config(config) do
          {:ok, coordinator} -> coordinator
          {:error, _reason} -> StrategyCoordinator.hybrid_htn_stn()  # Fallback
        end
      
      _ -> 
        StrategyCoordinator.hybrid_htn_stn()  # Default fallback
    end
  end

  @doc """
  Demonstrate runtime strategy selection based on problem characteristics.
  
  Pure Function as Object - strategies are selected and composed at runtime.
  """
  @spec adaptive_strategy_selection(Domain.Core.t(), [term()], keyword()) :: StrategyCoordinator.t()
  def adaptive_strategy_selection(domain, goals, opts \\ []) do
    # Analyze problem characteristics
    problem_analysis = %{
      goal_count: length(goals),
      domain_complexity: analyze_domain_complexity(domain),
      temporal_requirements: has_temporal_requirements?(domain),
      performance_priority: Keyword.get(opts, :performance_priority, :balanced)
    }
    
    # Select strategy based on analysis
    case problem_analysis do
      %{goal_count: n, temporal_requirements: false} when n <= 3 ->
        StrategyCoordinator.pure_strips()
      
      %{temporal_requirements: true, performance_priority: :speed} ->
        StrategyCoordinator.reactive_planner()
      
      %{domain_complexity: :high, temporal_requirements: true} ->
        # Custom high-performance coordinator with middleware
        coordinator = StrategyCoordinator.hybrid_htn_stn()
        
        # Add middleware for complex problems
        middleware = [
          StrategyCoordinator.logging_middleware("Complex HTN+STN"),
          StrategyCoordinator.timeout_middleware(30_000)  # 30 second timeout
        ]
        
        %{coordinator | middleware: middleware}
      
      _ ->
        StrategyCoordinator.hybrid_htn_stn()  # Default
    end
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Analyze domain complexity for adaptive strategy selection
  defp analyze_domain_complexity(domain) do
    action_count = map_size(domain.actions)
    method_count = Enum.reduce([domain.task_methods, domain.unigoal_methods], 0, fn methods, acc ->
      acc + map_size(methods)
    end)
    
    total_complexity = action_count + method_count
    
    cond do
      total_complexity > 20 -> :high
      total_complexity > 10 -> :medium
      true -> :low
    end
  end

  # Check if domain has temporal requirements
  defp has_temporal_requirements?(domain) do
    # Check if any actions have duration specifications
    Enum.any?(domain.actions, fn {action_name, _action_fn} ->
      case Domain.get_action_metadata(domain, action_name) do
        %{duration: _duration} -> true
        _ -> false
      end
    end)
  end

  # ==================== PRIVATE NESTED ENGINES ====================

  defmodule PlanningEngine do
    @moduledoc false  # Hide from documentation
    
    alias HybridPlanner.DataStructures.{EncapsulatedPlan, PlanningContext}
    
    require Logger

    @doc false
    def plan(domain, state, goals, context) do
      verbose = PlanningContext.get_verbose_level(context)
      opts = PlanningContext.get_options(context)
      
      if verbose > 1 do
        Logger.debug("PlanningEngine: Starting HTN planning for #{length(goals)} goals")
      end

      # Delegate to existing Plan.Core but with clean interface
      case Plan.plan(domain, state, goals, opts) do
        {:ok, solution_tree} ->
          if verbose > 1 do
            Logger.debug("PlanningEngine: HTN planning completed successfully")
          end
          {:ok, solution_tree}
        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("PlanningEngine: HTN planning failed - #{reason}")
          end
          {:error, reason}
      end
    end

    @doc false
    def replan(domain, state, encapsulated_plan, fail_node_id, context) do
      verbose = PlanningContext.get_verbose_level(context)
      opts = PlanningContext.get_options(context)
      
      if verbose > 1 do
        Logger.debug("PlanningEngine: Starting HTN replanning from node #{fail_node_id}")
      end

      # Extract internal plan from encapsulated structure
      internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
      
      case Plan.replan(domain, state, internal_plan, fail_node_id, opts) do
        {:ok, new_solution_tree} ->
          if verbose > 1 do
            Logger.debug("PlanningEngine: HTN replanning completed successfully")
          end
          {:ok, new_solution_tree}
        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("PlanningEngine: HTN replanning failed - #{reason}")
          end
          {:error, reason}
        :failure ->
          if verbose > 0 do
            Logger.warning("PlanningEngine: HTN replanning returned failure")
          end
          :failure
      end
    end

    # All other HTN operations stay private here
    
    @doc false
    def decompose_task(domain, {task_name, args}, state) do
      case Domain.get_task_methods(domain, task_name) do
        [] -> {:error, "No methods found for task #{task_name}"}
        methods ->
          # Try each method until one succeeds
          try_methods(methods, args, state, domain)
      end
    end

    @doc false
    def select_method(domain, task_name, args, state) do
      case Domain.get_task_methods(domain, task_name) do
        [] -> {:error, "No methods available for task #{task_name}"}
        methods ->
          # Select first applicable method (can be enhanced with cost-based selection)
          case find_applicable_method(methods, args, state, domain) do
            {:ok, method} -> {:ok, method}
            :no_applicable -> {:error, "No applicable methods for task #{task_name} with args #{inspect(args)}"}
          end
      end
    end

    @doc false
    def build_solution_tree(decomposed_tasks) when is_list(decomposed_tasks) do
      try do
        # Build hierarchical solution tree from decomposed tasks
        root_node = %{
          node_id: "root_#{:erlang.system_time(:millisecond)}",
          task: {:root, []},
          status: :composite,
          children: [],
          parent: nil,
          depth: 0
        }
        
        case build_tree_recursive(decomposed_tasks, root_node, 1) do
          {:ok, completed_tree} -> {:ok, completed_tree}
          {:error, reason} -> {:error, "Failed to build solution tree: #{reason}"}
        end
      rescue
        e -> {:error, "Solution tree construction error: #{Exception.message(e)}"}
      end
    end
    
    # Private helper functions for HTN operations
    
    defp try_methods([], _args, _state, _domain), do: {:error, "All methods failed"}
    defp try_methods([{method_name, method_fn} | rest], args, state, domain) do
      case apply_method_safely(method_fn, args, state) do
        {:ok, decomposition} -> {:ok, {method_name, decomposition}}
        {:error, _reason} -> try_methods(rest, args, state, domain)
      end
    end
    
    defp find_applicable_method([], _args, _state, _domain), do: :no_applicable
    defp find_applicable_method([{method_name, method_fn} | rest], args, state, domain) do
      case check_method_preconditions(method_fn, args, state) do
        true -> {:ok, {method_name, method_fn}}
        false -> find_applicable_method(rest, args, state, domain)
      end
    end
    
    defp apply_method_safely(method_fn, args, state) do
      try do
        case method_fn.(args, state) do
          result when is_list(result) -> {:ok, result}
          {:ok, result} -> {:ok, result}
          {:error, reason} -> {:error, reason}
          _ -> {:error, "Invalid method return format"}
        end
      rescue
        e -> {:error, "Method execution failed: #{Exception.message(e)}"}
      end
    end
    
    defp check_method_preconditions(method_fn, args, state) do
      # Simple precondition check - method should not immediately fail
      case apply_method_safely(method_fn, args, state) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end
    
    defp build_tree_recursive([], parent_node, _depth), do: {:ok, parent_node}
    defp build_tree_recursive([task | rest], parent_node, depth) do
      child_node = %{
        node_id: "node_#{:erlang.system_time(:millisecond)}_#{depth}",
        task: task,
        status: determine_task_status(task),
        children: [],
        parent: parent_node.node_id,
        depth: depth
      }
      
      updated_parent = %{parent_node | children: parent_node.children ++ [child_node]}
      build_tree_recursive(rest, updated_parent, depth)
    end
    
    defp determine_task_status({_task_name, _args}), do: :composite
    defp determine_task_status([_action_name | _args]), do: :primitive
    defp determine_task_status(_), do: :unknown
  end

  defmodule TemporalEngine do
    @moduledoc false  # Hide from documentation
    
    alias TemporalPlanner.{STNPlanner, STNMethod, STNAction}
    alias HybridPlanner.DataStructures.PlanningContext
    
    require Logger

    @doc false
    def validate(plan, domain, context) do
      verbose = PlanningContext.get_verbose_level(context)
      opts = PlanningContext.get_options(context)
      current_time = Keyword.get(opts, :current_time, 0)
      
      if verbose > 1 do
        Logger.debug("TemporalEngine: Starting STN temporal validation")
      end

      case validate_temporal_consistency(plan, domain, current_time) do
        :ok ->
          if verbose > 1 do
            Logger.debug("TemporalEngine: STN temporal validation completed successfully")
          end
          {:ok, plan}
        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("TemporalEngine: STN temporal validation failed - #{reason}")
          end
          {:error, "Temporal validation failed: #{reason}"}
      end
    end

    # All STN operations stay private here
    defp validate_temporal_consistency(plan, domain, current_time) do
      try do
        # Convert solution tree to STN methods with bridge actions
        stn_methods = solution_tree_to_stn_methods_with_bridges(plan, domain, current_time)
        
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

    defp solution_tree_to_stn_methods_with_bridges(solution_tree, domain, current_time) do
      # Extract primitive actions from solution tree
      primitive_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
      
      # Group actions into temporal segments separated by bridge actions
      action_segments = group_actions_into_temporal_segments(primitive_actions)
      
      # Convert each segment to STN method with bridges
      action_segments
      |> Enum.with_index()
      |> Enum.map(fn {segment, index} ->
        create_stn_method_with_bridges(segment, index, domain, current_time)
      end)
    end

    defp group_actions_into_temporal_segments(primitive_actions) do
      # For now, treat each action as its own segment with bridge separation
      # This creates maximum temporal flexibility
      Enum.map(primitive_actions, fn action -> [action] end)
    end

    defp create_stn_method_with_bridges(action_segment, segment_index, domain, current_time) do
      method_id = "segment_#{segment_index}"
      
      # Create bridge actions for HTN operations
      bridge_actions = [
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

    defp get_action_duration(action_name, domain) do
      case Domain.get_action_metadata(domain, action_name) do
        %{duration: %Timeline.Interval{} = interval} ->
          # If duration is an Interval struct, use its duration_ms as fixed min/max
          fixed_duration = Timeline.Interval.duration_ms(interval)
          {fixed_duration, fixed_duration}
        %{duration: {min, max}} when is_integer(min) and is_integer(max) and min <= max ->
          # If duration is a {min, max} tuple, use it directly
          {min, max}
        _ ->
          # Default duration if not specified or invalid
          {1, 5}
      end
    end

  end

  defmodule ExecutionEngine do
    @moduledoc false  # Hide from documentation
    
    alias HybridPlanner.DataStructures.{EncapsulatedPlan, PlanningContext}
    
    require Logger

    @doc false
    def execute(domain, state, encapsulated_plan, context) do
      verbose = PlanningContext.get_verbose_level(context)
      opts = PlanningContext.get_options(context)
      
      if verbose > 1 do
        Logger.debug("ExecutionEngine: Starting plan execution")
      end

      # Extract internal plan and execute
      internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
      
      case Plan.run_lazy_refineahead(domain, state, internal_plan, opts) do
        {:ok, final_state} ->
          if verbose > 1 do
            Logger.debug("ExecutionEngine: Plan execution completed successfully")
          end
          {:ok, final_state}
        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("ExecutionEngine: Plan execution failed - #{reason}")
          end
          {:error, reason}
      end
    end

    # All execution operations stay private here
    
    @doc false
    def execute_action(domain, state, action) do
      try do
        case action do
          {action_name, args} when is_atom(action_name) ->
            # Get action function from domain
            case Map.get(domain.actions, action_name) do
              nil -> {:error, "Action #{action_name} not found in domain"}
              action_fn when is_function(action_fn) ->
                # Execute action with state and arguments
                case apply_action_safely(action_fn, args, state) do
                  %AriaEngine.StateV2{} = new_state -> {:ok, new_state}
                  {:ok, new_state} -> {:ok, new_state}
                  {:error, reason} -> {:error, "Action execution failed: #{reason}"}
                  _ -> {:error, "Action returned invalid state format"}
                end
            end
          _ -> {:error, "Invalid action format: #{inspect(action)}"}
        end
      rescue
        e -> {:error, "Action execution error: #{Exception.message(e)}"}
      end
    end

    @doc false
    def handle_execution_failure(domain, state, encapsulated_plan, failure_info) do
      try do
        case failure_info do
          %{type: :action_failure, node_id: node_id, reason: reason} ->
            # Attempt replanning from failure point
            case HybridPlanner.HybridCoordinator.replan(domain, state, encapsulated_plan, node_id, []) do
              {:ok, new_plan} -> 
                {:replan, new_plan}
              {:error, replan_reason} -> 
                {:error, "Replanning failed: #{replan_reason}. Original failure: #{reason}"}
              :failure -> 
                {:failure, "Could not recover from action failure: #{reason}"}
            end
          
          %{type: :temporal_violation, constraints: constraints} ->
            # Handle temporal constraint violations
            {:error, "Temporal constraint violation: #{inspect(constraints)}"}
          
          %{type: :state_inconsistency, expected: expected, actual: actual} ->
            # Handle state inconsistencies
            {:error, "State inconsistency - expected: #{inspect(expected)}, actual: #{inspect(actual)}"}
          
          _ ->
            {:error, "Unknown failure type: #{inspect(failure_info)}"}
        end
      rescue
        e -> {:error, "Failure handling error: #{Exception.message(e)}"}
      end
    end
    
    # Private helper functions for execution
    
    defp apply_action_safely(action_fn, args, state) do
      try do
        case action_fn.(args, state) do
          %AriaEngine.StateV2{} = new_state -> new_state
          {:ok, new_state} -> new_state
          {:error, reason} -> {:error, reason}
          result -> {:error, "Action returned unexpected format: #{inspect(result)}"}
        end
      rescue
        e -> {:error, "Action function failed: #{Exception.message(e)}"}
      end
    end
  end

  defmodule BacktrackingEngine do
    @moduledoc false  # Hide from documentation
    
    alias HybridPlanner.DataStructures.{EncapsulatedPlan, PlanningContext}
    
    require Logger

    @doc false
    def replan_with_backtracking(domain, state, encapsulated_plan, fail_node_id, context) do
      verbose = PlanningContext.get_verbose_level(context)
      opts = PlanningContext.get_options(context)
      
      if verbose > 1 do
        Logger.debug("BacktrackingEngine: Starting backtracking replanning from node #{fail_node_id}")
      end

      # Extract internal plan for backtracking
      internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
      
      # Use sophisticated backtracking with blacklisting
      case backtrack_with_alternatives(domain, state, internal_plan, fail_node_id, opts) do
        {:ok, new_solution_tree} ->
          if verbose > 1 do
            Logger.debug("BacktrackingEngine: Backtracking replanning completed successfully")
          end
          {:ok, new_solution_tree}
        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("BacktrackingEngine: Backtracking replanning failed - #{reason}")
          end
          {:error, reason}
        :failure ->
          if verbose > 0 do
            Logger.warning("BacktrackingEngine: All backtracking alternatives exhausted")
          end
          :failure
      end
    end

    @doc false
    def find_failure_ancestors(solution_tree, fail_node_id) do
      # Find all ancestor nodes that could be replanned
      case find_node_in_tree(solution_tree, fail_node_id) do
        nil -> []
        node -> collect_ancestors(solution_tree, node, [])
      end
    end

    # Private backtracking functions
    
    defp backtrack_with_alternatives(domain, state, solution_tree, fail_node_id, opts) do
      # Get potential backtrack points (ancestors of failed node)
      backtrack_candidates = find_failure_ancestors(solution_tree, fail_node_id)
      
      # Try replanning from each ancestor, starting from closest
      try_backtrack_candidates(domain, state, solution_tree, backtrack_candidates, opts)
    end
    
    defp try_backtrack_candidates(_domain, _state, _tree, [], _opts), do: :failure
    defp try_backtrack_candidates(domain, state, solution_tree, [candidate | rest], opts) do
      case Plan.replan(domain, state, solution_tree, candidate.node_id, opts) do
        {:ok, new_tree} -> {:ok, new_tree}
        {:error, _reason} -> try_backtrack_candidates(domain, state, solution_tree, rest, opts)
        :failure -> try_backtrack_candidates(domain, state, solution_tree, rest, opts)
      end
    end
    
    defp find_node_in_tree(node, target_id) when is_map(node) do
      case node do
        %{node_id: ^target_id} -> node
        %{children: children} when is_list(children) ->
          Enum.find_value(children, fn child -> find_node_in_tree(child, target_id) end)
        _ -> nil
      end
    end
    defp find_node_in_tree(_tree, _target_id), do: nil
    
    defp collect_ancestors(tree, target_node, acc) do
      case Map.get(target_node, :parent) do
        nil -> acc
        parent_id ->
          case find_node_in_tree(tree, parent_id) do
            nil -> acc
            parent_node -> collect_ancestors(tree, parent_node, [parent_node | acc])
          end
      end
    end
  end

  defmodule ValidationEngine do
    @moduledoc false  # Hide from documentation
    
    alias HybridPlanner.DataStructures.{EncapsulatedPlan, PlanningContext}
    
    require Logger

    @doc false
    def validate_encapsulated_plan(domain, initial_state, encapsulated_plan, context) do
      verbose = PlanningContext.get_verbose_level(context)
      
      if verbose > 1 do
        Logger.debug("ValidationEngine: Starting comprehensive plan validation")
      end

      # Extract internal plan for validation
      internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
      
      # Multi-stage validation
      with {:ok, _} <- validate_plan_structure(internal_plan),
           {:ok, _} <- validate_plan_actions(domain, internal_plan),
           {:ok, final_state} <- validate_plan_execution(domain, initial_state, internal_plan) do
        if verbose > 1 do
          Logger.debug("ValidationEngine: Plan validation completed successfully")
        end
        {:ok, final_state}
      else
        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("ValidationEngine: Plan validation failed - #{reason}")
          end
          {:error, reason}
      end
    end

    @doc false
    def calculate_plan_metrics(encapsulated_plan) do
      internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
      
      %{
        total_actions: count_primitive_actions(internal_plan),
        tree_depth: calculate_tree_depth(internal_plan, 0),
        branching_factor: calculate_branching_factor(internal_plan),
        estimated_cost: estimate_execution_cost(internal_plan),
        complexity_score: calculate_complexity_score(internal_plan)
      }
    end

    # Private validation functions
    
    defp validate_plan_structure(solution_tree) do
      case solution_tree do
        %{node_id: _id, task: _task} -> {:ok, :valid_structure}
        _ -> {:error, "Invalid solution tree structure"}
      end
    end
    
    defp validate_plan_actions(domain, solution_tree) do
      primitive_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
      
      case validate_all_actions_exist(domain, primitive_actions) do
        [] -> {:ok, :all_actions_valid}
        missing_actions -> {:error, "Missing actions in domain: #{inspect(missing_actions)}"}
      end
    end
    
    defp validate_plan_execution(domain, initial_state, solution_tree) do
      # Use existing Plan validation but with error handling
      case Plan.validate_plan(domain, initial_state, solution_tree) do
        {:ok, final_state} -> {:ok, final_state}
        {:error, reason} -> {:error, "Execution validation failed: #{reason}"}
      end
    end
    
    defp validate_all_actions_exist(domain, primitive_actions) do
      primitive_actions
      |> Enum.map(fn {action_name, _args} -> action_name end)
      |> Enum.uniq()
      |> Enum.filter(fn action_name -> not Map.has_key?(domain.actions, action_name) end)
    end
    
    defp count_primitive_actions(solution_tree) do
      AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree) |> length()
    end
    
    defp calculate_tree_depth(node, current_depth) when is_map(node) do
      case Map.get(node, :children, []) do
        [] -> current_depth
        children ->
          children
          |> Enum.map(fn child -> calculate_tree_depth(child, current_depth + 1) end)
          |> Enum.max()
      end
    end
    defp calculate_tree_depth(_node, current_depth), do: current_depth
    
    defp calculate_branching_factor(node) when is_map(node) do
      children = Map.get(node, :children, [])
      child_counts = Enum.map(children, &calculate_branching_factor/1)
      
      case child_counts do
        [] -> 0
        counts -> (length(children) + Enum.sum(counts)) / (length(counts) + 1)
      end
    end
    defp calculate_branching_factor(_node), do: 0
    
    defp estimate_execution_cost(solution_tree) do
      # Simple cost estimation based on action count
      # Can be enhanced with domain-specific cost functions
      AriaEngine.Plan.Utils.plan_cost(solution_tree)
    end
    
    defp calculate_complexity_score(solution_tree) do
      depth = calculate_tree_depth(solution_tree, 0)
      actions = count_primitive_actions(solution_tree)
      branching = calculate_branching_factor(solution_tree)
      
      # Weighted complexity score
      depth * 2 + actions + branching * 3
    end
  end

  defmodule BlacklistingEngine do
    @moduledoc false  # Hide from documentation
    
    alias HybridPlanner.DataStructures.{EncapsulatedPlan, PlanningContext}
    
    require Logger

    @doc false
    def blacklist_failed_command(encapsulated_plan, failed_command, context) do
      verbose = PlanningContext.get_verbose_level(context)
      
      if verbose > 1 do
        Logger.debug("BlacklistingEngine: Blacklisting failed command #{inspect(failed_command)}")
      end

      # Extract internal plan and apply blacklisting
      internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
      
      # Use existing Plan blacklisting functionality
      blacklisted_plan = Plan.blacklist_command(internal_plan, failed_command)
      
      # Create new encapsulated plan with blacklisting metadata
      original_metadata = EncapsulatedPlan.get_metadata(encapsulated_plan)
      
      updated_metadata = Map.update(original_metadata, :blacklisted_commands, [failed_command], fn existing ->
        [failed_command | existing] |> Enum.uniq()
      end)
      |> Map.put(:blacklisted_at, DateTime.utc_now())
      
      new_encapsulated_plan = EncapsulatedPlan.new(blacklisted_plan, updated_metadata)
      
      if verbose > 1 do
        Logger.debug("BlacklistingEngine: Command blacklisting completed")
      end
      
      {:ok, new_encapsulated_plan}
    end

    @doc false
    def get_blacklisted_commands(encapsulated_plan) do
      metadata = EncapsulatedPlan.get_metadata(encapsulated_plan)
      Map.get(metadata, :blacklisted_commands, [])
    end

    @doc false
    def clear_blacklist(encapsulated_plan) do
      metadata = EncapsulatedPlan.get_metadata(encapsulated_plan)
      
      cleared_metadata = Map.delete(metadata, :blacklisted_commands)
      |> Map.delete(:blacklisted_at)
      |> Map.put(:blacklist_cleared_at, DateTime.utc_now())
      
      internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
      EncapsulatedPlan.new(internal_plan, cleared_metadata)
    end

    @doc false
    def is_command_blacklisted?(encapsulated_plan, command) do
      blacklisted_commands = get_blacklisted_commands(encapsulated_plan)
      Enum.member?(blacklisted_commands, command)
    end
  end
end
