# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.MockStrategyFilter do
  @moduledoc """
  Membrane filter that provides a mock planning strategy for testing and development.

  This filter simulates planning execution with configurable behavior including
  success, failure, timeout scenarios, and customizable response times. Useful
  for testing the membrane planning system without requiring actual planners.

  Follows the unified action specification from ADR-134 with standardized
  goal format (subject, predicate, value) and entity+capability model.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W031MOCK"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.Format.{StrategyRequest, PlanningResponse}

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: StrategyRequest},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningResponse},
    flow_control: :auto
  )

  def_options(
    config: [
      spec: map(),
      default: %{},
      description: "Configuration for mock strategy behavior"
    ],
    default_behavior: [
      spec: :success | :error | :timeout | :partial,
      default: :success,
      description: "Default mock behavior when not specified in config"
    ],
    default_delay_ms: [
      spec: non_neg_integer(),
      default: 100,
      description: "Default execution delay in milliseconds"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Mock Strategy Filter")
    Logger.info("🔧 Default behavior: #{opts.default_behavior}")
    Logger.info("🔧 Default delay: #{opts.default_delay_ms}ms")

    state = %{
      config: opts.config,
      default_behavior: opts.default_behavior,
      default_delay_ms: opts.default_delay_ms,
      execution_stats: %{
        total_requests: 0,
        success_responses: 0,
        error_responses: 0,
        timeout_responses: 0,
        partial_responses: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    strategy_request = buffer.payload

    # Only process requests for mock strategy
    if strategy_request.strategy == :mock do
      Logger.info("🔧 Mock strategy executing request: #{strategy_request.request_id}")

      start_time = System.monotonic_time(:millisecond)

      # Send notification about execution start
      send_notification({:strategy_execution_started, strategy_request.request_id, :mock})

      try do
        # Determine mock behavior for this request
        behavior = determine_mock_behavior(strategy_request, state)
        delay_ms = determine_execution_delay(strategy_request, state)

        # Simulate execution delay
        if delay_ms > 0 do
          Process.sleep(delay_ms)
        end

        end_time = System.monotonic_time(:millisecond)
        execution_time_ms = end_time - start_time

        # Create mock response based on behavior
        response = create_mock_response(behavior, strategy_request, execution_time_ms, state)

        # Update execution statistics
        updated_stats = update_execution_stats(state.execution_stats, behavior)
        new_state = %{state | execution_stats: updated_stats}

        # Send notification about execution completion
        result_status = case behavior do
          :success -> {:ok, :mock_success}
          :partial -> {:ok, :mock_partial}
          :error -> {:error, :mock_error}
          :timeout -> {:timeout, nil}
        end
        send_notification({:strategy_execution_completed, strategy_request.request_id, :mock, result_status})

        # Send performance metrics
        metrics = %{
          execution_time_ms: execution_time_ms,
          strategy: :mock,
          behavior: behavior,
          request_id: strategy_request.request_id
        }
        send_notification({:performance_metrics, strategy_request.request_id, metrics})

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: response,
          metadata: %{
            strategy: :mock,
            behavior: behavior,
            execution_time_ms: execution_time_ms,
            request_id: strategy_request.request_id,
            completed_at: DateTime.utc_now()
          }
        }

        Logger.info("✅ Mock strategy completed request: #{strategy_request.request_id} (#{behavior})")
        {[buffer: {:output, output_buffer}], new_state}

      rescue
        error ->
          end_time = System.monotonic_time(:millisecond)
          execution_time_ms = end_time - start_time

          Logger.error("❌ Mock strategy exception for request: #{strategy_request.request_id}")
          Logger.error("❌ Exception: #{inspect(error)}")

          # Create error response
          error_response = PlanningResponse.error(
            "Mock strategy execution exception: #{Exception.message(error)}",
            strategy_request.request_id,
            %{execution_time_ms: execution_time_ms},
            strategy_used: :mock,
            execution_metadata: %{
              failed_at: DateTime.utc_now(),
              planner_version: "mock_v1",
              exception: Exception.message(error),
              execution_context: strategy_request.execution_context
            }
          )

          # Update stats for exception
          updated_stats = update_execution_stats(state.execution_stats, :error)
          new_state = %{state | execution_stats: updated_stats}

          # Send notifications
          send_notification({:strategy_execution_completed, strategy_request.request_id, :mock, {:error, error}})

          output_buffer = %Membrane.Buffer{
            payload: error_response,
            metadata: %{
              strategy: :mock,
              execution_time_ms: execution_time_ms,
              request_id: strategy_request.request_id,
              error: true,
              exception: Exception.message(error)
            }
          }

          {[buffer: {:output, output_buffer}], new_state}
      end
    else
      # Pass through requests for other strategies
      Logger.debug("🔄 Passing through request for strategy: #{strategy_request.strategy}")
      {[buffer: {:output, buffer}], state}
    end
  end

  # Private functions

  defp determine_mock_behavior(strategy_request, state) do
    # Check for request-specific behavior configuration
    request_config = StrategyRequest.get_strategy_config(strategy_request)

    cond do
      Map.has_key?(request_config, :behavior) ->
        Map.get(request_config, :behavior)

      Map.has_key?(state.config, :behavior) ->
        Map.get(state.config, :behavior)

      true ->
        state.default_behavior
    end
  end

  defp determine_execution_delay(strategy_request, state) do
    # Check for request-specific delay configuration
    request_config = StrategyRequest.get_strategy_config(strategy_request)

    cond do
      Map.has_key?(request_config, :delay_ms) ->
        Map.get(request_config, :delay_ms)

      Map.has_key?(state.config, :delay_ms) ->
        Map.get(state.config, :delay_ms)

      true ->
        state.default_delay_ms
    end
  end

  defp create_mock_response(:success, strategy_request, execution_time_ms, _state) do
    # Create successful mock response
    mock_result = create_mock_plan_result(strategy_request)

    PlanningResponse.success(
      mock_result,
      :mock,
      strategy_request.request_id,
      %{
        execution_time_ms: execution_time_ms,
        strategy_config: StrategyRequest.get_strategy_config(strategy_request),
        performance_metrics: %{
          execution_time_ms: execution_time_ms,
          strategy: :mock,
          mock_behavior: :success
        }
      },
      execution_metadata: %{
        completed_at: DateTime.utc_now(),
        planner_version: "mock_v1",
        execution_context: strategy_request.execution_context,
        mock_behavior: :success
      }
    )
  end

  defp create_mock_response(:error, strategy_request, execution_time_ms, _state) do
    PlanningResponse.error(
      "Mock strategy simulated error",
      strategy_request.request_id,
      %{execution_time_ms: execution_time_ms},
      strategy_used: :mock,
      execution_metadata: %{
        failed_at: DateTime.utc_now(),
        planner_version: "mock_v1",
        failure_reason: "simulated_error",
        execution_context: strategy_request.execution_context,
        mock_behavior: :error
      }
    )
  end

  defp create_mock_response(:timeout, strategy_request, execution_time_ms, _state) do
    PlanningResponse.timeout(
      strategy_request.request_id,
      %{execution_time_ms: execution_time_ms},
      strategy_used: :mock,
      execution_metadata: %{
        timeout_at: DateTime.utc_now(),
        planner_version: "mock_v1",
        execution_context: strategy_request.execution_context,
        mock_behavior: :timeout
      }
    )
  end

  defp create_mock_response(:partial, strategy_request, execution_time_ms, _state) do
    # Create partial mock response
    partial_result = create_mock_plan_result(strategy_request, partial: true)

    PlanningResponse.partial(
      partial_result,
      :mock,
      strategy_request.request_id,
      %{execution_time_ms: execution_time_ms},
      execution_metadata: %{
        completed_at: DateTime.utc_now(),
        planner_version: "mock_v1",
        partial_reason: "simulated_partial_completion",
        execution_context: strategy_request.execution_context,
        mock_behavior: :partial
      },
      warnings: ["Mock strategy simulated partial completion"]
    )
  end

  defp create_mock_plan_result(strategy_request, opts \\ []) do
    planning_params = strategy_request.planning_params
    partial = Keyword.get(opts, :partial, false)

    # Create mock actions based on goals
    mock_actions = create_mock_actions(planning_params.goals, partial)

    # Create mock timeline
    mock_timeline = create_mock_timeline(mock_actions)

    %{
      actions: mock_actions,
      timeline: mock_timeline,
      resource_allocation: create_mock_resource_allocation(planning_params.goals),
      validation_status: if(partial, do: :unknown, else: :valid)
    }
  end

  defp create_mock_actions(goals, partial) do
    # Create mock actions for each goal
    goal_count = length(goals)
    action_count = if partial, do: max(1, div(goal_count, 2)), else: goal_count

    goals
    |> Enum.take(action_count)
    |> Enum.with_index()
    |> Enum.map(fn {{subject, predicate, value}, index} ->
      %{
        name: :"mock_action_#{index + 1}",
        duration: "PT#{index + 1}M",  # 1 minute, 2 minutes, etc.
        start: nil,
        end: nil,
        requires_entities: [
          %{type: subject, capabilities: [:mock_capability]},
          %{type: "mock_tool", capabilities: [:tool, :mock]}
        ],
        description: "Mock action to achieve #{subject} #{predicate} #{value}",
        metadata: %{
          mock: true,
          goal: {subject, predicate, value},
          action_index: index + 1
        }
      }
    end)
  end

  defp create_mock_timeline(actions) do
    # Create timeline events for mock actions
    Enum.flat_map(actions, fn action ->
      action_name = to_string(action.name)

      [
        %{
          time: "2025-06-22T10:00:00Z",
          event_type: :action_start,
          action_id: action_name,
          description: "#{action.description} started",
          metadata: %{action: action.name, mock: true}
        },
        %{
          time: "2025-06-22T10:05:00Z",
          event_type: :action_end,
          action_id: action_name,
          description: "#{action.description} completed",
          metadata: %{action: action.name, mock: true}
        }
      ]
    end)
    |> Enum.sort_by(fn event -> event.time end)
  end

  defp create_mock_resource_allocation(goals) do
    # Create mock resource allocation based on goals
    %{
      agents: ["mock_agent_1"],
      tools: ["mock_tool_1", "mock_tool_2"],
      locations: ["mock_location"],
      consumables: [],
      allocation_strategy: "mock_allocation",
      total_goals: length(goals)
    }
  end

  defp update_execution_stats(stats, behavior) do
    new_total = stats.total_requests + 1

    updated_stats = case behavior do
      :success ->
        %{stats |
          success_responses: stats.success_responses + 1,
          total_requests: new_total
        }

      :error ->
        %{stats |
          error_responses: stats.error_responses + 1,
          total_requests: new_total
        }

      :timeout ->
        %{stats |
          timeout_responses: stats.timeout_responses + 1,
          total_requests: new_total
        }

      :partial ->
        %{stats |
          partial_responses: stats.partial_responses + 1,
          total_requests: new_total
        }
    end

    updated_stats
  end

  defp send_notification(notification) do
    # Send notification to parent bin
    send(self(), {:child_notification, notification})
  end
end
