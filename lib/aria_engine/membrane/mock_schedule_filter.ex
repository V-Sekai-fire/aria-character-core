# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.MockScheduleFilter do
  @moduledoc """
  Mock implementation of ScheduleFilter for testing pipeline structure.
  
  This mock filter provides predictable behavior for testing the Membrane
  pipeline without the complexity of real schedule processing. It:
  
  1. Accepts MCPRequest format input
  2. Returns mock PlanningParams format output
  3. Provides telemetry and statistics like the real filter
  4. Always succeeds with predictable mock data
  
  ## Usage in Tests
  
      # Replace ScheduleFilter with MockScheduleFilter in pipeline specs
      children = [
        child(:mcp_source, MCPSource)
        |> child(:schedule_filter, MockScheduleFilter)
        |> child(:planner_filter, MockPlannerFilter)
        |> child(:mcp_sink, MCPSink)
      ]
  """

  use Membrane.Filter

  require Logger

  alias AriaEngine.Membrane.Format.{MCPRequest, PlanningParams}
  alias Membrane.Buffer

  def_input_pad :input,
    accepted_format: MCPRequest,
    flow_control: :auto

  def_output_pad :output,
    accepted_format: PlanningParams,
    flow_control: :auto

  def_options telemetry_prefix: [
                spec: [atom()],
                default: [:aria_engine, :membrane, :mock_schedule_filter],
                description: "Telemetry event prefix for monitoring"
              ],
              mock_delay_ms: [
                spec: non_neg_integer(),
                default: 0,
                description: "Artificial delay in milliseconds for testing"
              ],
              force_error: [
                spec: boolean(),
                default: false,
                description: "Force error responses for testing error handling"
              ]

  @typedoc "Internal state of the MockScheduleFilter element"
  @type state :: %{
    telemetry_prefix: [atom()],
    mock_delay_ms: non_neg_integer(),
    force_error: boolean(),
    processed_count: non_neg_integer(),
    success_count: non_neg_integer(),
    error_count: non_neg_integer()
  }

  # ==================== Membrane Callbacks ====================

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      mock_delay_ms: opts.mock_delay_ms,
      force_error: opts.force_error,
      processed_count: 0,
      success_count: 0,
      error_count: 0
    }
    
    Logger.info("MockScheduleFilter initialized with delay: #{opts.mock_delay_ms}ms, force_error: #{opts.force_error}")
    emit_telemetry(state.telemetry_prefix, :initialized, %{
      mock_delay_ms: opts.mock_delay_ms,
      force_error: opts.force_error
    })
    
    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: mcp_request}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)
    
    # Add artificial delay if configured
    if state.mock_delay_ms > 0 do
      Process.sleep(state.mock_delay_ms)
    end
    
    case process_mock_request(mcp_request, state) do
      {:ok, planning_params} ->
        emit_telemetry(state.telemetry_prefix, :mock_processed, %{
          request_id: mcp_request.request_id,
          processing_time: System.monotonic_time(:microsecond) - start_time,
          mock_activities_count: 3,
          mock_entities_count: 2
        })

        output_buffer = %Buffer{payload: planning_params}
        new_state = %{state | 
          processed_count: state.processed_count + 1,
          success_count: state.success_count + 1
        }

        {[buffer: {:output, output_buffer}], new_state}

      {:error, reason} ->
        Logger.debug("MockScheduleFilter simulated error: #{reason}")
        
        emit_telemetry(state.telemetry_prefix, :mock_error, %{
          request_id: mcp_request.request_id,
          error_reason: reason,
          processing_time: System.monotonic_time(:microsecond) - start_time
        })

        error_params = create_mock_error_planning_params(mcp_request, reason)
        output_buffer = %Buffer{payload: error_params}
        
        new_state = %{state | 
          processed_count: state.processed_count + 1,
          error_count: state.error_count + 1
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    stats = %{
      processed_count: state.processed_count,
      success_count: state.success_count,
      error_count: state.error_count,
      mock_delay_ms: state.mock_delay_ms,
      force_error: state.force_error,
      success_rate: calculate_success_rate(state.success_count, state.processed_count)
    }
    
    send(from, {:mock_schedule_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("MockScheduleFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end

  # ==================== PRIVATE FUNCTIONS ====================

  defp process_mock_request(%MCPRequest{} = request, state) do
    if state.force_error do
      {:error, "Simulated error for testing"}
    else
      {:ok, create_mock_planning_params(request)}
    end
  end

  defp create_mock_planning_params(%MCPRequest{} = request) do
    %PlanningParams{
      domain: create_mock_domain(),
      state: create_mock_state(),
      goals: create_mock_goals(),
      options: [],
      request_id: request.request_id,
      conversion_metadata: %{
        mock: true,
        original_tool: request.tool_name,
        converted_at: DateTime.utc_now(),
        activities_count: 3,
        entities_count: 2,
        mock_version: "1.0"
      }
    }
  end

  defp create_mock_domain do
    %{
      name: "mock_schedule_domain",
      actions: [
        %{
          name: "mock_activity_1",
          parameters: ["entity", "resource"],
          duration: %{hours: 1, minutes: 0, seconds: 0}
        },
        %{
          name: "mock_activity_2", 
          parameters: ["entity", "resource"],
          duration: %{hours: 2, minutes: 30, seconds: 0}
        }
      ],
      predicates: [
        "available(entity)",
        "busy(entity)",
        "allocated(resource)"
      ]
    }
  end

  defp create_mock_state do
    %{
      facts: [
        "available(alice)",
        "available(bob)",
        "allocated(room_1)"
      ],
      timestamp: DateTime.utc_now()
    }
  end

  defp create_mock_goals do
    [
      %{
        type: "schedule_completion",
        target: "all_activities_scheduled",
        priority: 1
      },
      %{
        type: "resource_optimization",
        target: "minimize_conflicts",
        priority: 2
      }
    ]
  end

  defp create_mock_error_planning_params(%MCPRequest{} = request, reason) do
    %PlanningParams{
      domain: nil,
      state: nil,
      goals: [],
      options: [error: true, mock: true],
      request_id: request.request_id,
      conversion_metadata: %{
        error: true,
        mock: true,
        error_reason: reason,
        original_tool: request.tool_name,
        converted_at: DateTime.utc_now(),
        mock_version: "1.0"
      }
    }
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
  Gets the current processing statistics of the MockScheduleFilter element.
  """
  @spec get_stats(pid(), timeout()) :: map()
  def get_stats(filter_pid, timeout \\ 5000) do
    send(filter_pid, {:get_stats, self()})
    
    receive do
      {:mock_schedule_filter_stats, stats} -> stats
    after
      timeout -> %{error: "Timeout waiting for stats"}
    end
  end

  @doc """
  Creates a mock MCPRequest for testing purposes.
  """
  @spec create_mock_mcp_request(String.t()) :: MCPRequest.t()
  def create_mock_mcp_request(request_id \\ "mock_request_#{System.unique_integer()}") do
    %MCPRequest{
      request_id: request_id,
      tool_name: "schedule_activities",
      parameters: %{
        "schedule_name" => "Mock Schedule",
        "activities" => [
          %{"id" => "act_1", "name" => "Mock Activity 1"},
          %{"id" => "act_2", "name" => "Mock Activity 2"},
          %{"id" => "act_3", "name" => "Mock Activity 3"}
        ],
        "entities" => [
          %{"id" => "alice", "name" => "Alice"},
          %{"id" => "bob", "name" => "Bob"}
        ],
        "resources" => %{},
        "constraints" => %{}
      },
      metadata: %{
        mock: true,
        created_at: DateTime.utc_now()
      }
    }
  end
end
