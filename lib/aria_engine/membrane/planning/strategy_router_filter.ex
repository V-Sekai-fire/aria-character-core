# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.StrategyRouterFilter do
  @moduledoc """
  Membrane filter that routes planning requests to appropriate strategies.

  This filter analyzes incoming planning requests and routes them to the
  most suitable strategy based on problem characteristics, user preferences,
  and strategy availability. Handles fallback routing when strategies fail.

  Supports routing to: HybridCoordinator, MiniZinc, LazyExecution, Mock, Default
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W029SROU"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.Format.{PlanningRequest, PlanningResponse, StrategyRequest}
  alias AriaEngine.Membrane.Format.PlanningParams

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningParams},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningResponse},
    flow_control: :auto
  )

  def_options(
    strategy_config: [
      spec: map(),
      default: %{},
      description: "Configuration for each strategy"
    ],
    enable_fallback: [
      spec: boolean(),
      default: true,
      description: "Enable automatic fallback to alternative strategies"
    ],
    routing_rules: [
      spec: map(),
      default: %{},
      description: "Custom routing rules for strategy selection"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Strategy Router Filter")
    Logger.info("🔧 Strategy config: #{inspect(opts.strategy_config, pretty: true)}")
    Logger.info("🔧 Fallback enabled: #{opts.enable_fallback}")

    state = %{
      strategy_config: opts.strategy_config,
      enable_fallback: opts.enable_fallback,
      routing_rules: opts.routing_rules,
      routing_stats: %{
        total_requests: 0,
        strategy_selections: %{
          hybrid_coordinator: 0,
          minizinc: 0,
          lazy_execution: 0,
          mock: 0,
          default: 0
        },
        fallback_triggers: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    Logger.info("🔧 Strategy Router received planning params")

    try do
      planning_params = buffer.payload
      Logger.info("🔧 Processing request: #{planning_params.request_id}")

      # Validate planning params
      if PlanningParams.valid?(planning_params) do
        # Route to appropriate strategy and execute it
        {strategy, fallback_strategies} = select_strategy(planning_params, state)

        # Execute the selected strategy
        execution_result = execute_strategy(strategy, planning_params, state)

        # Update routing statistics
        updated_stats = update_routing_stats(state.routing_stats, strategy)
        new_state = %{state | routing_stats: updated_stats}

        # Send notification about strategy execution
        send_notification({:strategy_executed, planning_params.request_id, strategy, execution_result})

        # Convert execution result to PlanningResponse
        planning_response = convert_to_planning_response(planning_params, execution_result, strategy)

        # Create output buffer with planning response
        output_buffer = %Membrane.Buffer{
          payload: planning_response,
          metadata: %{
            strategy: strategy,
            fallback_strategies: fallback_strategies,
            request_id: planning_params.request_id,
            executed_at: DateTime.utc_now(),
            success: match?({:ok, _}, execution_result)
          }
        }

        Logger.info("✅ Executed strategy #{strategy} for request #{planning_params.request_id}")
        {[buffer: {:output, output_buffer}], new_state}
      else
        Logger.error("❌ Invalid planning params for request: #{planning_params.request_id}")
        create_error_response(planning_params, "Invalid planning parameters", state)
      end
    rescue
      error ->
        Logger.error("❌ Strategy routing error: #{inspect(error)}")
        create_error_response(buffer.payload, "Strategy routing failed: #{Exception.message(error)}", state)
    end
  end

  @doc """
  Selects the most appropriate strategy for a planning request.

  Strategy selection priority:
  1. User preferences (if valid)
  2. Problem characteristics analysis
  3. Strategy availability and performance
  4. Default fallback chain
  """
  @spec select_strategy(PlanningParams.t(), map()) :: {atom(), [atom()]}
  def select_strategy(planning_params, state) do
    # Check for error state
    if PlanningParams.error?(planning_params) do
      {:mock, []}
    else
      # Analyze problem characteristics
      problem_analysis = analyze_problem_characteristics(planning_params)

      # Get user preferences from conversion metadata
      user_preferences = get_user_preferences(planning_params)

      # Select primary strategy
      primary_strategy = select_primary_strategy(user_preferences, problem_analysis, state)

      # Build fallback chain
      fallback_strategies = build_fallback_chain(primary_strategy, user_preferences, state)

      {primary_strategy, fallback_strategies}
    end
  end

  # Private functions

  defp analyze_problem_characteristics(planning_params) do
    %{
      goal_count: length(planning_params.goals),
      has_temporal_constraints: has_temporal_constraints?(planning_params),
      complexity_estimate: estimate_complexity(planning_params),
      domain_type: analyze_domain_type(planning_params),
      resource_requirements: analyze_resource_requirements(planning_params)
    }
  end

  defp has_temporal_constraints?(planning_params) do
    # Check if goals or options indicate temporal constraints
    temporal_keywords = ["time", "schedule", "duration", "deadline", "temporal"]

    goal_has_temporal = Enum.any?(planning_params.goals, fn goal ->
      goal_str = inspect(goal)
      Enum.any?(temporal_keywords, &String.contains?(String.downcase(goal_str), &1))
    end)

    options_has_temporal = Enum.any?(planning_params.options, fn {key, value} ->
      key_str = to_string(key)
      value_str = inspect(value)
      Enum.any?(temporal_keywords, fn keyword ->
        String.contains?(String.downcase(key_str), keyword) or
        String.contains?(String.downcase(value_str), keyword)
      end)
    end)

    goal_has_temporal or options_has_temporal
  end

  defp estimate_complexity(planning_params) do
    goal_count = length(planning_params.goals)
    option_count = length(planning_params.options)

    cond do
      goal_count <= 2 and option_count <= 3 -> :low
      goal_count <= 5 and option_count <= 8 -> :medium
      goal_count <= 10 and option_count <= 15 -> :high
      true -> :very_high
    end
  end

  defp analyze_domain_type(planning_params) do
    # Analyze domain characteristics if domain is available
    if planning_params.domain do
      # Could inspect domain structure, actions, etc.
      :general
    else
      :unknown
    end
  end

  defp analyze_resource_requirements(planning_params) do
    # Analyze resource requirements from goals and options
    %{
      memory_intensive: length(planning_params.goals) > 10,
      computation_intensive: has_temporal_constraints?(planning_params),
      io_intensive: false  # Could be determined from domain analysis
    }
  end

  defp get_user_preferences(planning_params) do
    # Extract user preferences from conversion metadata
    metadata = planning_params.conversion_metadata || %{}
    Map.get(metadata, :strategy_preferences, [:hybrid_coordinator, :minizinc])
  end

  defp select_primary_strategy(user_preferences, problem_analysis, state) do
    # Check user preferences first
    preferred_strategy = List.first(user_preferences)

    # Validate preference against problem characteristics
    if valid_strategy_for_problem?(preferred_strategy, problem_analysis, state) do
      preferred_strategy
    else
      # Fall back to problem-based selection
      select_strategy_by_problem(problem_analysis, state)
    end
  end

  defp valid_strategy_for_problem?(strategy, problem_analysis, _state) do
    case {strategy, problem_analysis} do
      # HybridCoordinator is good for most problems
      {:hybrid_coordinator, _} -> true

      # MiniZinc is excellent for constraint satisfaction and optimization
      {:minizinc, %{has_temporal_constraints: true}} -> true
      {:minizinc, %{complexity_estimate: complexity}} when complexity in [:high, :very_high] -> true

      # LazyExecution is good for simple problems
      {:lazy_execution, %{complexity_estimate: :low}} -> true
      {:lazy_execution, %{goal_count: count}} when count <= 3 -> true

      # Mock is always valid (for testing)
      {:mock, _} -> true

      # Default is always valid (fallback)
      {:default, _} -> true

      # Other combinations need validation
      _ -> false
    end
  end

  defp select_strategy_by_problem(problem_analysis, _state) do
    case problem_analysis do
      %{has_temporal_constraints: true, complexity_estimate: complexity} when complexity in [:high, :very_high] ->
        :minizinc

      %{complexity_estimate: :low, goal_count: count} when count <= 3 ->
        :lazy_execution

      %{complexity_estimate: complexity} when complexity in [:medium, :high] ->
        :hybrid_coordinator

      _ ->
        :hybrid_coordinator  # Default choice
    end
  end

  defp build_fallback_chain(primary_strategy, user_preferences, state) do
    if state.enable_fallback do
      # Remove primary strategy from preferences
      remaining_preferences = List.delete(user_preferences, primary_strategy)

      # Add standard fallback strategies
      standard_fallbacks = [:hybrid_coordinator, :minizinc, :lazy_execution, :mock]

      # Combine and deduplicate
      (remaining_preferences ++ standard_fallbacks)
      |> Enum.uniq()
      |> List.delete(primary_strategy)
      |> Enum.take(3)  # Limit fallback chain length
    else
      []
    end
  end

  defp determine_routing_reason(planning_params, strategy) do
    user_preferences = get_user_preferences(planning_params)

    cond do
      strategy in user_preferences -> "user_preference"
      PlanningParams.error?(planning_params) -> "error_handling"
      true -> "problem_analysis"
    end
  end

  defp get_available_strategies(state) do
    Map.keys(state.strategy_config)
  end

  defp get_applied_rules(planning_params, state) do
    # Return which routing rules were applied
    applied_rules = []

    # Check custom routing rules
    custom_rules = Enum.filter(state.routing_rules, fn {_rule_name, rule_func} ->
      is_function(rule_func, 1) and rule_func.(planning_params)
    end)

    applied_rules ++ Enum.map(custom_rules, fn {rule_name, _} -> rule_name end)
  end

  defp update_routing_stats(stats, strategy) do
    %{stats |
      total_requests: stats.total_requests + 1,
      strategy_selections: Map.update(stats.strategy_selections, strategy, 1, &(&1 + 1))
    }
  end

  defp execute_strategy(strategy, planning_params, state) do
    Logger.info("🔧 Executing strategy: #{strategy}")

    try do
      case strategy do
        :hybrid_coordinator ->
          execute_hybrid_coordinator(planning_params, state)

        :minizinc ->
          execute_minizinc_solver(planning_params, state)

        :lazy_execution ->
          execute_lazy_execution(planning_params, state)

        :mock ->
          execute_mock_strategy(planning_params, state)

        _ ->
          Logger.warn("⚠️ Unknown strategy: #{strategy}, falling back to mock")
          execute_mock_strategy(planning_params, state)
      end
    rescue
      error ->
        Logger.error("❌ Strategy execution failed: #{inspect(error)}")
        {:error, "Strategy execution failed: #{Exception.message(error)}"}
    end
  end

  defp execute_hybrid_coordinator(planning_params, _state) do
    # Call the HybridCoordinatorV2 directly
    domain = planning_params.domain
    state_data = planning_params.state
    goals = planning_params.goals
    options = planning_params.options

    case AriaEngine.HybridPlanner.HybridCoordinatorV2.plan(domain, state_data, goals, options) do
      {:ok, plan} ->
        {:ok, %{
          strategy: :hybrid_coordinator,
          plan: plan,
          success: true,
          execution_time: 0  # Could be measured
        }}

      {:error, reason} ->
        {:error, "HybridCoordinator failed: #{reason}"}
    end
  end

  defp execute_minizinc_solver(planning_params, _state) do
    # Call MiniZinc solver directly
    domain = planning_params.domain
    state_data = planning_params.state
    goals = planning_params.goals
    options = planning_params.options

    case AriaEngine.MiniZinc.Solver.solve(goals, options) do
      {:ok, solution} ->
        {:ok, %{
          strategy: :minizinc,
          solution: solution,
          success: true,
          execution_time: Map.get(solution, :solving_time, 0)
        }}

      {:error, reason} ->
        {:error, "MiniZinc solver failed: #{reason}"}
    end
  end

  defp execute_lazy_execution(planning_params, _state) do
    # Call LazyExecution directly
    domain = planning_params.domain
    state_data = planning_params.state
    goals = planning_params.goals
    options = planning_params.options

    case AriaEngine.Planning.LazyExecution.plan_goals_sequentially(domain, state_data, goals, options) do
      {:ok, plan, final_state} ->
        {:ok, %{
          strategy: :lazy_execution,
          plan: plan,
          final_state: final_state,
          success: true,
          execution_time: 0  # Could be measured
        }}

      {:error, reason} ->
        {:error, "LazyExecution failed: #{reason}"}
    end
  end

  defp execute_mock_strategy(planning_params, _state) do
    # Mock strategy for testing
    Logger.info("🔧 Executing mock strategy for request: #{planning_params.request_id}")

    {:ok, %{
      strategy: :mock,
      plan: [
        %{
          action: "mock_action",
          entity: "mock_entity",
          start_time: 0,
          duration: 1,
          cost: 1
        }
      ],
      success: true,
      execution_time: 10,
      mock: true
    }}
  end

  defp convert_to_planning_response(planning_params, execution_result, strategy) do
    case execution_result do
      {:ok, result} ->
        # Extract actions and timeline from result
        actions = extract_actions_from_result(result)
        timeline = extract_timeline_from_result(result)

        # Create plan result structure
        plan_result = %{
          actions: actions,
          timeline: timeline,
          resource_allocation: %{},
          validation_status: :valid
        }

        # Create performance metrics
        performance_metrics = %{
          execution_time_ms: Map.get(result, :execution_time, 0),
          strategy_used: strategy,
          success: true
        }

        PlanningResponse.success(
          plan_result,
          strategy,
          planning_params.request_id,
          performance_metrics
        )

      {:error, reason} ->
        performance_metrics = %{
          execution_time_ms: 0,
          strategy_used: strategy,
          success: false
        }

        PlanningResponse.error(
          reason,
          planning_params.request_id,
          performance_metrics,
          strategy_used: strategy
        )
    end
  end

  defp extract_actions_from_result(result) do
    case result do
      %{plan: plan} when is_list(plan) -> plan
      %{actions: actions} when is_list(actions) -> actions
      %{solution: %{actions: actions}} when is_list(actions) -> actions
      _ -> []
    end
  end

  defp extract_timeline_from_result(result) do
    case result do
      %{timeline: timeline} when is_list(timeline) -> timeline
      %{solution: %{timeline: timeline}} when is_list(timeline) -> timeline
      %{plan: plan} when is_list(plan) ->
        # Convert plan to timeline events
        Enum.with_index(plan, fn action, index ->
          %{
            time: Map.get(action, :start_time, index),
            action: action,
            effects: Map.get(action, :effects, [])
          }
        end)
      _ -> []
    end
  end

  defp send_notification(notification) do
    # Send notification to parent bin
    send(self(), {:child_notification, notification})
  end

  defp create_error_response(planning_params, error_reason, state) do
    # Create error strategy request
    error_request = StrategyRequest.new(
      planning_params,
      :mock,  # Use mock strategy for errors
      [],
      strategy_config: state.strategy_config,
      routing_metadata: %{
        routed_at: DateTime.utc_now(),
        routing_reason: "error_handling",
        error_reason: error_reason
      }
    )

    output_buffer = %Membrane.Buffer{
      payload: error_request,
      metadata: %{
        strategy: :mock,
        fallback_strategies: [],
        request_id: planning_params.request_id,
        error: true,
        error_reason: error_reason
      }
    }

    {[buffer: {:output, output_buffer}], state}
  end
end
