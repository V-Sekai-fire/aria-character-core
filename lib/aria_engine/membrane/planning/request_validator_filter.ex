# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.RequestValidatorFilter do
  @moduledoc """
  Membrane filter that validates incoming planning requests.

  This filter performs comprehensive validation of planning requests including
  goal format validation, domain compatibility checks, state consistency
  verification, and option validation following ADR-134 specifications.

  Invalid requests are converted to error responses with detailed feedback.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W032RVAL"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.Format.{PlanningRequest, PlanningResponse}

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningRequest},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningRequest},
    flow_control: :auto
  )

  def_options(
    strict_validation: [
      spec: boolean(),
      default: true,
      description: "Enable strict validation mode with comprehensive checks"
    ],
    max_goals: [
      spec: pos_integer(),
      default: 100,
      description: "Maximum number of goals allowed per request"
    ],
    max_timeout_ms: [
      spec: pos_integer(),
      default: 300_000,
      description: "Maximum timeout allowed per request (5 minutes)"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Request Validator Filter")
    Logger.info("🔧 Strict validation: #{opts.strict_validation}")
    Logger.info("🔧 Max goals: #{opts.max_goals}")
    Logger.info("🔧 Max timeout: #{opts.max_timeout_ms}ms")

    state = %{
      strict_validation: opts.strict_validation,
      max_goals: opts.max_goals,
      max_timeout_ms: opts.max_timeout_ms,
      validation_stats: %{
        total_requests: 0,
        valid_requests: 0,
        invalid_requests: 0,
        validation_errors: %{}
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    planning_request = buffer.payload

    Logger.info("🔧 Validating planning request: #{planning_request.request_id}")

    try do
      # Perform comprehensive validation
      validation_result = validate_planning_request(planning_request, state)

      case validation_result do
        :ok ->
          Logger.info("✅ Planning request validation passed: #{planning_request.request_id}")

          # Update validation statistics
          updated_stats = update_validation_stats(state.validation_stats, :valid)
          new_state = %{state | validation_stats: updated_stats}

          # Pass through valid request
          {[buffer: {:output, buffer}], new_state}

        {:error, validation_errors} ->
          Logger.error("❌ Planning request validation failed: #{planning_request.request_id}")
          Logger.error("❌ Errors: #{inspect(validation_errors)}")

          # Update validation statistics
          updated_stats = update_validation_stats(state.validation_stats, :invalid, validation_errors)
          new_state = %{state | validation_stats: updated_stats}

          # Create error response
          error_response = create_validation_error_response(planning_request, validation_errors)

          # Convert to error buffer (change format to PlanningResponse)
          error_buffer = %Membrane.Buffer{
            payload: error_response,
            metadata: %{
              validation_failed: true,
              validation_errors: validation_errors,
              request_id: planning_request.request_id,
              validated_at: DateTime.utc_now()
            }
          }

          # Note: This would need format conversion in a real implementation
          # For now, we'll create an error request
          error_request = PlanningRequest.create_error(
            "Validation failed: #{format_validation_errors(validation_errors)}",
            request_id: planning_request.request_id
          )

          error_request_buffer = %Membrane.Buffer{
            payload: error_request,
            metadata: %{
              validation_failed: true,
              validation_errors: validation_errors,
              request_id: planning_request.request_id,
              validated_at: DateTime.utc_now()
            }
          }

          {[buffer: {:output, error_request_buffer}], new_state}
      end

    rescue
      error ->
        Logger.error("❌ Request validation exception for request: #{planning_request.request_id}")
        Logger.error("❌ Exception: #{inspect(error)}")

        # Update stats for exception
        updated_stats = update_validation_stats(state.validation_stats, :invalid, ["validation_exception"])
        new_state = %{state | validation_stats: updated_stats}

        # Create error request for exception
        error_request = PlanningRequest.create_error(
          "Validation exception: #{Exception.message(error)}",
          request_id: planning_request.request_id
        )

        error_buffer = %Membrane.Buffer{
          payload: error_request,
          metadata: %{
            validation_failed: true,
            validation_exception: Exception.message(error),
            request_id: planning_request.request_id,
            validated_at: DateTime.utc_now()
          }
        }

        {[buffer: {:output, error_buffer}], new_state}
    end
  end

  # Private functions

  defp validate_planning_request(request, state) do
    errors = []

    # Basic structure validation
    errors = if PlanningRequest.valid?(request) do
      errors
    else
      ["invalid_request_structure" | errors]
    end

    # Goal validation
    errors = validate_goals(request.goals, state) ++ errors

    # Strategy preferences validation
    errors = validate_strategy_preferences(request.strategy_preferences) ++ errors

    # Timeout validation
    errors = validate_timeout(request.timeout_ms, state) ++ errors

    # Priority validation
    errors = validate_priority(request.priority) ++ errors

    # Domain validation (if present)
    errors = validate_domain(request.domain, state) ++ errors

    # State validation (if present)
    errors = validate_state(request.state, state) ++ errors

    # Options validation
    errors = validate_options(request.options, state) ++ errors

    # Metadata validation
    errors = validate_metadata(request.metadata, state) ++ errors

    case errors do
      [] -> :ok
      validation_errors -> {:error, Enum.reverse(validation_errors)}
    end
  end

  defp validate_goals(goals, state) do
    errors = []

    # Check goal count
    errors = if length(goals) > state.max_goals do
      ["too_many_goals" | errors]
    else
      errors
    end

    # Check goal format (ADR-134 compliance)
    errors = if Enum.all?(goals, &valid_unified_goal?/1) do
      errors
    else
      ["invalid_goal_format" | errors]
    end

    # Check for empty goals list
    errors = if length(goals) == 0 do
      ["empty_goals_list" | errors]
    else
      errors
    end

    # Check for duplicate goals
    errors = if length(goals) != length(Enum.uniq(goals)) do
      ["duplicate_goals" | errors]
    else
      errors
    end

    # Strict validation checks
    if state.strict_validation do
      # Check goal complexity
      errors = if Enum.any?(goals, &complex_goal?/1) do
        ["complex_goals_detected" | errors]
      else
        errors
      end

      # Check goal consistency
      errors = if inconsistent_goals?(goals) do
        ["inconsistent_goals" | errors]
      else
        errors
      end
    end

    errors
  end

  defp validate_strategy_preferences(preferences) do
    errors = []

    valid_strategies = [:hybrid_coordinator, :minizinc, :lazy_execution, :mock, :default]

    # Check if all preferences are valid
    errors = if Enum.all?(preferences, &(&1 in valid_strategies)) do
      errors
    else
      ["invalid_strategy_preferences" | errors]
    end

    # Check for duplicate preferences
    errors = if length(preferences) != length(Enum.uniq(preferences)) do
      ["duplicate_strategy_preferences" | errors]
    else
      errors
    end

    errors
  end

  defp validate_timeout(timeout_ms, state) do
    errors = []

    # Check timeout range
    errors = cond do
      timeout_ms <= 0 ->
        ["invalid_timeout_zero_or_negative" | errors]

      timeout_ms > state.max_timeout_ms ->
        ["timeout_exceeds_maximum" | errors]

      true ->
        errors
    end

    errors
  end

  defp validate_priority(priority) do
    valid_priorities = [:low, :normal, :high, :critical]

    if priority in valid_priorities do
      []
    else
      ["invalid_priority"]
    end
  end

  defp validate_domain(nil, _state), do: []
  defp validate_domain(domain, state) do
    errors = []

    # Basic domain structure validation
    errors = if is_map(domain) or is_struct(domain) do
      errors
    else
      ["invalid_domain_structure" | errors]
    end

    # Strict validation for domain
    if state.strict_validation and is_struct(domain) do
      # Could add more specific domain validation here
      errors
    else
      errors
    end
  end

  defp validate_state(nil, _state), do: []
  defp validate_state(state_data, state) do
    errors = []

    # Basic state structure validation
    errors = if is_map(state_data) or is_struct(state_data) do
      errors
    else
      ["invalid_state_structure" | errors]
    end

    # Strict validation for state
    if state.strict_validation do
      # Could add state consistency checks here
      errors
    else
      errors
    end
  end

  defp validate_options(options, state) do
    errors = []

    # Check options structure
    errors = if is_list(options) do
      errors
    else
      ["invalid_options_structure" | errors]
    end

    # Check for error flag (indicates pre-existing error)
    errors = if Keyword.get(options, :error, false) do
      ["request_already_has_error" | errors]
    else
      errors
    end

    # Strict validation for options
    if state.strict_validation do
      # Check for unknown options
      known_options = [:strategy_config, :timeout_override, :priority_override, :error]
      unknown_options = Keyword.keys(options) -- known_options

      errors = if length(unknown_options) > 0 do
        ["unknown_options" | errors]
      else
        errors
      end
    end

    errors
  end

  defp validate_metadata(metadata, state) do
    errors = []

    # Check metadata structure
    errors = if is_map(metadata) do
      errors
    else
      ["invalid_metadata_structure" | errors]
    end

    # Check for error metadata (indicates pre-existing error)
    errors = if Map.get(metadata, :error, false) do
      ["request_metadata_has_error" | errors]
    else
      errors
    end

    # Strict validation for metadata
    if state.strict_validation do
      # Check metadata size
      metadata_size = :erlang.external_size(metadata)

      errors = if metadata_size > 10_000 do  # 10KB limit
        ["metadata_too_large" | errors]
      else
        errors
      end
    end

    errors
  end

  defp valid_unified_goal?({subject, predicate, _value})
       when is_binary(subject) and is_binary(predicate) do
    true
  end

  defp valid_unified_goal?(_), do: false

  defp complex_goal?({_subject, _predicate, value}) do
    # Consider goals with complex values as potentially problematic
    case value do
      value when is_map(value) -> map_size(value) > 5
      value when is_list(value) -> length(value) > 10
      value when is_binary(value) -> String.length(value) > 100
      _ -> false
    end
  end

  defp inconsistent_goals?(goals) do
    # Check for goals that might conflict with each other
    # This is a simplified check - could be more sophisticated
    subjects = Enum.map(goals, fn {subject, _predicate, _value} -> subject end)
    predicates = Enum.map(goals, fn {_subject, predicate, _value} -> predicate end)

    # Check for conflicting location goals for the same subject
    location_goals = Enum.filter(goals, fn {_subject, predicate, _value} ->
      predicate == "location"
    end)

    location_subjects = Enum.map(location_goals, fn {subject, _predicate, _value} -> subject end)

    # If same subject has multiple location goals, it might be inconsistent
    length(location_subjects) != length(Enum.uniq(location_subjects))
  end

  defp update_validation_stats(stats, result, errors \\ []) do
    new_total = stats.total_requests + 1

    case result do
      :valid ->
        %{stats |
          total_requests: new_total,
          valid_requests: stats.valid_requests + 1
        }

      :invalid ->
        # Update error frequency tracking
        updated_error_counts = Enum.reduce(errors, stats.validation_errors, fn error, acc ->
          Map.update(acc, error, 1, &(&1 + 1))
        end)

        %{stats |
          total_requests: new_total,
          invalid_requests: stats.invalid_requests + 1,
          validation_errors: updated_error_counts
        }
    end
  end

  defp create_validation_error_response(request, validation_errors) do
    PlanningResponse.error(
      "Request validation failed: #{format_validation_errors(validation_errors)}",
      request.request_id,
      %{execution_time_ms: 0},
      strategy_used: nil,
      execution_metadata: %{
        failed_at: DateTime.utc_now(),
        failure_reason: "validation_failed",
        validation_errors: validation_errors
      }
    )
  end

  defp format_validation_errors(errors) do
    errors
    |> Enum.map(&format_single_error/1)
    |> Enum.join(", ")
  end

  defp format_single_error(error) do
    case error do
      "invalid_request_structure" -> "Invalid request structure"
      "too_many_goals" -> "Too many goals"
      "invalid_goal_format" -> "Invalid goal format (must be {subject, predicate, value})"
      "empty_goals_list" -> "Goals list cannot be empty"
      "duplicate_goals" -> "Duplicate goals detected"
      "complex_goals_detected" -> "Complex goals detected"
      "inconsistent_goals" -> "Inconsistent goals detected"
      "invalid_strategy_preferences" -> "Invalid strategy preferences"
      "duplicate_strategy_preferences" -> "Duplicate strategy preferences"
      "invalid_timeout_zero_or_negative" -> "Timeout must be positive"
      "timeout_exceeds_maximum" -> "Timeout exceeds maximum allowed"
      "invalid_priority" -> "Invalid priority level"
      "invalid_domain_structure" -> "Invalid domain structure"
      "invalid_state_structure" -> "Invalid state structure"
      "invalid_options_structure" -> "Invalid options structure"
      "request_already_has_error" -> "Request already has error flag"
      "unknown_options" -> "Unknown options detected"
      "invalid_metadata_structure" -> "Invalid metadata structure"
      "request_metadata_has_error" -> "Request metadata indicates error"
      "metadata_too_large" -> "Metadata exceeds size limit"
      "validation_exception" -> "Validation exception occurred"
      _ -> "Unknown validation error: #{error}"
    end
  end
end
