# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.TemporalValidationFilter do
  @moduledoc """
  Membrane filter that validates temporal constraints for planning results.

  This filter is the third stage of the decomposed hybrid coordinator pipeline.
  It takes temporal constraint results and validates their consistency using temporal
  strategies, then passes the result to the final response stage.

  Pipeline flow: HTNPlanning → TemporalConstraint → TemporalValidation → MiniZinc → Response
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W034TVAL"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.TemporalConstraintFilter.TemporalConstraintResult

  # Define final format for validated temporal planning results
  defmodule TemporalValidationResult do
    @moduledoc "Final result format for temporal validation stage"

    defstruct [
      :request_id,
      :solution_tree,
      :temporal_constraints,
      :validation_result,
      :validation_metadata,
      :original_constraint_result,
      :domain,
      :state,
      :goals,
      :options
    ]

    @type t :: %__MODULE__{
      request_id: String.t(),
      solution_tree: map(),
      temporal_constraints: map(),
      validation_result: boolean() | nil,
      validation_metadata: map(),
      original_constraint_result: TemporalConstraintResult.t(),
      domain: term(),
      state: map(),
      goals: list(),
      options: keyword()
    }
  end

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: TemporalConstraintResult},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: TemporalValidationResult},
    flow_control: :auto
  )

  def_options(
    temporal_strategy: [
      spec: module(),
      default: nil,
      description: "Temporal validation strategy module to use"
    ],
    logging_strategy: [
      spec: module(),
      default: nil,
      description: "Logging strategy module to use"
    ],
    max_validation_time_ms: [
      spec: pos_integer(),
      default: 10_000,
      description: "Maximum time allowed for temporal validation"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Temporal Validation Filter")
    Logger.info("🔧 Temporal strategy: #{inspect(opts.temporal_strategy)}")
    Logger.info("🔧 Max validation time: #{opts.max_validation_time_ms}ms")

    state = %{
      temporal_strategy: opts.temporal_strategy || get_default_temporal_strategy(),
      logging_strategy: opts.logging_strategy || get_default_logging_strategy(),
      max_validation_time_ms: opts.max_validation_time_ms,
      validation_stats: %{
        total_requests: 0,
        successful_validations: 0,
        failed_validations: 0,
        inconsistent_constraints: 0,
        average_validation_time_ms: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    constraint_result = buffer.payload

    Logger.info("🔧 Temporal Validation processing request: #{constraint_result.request_id}")

    start_time = System.monotonic_time(:millisecond)

    # Send notification about validation start
    send_notification({:temporal_validation_started, constraint_result.request_id})

    try do
      # Check if temporal constraints were successfully created
      if constraint_result.temporal_constraints do
        # Execute temporal validation with timeout
        result = execute_temporal_validation_with_timeout(constraint_result, state)

        end_time = System.monotonic_time(:millisecond)
        validation_time_ms = end_time - start_time

        case result do
          {:ok, true} ->
            Logger.info("✅ Temporal Validation succeeded for request: #{constraint_result.request_id}")

            # Create temporal validation result
            validation_result = %TemporalValidationResult{
              request_id: constraint_result.request_id,
              solution_tree: constraint_result.solution_tree,
              temporal_constraints: constraint_result.temporal_constraints,
              validation_result: true,
              validation_metadata: %{
                validation_time_ms: validation_time_ms,
                constraints_validated: count_temporal_constraints(constraint_result.temporal_constraints),
                strategy_used: :temporal_validation,
                completed_at: DateTime.utc_now()
              },
              original_constraint_result: constraint_result,
              domain: constraint_result.domain,
              state: constraint_result.state,
              goals: constraint_result.goals,
              options: constraint_result.options
            }

            # Update statistics
            updated_stats = update_validation_stats(state.validation_stats, :success, validation_time_ms)
            new_state = %{state | validation_stats: updated_stats}

            # Send notification about completion
            send_notification({:temporal_validation_completed, constraint_result.request_id, :success})

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: validation_result,
              metadata: %{
                stage: :temporal_validation,
                validation_time_ms: validation_time_ms,
                request_id: constraint_result.request_id,
                success: true,
                validation_result: true
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:ok, false} ->
            Logger.warn("⚠️ Temporal Validation found inconsistent constraints for request: #{constraint_result.request_id}")

            # Update statistics
            updated_stats = update_validation_stats(state.validation_stats, :inconsistent, validation_time_ms)
            new_state = %{state | validation_stats: updated_stats}

            # Send notification about inconsistency
            send_notification({:temporal_validation_completed, constraint_result.request_id, :inconsistent})

            # Create inconsistent result
            inconsistent_result = %TemporalValidationResult{
              request_id: constraint_result.request_id,
              solution_tree: constraint_result.solution_tree,
              temporal_constraints: constraint_result.temporal_constraints,
              validation_result: false,
              validation_metadata: %{
                validation_time_ms: validation_time_ms,
                inconsistency_reason: "Temporal constraints are inconsistent",
                strategy_used: :temporal_validation,
                failed_at: DateTime.utc_now()
              },
              original_constraint_result: constraint_result,
              domain: constraint_result.domain,
              state: constraint_result.state,
              goals: constraint_result.goals,
              options: constraint_result.options
            }

            output_buffer = %Membrane.Buffer{
              payload: inconsistent_result,
              metadata: %{
                stage: :temporal_validation,
                validation_time_ms: validation_time_ms,
                request_id: constraint_result.request_id,
                success: false,
                validation_result: false
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:error, reason} ->
            Logger.error("❌ Temporal Validation failed for request: #{constraint_result.request_id}")
            Logger.error("❌ Reason: #{inspect(reason)}")

            # Update statistics
            updated_stats = update_validation_stats(state.validation_stats, :failure, validation_time_ms)
            new_state = %{state | validation_stats: updated_stats}

            # Send notification about failure
            send_notification({:temporal_validation_completed, constraint_result.request_id, {:error, reason}})

            # Create error result
            error_result = %TemporalValidationResult{
              request_id: constraint_result.request_id,
              solution_tree: constraint_result.solution_tree,
              temporal_constraints: constraint_result.temporal_constraints,
              validation_result: nil,
              validation_metadata: %{
                validation_time_ms: validation_time_ms,
                error_reason: reason,
                strategy_used: :temporal_validation,
                failed_at: DateTime.utc_now()
              },
              original_constraint_result: constraint_result,
              domain: constraint_result.domain,
              state: constraint_result.state,
              goals: constraint_result.goals,
              options: constraint_result.options
            }

            output_buffer = %Membrane.Buffer{
              payload: error_result,
              metadata: %{
                stage: :temporal_validation,
                validation_time_ms: validation_time_ms,
                request_id: constraint_result.request_id,
                success: false,
                error_reason: reason
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:timeout} ->
            Logger.warn("⏰ Temporal Validation timeout for request: #{constraint_result.request_id}")

            # Update statistics
            updated_stats = update_validation_stats(state.validation_stats, :timeout, validation_time_ms)
            new_state = %{state | validation_stats: updated_stats}

            # Send notification about timeout
            send_notification({:temporal_validation_completed, constraint_result.request_id, :timeout})

            # Create timeout result
            timeout_result = %TemporalValidationResult{
              request_id: constraint_result.request_id,
              solution_tree: constraint_result.solution_tree,
              temporal_constraints: constraint_result.temporal_constraints,
              validation_result: nil,
              validation_metadata: %{
                validation_time_ms: validation_time_ms,
                timeout_reason: "Temporal validation exceeded maximum time limit",
                strategy_used: :temporal_validation,
                timeout_at: DateTime.utc_now()
              },
              original_constraint_result: constraint_result,
              domain: constraint_result.domain,
              state: constraint_result.state,
              goals: constraint_result.goals,
              options: constraint_result.options
            }

            output_buffer = %Membrane.Buffer{
              payload: timeout_result,
              metadata: %{
                stage: :temporal_validation,
                validation_time_ms: validation_time_ms,
                request_id: constraint_result.request_id,
                success: false,
                timeout: true
              }
            }

            {[buffer: {:output, output_buffer}], new_state}
        end
      else
        # Temporal constraints failed, pass through the error
        Logger.info("🔄 Passing through temporal constraint failure for request: #{constraint_result.request_id}")

        end_time = System.monotonic_time(:millisecond)
        validation_time_ms = end_time - start_time

        # Create passthrough result for failed temporal constraints
        passthrough_result = %TemporalValidationResult{
          request_id: constraint_result.request_id,
          solution_tree: constraint_result.solution_tree,
          temporal_constraints: nil,
          validation_result: nil,
          validation_metadata: %{
            validation_time_ms: validation_time_ms,
            passthrough_reason: "Temporal constraints failed, skipping validation",
            strategy_used: :temporal_validation,
            passthrough_at: DateTime.utc_now()
          },
          original_constraint_result: constraint_result,
          domain: constraint_result.domain,
          state: constraint_result.state,
          goals: constraint_result.goals,
          options: constraint_result.options
        }

        output_buffer = %Membrane.Buffer{
          payload: passthrough_result,
          metadata: %{
            stage: :temporal_validation,
            validation_time_ms: validation_time_ms,
            request_id: constraint_result.request_id,
            success: false,
            passthrough: true
          }
        }

        {[buffer: {:output, output_buffer}], state}
      end

    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        validation_time_ms = end_time - start_time

        Logger.error("❌ Temporal Validation exception for request: #{constraint_result.request_id}")
        Logger.error("❌ Exception: #{inspect(error)}")

        # Update statistics
        updated_stats = update_validation_stats(state.validation_stats, :exception, validation_time_ms)
        new_state = %{state | validation_stats: updated_stats}

        # Send notification about exception
        send_notification({:temporal_validation_completed, constraint_result.request_id, {:exception, error}})

        # Create exception result
        exception_result = %TemporalValidationResult{
          request_id: constraint_result.request_id,
          solution_tree: constraint_result.solution_tree,
          temporal_constraints: constraint_result.temporal_constraints,
          validation_result: nil,
          validation_metadata: %{
            validation_time_ms: validation_time_ms,
            exception: Exception.message(error),
            strategy_used: :temporal_validation,
            failed_at: DateTime.utc_now()
          },
          original_constraint_result: constraint_result,
          domain: constraint_result.domain,
          state: constraint_result.state,
          goals: constraint_result.goals,
          options: constraint_result.options
        }

        output_buffer = %Membrane.Buffer{
          payload: exception_result,
          metadata: %{
            stage: :temporal_validation,
            validation_time_ms: validation_time_ms,
            request_id: constraint_result.request_id,
            success: false,
            exception: Exception.message(error)
          }
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  # Private functions

  defp execute_temporal_validation_with_timeout(constraint_result, state) do
    timeout_ms = state.max_validation_time_ms

    # Create task for temporal validation
    task = Task.async(fn ->
      execute_temporal_validation(constraint_result, state)
    end)

    # Wait for result with timeout
    case Task.yield(task, timeout_ms) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:timeout}
    end
  end

  defp execute_temporal_validation(constraint_result, state) do
    temporal_constraints = constraint_result.temporal_constraints

    # Log start using logging strategy
    state.logging_strategy.log_progress(
      "temporal_validation",
      %{
        status: "started",
        constraint_count: count_temporal_constraints(temporal_constraints)
      },
      constraint_result.options
    )

    # Use temporal strategy to validate constraints
    case state.temporal_strategy.validate_temporal_consistency(
           temporal_constraints,
           constraint_result.options
         ) do
      {:ok, validation_result} when is_boolean(validation_result) ->
        state.logging_strategy.log_progress(
          "temporal_validation",
          %{
            status: "completed_successfully",
            validation_result: validation_result
          },
          constraint_result.options
        )

        {:ok, validation_result}

      {:error, reason} ->
        state.logging_strategy.log_error(
          reason,
          %{phase: "temporal_validation"},
          constraint_result.options
        )

        {:error, reason}

      other ->
        error_msg = "Unexpected result from temporal validation strategy: #{inspect(other)}"
        state.logging_strategy.log_error(
          error_msg,
          %{phase: "temporal_validation"},
          constraint_result.options
        )

        {:error, error_msg}
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

  defp update_validation_stats(stats, result_type, validation_time_ms) do
    new_total = stats.total_requests + 1

    updated_stats = case result_type do
      :success ->
        %{stats |
          successful_validations: stats.successful_validations + 1,
          total_requests: new_total
        }

      :inconsistent ->
        %{stats |
          inconsistent_constraints: stats.inconsistent_constraints + 1,
          total_requests: new_total
        }

      _ ->
        %{stats |
          failed_validations: stats.failed_validations + 1,
          total_requests: new_total
        }
    end

    # Update average validation time
    current_avg = stats.average_validation_time_ms
    new_avg = ((current_avg * (new_total - 1)) + validation_time_ms) / new_total

    %{updated_stats | average_validation_time_ms: new_avg}
  end

  defp get_default_temporal_strategy() do
    # Return a default temporal validation strategy
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
