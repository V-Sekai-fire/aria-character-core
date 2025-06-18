# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.StrategyRegistry do
  @moduledoc """
  Registry of planning strategy functions that can be composed at runtime.
  
  Pure Function as Object implementation following Martin Fowler's pattern.
  All strategies are functions that can be stored, passed around, and composed
  without requiring complex object hierarchies.
  
  ## Function Signatures
  
  All strategy functions follow consistent signatures for composability:
  
  - Planning strategies: `(Domain.t(), StateV2.t(), [term()], keyword()) -> {:ok, term()} | {:error, String.t()}`
  - Temporal strategies: `(term(), Domain.t(), keyword()) -> {:ok, term()} | {:error, String.t()}`
  - Execution strategies: `(Domain.t(), StateV2.t(), term(), keyword()) -> {:ok, StateV2.t()} | {:error, String.t()}`
  
  ## Usage
  
      strategies = StrategyRegistry.default_strategies()
      planning_fn = strategies.planning.htn
      temporal_fn = strategies.temporal.stn
      execution_fn = strategies.execution.lazy
      
      # Compose them in a coordinator
      coordinator = StrategyCoordinator.new(planning_fn, temporal_fn, execution_fn)
  """

  alias TemporalPlanner.{STNPlanner, STNMethod, STNAction}

  # Strategy function type definitions
  @type planning_strategy :: (Domain.Core.t(), StateV2.t(), [term()], keyword() -> {:ok, term()} | {:error, String.t()})
  @type temporal_strategy :: (term(), Domain.Core.t(), keyword() -> {:ok, term()} | {:error, String.t()})
  @type execution_strategy :: (Domain.Core.t(), StateV2.t(), term(), keyword() -> {:ok, StateV2.t()} | {:error, String.t()})

  @type strategy_map :: %{
    planning: %{atom() => planning_strategy()},
    temporal: %{atom() => temporal_strategy()},
    execution: %{atom() => execution_strategy()}
  }

  @doc """
  Get the default registry of strategy functions.
  
  Returns a map of strategy categories, each containing named function strategies.
  """
  @spec default_strategies() :: strategy_map()
  def default_strategies() do
    %{
      planning: %{
        htn: &htn_planning_strategy/4,
        strips: &strips_planning_strategy/4,
        reactive: &reactive_planning_strategy/4
      },
      temporal: %{
        stn: &stn_temporal_strategy/3,
        csp: &csp_temporal_strategy/3,
        none: &no_temporal_strategy/3
      },
      execution: %{
        lazy: &lazy_execution_strategy/4,
        eager: &eager_execution_strategy/4,
        streaming: &streaming_execution_strategy/4
      }
    }
  end

  @doc """
  Register a custom strategy function.
  """
  @spec register_strategy(strategy_map(), atom(), atom(), function()) :: strategy_map()
  def register_strategy(strategies, category, name, strategy_fn) do
    put_in(strategies, [category, name], strategy_fn)
  end

  @doc """
  Get a specific strategy function by category and name.
  """
  @spec get_strategy(strategy_map(), atom(), atom()) :: {:ok, function()} | {:error, String.t()}
  def get_strategy(strategies, category, name) do
    case get_in(strategies, [category, name]) do
      nil -> {:error, "Strategy #{category}.#{name} not found"}
      strategy_fn -> {:ok, strategy_fn}
    end
  end

  @doc """
  Create a function pipeline for enhanced strategy composition.
  """
  @spec create_pipeline([function()]) :: function()
  def create_pipeline(functions) when is_list(functions) do
    fn input ->
      Enum.reduce_while(functions, {:ok, input}, fn func, {:ok, acc} ->
        case func.(acc) do
          {:ok, result} -> {:cont, {:ok, result}}
          error -> {:halt, error}
        end
      end)
    end
  end

  # ==================== PLANNING STRATEGIES ====================

  @doc false
  def htn_planning_strategy(domain, state, goals, opts) do
    # Delegate to existing HTN implementation
    Plan.plan(domain, state, goals, opts)
  end

  @doc false
  def strips_planning_strategy(domain, state, goals, opts) do
    # Future: STRIPS implementation
    # For now, delegate to HTN but could be replaced with actual STRIPS planner
    Plan.plan(domain, state, goals, opts)
  end

  @doc false
  def reactive_planning_strategy(domain, state, goals, opts) do
    # Future: Reactive planning implementation
    # For now, delegate to HTN
    Plan.plan(domain, state, goals, opts)
  end

  # ==================== TEMPORAL STRATEGIES ====================

  @doc false
  def stn_temporal_strategy(plan, domain, opts) do
    current_time = Keyword.get(opts, :current_time, 0)
    
    try do
      # Convert solution tree to STN methods with bridge actions
      stn_methods = solution_tree_to_stn_methods_with_bridges(plan, domain, current_time)
      
      # Create STN planner for validation
      goal_id = "validation_#{:erlang.system_time(:millisecond)}"
      planner = STNPlanner.new(goal_id, :hierarchical, methods: stn_methods)
      
      # Check temporal consistency
      if STNPlanner.consistent?(planner) do
        {:ok, plan}
      else
        {:error, "STN temporal constraints are inconsistent"}
      end
    rescue
      e -> {:error, "STN validation error: #{Exception.message(e)}"}
    end
  end

  @doc false
  def csp_temporal_strategy(plan, _domain, _opts) do
    # Future: CSP-based temporal validation
    # For now, just pass through
    {:ok, plan}
  end

  @doc false
  def no_temporal_strategy(plan, _domain, _opts) do
    # No temporal validation - just pass through
    {:ok, plan}
  end

  # ==================== EXECUTION STRATEGIES ====================

  @doc false
  def lazy_execution_strategy(domain, state, plan, opts) do
    # Use Run-Lazy-Refineahead execution
    Plan.run_lazy_refineahead(domain, state, plan, opts)
  end

  @doc false
  def eager_execution_strategy(domain, state, plan, opts) do
    # Future: Eager execution (validate entire plan first)
    # For now, delegate to lazy
    Plan.run_lazy_refineahead(domain, state, plan, opts)
  end

  @doc false
  def streaming_execution_strategy(domain, state, plan, opts) do
    # Future: Streaming execution with live updates
    # For now, delegate to lazy
    Plan.run_lazy_refineahead(domain, state, plan, opts)
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Convert solution tree to STN methods with bridge actions for validation
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
