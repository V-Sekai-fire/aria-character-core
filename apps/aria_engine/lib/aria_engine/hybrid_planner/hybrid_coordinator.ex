# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.HybridPlanner.HybridCoordinator do
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
  
      domain = AriaEngine.Domain.new("example")
      initial_state = AriaEngine.StateV2.new()
      goals = [{"location", "robot", "room2"}]
      
      case AriaEngine.HybridPlanner.HybridCoordinator.plan(domain, initial_state, goals) do
        {:ok, encapsulated_plan} ->
          AriaEngine.HybridPlanner.HybridCoordinator.execute(domain, initial_state, encapsulated_plan)
        {:error, error_reason} ->
          IO.puts("Planning failed: \#{error_reason}")
      end
  """

  alias AriaEngine.{StateV2, Domain}
  alias AriaEngine.HybridPlanner.DataStructures
  alias AriaEngine.HybridPlanner.DataStructures.{EncapsulatedPlan, PlanningContext}
  alias AriaEngine.HybridPlanner.StrategyCoordinator

  require Logger

  # Public API types
  @type plan_result :: {:ok, EncapsulatedPlan.t()} | {:error, String.t()}
  @type execution_result :: {:ok, StateV2.t()} | {:error, String.t()}
  @type replan_result :: {:ok, EncapsulatedPlan.t()} | {:error, String.t()} | :failure

  # ==================== PUBLIC API ====================

  @doc """
  Plan goals using coordinated HTN planning with STN temporal validation.
  
  Returns an encapsulated plan that hides all internal complexity.
  Uses Function as Object pattern for maximum flexibility.
  """
  @spec plan(Domain.Core.t(), StateV2.t(), [term()], keyword()) :: plan_result()
  def plan(domain, %StateV2{} = state, goals, opts \\ []) do
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
  @spec execute(Domain.Core.t(), StateV2.t(), EncapsulatedPlan.t(), keyword()) :: execution_result()
  def execute(domain, %StateV2{} = state, %EncapsulatedPlan{} = encapsulated_plan, opts \\ []) do
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
  @spec replan(Domain.Core.t(), StateV2.t(), EncapsulatedPlan.t(), String.t(), keyword()) :: replan_result()
  def replan(domain, %StateV2{} = state, %EncapsulatedPlan{} = plan, fail_node_id, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    
    if verbose > 0 do
      Logger.info("HybridCoordinator: Starting coordinated replanning from failure point #{fail_node_id}")
    end

    # Get strategy coordinator 
    coordinator = get_strategy_coordinator(opts)
    
    # Extract internal plan for replanning
    internal_plan = EncapsulatedPlan.get_internal_plan(plan)
    
    # Use Plan.replan for actual replanning, then validate with strategy coordinator
    case AriaEngine.Plan.replan(domain, state, internal_plan, fail_node_id, opts) do
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
  @spec validate_plan(Domain.Core.t(), StateV2.t(), EncapsulatedPlan.t()) :: 
    {:ok, StateV2.t()} | {:error, String.t()}
  def validate_plan(domain, %StateV2{} = initial_state, %EncapsulatedPlan{} = encapsulated_plan) do
    # Use both planning and temporal validation
    internal_plan = EncapsulatedPlan.get_internal_plan(encapsulated_plan)
    
    case AriaEngine.Plan.validate_plan(domain, initial_state, internal_plan) do
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
    
    alias AriaEngine.{Plan, Domain, StateV2}
    alias AriaEngine.HybridPlanner.DataStructures.{EncapsulatedPlan, PlanningContext}
    
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
    defp decompose_task(_domain, _task, _state) do
      # Future: Private task decomposition logic
      {:error, "Not implemented"}
    end

    defp select_method(_domain, _task_name, _args, _state) do
      # Future: Private method selection logic
      {:error, "Not implemented"}
    end

    defp build_solution_tree(_decomposed_tasks) do
      # Future: Private solution tree building
      {:error, "Not implemented"}
    end
  end

  defmodule TemporalEngine do
    @moduledoc false  # Hide from documentation
    
    alias AriaEngine.{Domain, Plan}
    alias AriaEngine.TemporalPlanner.{STNPlanner, STNMethod, STNAction}
    alias AriaEngine.HybridPlanner.DataStructures.PlanningContext
    
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
      primitive_actions = Plan.Utils.get_primitive_actions_dfs(solution_tree)
      
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
        %{duration: %AriaEngine.Timeline.Interval{} = interval} ->
          # If duration is an Interval struct, use its duration_ms as fixed min/max
          fixed_duration = AriaEngine.Timeline.Interval.duration_ms(interval)
          {fixed_duration, fixed_duration}
        %{duration: {min, max}} when is_integer(min) and is_integer(max) and min <= max ->
          # If duration is a {min, max} tuple, use it directly
          {min, max}
        _ ->
          # Default duration if not specified or invalid
          {1, 5}
      end
    end

    defp build_constraint_network(_plan, _domain) do
      # Future: Private constraint network building
      {:error, "Not implemented"}
    end

    defp check_stn_consistency(_constraints) do
      # Future: Private STN consistency checking
      {:error, "Not implemented"}
    end
  end

  defmodule ExecutionEngine do
    @moduledoc false  # Hide from documentation
    
    alias AriaEngine.{Plan, StateV2}
    alias AriaEngine.HybridPlanner.DataStructures.{EncapsulatedPlan, PlanningContext}
    
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
    defp execute_action(_domain, _state, _action) do
      # Future: Private action execution logic
      {:error, "Not implemented"}
    end

    defp handle_execution_failure(_domain, _state, _plan, _failure) do
      # Future: Private execution failure handling
      {:error, "Not implemented"}
    end
  end
end
