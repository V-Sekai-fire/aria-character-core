# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.TemporalConstraintFilter do
  @moduledoc """
  Membrane filter that adds temporal constraints to HTN planning results.

  This filter is the second stage of the decomposed hybrid coordinator pipeline.
  It takes HTN planning results and adds temporal constraints using temporal
  strategies, then passes the result to temporal validation.

  Pipeline flow: HTNPlanning → TemporalConstraint → TemporalValidation → MiniZinc → Response
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W033TCST"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.HTNPlanningFilter.HTNPlanningResult

  # Define intermediate format for temporal constraint results
  defmodule TemporalConstraintResult do
    @moduledoc "Intermediate result format for temporal constraint stage"

    defstruct [
      :request_id,
      :solution_tree,
      :temporal_constraints,
      :constraint_metadata,
      :original_htn_result,
      :domain,
      :state,
      :goals,
      :options
    ]

    @type t :: %__MODULE__{
      request_id: String.t(),
      solution_tree: map(),
      temporal_constraints: map(),
      constraint_metadata: map(),
      original_htn_result: HTNPlanningResult.t(),
      domain: term(),
      state: map(),
      goals: list(),
      options: keyword()
    }
  end

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: HTNPlanningResult},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: TemporalConstraintResult},
    flow_control: :auto
  )

  def_options(
    temporal_strategy: [
      spec: module(),
      default: nil,
      description: "Temporal constraint strategy module to use"
    ],
    logging_strategy: [
      spec: module(),
      default: nil,
      description: "Logging strategy module to use"
    ],
    max_constraint_time_ms: [
      spec: pos_integer(),
      default: 15_000,
      description: "Maximum time allowed for temporal constraint processing"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Temporal Constraint Filter")
    Logger.info("🔧 Temporal strategy: #{inspect(opts.temporal_strategy)}")
    Logger.info("🔧 Max constraint time: #{opts.max_constraint_time_ms}ms")

    state = %{
      temporal_strategy: opts.temporal_strategy || get_default_temporal_strategy(),
      logging_strategy: opts.logging_strategy || get_default_logging_strategy(),
      max_constraint_time_ms: opts.max_constraint_time_ms,
      constraint_stats: %{
        total_requests: 0,
        successful_constraints: 0,
        failed_constraints: 0,
        average_constraint_time_ms: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    htn_result = buffer.payload

    Logger.info("🔧 Temporal Constraint processing request: #{htn_result.request_id}")

    start_time = System.monotonic_time(:millisecond)

    # Send notification about constraint processing start
    send_notification({:temporal_constraint_started, htn_result.request_id})

    try do
      # Check if HTN planning was successful
      if htn_result.solution_tree do
        # Execute temporal constraint processing with timeout
        result = execute_temporal_constraints_with_timeout(htn_result, state)

        end_time = System.monotonic_time(:millisecond)
        constraint_time_ms = end_time - start_time

        case result do
          {:ok, temporal_constraints} ->
            Logger.info("✅ Temporal Constraint succeeded for request: #{htn_result.request_id}")

            # Create temporal constraint result
            constraint_result = %TemporalConstraintResult{
              request_id: htn_result.request_id,
              solution_tree: htn_result.solution_tree,
              temporal_constraints: temporal_constraints,
              constraint_metadata: %{
                constraint_time_ms: constraint_time_ms,
                constraint_count: count_temporal_constraints(temporal_constraints),
                strategy_used: :temporal_constraint,
                completed_at: DateTime.utc_now()
              },
              original_htn_result: htn_result,
              domain: htn_result.domain,
              state: htn_result.state,
              goals: htn_result.goals,
              options: htn_result.options
            }

            # Update statistics
            updated_stats = update_constraint_stats(state.constraint_stats, :success, constraint_time_ms)
            new_state = %{state | constraint_stats: updated_stats}

            # Send notification about completion
            send_notification({:temporal_constraint_completed, htn_result.request_id, :success})

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: constraint_result,
              metadata: %{
                stage: :temporal_constraint,
                constraint_time_ms: constraint_time_ms,
                request_id: htn_result.request_id,
                success: true
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:error, reason} ->
            Logger.error("❌ Temporal Constraint failed for request: #{htn_result.request_id}")
            Logger.error("❌ Reason: #{inspect(reason)}")

            # Update statistics
            updated_stats = update_constraint_stats(state.constraint_stats, :failure, constraint_time_ms)
            new_state = %{state | constraint_stats: updated_stats}

            # Send notification about failure
            send_notification({:temporal_constraint_completed, htn_result.request_id, {:error, reason}})

            # Create error result (still pass through pipeline for error handling)
            error_result = %TemporalConstraintResult{
              request_id: htn_result.request_id,
              solution_tree: htn_result.solution_tree,
              temporal_constraints: nil,
              constraint_metadata: %{
                constraint_time_ms: constraint_time_ms,
                error_reason: reason,
                strategy_used: :temporal_constraint,
                failed_at: DateTime.utc_now()
              },
              original_htn_result: htn_result,
              domain: htn_result.domain,
              state: htn_result.state,
              goals: htn_result.goals,
              options: htn_result.options
            }

            output_buffer = %Membrane.Buffer{
              payload: error_result,
              metadata: %{
                stage: :temporal_constraint,
                constraint_time_ms: constraint_time_ms,
                request_id: htn_result.request_id,
                success: false,
                error_reason: reason
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:timeout} ->
            Logger.warn("⏰ Temporal Constraint timeout for request: #{htn_result.request_id}")

            # Update statistics
            updated_stats = update_constraint_stats(state.constraint_stats, :timeout, constraint_time_ms)
            new_state = %{state | constraint_stats: updated_stats}

            # Send notification about timeout
            send_notification({:temporal_constraint_completed, htn_result.request_id, :timeout})

            # Create timeout result
            timeout_result = %TemporalConstraintResult{
              request_id: htn_result.request_id,
              solution_tree: htn_result.solution_tree,
              temporal_constraints: nil,
              constraint_metadata: %{
                constraint_time_ms: constraint_time_ms,
                timeout_reason: "Temporal constraint processing exceeded maximum time limit",
                strategy_used: :temporal_constraint,
                timeout_at: DateTime.utc_now()
              },
              original_htn_result: htn_result,
              domain: htn_result.domain,
              state: htn_result.state,
              goals: htn_result.goals,
              options: htn_result.options
            }

            output_buffer = %Membrane.Buffer{
              payload: timeout_result,
              metadata: %{
                stage: :temporal_constraint,
                constraint_time_ms: constraint_time_ms,
                request_id: htn_result.request_id,
                success: false,
                timeout: true
              }
            }

            {[buffer: {:output, output_buffer}], new_state}
        end
      else
        # HTN planning failed, pass through the error
        Logger.info("🔄 Passing through HTN planning failure for request: #{htn_result.request_id}")

        end_time = System.monotonic_time(:millisecond)
        constraint_time_ms = end_time - start_time

        # Create passthrough result for failed HTN planning
        passthrough_result = %TemporalConstraintResult{
          request_id: htn_result.request_id,
          solution_tree: nil,
          temporal_constraints: nil,
          constraint_metadata: %{
            constraint_time_ms: constraint_time_ms,
            passthrough_reason: "HTN planning failed, skipping temporal constraints",
            strategy_used: :temporal_constraint,
            passthrough_at: DateTime.utc_now()
          },
          original_htn_result: htn_result,
          domain: htn_result.domain,
          state: htn_result.state,
          goals: htn_result.goals,
          options: htn_result.options
        }

        output_buffer = %Membrane.Buffer{
          payload: passthrough_result,
          metadata: %{
            stage: :temporal_constraint,
            constraint_time_ms: constraint_time_ms,
            request_id: htn_result.request_id,
            success: false,
            passthrough: true
          }
        }

        {[buffer: {:output, output_buffer}], state}
      end

    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        constraint_time_ms = end_time - start_time

        Logger.error("❌ Temporal Constraint exception for request: #{htn_result.request_id}")
        Logger.error("❌ Exception: #{inspect(error)}")

        # Update statistics
        updated_stats = update_constraint_stats(state.constraint_stats, :exception, constraint_time_ms)
        new_state = %{state | constraint_stats: updated_stats}

        # Send notification about exception
        send_notification({:temporal_constraint_completed, htn_result.request_id, {:exception, error}})

        # Create exception result
        exception_result = %TemporalConstraintResult{
          request_id: htn_result.request_id,
          solution_tree: htn_result.solution_tree,
          temporal_constraints: nil,
          constraint_metadata: %{
            constraint_time_ms: constraint_time_ms,
            exception: Exception.message(error),
            strategy_used: :temporal_constraint,
            failed_at: DateTime.utc_now()
          },
          original_htn_result: htn_result,
          domain: htn_result.domain,
          state: htn_result.state,
          goals: htn_result.goals,
          options: htn_result.options
        }

        output_buffer = %Membrane.Buffer{
          payload: exception_result,
          metadata: %{
            stage: :temporal_constraint,
            constraint_time_ms: constraint_time_ms,
            request_id: htn_result.request_id,
            success: false,
            exception: Exception.message(error)
          }
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  # Private functions

  defp execute_temporal_constraints_with_timeout(htn_result, state) do
    timeout_ms = state.max_constraint_time_ms

    # Create task for temporal constraint processing
    task = Task.async(fn ->
      execute_temporal_constraints(htn_result, state)
    end)

    # Wait for result with timeout
    case Task.yield(task, timeout_ms) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:timeout}
    end
  end

  defp execute_temporal_constraints(htn_result, state) do
    # Extract primitive actions from solution tree
    primitive_actions = extract_primitive_actions(htn_result.solution_tree)
    current_time = Keyword.get(htn_result.options, :current_time, 0)

    # Log start using logging strategy
    state.logging_strategy.log_progress(
      "temporal_constraint",
      %{
        status: "started",
        primitive_actions: length(primitive_actions),
        current_time: current_time
      },
      htn_result.options
    )

    # Use temporal strategy to add constraints
    case state.temporal_strategy.add_temporal_constraints(
           %{},
           primitive_actions,
           Keyword.merge(htn_result.options, current_time: current_time)
         ) do
      {:ok, temporal_constraints} ->
        state.logging_strategy.log_progress(
          "temporal_constraint",
          %{
            status: "completed_successfully",
            constraint_count: count_temporal_constraints(temporal_constraints)
          },
          htn_result.options
        )

        {:ok, temporal_constraints}

      {:error, reason} ->
        state.logging_strategy.log_error(
          reason,
          %{phase: "temporal_constraint"},
          htn_result.options
        )

        {:error, reason}

      other ->
        error_msg = "Unexpected result from temporal constraint strategy: #{inspect(other)}"
        state.logging_strategy.log_error(
          error_msg,
          %{phase: "temporal_constraint"},
          htn_result.options
        )

        {:error, error_msg}
    end
  end

  # Extract primitive actions from solution tree
  defp extract_primitive_actions(solution_tree) do
    case solution_tree do
      %{children: children} when is_list(children) ->
        Enum.flat_map(children, &extract_primitive_actions/1)

      %{task: {action_name, args}, status: :primitive} ->
        [{action_name, args}]

      %{task: task} when is_tuple(task) ->
        [task]

      _ ->
        []
    end
  end

  defp count_temporal_constraints(temporal_constraints) do
    case temporal_constraints do
      %{constraints: constraints} when is_list(constraints) ->
        length(constraints)

      constraints when is_list(constraints) ->
        length(constraints)

      %{} = constraint_map ->
        Map.keys(constraint_map) |> length()

      _ ->
        0
    end
  end

  defp update_constraint_stats(stats, result_type, constraint_time_ms) do
    new_total = stats.total_requests + 1

    updated_stats = case result_type do
      :success ->
        %{stats |
          successful_constraints: stats.successful_constraints + 1,
          total_requests: new_total
        }

      _ ->
        %{stats |
          failed_constraints: stats.failed_constraints + 1,
          total_requests: new_total
        }
    end

    # Update average constraint time
    current_avg = stats.average_constraint_time_ms
    new_avg = ((current_avg * (new_total - 1)) + constraint_time_ms) / new_total

    %{updated_stats | average_constraint_time_ms: new_avg}
  end

  defp get_default_temporal_strategy() do
    # Return a default temporal constraint strategy
    # This would be configured based on available strategies
    AriaEngine.Timeline.DefaultTemporalStrategy
  end

  defp get_default_logging_strategy() do
    # Return a default logging strategy
    # This could be a simple logger wrapper
    AriaEngine.Membrane.Planning.DefaultLoggingStrategy
  end

  defp send_notification(notification) do
    # Send notification to parent bin
    send(self(), {:child_notification, notification})
  end
end
