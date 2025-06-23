# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.HybridCoordinatorFilter do
  @moduledoc """
  Membrane filter that wraps the existing HybridCoordinatorV2 for planning execution.

  This filter integrates the HybridCoordinatorV2 into the membrane planning
  pipeline, handling strategy requests and converting results to the unified
  planning response format following ADR-134 specifications.

  Provides asynchronous execution with timeout handling and performance metrics.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W030HCOO"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.Format.{StrategyRequest, PlanningResponse}
  alias AriaEngine.HybridPlanner.HybridCoordinatorV2

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
      description: "Configuration for HybridCoordinator strategy"
    ],
    max_execution_time_ms: [
      spec: pos_integer(),
      default: 30_000,
      description: "Maximum execution time for planning operations"
    ],
    enable_performance_monitoring: [
      spec: boolean(),
      default: true,
      description: "Enable detailed performance monitoring"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing HybridCoordinator Filter")
    Logger.info("🔧 Config: #{inspect(opts.config, pretty: true)}")
    Logger.info("🔧 Max execution time: #{opts.max_execution_time_ms}ms")

    state = %{
      config: opts.config,
      max_execution_time_ms: opts.max_execution_time_ms,
      enable_performance_monitoring: opts.enable_performance_monitoring,
      execution_stats: %{
        total_requests: 0,
        successful_executions: 0,
        failed_executions: 0,
        timeout_executions: 0,
        average_execution_time_ms: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    strategy_request = buffer.payload

    # Only process requests for hybrid_coordinator strategy
    if strategy_request.strategy == :hybrid_coordinator do
      Logger.info("🔧 HybridCoordinator executing request: #{strategy_request.request_id}")

      start_time = System.monotonic_time(:millisecond)

      # Send notification about execution start
      send_notification({:strategy_execution_started, strategy_request.request_id, :hybrid_coordinator})

      try do
        # Execute planning with timeout
        result = execute_with_timeout(strategy_request, state)

        end_time = System.monotonic_time(:millisecond)
        execution_time_ms = end_time - start_time

        # Create response based on result
        response = case result do
          {:ok, plan_result} ->
            Logger.info("✅ HybridCoordinator succeeded for request: #{strategy_request.request_id}")

            # Convert to unified response format
            unified_result = convert_to_unified_format(plan_result, strategy_request)

            PlanningResponse.success(
              unified_result,
              :hybrid_coordinator,
              strategy_request.request_id,
              %{
                execution_time_ms: execution_time_ms,
                strategy_config: StrategyRequest.get_strategy_config(strategy_request),
                performance_metrics: extract_performance_metrics(plan_result, execution_time_ms)
              },
              execution_metadata: %{
                completed_at: DateTime.utc_now(),
                planner_version: "hybrid_coordinator_v2",
                execution_context: strategy_request.execution_context
              }
            )

          {:error, reason} ->
            Logger.error("❌ HybridCoordinator failed for request: #{strategy_request.request_id}")
            Logger.error("❌ Reason: #{inspect(reason)}")

            PlanningResponse.error(
              "HybridCoordinator execution failed: #{inspect(reason)}",
              strategy_request.request_id,
              %{execution_time_ms: execution_time_ms},
              strategy_used: :hybrid_coordinator,
              execution_metadata: %{
                failed_at: DateTime.utc_now(),
                planner_version: "hybrid_coordinator_v2",
                failure_reason: inspect(reason),
                execution_context: strategy_request.execution_context
              }
            )

          {:timeout, partial_result} ->
            Logger.warn("⏰ HybridCoordinator timeout for request: #{strategy_request.request_id}")

            if partial_result do
              unified_result = convert_to_unified_format(partial_result, strategy_request)

              PlanningResponse.partial(
                unified_result,
                :hybrid_coordinator,
                strategy_request.request_id,
                %{execution_time_ms: execution_time_ms},
                execution_metadata: %{
                  completed_at: DateTime.utc_now(),
                  planner_version: "hybrid_coordinator_v2",
                  partial_reason: "execution_timeout",
                  execution_context: strategy_request.execution_context
                },
                warnings: ["Planning execution timed out, returning partial results"]
              )
            else
              PlanningResponse.timeout(
                strategy_request.request_id,
                %{execution_time_ms: execution_time_ms},
                strategy_used: :hybrid_coordinator,
                execution_metadata: %{
                  timeout_at: DateTime.utc_now(),
                  planner_version: "hybrid_coordinator_v2",
                  execution_context: strategy_request.execution_context
                }
              )
            end
        end

        # Update execution statistics
        updated_stats = update_execution_stats(state.execution_stats, result, execution_time_ms)
        new_state = %{state | execution_stats: updated_stats}

        # Send notification about execution completion
        send_notification({:strategy_execution_completed, strategy_request.request_id, :hybrid_coordinator, result})

        # Send performance metrics if enabled
        if state.enable_performance_monitoring do
          metrics = %{
            execution_time_ms: execution_time_ms,
            strategy: :hybrid_coordinator,
            result_status: elem(result, 0),
            request_id: strategy_request.request_id
          }
          send_notification({:performance_metrics, strategy_request.request_id, metrics})
        end

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: response,
          metadata: %{
            strategy: :hybrid_coordinator,
            execution_time_ms: execution_time_ms,
            request_id: strategy_request.request_id,
            completed_at: DateTime.utc_now()
          }
        }

        {[buffer: {:output, output_buffer}], new_state}

      rescue
        error ->
          end_time = System.monotonic_time(:millisecond)
          execution_time_ms = end_time - start_time

          Logger.error("❌ HybridCoordinator exception for request: #{strategy_request.request_id}")
          Logger.error("❌ Exception: #{inspect(error)}")

          # Create error response
          error_response = PlanningResponse.error(
            "HybridCoordinator execution exception: #{Exception.message(error)}",
            strategy_request.request_id,
            %{execution_time_ms: execution_time_ms},
            strategy_used: :hybrid_coordinator,
            execution_metadata: %{
              failed_at: DateTime.utc_now(),
              planner_version: "hybrid_coordinator_v2",
              exception: Exception.message(error),
              execution_context: strategy_request.execution_context
            }
          )

          # Update stats for exception
          updated_stats = update_execution_stats(state.execution_stats, {:error, error}, execution_time_ms)
          new_state = %{state | execution_stats: updated_stats}

          # Send notifications
          send_notification({:strategy_execution_completed, strategy_request.request_id, :hybrid_coordinator, {:error, error}})

          output_buffer = %Membrane.Buffer{
            payload: error_response,
            metadata: %{
              strategy: :hybrid_coordinator,
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

  defp execute_with_timeout(strategy_request, state) do
    planning_params = strategy_request.planning_params
    timeout_ms = min(strategy_request.timeout_ms, state.max_execution_time_ms)

    # Create task for planning execution
    task = Task.async(fn ->
      execute_hybrid_coordinator(planning_params, strategy_request, state)
    end)

    # Wait for result with timeout
    case Task.yield(task, timeout_ms) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:timeout, nil}
    end
  end

  defp execute_hybrid_coordinator(planning_params, strategy_request, state) do
    # Extract planning parameters
    domain = planning_params.domain
    state_data = planning_params.state
    goals = planning_params.goals
    options = planning_params.options ++ [strategy_config: StrategyRequest.get_strategy_config(strategy_request)]

    # Execute HybridCoordinatorV2
    case HybridCoordinatorV2.plan(domain, state_data, goals, options) do
      {:ok, plan} ->
        {:ok, plan}

      {:error, reason} ->
        {:error, reason}

      other ->
        {:error, "Unexpected result from HybridCoordinatorV2: #{inspect(other)}"}
    end
  end

  defp convert_to_unified_format(plan_result, strategy_request) do
    # Convert HybridCoordinatorV2 result to unified format following ADR-134
    %{
      actions: convert_actions_to_unified_format(plan_result),
      timeline: generate_timeline_from_plan(plan_result),
      resource_allocation: extract_resource_allocation(plan_result),
      validation_status: determine_validation_status(plan_result)
    }
  end

  defp convert_actions_to_unified_format(plan_result) do
    # Convert plan actions to unified action format
    case plan_result do
      %{actions: actions} when is_list(actions) ->
        Enum.map(actions, &convert_action_to_unified/1)

      actions when is_list(actions) ->
        Enum.map(actions, &convert_action_to_unified/1)

      _ ->
        []
    end
  end

  defp convert_action_to_unified(action) do
    # Convert individual action to unified format
    %{
      name: extract_action_name(action),
      duration: extract_action_duration(action),
      start: extract_action_start(action),
      end: extract_action_end(action),
      requires_entities: extract_required_entities(action),
      description: extract_action_description(action),
      metadata: extract_action_metadata(action)
    }
  end

  defp extract_action_name(action) do
    cond do
      is_atom(action) -> action
      is_tuple(action) -> elem(action, 0)
      is_map(action) -> Map.get(action, :name, :unknown_action)
      true -> :unknown_action
    end
  end

  defp extract_action_duration(action) do
    # Extract duration in ISO 8601 format if available
    cond do
      is_map(action) and Map.has_key?(action, :duration) ->
        duration = Map.get(action, :duration)
        if is_binary(duration), do: duration, else: nil

      true -> nil
    end
  end

  defp extract_action_start(action) do
    # Extract start time in ISO 8601 format if available
    cond do
      is_map(action) and Map.has_key?(action, :start) ->
        start_time = Map.get(action, :start)
        if is_binary(start_time), do: start_time, else: nil

      true -> nil
    end
  end

  defp extract_action_end(action) do
    # Extract end time in ISO 8601 format if available
    cond do
      is_map(action) and Map.has_key?(action, :end) ->
        end_time = Map.get(action, :end)
        if is_binary(end_time), do: end_time, else: nil

      true -> nil
    end
  end

  defp extract_required_entities(action) do
    # Extract entity requirements following ADR-134 format
    cond do
      is_map(action) and Map.has_key?(action, :requires_entities) ->
        Map.get(action, :requires_entities, [])

      true -> []
    end
  end

  defp extract_action_description(action) do
    cond do
      is_map(action) and Map.has_key?(action, :description) ->
        Map.get(action, :description)

      is_atom(action) ->
        action |> to_string() |> String.replace("_", " ") |> String.capitalize()

      true -> "Action execution"
    end
  end

  defp extract_action_metadata(action) do
    cond do
      is_map(action) ->
        Map.drop(action, [:name, :duration, :start, :end, :requires_entities, :description])

      true -> %{}
    end
  end

  defp generate_timeline_from_plan(plan_result) do
    # Generate timeline events from plan
    actions = convert_actions_to_unified_format(plan_result)

    Enum.flat_map(actions, fn action ->
      events = []

      # Add start event if start time is available
      events = if action.start do
        [%{
          time: action.start,
          event_type: :action_start,
          action_id: to_string(action.name),
          description: "#{action.description} started",
          metadata: %{action: action.name}
        } | events]
      else
        events
      end

      # Add end event if end time is available
      events = if action.end do
        [%{
          time: action.end,
          event_type: :action_end,
          action_id: to_string(action.name),
          description: "#{action.description} completed",
          metadata: %{action: action.name}
        } | events]
      else
        events
      end

      events
    end)
    |> Enum.sort_by(fn event -> event.time || "0" end)
  end

  defp extract_resource_allocation(plan_result) do
    # Extract resource allocation information
    cond do
      is_map(plan_result) and Map.has_key?(plan_result, :resource_allocation) ->
        Map.get(plan_result, :resource_allocation)

      is_map(plan_result) and Map.has_key?(plan_result, :resources) ->
        Map.get(plan_result, :resources)

      true -> %{}
    end
  end

  defp determine_validation_status(plan_result) do
    # Determine if the plan is valid
    cond do
      is_map(plan_result) and Map.has_key?(plan_result, :valid) ->
        if Map.get(plan_result, :valid), do: :valid, else: :invalid

      is_map(plan_result) and Map.has_key?(plan_result, :validation_status) ->
        Map.get(plan_result, :validation_status)

      # Assume valid if we got a result
      true -> :valid
    end
  end

  defp extract_performance_metrics(plan_result, execution_time_ms) do
    base_metrics = %{
      execution_time_ms: execution_time_ms,
      strategy: :hybrid_coordinator
    }

    # Add plan-specific metrics if available
    cond do
      is_map(plan_result) and Map.has_key?(plan_result, :metrics) ->
        Map.merge(base_metrics, Map.get(plan_result, :metrics))

      is_map(plan_result) and Map.has_key?(plan_result, :performance) ->
        Map.merge(base_metrics, Map.get(plan_result, :performance))

      true -> base_metrics
    end
  end

  defp update_execution_stats(stats, result, execution_time_ms) do
    new_total = stats.total_requests + 1

    updated_stats = case result do
      {:ok, _} ->
        %{stats |
          successful_executions: stats.successful_executions + 1,
          total_requests: new_total
        }

      {:error, _} ->
        %{stats |
          failed_executions: stats.failed_executions + 1,
          total_requests: new_total
        }

      {:timeout, _} ->
        %{stats |
          timeout_executions: stats.timeout_executions + 1,
          total_requests: new_total
        }
    end

    # Update average execution time
    current_avg = stats.average_execution_time_ms
    new_avg = ((current_avg * (new_total - 1)) + execution_time_ms) / new_total

    %{updated_stats | average_execution_time_ms: new_avg}
  end

  defp send_notification(notification) do
    # Send notification to parent bin
    send(self(), {:child_notification, notification})
  end
end
