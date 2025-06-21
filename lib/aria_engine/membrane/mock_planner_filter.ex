# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.MockPlannerFilter do
  @moduledoc """
  Mock implementation of PlannerFilter for testing pipeline structure.
  
  This mock filter provides predictable behavior for testing the Membrane
  pipeline without the complexity of real planning execution. It:
  
  1. Accepts PlanningParams format input
  2. Returns mock PlanningResult format output
  3. Provides telemetry and statistics like the real filter
  4. Always succeeds with predictable mock planning results
  
  ## Usage in Tests
  
      # Replace PlannerFilter with MockPlannerFilter in pipeline specs
      children = [
        child(:mcp_source, MCPSource)
        |> child(:schedule_filter, MockScheduleFilter)
        |> child(:planner_filter, MockPlannerFilter)
        |> child(:response_filter, MCPResponseFilter)
        |> child(:mcp_sink, MCPSink)
      ]
  """

  use Membrane.Filter

  require Logger

  alias AriaEngine.Membrane.Format.{PlanningParams, PlanningResult}
  alias Membrane.Buffer

  def_input_pad :input,
    accepted_format: PlanningParams,
    flow_control: :auto

  def_output_pad :output,
    accepted_format: PlanningResult,
    flow_control: :auto

  def_options telemetry_prefix: [
                spec: [atom()],
                default: [:aria_engine, :membrane, :mock_planner_filter],
                description: "Telemetry event prefix for monitoring"
              ],
              mock_delay_ms: [
                spec: non_neg_integer(),
                default: 100,
                description: "Artificial planning delay in milliseconds for testing"
              ],
              force_error: [
                spec: boolean(),
                default: false,
                description: "Force planning error responses for testing error handling"
              ],
              mock_plan_size: [
                spec: pos_integer(),
                default: 5,
                description: "Number of mock actions to include in successful plans"
              ]

  @typedoc "Internal state of the MockPlannerFilter element"
  @type state :: %{
    telemetry_prefix: [atom()],
    mock_delay_ms: non_neg_integer(),
    force_error: boolean(),
    mock_plan_size: pos_integer(),
    processed_count: non_neg_integer(),
    success_count: non_neg_integer(),
    error_count: non_neg_integer(),
    total_planning_time: non_neg_integer()
  }

  # ==================== Membrane Callbacks ====================

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      mock_delay_ms: opts.mock_delay_ms,
      force_error: opts.force_error,
      mock_plan_size: opts.mock_plan_size,
      processed_count: 0,
      success_count: 0,
      error_count: 0,
      total_planning_time: 0
    }
    
    Logger.info("MockPlannerFilter initialized with delay: #{opts.mock_delay_ms}ms, plan_size: #{opts.mock_plan_size}, force_error: #{opts.force_error}")
    emit_telemetry(state.telemetry_prefix, :initialized, %{
      mock_delay_ms: opts.mock_delay_ms,
      force_error: opts.force_error,
      mock_plan_size: opts.mock_plan_size
    })
    
    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: planning_params}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)
    
    # Add artificial planning delay
    if state.mock_delay_ms > 0 do
      Process.sleep(state.mock_delay_ms)
    end
    
    case execute_mock_planning(planning_params, state) do
      {:ok, planning_result} ->
        processing_time = System.monotonic_time(:microsecond) - start_time
        
        emit_telemetry(state.telemetry_prefix, :mock_planning_success, %{
          request_id: planning_params.request_id,
          processing_time: processing_time,
          mock_actions_count: state.mock_plan_size,
          mock_planning: true
        })

        output_buffer = %Buffer{payload: planning_result}
        new_state = %{state | 
          processed_count: state.processed_count + 1,
          success_count: state.success_count + 1,
          total_planning_time: state.total_planning_time + processing_time
        }

        {[buffer: {:output, output_buffer}], new_state}

      {:error, reason} ->
        processing_time = System.monotonic_time(:microsecond) - start_time
        Logger.debug("MockPlannerFilter simulated planning error: #{reason}")
        
        emit_telemetry(state.telemetry_prefix, :mock_planning_error, %{
          request_id: planning_params.request_id,
          error_reason: reason,
          processing_time: processing_time,
          mock_planning: true
        })

        error_result = create_mock_error_planning_result(planning_params, reason)
        output_buffer = %Buffer{payload: error_result}
        
        new_state = %{state | 
          processed_count: state.processed_count + 1,
          error_count: state.error_count + 1,
          total_planning_time: state.total_planning_time + processing_time
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    avg_planning_time = if state.processed_count > 0 do
      state.total_planning_time / state.processed_count
    else
      0
    end

    stats = %{
      processed_count: state.processed_count,
      success_count: state.success_count,
      error_count: state.error_count,
      mock_delay_ms: state.mock_delay_ms,
      force_error: state.force_error,
      mock_plan_size: state.mock_plan_size,
      total_planning_time: state.total_planning_time,
      avg_planning_time: Float.round(avg_planning_time, 2),
      success_rate: calculate_success_rate(state.success_count, state.processed_count)
    }
    
    send(from, {:mock_planner_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("MockPlannerFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end

  # ==================== PRIVATE FUNCTIONS ====================

  defp execute_mock_planning(%PlanningParams{} = params, state) do
    # Check if this is an error params from upstream
    if Keyword.get(params.options, :error, false) do
      {:error, "Upstream error: #{get_in(params.conversion_metadata, [:error_reason]) || "unknown"}"}
    else
      if state.force_error do
        {:error, "Simulated planning failure for testing"}
      else
        {:ok, create_mock_planning_result(params, state)}
      end
    end
  end

  defp create_mock_planning_result(%PlanningParams{} = params, state) do
    mock_actions = create_mock_plan_actions(state.mock_plan_size)
    
    plan_result = %{
      actions: mock_actions,
      total_duration: calculate_mock_total_duration(mock_actions),
      success: true,
      optimization_score: 0.85
    }
    
    execution_metadata = %{
      planning_time_ms: state.mock_delay_ms,
      actions_count: length(mock_actions),
      mock_planning: true,
      planner_version: "mock_v1.0",
      executed_at: DateTime.utc_now(),
      coordinator_version: "v2"
    }
    
    performance_metrics = %{
      execution_time_ms: state.mock_delay_ms
    }
    
    PlanningResult.success(plan_result, params.request_id, execution_metadata, performance_metrics)
  end

  defp create_mock_plan_actions(count) do
    1..count
    |> Enum.map(fn i ->
      %{
        id: "mock_action_#{i}",
        name: "Mock Activity #{i}",
        start_time: DateTime.add(DateTime.utc_now(), (i - 1) * 3600, :second),
        end_time: DateTime.add(DateTime.utc_now(), i * 3600, :second),
        duration: %{hours: 1, minutes: 0, seconds: 0},
        assigned_entity: if(rem(i, 2) == 0, do: "alice", else: "bob"),
        assigned_resources: ["room_#{rem(i, 3) + 1}"],
        status: "scheduled",
        dependencies: if(i > 1, do: ["mock_action_#{i-1}"], else: [])
      }
    end)
  end

  defp calculate_mock_total_duration(actions) do
    %{
      hours: length(actions),
      minutes: 0,
      seconds: 0
    }
  end

  defp create_mock_error_planning_result(%PlanningParams{} = params, reason) do
    execution_metadata = %{
      planning_time_ms: 0,
      actions_count: 0,
      mock_planning: true,
      error_reason: reason,
      planner_version: "mock_v1.0"
    }
    
    performance_metrics = %{
      execution_time_ms: 0
    }
    
    PlanningResult.error(params.request_id, execution_metadata, performance_metrics)
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  defp calculate_success_rate(0, 0), do: 0.0
  defp calculate_success_rate(success_count, total_count) do
    Float.round(success_count / total_count * 100, 2)
  end

  # ==================== PUBLIC API FOR TESTING ====================

  @doc """
  Gets the current processing statistics of the MockPlannerFilter element.
  """
  @spec get_stats(pid(), timeout()) :: map()
  def get_stats(filter_pid, timeout \\ 5000) do
    send(filter_pid, {:get_stats, self()})
    
    receive do
      {:mock_planner_filter_stats, stats} -> stats
    after
      timeout -> %{error: "Timeout waiting for stats"}
    end
  end

  @doc """
  Creates a mock PlanningParams for testing purposes.
  """
  @spec create_mock_planning_params(String.t()) :: PlanningParams.t()
  def create_mock_planning_params(request_id \\ "mock_planning_#{System.unique_integer()}") do
    %PlanningParams{
      domain: %{
        name: "mock_domain",
        actions: ["mock_action_1", "mock_action_2"],
        predicates: ["available(entity)", "busy(entity)"]
      },
      state: %{
        facts: ["available(alice)", "available(bob)"],
        timestamp: DateTime.utc_now()
      },
      goals: [
        %{type: "schedule_completion", target: "all_activities"}
      ],
      options: [],
      request_id: request_id,
      conversion_metadata: %{
        mock: true,
        activities_count: 2,
        entities_count: 2,
        converted_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Creates a mock error PlanningParams for testing error handling.
  """
  @spec create_mock_error_planning_params(String.t(), String.t()) :: PlanningParams.t()
  def create_mock_error_planning_params(request_id \\ "mock_error_#{System.unique_integer()}", reason \\ "Mock error") do
    %PlanningParams{
      domain: nil,
      state: nil,
      goals: [],
      options: [error: true],
      request_id: request_id,
      conversion_metadata: %{
        error: true,
        mock: true,
        error_reason: reason,
        converted_at: DateTime.utc_now()
      }
    }
  end
end
