# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.PlannerBin do
  @moduledoc """
  Main planning bin that orchestrates all planning strategies asynchronously.

  This bin replaces the existing HybridCoordinatorV2 approach with a unified
  membrane-based system that integrates all strategies including MiniZinc,
  provides fallback handling, and supports asynchronous execution.

  Follows the unified action specification from ADR-134 with standardized
  goal format (subject, predicate, value) and entity+capability model.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W028PBIN"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Bin
  require Logger

  alias AriaEngine.Membrane.Planning.Format.{PlanningRequest, PlanningResponse, StrategyRequest}
  alias AriaEngine.Membrane.Format.PlanningParams

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningRequest}
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningResponse}
  )

  def_options(
    strategy_config: [
      spec: map(),
      default: %{},
      description: "Configuration for each strategy"
    ],
    default_timeout_ms: [
      spec: pos_integer(),
      default: 30_000,
      description: "Default timeout for planning operations"
    ],
    enable_fallback: [
      spec: boolean(),
      default: true,
      description: "Enable automatic fallback to alternative strategies"
    ],
    performance_monitoring: [
      spec: boolean(),
      default: true,
      description: "Enable performance metrics collection"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Planning Bin")
    Logger.info("🔧 Strategy config: #{inspect(opts.strategy_config, pretty: true)}")
    Logger.info("🔧 Default timeout: #{opts.default_timeout_ms}ms")
    Logger.info("🔧 Fallback enabled: #{opts.enable_fallback}")

    spec = [
      # Input processing and validation
      child(:request_validator, %AriaEngine.Membrane.Planning.RequestValidatorFilter{})
      |> child(:request_converter, %AriaEngine.Membrane.Planning.RequestConverterFilter{})

      # Strategy routing and execution
      |> child(:strategy_router, %AriaEngine.Membrane.Planning.StrategyRouterFilter{
        strategy_config: opts.strategy_config,
        enable_fallback: opts.enable_fallback
      })

      # Strategy execution filters
      |> child(:hybrid_coordinator_filter, %AriaEngine.Membrane.Planning.HybridCoordinatorFilter{
        config: Map.get(opts.strategy_config, :hybrid_coordinator, %{})
      })
      |> child(:minizinc_solver_filter, %AriaEngine.Membrane.Planning.MiniZincSolverFilter{
        solver_timeout_ms: Map.get(opts.strategy_config, :minizinc, %{}) |> Map.get(:solver_timeout_ms, 30_000),
        max_solutions: Map.get(opts.strategy_config, :minizinc, %{}) |> Map.get(:max_solutions, 1),
        optimization_level: Map.get(opts.strategy_config, :minizinc, %{}) |> Map.get(:optimization_level, :basic),
        enable_fallback: Map.get(opts.strategy_config, :minizinc, %{}) |> Map.get(:enable_fallback, true)
      })
      |> child(:lazy_execution_filter, %AriaEngine.Membrane.Planning.LazyExecutionFilter{
        execution_timeout_ms: Map.get(opts.strategy_config, :lazy_execution, %{}) |> Map.get(:execution_timeout_ms, 10_000),
        max_depth: Map.get(opts.strategy_config, :lazy_execution, %{}) |> Map.get(:max_depth, 100),
        enable_refinement: Map.get(opts.strategy_config, :lazy_execution, %{}) |> Map.get(:enable_refinement, true),
        enable_backtracking: Map.get(opts.strategy_config, :lazy_execution, %{}) |> Map.get(:enable_backtracking, true)
      })
      |> child(:mock_strategy_filter, %AriaEngine.Membrane.Planning.MockStrategyFilter{
        config: Map.get(opts.strategy_config, :mock, %{})
      })

      # Response processing and aggregation
      |> child(:response_aggregator, %AriaEngine.Membrane.Planning.ResponseAggregatorFilter{
        aggregation_timeout_ms: Map.get(opts.strategy_config, :aggregator, %{}) |> Map.get(:aggregation_timeout_ms, 60_000),
        selection_strategy: Map.get(opts.strategy_config, :aggregator, %{}) |> Map.get(:selection_strategy, :best_quality),
        enable_multi_strategy: Map.get(opts.strategy_config, :aggregator, %{}) |> Map.get(:enable_multi_strategy, false)
      })
      |> child(:response_formatter, %AriaEngine.Membrane.Planning.ResponseFormatterFilter{})
    ]

    {[spec: spec], %{
      strategy_config: opts.strategy_config,
      default_timeout_ms: opts.default_timeout_ms,
      enable_fallback: opts.enable_fallback,
      performance_monitoring: opts.performance_monitoring,
      active_requests: %{},
      strategy_stats: %{
        hybrid_coordinator: %{requests: 0, successes: 0, failures: 0},
        minizinc: %{requests: 0, successes: 0, failures: 0},
        lazy_execution: %{requests: 0, successes: 0, failures: 0},
        mock: %{requests: 0, successes: 0, failures: 0}
      }
    }}
  end

  @impl true
  def handle_child_notification({:strategy_execution_started, request_id, strategy}, _element, _ctx, state) do
    Logger.info("🔧 Strategy execution started: #{strategy} for request #{request_id}")

    updated_stats = update_in(state.strategy_stats[strategy][:requests], &(&1 + 1))
    new_state = %{state |
      strategy_stats: updated_stats,
      active_requests: Map.put(state.active_requests, request_id, %{
        strategy: strategy,
        started_at: DateTime.utc_now()
      })
    }

    {[], new_state}
  end

  @impl true
  def handle_child_notification({:strategy_execution_completed, request_id, strategy, result}, _element, _ctx, state) do
    Logger.info("🔧 Strategy execution completed: #{strategy} for request #{request_id}")

    updated_stats = case result do
      {:ok, _} -> update_in(state.strategy_stats[strategy][:successes], &(&1 + 1))
      {:error, _} -> update_in(state.strategy_stats[strategy][:failures], &(&1 + 1))
    end

    new_state = %{state |
      strategy_stats: updated_stats,
      active_requests: Map.delete(state.active_requests, request_id)
    }

    {[], new_state}
  end

  @impl true
  def handle_child_notification({:fallback_triggered, request_id, from_strategy, to_strategy, reason}, _element, _ctx, state) do
    Logger.warn("⚠️ Fallback triggered for request #{request_id}: #{from_strategy} -> #{to_strategy}")
    Logger.warn("⚠️ Reason: #{reason}")

    # Update active request tracking
    updated_active = Map.update(state.active_requests, request_id, %{}, fn request_info ->
      %{request_info |
        strategy: to_strategy,
        fallback_from: from_strategy,
        fallback_reason: reason,
        fallback_at: DateTime.utc_now()
      }
    end)

    new_state = %{state | active_requests: updated_active}

    {[], new_state}
  end

  @impl true
  def handle_child_notification({:performance_metrics, request_id, metrics}, _element, _ctx, state) do
    if state.performance_monitoring do
      Logger.info("📊 Performance metrics for request #{request_id}: #{inspect(metrics, pretty: true)}")
    end

    {[], state}
  end

  @impl true
  def handle_child_notification(notification, element, _ctx, state) do
    Logger.debug("🔧 Unhandled notification from #{inspect(element)}: #{inspect(notification)}")
    {[], state}
  end

  @doc """
  Gets current strategy statistics.
  """
  @spec get_strategy_stats(pid()) :: map()
  def get_strategy_stats(bin_pid) do
    GenServer.call(bin_pid, :get_strategy_stats)
  end

  @doc """
  Gets currently active requests.
  """
  @spec get_active_requests(pid()) :: map()
  def get_active_requests(bin_pid) do
    GenServer.call(bin_pid, :get_active_requests)
  end

  @impl true
  def handle_call(:get_strategy_stats, _from, _ctx, state) do
    {[reply: state.strategy_stats], state}
  end

  @impl true
  def handle_call(:get_active_requests, _from, _ctx, state) do
    {[reply: state.active_requests], state}
  end

  @doc """
  Creates a planning request with unified goal format.

  Goals should follow the format: {subject, predicate, value}

  ## Examples

      iex> request = AriaEngine.Membrane.Planning.PlannerBin.create_request(
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [{"player", "location", "room1"}, {"chef", "task", "cooking"}],
      ...>   strategy_preferences: [:hybrid_coordinator, :minizinc]
      ...> )
      iex> length(request.goals)
      2

  """
  @spec create_request(keyword()) :: PlanningRequest.t()
  def create_request(opts) do
    PlanningRequest.new(opts)
  end

  @doc """
  Validates that goals follow the unified format from ADR-134.

  ## Examples

      iex> goals = [{"player", "location", "room1"}, {"chef", "task", "cooking"}]
      iex> AriaEngine.Membrane.Planning.PlannerBin.validate_unified_goals(goals)
      :ok

      iex> invalid_goals = [{"location", "player", "room1"}]  # Wrong order
      iex> AriaEngine.Membrane.Planning.PlannerBin.validate_unified_goals(invalid_goals)
      {:error, "Goals must follow unified format: {subject, predicate, value}"}

  """
  @spec validate_unified_goals([tuple()]) :: :ok | {:error, String.t()}
  def validate_unified_goals(goals) when is_list(goals) do
    case Enum.all?(goals, &valid_unified_goal?/1) do
      true -> :ok
      false -> {:error, "Goals must follow unified format: {subject, predicate, value}"}
    end
  end

  def validate_unified_goals(_), do: {:error, "Goals must be a list"}

  # Private functions

  defp valid_unified_goal?({subject, predicate, _value})
       when is_binary(subject) and is_binary(predicate) do
    true
  end

  defp valid_unified_goal?(_), do: false
end
