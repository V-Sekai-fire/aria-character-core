# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.RequestConverterFilter do
  @moduledoc """
  Membrane filter that converts planning requests to internal planning parameters.

  This filter transforms validated PlanningRequest structures into PlanningParams
  format suitable for strategy execution. Handles domain preparation, state
  normalization, goal transformation, and metadata enrichment.

  Follows the unified action specification from ADR-134 with standardized
  goal format (subject, predicate, value) and entity+capability model.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W033RCON"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.Format.PlanningRequest
  alias AriaEngine.Membrane.Format.PlanningParams

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningRequest},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningParams},
    flow_control: :auto
  )

  def_options(
    enable_domain_preparation: [
      spec: boolean(),
      default: true,
      description: "Enable domain preparation and validation"
    ],
    enable_state_normalization: [
      spec: boolean(),
      default: true,
      description: "Enable state normalization and consistency checks"
    ],
    enable_goal_transformation: [
      spec: boolean(),
      default: true,
      description: "Enable goal transformation and optimization"
    ],
    conversion_timeout_ms: [
      spec: pos_integer(),
      default: 5_000,
      description: "Maximum time allowed for conversion operations"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Request Converter Filter")
    Logger.info("🔧 Domain preparation: #{opts.enable_domain_preparation}")
    Logger.info("🔧 State normalization: #{opts.enable_state_normalization}")
    Logger.info("🔧 Goal transformation: #{opts.enable_goal_transformation}")
    Logger.info("🔧 Conversion timeout: #{opts.conversion_timeout_ms}ms")

    state = %{
      enable_domain_preparation: opts.enable_domain_preparation,
      enable_state_normalization: opts.enable_state_normalization,
      enable_goal_transformation: opts.enable_goal_transformation,
      conversion_timeout_ms: opts.conversion_timeout_ms,
      conversion_stats: %{
        total_conversions: 0,
        successful_conversions: 0,
        failed_conversions: 0,
        average_conversion_time_ms: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    planning_request = buffer.payload

    Logger.info("🔧 Converting planning request: #{planning_request.request_id}")

    start_time = System.monotonic_time(:millisecond)

    try do
      # Check if request is already an error
      if PlanningRequest.error?(planning_request) do
        Logger.warn("⚠️ Converting error request: #{planning_request.request_id}")

        # Create error planning params
        error_params = PlanningParams.create_error(
          planning_request.request_id,
          PlanningRequest.error_reason(planning_request) || "Unknown error"
        )

        # Update stats
        updated_stats = update_conversion_stats(state.conversion_stats, :error, 0)
        new_state = %{state | conversion_stats: updated_stats}

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: error_params,
          metadata: %{
            conversion_status: :error,
            request_id: planning_request.request_id,
            converted_at: DateTime.utc_now()
          }
        }

        {[buffer: {:output, output_buffer}], new_state}
      else
        # Perform conversion with timeout
        conversion_result = convert_with_timeout(planning_request, state)

        end_time = System.monotonic_time(:millisecond)
        conversion_time_ms = end_time - start_time

        case conversion_result do
          {:ok, planning_params} ->
            Logger.info("✅ Request conversion successful: #{planning_request.request_id}")

            # Update conversion statistics
            updated_stats = update_conversion_stats(state.conversion_stats, :success, conversion_time_ms)
            new_state = %{state | conversion_stats: updated_stats}

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: planning_params,
              metadata: %{
                conversion_status: :success,
                conversion_time_ms: conversion_time_ms,
                request_id: planning_request.request_id,
                converted_at: DateTime.utc_now()
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:error, reason} ->
            Logger.error("❌ Request conversion failed: #{planning_request.request_id}")
            Logger.error("❌ Reason: #{inspect(reason)}")

            # Create error planning params
            error_params = PlanningParams.create_error(
              planning_request.request_id,
              "Conversion failed: #{inspect(reason)}"
            )

            # Update stats
            updated_stats = update_conversion_stats(state.conversion_stats, :error, conversion_time_ms)
            new_state = %{state | conversion_stats: updated_stats}

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: error_params,
              metadata: %{
                conversion_status: :error,
                conversion_time_ms: conversion_time_ms,
                conversion_error: inspect(reason),
                request_id: planning_request.request_id,
                converted_at: DateTime.utc_now()
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:timeout} ->
            Logger.error("⏰ Request conversion timeout: #{planning_request.request_id}")

            # Create timeout error params
            error_params = PlanningParams.create_error(
              planning_request.request_id,
              "Conversion timeout after #{state.conversion_timeout_ms}ms"
            )

            # Update stats
            updated_stats = update_conversion_stats(state.conversion_stats, :error, conversion_time_ms)
            new_state = %{state | conversion_stats: updated_stats}

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: error_params,
              metadata: %{
                conversion_status: :timeout,
                conversion_time_ms: conversion_time_ms,
                request_id: planning_request.request_id,
                converted_at: DateTime.utc_now()
              }
            }

            {[buffer: {:output, output_buffer}], new_state}
        end
      end

    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        conversion_time_ms = end_time - start_time

        Logger.error("❌ Request conversion exception: #{planning_request.request_id}")
        Logger.error("❌ Exception: #{inspect(error)}")

        # Create exception error params
        error_params = PlanningParams.create_error(
          planning_request.request_id,
          "Conversion exception: #{Exception.message(error)}"
        )

        # Update stats
        updated_stats = update_conversion_stats(state.conversion_stats, :error, conversion_time_ms)
        new_state = %{state | conversion_stats: updated_stats}

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: error_params,
          metadata: %{
            conversion_status: :exception,
            conversion_time_ms: conversion_time_ms,
            conversion_exception: Exception.message(error),
            request_id: planning_request.request_id,
            converted_at: DateTime.utc_now()
          }
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  # Private functions

  defp convert_with_timeout(planning_request, state) do
    # Create task for conversion
    task = Task.async(fn ->
      perform_conversion(planning_request, state)
    end)

    # Wait for result with timeout
    case Task.yield(task, state.conversion_timeout_ms) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:timeout}
    end
  end

  defp perform_conversion(planning_request, state) do
    try do
      # Prepare domain
      domain = if state.enable_domain_preparation do
        prepare_domain(planning_request.domain, planning_request)
      else
        planning_request.domain
      end

      # Normalize state
      normalized_state = if state.enable_state_normalization do
        normalize_state(planning_request.state, planning_request)
      else
        planning_request.state
      end

      # Transform goals
      transformed_goals = if state.enable_goal_transformation do
        transform_goals(planning_request.goals, planning_request)
      else
        planning_request.goals
      end

      # Prepare options
      prepared_options = prepare_options(planning_request.options, planning_request)

      # Create conversion metadata
      conversion_metadata = create_conversion_metadata(planning_request, state)

      # Create planning params
      planning_params = PlanningParams.create(
        domain,
        normalized_state,
        transformed_goals,
        prepared_options,
        planning_request.request_id,
        conversion_metadata
      )

      {:ok, planning_params}

    rescue
      error ->
        {:error, error}
    end
  end

  defp prepare_domain(nil, _request), do: nil
  defp prepare_domain(domain, request) do
    # Domain preparation logic
    # Could include validation, normalization, or enhancement
    Logger.debug("🔧 Preparing domain for request: #{request.request_id}")

    # For now, pass through the domain as-is
    # In a full implementation, this might:
    # - Validate domain structure
    # - Add missing default actions
    # - Normalize action specifications
    # - Validate entity+capability consistency

    domain
  end

  defp normalize_state(nil, _request), do: nil
  defp normalize_state(state_data, request) do
    # State normalization logic
    Logger.debug("🔧 Normalizing state for request: #{request.request_id}")

    # For now, pass through the state as-is
    # In a full implementation, this might:
    # - Validate state structure
    # - Normalize fact formats
    # - Remove inconsistencies
    # - Add derived facts
    # - Validate entity existence

    state_data
  end

  defp transform_goals(goals, request) do
    # Goal transformation logic
    Logger.debug("🔧 Transforming #{length(goals)} goals for request: #{request.request_id}")

    # Validate goal format (should already be validated, but double-check)
    validated_goals = Enum.filter(goals, &valid_unified_goal?/1)

    if length(validated_goals) != length(goals) do
      Logger.warn("⚠️ Some goals were filtered out during transformation")
    end

    # Apply goal transformations
    transformed_goals = validated_goals
    |> normalize_goal_values()
    |> optimize_goal_order()
    |> add_goal_metadata(request)

    Logger.debug("🔧 Transformed to #{length(transformed_goals)} goals")
    transformed_goals
  end

  defp normalize_goal_values(goals) do
    # Normalize goal values for consistency
    Enum.map(goals, fn {subject, predicate, value} ->
      normalized_value = case value do
        value when is_binary(value) -> String.trim(value)
        value when is_atom(value) -> value
        value when is_number(value) -> value
        value when is_boolean(value) -> value
        value -> inspect(value)  # Convert complex values to strings
      end

      {subject, predicate, normalized_value}
    end)
  end

  defp optimize_goal_order(goals) do
    # Optimize goal order for better planning performance
    # Sort by predicate type to group similar goals together
    Enum.sort_by(goals, fn {_subject, predicate, _value} -> predicate end)
  end

  defp add_goal_metadata(goals, request) do
    # Add metadata to goals if needed
    # For now, just return goals as-is
    # Could add priority, dependencies, or other metadata
    goals
  end

  defp prepare_options(options, request) do
    # Prepare options for planning execution
    Logger.debug("🔧 Preparing options for request: #{request.request_id}")

    # Add strategy preferences from request
    enhanced_options = options ++ [
      strategy_preferences: request.strategy_preferences,
      timeout_ms: request.timeout_ms,
      priority: request.priority,
      request_metadata: request.metadata
    ]

    # Remove duplicates and nil values
    enhanced_options
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.uniq_by(fn {key, _value} -> key end)
  end

  defp create_conversion_metadata(request, state) do
    %{
      converted_at: DateTime.utc_now(),
      converter_version: "v1.0",
      original_request_id: request.request_id,
      conversion_settings: %{
        domain_preparation: state.enable_domain_preparation,
        state_normalization: state.enable_state_normalization,
        goal_transformation: state.enable_goal_transformation
      },
      strategy_preferences: request.strategy_preferences,
      original_metadata: request.metadata
    }
  end

  defp valid_unified_goal?({subject, predicate, _value})
       when is_binary(subject) and is_binary(predicate) do
    true
  end

  defp valid_unified_goal?(_), do: false

  defp update_conversion_stats(stats, result, conversion_time_ms) do
    new_total = stats.total_conversions + 1

    updated_stats = case result do
      :success ->
        %{stats |
          total_conversions: new_total,
          successful_conversions: stats.successful_conversions + 1
        }

      :error ->
        %{stats |
          total_conversions: new_total,
          failed_conversions: stats.failed_conversions + 1
        }
    end

    # Update average conversion time
    if conversion_time_ms > 0 do
      current_avg = stats.average_conversion_time_ms
      new_avg = ((current_avg * (new_total - 1)) + conversion_time_ms) / new_total

      %{updated_stats | average_conversion_time_ms: new_avg}
    else
      updated_stats
    end
  end
end
