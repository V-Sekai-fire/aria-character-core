# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.ResponseAggregatorFilter do
  @moduledoc """
  Membrane filter that aggregates planning responses from multiple strategies.

  This filter collects responses from different strategy filters, handles
  timeout scenarios, and selects the best response based on configurable
  criteria. Supports both single-strategy and multi-strategy execution modes.

  Follows the unified action specification from ADR-134 with standardized
  response format and comprehensive result analysis.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W033RAGG"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.Format.PlanningResponse

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningResponse},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningResponse},
    flow_control: :auto
  )

  def_options(
    aggregation_timeout_ms: [
      spec: pos_integer(),
      default: 60_000,
      description: "Maximum time to wait for all responses"
    ],
    selection_strategy: [
      spec: :first_success | :best_quality | :fastest | :most_actions | :custom,
      default: :best_quality,
      description: "Strategy for selecting the best response"
    ],
    enable_multi_strategy: [
      spec: boolean(),
      default: false,
      description: "Enable collection from multiple strategies"
    ],
    quality_weights: [
      spec: %{atom() => float()},
      default: %{
        execution_time: 0.3,
        plan_length: 0.2,
        strategy_reliability: 0.3,
        solution_optimality: 0.2
      },
      description: "Weights for quality-based selection"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Response Aggregator Filter")
    Logger.info("🔧 Aggregation timeout: #{opts.aggregation_timeout_ms}ms")
    Logger.info("🔧 Selection strategy: #{opts.selection_strategy}")
    Logger.info("🔧 Multi-strategy enabled: #{opts.enable_multi_strategy}")

    state = %{
      aggregation_timeout_ms: opts.aggregation_timeout_ms,
      selection_strategy: opts.selection_strategy,
      enable_multi_strategy: opts.enable_multi_strategy,
      quality_weights: opts.quality_weights,
      pending_requests: %{},
      aggregation_stats: %{
        total_requests: 0,
        successful_aggregations: 0,
        timeout_aggregations: 0,
        multi_strategy_selections: 0,
        average_aggregation_time_ms: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    planning_response = buffer.payload

    Logger.info("🔧 Processing response: #{planning_response.request_id}")

    start_time = System.monotonic_time(:millisecond)

    try do
      # Check if this is a single-strategy response or part of multi-strategy
      if state.enable_multi_strategy do
        # Handle multi-strategy aggregation
        handle_multi_strategy_response(planning_response, buffer, state, start_time)
      else
        # Handle single-strategy response (pass-through with validation)
        handle_single_strategy_response(planning_response, buffer, state, start_time)
      end

    rescue
      error ->
        Logger.error("❌ Response aggregation exception: #{planning_response.request_id}")
        Logger.error("❌ Exception: #{inspect(error)}")

        # Create exception error response
        error_response = PlanningResponse.create_error(
          planning_response.request_id,
          "Response aggregation exception: #{Exception.message(error)}",
          "aggregator"
        )

        # Update stats
        updated_stats = update_aggregation_stats(state.aggregation_stats, :error, 0)
        new_state = %{state | aggregation_stats: updated_stats}

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: error_response,
          metadata: %{
            aggregation_status: :exception,
            aggregation_exception: Exception.message(error),
            request_id: planning_response.request_id,
            aggregated_at: DateTime.utc_now()
          }
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  # Private functions

  defp handle_single_strategy_response(planning_response, buffer, state, start_time) do
    end_time = System.monotonic_time(:millisecond)
    aggregation_time_ms = end_time - start_time

    Logger.info("✅ Single strategy response processed: #{planning_response.request_id}")

    # Update aggregation statistics
    updated_stats = update_aggregation_stats(state.aggregation_stats, :success, aggregation_time_ms)
    new_state = %{state | aggregation_stats: updated_stats}

    # Create output buffer with aggregation metadata
    output_buffer = %Membrane.Buffer{
      payload: planning_response,
      metadata: Map.merge(buffer.metadata || %{}, %{
        aggregation_status: :single_strategy,
        aggregation_time_ms: aggregation_time_ms,
        aggregated_at: DateTime.utc_now()
      })
    }

    {[buffer: {:output, output_buffer}], new_state}
  end

  defp handle_multi_strategy_response(planning_response, buffer, state, start_time) do
    request_id = planning_response.request_id

    # Get or create pending request entry
    pending_request = Map.get(state.pending_requests, request_id, %{
      responses: [],
      start_time: start_time,
      timeout_ref: nil
    })

    # Add this response to the collection
    updated_responses = [%{response: planning_response, metadata: buffer.metadata} | pending_request.responses]

    # Check if we should wait for more responses or select now
    should_select = should_select_response?(updated_responses, state)

    if should_select do
      # Select best response and output
      select_and_output_response(request_id, updated_responses, state, start_time)
    else
      # Continue waiting for more responses
      continue_waiting_for_responses(request_id, pending_request, updated_responses, state)
    end
  end

  defp should_select_response?(responses, state) do
    case state.selection_strategy do
      :first_success ->
        # Select immediately on first successful response
        Enum.any?(responses, fn %{response: resp} -> PlanningResponse.success?(resp) end)

      :fastest ->
        # Select immediately on any response (fastest wins)
        length(responses) >= 1

      _ ->
        # For quality-based selection, wait for timeout or multiple responses
        length(responses) >= 2 or check_timeout_condition(responses, state)
    end
  end

  defp check_timeout_condition(responses, state) do
    # Check if we've been waiting too long
    case responses do
      [%{response: %{request_id: request_id}} | _] ->
        pending_request = Map.get(state.pending_requests, request_id)
        if pending_request do
          elapsed = System.monotonic_time(:millisecond) - pending_request.start_time
          elapsed >= state.aggregation_timeout_ms
        else
          true  # No pending request found, select immediately
        end
      _ ->
        true  # No responses, something went wrong
    end
  end

  defp select_and_output_response(request_id, responses, state, start_time) do
    end_time = System.monotonic_time(:millisecond)
    aggregation_time_ms = end_time - start_time

    # Select best response based on strategy
    selected = select_best_response(responses, state.selection_strategy, state.quality_weights)

    Logger.info("✅ Multi-strategy response selected: #{request_id}")
    Logger.info("🔧 Selected strategy: #{selected.response.strategy}")
    Logger.info("🔧 Total responses considered: #{length(responses)}")

    # Clean up pending request
    updated_pending = Map.delete(state.pending_requests, request_id)

    # Update aggregation statistics
    updated_stats = update_aggregation_stats(
      state.aggregation_stats,
      :multi_strategy,
      aggregation_time_ms
    )

    new_state = %{state |
      pending_requests: updated_pending,
      aggregation_stats: updated_stats
    }

    # Create output buffer with aggregation metadata
    output_buffer = %Membrane.Buffer{
      payload: selected.response,
      metadata: Map.merge(selected.metadata || %{}, %{
        aggregation_status: :multi_strategy_selected,
        aggregation_time_ms: aggregation_time_ms,
        total_responses: length(responses),
        selection_strategy: state.selection_strategy,
        aggregated_at: DateTime.utc_now()
      })
    }

    {[buffer: {:output, output_buffer}], new_state}
  end

  defp continue_waiting_for_responses(request_id, pending_request, updated_responses, state) do
    # Update pending request with new response
    updated_pending_request = %{pending_request | responses: updated_responses}

    # Set up timeout if not already set
    timeout_ref = if pending_request.timeout_ref do
      pending_request.timeout_ref
    else
      # Schedule timeout
      Process.send_after(self(), {:aggregation_timeout, request_id}, state.aggregation_timeout_ms)
    end

    updated_pending_request = %{updated_pending_request | timeout_ref: timeout_ref}

    # Update state
    updated_pending = Map.put(state.pending_requests, request_id, updated_pending_request)
    new_state = %{state | pending_requests: updated_pending}

    Logger.info("🔄 Waiting for more responses: #{request_id} (#{length(updated_responses)} received)")

    # No output yet, continue waiting
    {[], new_state}
  end

  defp select_best_response(responses, selection_strategy, quality_weights) do
    case selection_strategy do
      :first_success ->
        # Select first successful response
        Enum.find(responses, fn %{response: resp} -> PlanningResponse.success?(resp) end) ||
        List.first(responses)

      :fastest ->
        # Select response with shortest execution time
        Enum.min_by(responses, fn %{metadata: meta} ->
          Map.get(meta || %{}, :execution_time_ms, 999_999)
        end)

      :most_actions ->
        # Select response with most actions in plan
        Enum.max_by(responses, fn %{response: resp} ->
          case resp do
            %{actions: actions} when is_list(actions) -> length(actions)
            _ -> 0
          end
        end)

      :best_quality ->
        # Select response with best quality score
        select_by_quality_score(responses, quality_weights)

      :custom ->
        # Use custom selection logic (placeholder for future extension)
        select_by_quality_score(responses, quality_weights)
    end
  end

  defp select_by_quality_score(responses, quality_weights) do
    # Calculate quality scores for each response
    scored_responses = Enum.map(responses, fn response_data ->
      score = calculate_quality_score(response_data, quality_weights)
      {response_data, score}
    end)

    # Select response with highest score
    {best_response, _score} = Enum.max_by(scored_responses, fn {_resp, score} -> score end)
    best_response
  end

  defp calculate_quality_score(%{response: response, metadata: metadata}, weights) do
    # Normalize execution time (lower is better)
    execution_time_score = case Map.get(metadata || %{}, :execution_time_ms) do
      nil -> 0.5  # Default score for missing data
      time when time <= 1000 -> 1.0  # Excellent
      time when time <= 5000 -> 0.8  # Good
      time when time <= 15000 -> 0.6  # Acceptable
      time when time <= 30000 -> 0.4  # Slow
      _ -> 0.2  # Very slow
    end

    # Normalize plan length (more actions can be better for complex problems)
    plan_length_score = case response do
      %{actions: actions} when is_list(actions) ->
        length = length(actions)
        cond do
          length == 0 -> 0.0  # No plan
          length <= 5 -> 1.0  # Concise plan
          length <= 15 -> 0.8  # Reasonable plan
          length <= 30 -> 0.6  # Complex plan
          true -> 0.4  # Very complex plan
        end
      _ -> 0.0  # No actions
    end

    # Strategy reliability (based on known performance)
    strategy_reliability_score = case response.strategy do
      "hybrid_coordinator" -> 0.9  # Most reliable
      "lazy_execution" -> 0.8      # Good for simple problems
      "minizinc" -> 0.7            # Good for complex problems
      "mock" -> 0.1                # Testing only
      _ -> 0.5                     # Unknown strategy
    end

    # Solution optimality (based on response metadata)
    solution_optimality_score = case response do
      %{metadata: %{optimization_used: true}} -> 1.0
      %{metadata: %{refinement_used: true}} -> 0.8
      %{status: :success} -> 0.6
      _ -> 0.3
    end

    # Calculate weighted score
    (execution_time_score * weights.execution_time) +
    (plan_length_score * weights.plan_length) +
    (strategy_reliability_score * weights.strategy_reliability) +
    (solution_optimality_score * weights.solution_optimality)
  end

  defp update_aggregation_stats(stats, result, aggregation_time_ms) do
    new_total = stats.total_requests + 1

    updated_stats = case result do
      :success ->
        %{stats |
          total_requests: new_total,
          successful_aggregations: stats.successful_aggregations + 1
        }

      :multi_strategy ->
        %{stats |
          total_requests: new_total,
          successful_aggregations: stats.successful_aggregations + 1,
          multi_strategy_selections: stats.multi_strategy_selections + 1
        }

      :timeout ->
        %{stats |
          total_requests: new_total,
          timeout_aggregations: stats.timeout_aggregations + 1
        }

      :error ->
        %{stats |
          total_requests: new_total
        }
    end

    # Update average aggregation time
    if aggregation_time_ms > 0 do
      current_avg = stats.average_aggregation_time_ms
      new_avg = ((current_avg * (new_total - 1)) + aggregation_time_ms) / new_total

      %{updated_stats | average_aggregation_time_ms: new_avg}
    else
      updated_stats
    end
  end

  @impl true
  def handle_info({:aggregation_timeout, request_id}, state) do
    case Map.get(state.pending_requests, request_id) do
      nil ->
        # Request already processed
        {[], state}

      pending_request ->
        Logger.warn("⏰ Aggregation timeout for request: #{request_id}")
        Logger.info("🔧 Responses received: #{length(pending_request.responses)}")

        # Select best response from what we have
        if length(pending_request.responses) > 0 do
          select_and_output_response(
            request_id,
            pending_request.responses,
            state,
            pending_request.start_time
          )
        else
          # No responses received, create timeout error
          error_response = PlanningResponse.create_error(
            request_id,
            "Aggregation timeout: no responses received",
            "aggregator"
          )

          # Clean up pending request
          updated_pending = Map.delete(state.pending_requests, request_id)

          # Update stats
          updated_stats = update_aggregation_stats(state.aggregation_stats, :timeout, 0)

          new_state = %{state |
            pending_requests: updated_pending,
            aggregation_stats: updated_stats
          }

          # Create output buffer
          output_buffer = %Membrane.Buffer{
            payload: error_response,
            metadata: %{
              aggregation_status: :timeout,
              request_id: request_id,
              aggregated_at: DateTime.utc_now()
            }
          }

          {[buffer: {:output, output_buffer}], new_state}
        end
    end
  end
end
