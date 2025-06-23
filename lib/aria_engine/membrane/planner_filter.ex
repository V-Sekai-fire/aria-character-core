# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.PlannerFilter do
  @moduledoc "Membrane Filter element that executes actual planning using HybridCoordinatorV2.\n\nThis element receives PlanningParams and executes real planning to produce PlanningResult.\nIt's the core planning engine in the pipeline that bridges the gap between\ndata transformation and response formatting.\n"
  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W022PLNR"
  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger
  alias AriaEngine.Membrane.Format.{PlanningParams, PlanningResult}
  alias HybridPlanner.HybridCoordinatorV2
  alias Membrane.Buffer
  def_input_pad(:input, accepted_format: PlanningParams, flow_control: :auto)
  def_output_pad(:output, accepted_format: PlanningResult, flow_control: :auto)

  def_options(
    telemetry_prefix: [
      spec: [atom()],
      default: [:aria_engine, :membrane, :planner_filter],
      description: "Telemetry event prefix for monitoring"
    ],
    timeout_ms: [
      spec: pos_integer(),
      default: 30000,
      description: "Planning execution timeout in milliseconds"
    ],
    strategy_config: [
      spec: map(),
      default: %{},
      description: "Configuration for planning strategies"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      timeout_ms: opts.timeout_ms,
      strategy_config: opts.strategy_config,
      executed_count: 0,
      success_count: 0,
      error_count: 0,
      total_planning_time_ms: 0
    }

    Logger.info("PlannerFilter initialized with timeout: #{opts.timeout_ms}ms")
    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: planning_params}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)
    Logger.info("PlannerFilter executing planning for request: #{planning_params.request_id}")

    case execute_planning_with_timeout(planning_params, state.timeout_ms) do
      {:ok, plan_result} ->
        execution_time_ms = div(System.monotonic_time(:microsecond) - start_time, 1000)

        planning_result = %PlanningResult{
          status: :success,
          result: plan_result,
          execution_metadata: %{
            executed_at: DateTime.utc_now(),
            planner: "HybridCoordinatorV2",
            strategy_used: extract_strategy_info(plan_result),
            domain_size: get_domain_size(planning_params.domain),
            goals_count: length(planning_params.goals || [])
          },
          request_id: planning_params.request_id,
          performance_metrics: %{execution_time_ms: execution_time_ms, planning_successful: true}
        }

        emit_telemetry(state.telemetry_prefix, :planning_success, %{
          request_id: planning_params.request_id,
          execution_time_ms: execution_time_ms,
          goals_count: length(planning_params.goals || [])
        })

        output_buffer = %Buffer{payload: planning_result}

        new_state = %{
          state
          | executed_count: state.executed_count + 1,
            success_count: state.success_count + 1,
            total_planning_time_ms: state.total_planning_time_ms + execution_time_ms
        }

        Logger.info("PlannerFilter completed successfully in #{execution_time_ms}ms")
        {[buffer: {:output, output_buffer}], new_state}

      {:error, reason} ->
        execution_time_ms = div(System.monotonic_time(:microsecond) - start_time, 1000)

        planning_result = %PlanningResult{
          status: :error,
          result: nil,
          execution_metadata: %{
            error_reason: reason,
            executed_at: DateTime.utc_now(),
            planner: "HybridCoordinatorV2",
            domain_size: get_domain_size(planning_params.domain),
            goals_count: length(planning_params.goals || [])
          },
          request_id: planning_params.request_id,
          performance_metrics: %{execution_time_ms: execution_time_ms, planning_successful: false}
        }

        emit_telemetry(state.telemetry_prefix, :planning_error, %{
          request_id: planning_params.request_id,
          error_reason: reason,
          execution_time_ms: execution_time_ms
        })

        output_buffer = %Buffer{payload: planning_result}

        new_state = %{
          state
          | executed_count: state.executed_count + 1,
            error_count: state.error_count + 1,
            total_planning_time_ms: state.total_planning_time_ms + execution_time_ms
        }

        Logger.warning("PlannerFilter failed: #{reason} (#{execution_time_ms}ms)")
        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  defp execute_planning_with_timeout(
         %PlanningParams{options: [error: true]} = params,
         _timeout_ms
       ) do
    error_reason =
      get_in(params.conversion_metadata, [:error_reason]) || "Unknown conversion error"

    {:error, "Planning skipped due to conversion error: #{error_reason}"}
  end

  defp execute_planning_with_timeout(%PlanningParams{} = params, timeout_ms) do
    task = Task.async(fn -> execute_planning(params) end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:error, "Planning execution timeout after #{timeout_ms}ms"}
    end
  end

  defp execute_planning(%PlanningParams{} = params) do
    try do
      coordinator = HybridCoordinatorV2.new_default()
      domain = params.domain || create_default_domain()
      state = params.state || State.new()
      goals = params.goals || []
      options = params.options || []

      case HybridCoordinatorV2.plan(coordinator, domain, state, goals, options) do
        {:ok, plan} ->
          {:ok,
           %{
             plan: plan,
             planning_method: "hybrid_coordinator_v2",
             goals_processed: length(goals),
             domain_info: extract_domain_info(domain),
             state_info: extract_state_info(state)
           }}

        {:error, reason} ->
          {:error, "HybridCoordinatorV2 planning failed: #{inspect(reason)}"}
      end
    rescue
      error ->
        Logger.error("Planning execution exception: #{inspect(error)}")
        {:error, "Planning execution exception: #{Exception.message(error)}"}
    end
  end

  defp create_default_domain do
    AriaEngine.Domain.new("test_domain")
  end

  defp extract_strategy_info(plan_result) when is_map(plan_result) do
    Map.get(plan_result, :strategy_used, "unknown")
  end

  defp extract_strategy_info(_) do
    "unknown"
  end

  defp get_domain_size(nil) do
    0
  end

  defp get_domain_size(domain) when is_map(domain) do
    Map.get(domain, :size, 0)
  end

  defp get_domain_size(_) do
    0
  end

  defp extract_domain_info(nil) do
    %{type: "unknown", size: 0}
  end

  defp extract_domain_info(domain) when is_map(domain) do
    %{
      type: Map.get(domain, :type, "unknown"),
      size: get_domain_size(domain),
      predicates: Map.get(domain, :predicates, []) |> length()
    }
  end

  defp extract_domain_info(_) do
    %{type: "unknown", size: 0}
  end

  defp extract_state_info(nil) do
    %{type: "unknown", facts_count: 0}
  end

  defp extract_state_info(state) when is_map(state) do
    %{type: "State", facts_count: Map.get(state, :facts, %{}) |> map_size()}
  end

  defp extract_state_info(_) do
    %{type: "unknown", facts_count: 0}
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  @doc "Gets the current planning statistics of the PlannerFilter element.\n"
  @spec get_stats(pid()) :: map()
  def get_stats(filter_pid) do
    send(filter_pid, {:get_stats, self()})

    receive do
      {:planner_filter_stats, stats} -> stats
    after
      5000 -> %{error: "Timeout waiting for stats"}
    end
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    avg_time =
      if state.executed_count > 0 do
        div(state.total_planning_time_ms, state.executed_count)
      else
        0
      end

    stats = %{
      executed_count: state.executed_count,
      success_count: state.success_count,
      error_count: state.error_count,
      success_rate:
        if state.executed_count > 0 do
          state.success_count / state.executed_count
        else
          0.0
        end,
      total_planning_time_ms: state.total_planning_time_ms,
      average_planning_time_ms: avg_time,
      timeout_ms: state.timeout_ms
    }

    send(from, {:planner_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("PlannerFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end
end
