# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.ResponseFormatterFilter do
  @moduledoc """
  Membrane filter that formats planning responses for external consumption.

  This filter transforms internal planning responses into various output formats
  suitable for different clients (JSON, structured maps, timeline formats, etc.).
  Handles format validation, data sanitization, and comprehensive error reporting.

  Follows the unified action specification from ADR-134 with standardized
  output formats and comprehensive metadata inclusion.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W033RFMT"

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
    accepted_format: %Membrane.RemoteStream{content_format: %{}},
    flow_control: :auto
  )

  def_options(
    output_format: [
      spec: :json | :structured_map | :timeline | :gltf_khr | :custom,
      default: :structured_map,
      description: "Output format for planning responses"
    ],
    include_metadata: [
      spec: boolean(),
      default: true,
      description: "Include processing metadata in output"
    ],
    include_statistics: [
      spec: boolean(),
      default: false,
      description: "Include performance statistics in output"
    ],
    sanitize_output: [
      spec: boolean(),
      default: true,
      description: "Remove internal implementation details from output"
    ],
    custom_formatter: [
      spec: {module(), atom()} | nil,
      default: nil,
      description: "Custom formatter function {module, function}"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Response Formatter Filter")
    Logger.info("🔧 Output format: #{opts.output_format}")
    Logger.info("🔧 Include metadata: #{opts.include_metadata}")
    Logger.info("🔧 Include statistics: #{opts.include_statistics}")
    Logger.info("🔧 Sanitize output: #{opts.sanitize_output}")

    state = %{
      output_format: opts.output_format,
      include_metadata: opts.include_metadata,
      include_statistics: opts.include_statistics,
      sanitize_output: opts.sanitize_output,
      custom_formatter: opts.custom_formatter,
      formatting_stats: %{
        total_responses: 0,
        successful_formats: 0,
        failed_formats: 0,
        average_format_time_ms: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    planning_response = buffer.payload

    Logger.info("🔧 Formatting response: #{planning_response.request_id}")

    start_time = System.monotonic_time(:millisecond)

    try do
      # Format the response based on configured output format
      formatted_result = format_response(planning_response, buffer.metadata, state)

      end_time = System.monotonic_time(:millisecond)
      format_time_ms = end_time - start_time

      case formatted_result do
        {:ok, formatted_response} ->
          Logger.info("✅ Response formatted successfully: #{planning_response.request_id}")

          # Update formatting statistics
          updated_stats = update_formatting_stats(state.formatting_stats, :success, format_time_ms)
          new_state = %{state | formatting_stats: updated_stats}

          # Create output buffer
          output_buffer = %Membrane.Buffer{
            payload: formatted_response,
            metadata: Map.merge(buffer.metadata || %{}, %{
              formatting_status: :success,
              format_time_ms: format_time_ms,
              output_format: state.output_format,
              formatted_at: DateTime.utc_now()
            })
          }

          {[buffer: {:output, output_buffer}], new_state}

        {:error, reason} ->
          Logger.error("❌ Response formatting failed: #{planning_response.request_id}")
          Logger.error("❌ Reason: #{inspect(reason)}")

          # Create error response in basic format
          error_response = create_error_response(
            planning_response.request_id,
            "Response formatting failed: #{inspect(reason)}",
            state.output_format
          )

          # Update stats
          updated_stats = update_formatting_stats(state.formatting_stats, :error, format_time_ms)
          new_state = %{state | formatting_stats: updated_stats}

          # Create output buffer
          output_buffer = %Membrane.Buffer{
            payload: error_response,
            metadata: Map.merge(buffer.metadata || %{}, %{
              formatting_status: :error,
              format_time_ms: format_time_ms,
              format_error: inspect(reason),
              output_format: state.output_format,
              formatted_at: DateTime.utc_now()
            })
          }

          {[buffer: {:output, output_buffer}], new_state}
      end

    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        format_time_ms = end_time - start_time

        Logger.error("❌ Response formatting exception: #{planning_response.request_id}")
        Logger.error("❌ Exception: #{inspect(error)}")

        # Create exception error response
        error_response = create_error_response(
          planning_response.request_id,
          "Response formatting exception: #{Exception.message(error)}",
          state.output_format
        )

        # Update stats
        updated_stats = update_formatting_stats(state.formatting_stats, :error, format_time_ms)
        new_state = %{state | formatting_stats: updated_stats}

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: error_response,
          metadata: Map.merge(buffer.metadata || %{}, %{
            formatting_status: :exception,
            format_time_ms: format_time_ms,
            format_exception: Exception.message(error),
            output_format: state.output_format,
            formatted_at: DateTime.utc_now()
          })
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  # Private functions

  defp format_response(planning_response, metadata, state) do
    case state.output_format do
      :json ->
        format_as_json(planning_response, metadata, state)

      :structured_map ->
        format_as_structured_map(planning_response, metadata, state)

      :timeline ->
        format_as_timeline(planning_response, metadata, state)

      :gltf_khr ->
        format_as_gltf_khr(planning_response, metadata, state)

      :custom ->
        format_with_custom_formatter(planning_response, metadata, state)
    end
  end

  defp format_as_json(planning_response, metadata, state) do
    try do
      # Create base structure
      base_structure = create_base_structure(planning_response, metadata, state)

      # Convert to JSON
      json_result = Jason.encode(base_structure, pretty: true)

      case json_result do
        {:ok, json_string} -> {:ok, json_string}
        {:error, reason} -> {:error, {:json_encoding_failed, reason}}
      end

    rescue
      error -> {:error, {:json_formatting_exception, error}}
    end
  end

  defp format_as_structured_map(planning_response, metadata, state) do
    try do
      # Create structured map format
      structured_map = create_base_structure(planning_response, metadata, state)
      {:ok, structured_map}

    rescue
      error -> {:error, {:structured_map_exception, error}}
    end
  end

  defp format_as_timeline(planning_response, metadata, state) do
    try do
      # Create timeline-focused format
      timeline_format = %{
        request_id: planning_response.request_id,
        status: planning_response.status,
        timeline: extract_timeline_events(planning_response),
        duration: calculate_total_duration(planning_response),
        action_count: count_actions(planning_response)
      }

      # Add metadata if requested
      timeline_format = if state.include_metadata do
        Map.put(timeline_format, :metadata, sanitize_metadata(metadata, state))
      else
        timeline_format
      end

      {:ok, timeline_format}

    rescue
      error -> {:error, {:timeline_formatting_exception, error}}
    end
  end

  defp format_as_gltf_khr(planning_response, metadata, state) do
    try do
      # Create glTF KHR_interactivity compatible format
      gltf_format = %{
        request_id: planning_response.request_id,
        status: planning_response.status,
        interactivity: %{
          nodes: extract_gltf_nodes(planning_response),
          behaviors: extract_gltf_behaviors(planning_response),
          variables: extract_gltf_variables(planning_response)
        }
      }

      # Add metadata if requested
      gltf_format = if state.include_metadata do
        Map.put(gltf_format, :metadata, sanitize_metadata(metadata, state))
      else
        gltf_format
      end

      {:ok, gltf_format}

    rescue
      error -> {:error, {:gltf_formatting_exception, error}}
    end
  end

  defp format_with_custom_formatter(planning_response, metadata, state) do
    case state.custom_formatter do
      {module, function} ->
        try do
          result = apply(module, function, [planning_response, metadata, state])
          {:ok, result}
        rescue
          error -> {:error, {:custom_formatter_exception, error}}
        end

      nil ->
        # Fallback to structured map
        format_as_structured_map(planning_response, metadata, state)
    end
  end

  defp create_base_structure(planning_response, metadata, state) do
    # Create base response structure
    base = %{
      request_id: planning_response.request_id,
      status: planning_response.status,
      strategy: planning_response.strategy
    }

    # Add success-specific fields
    base = case planning_response.status do
      :success ->
        Map.merge(base, %{
          actions: sanitize_actions(planning_response.actions, state),
          timeline: sanitize_timeline(planning_response.timeline, state)
        })

      :error ->
        Map.put(base, :error, planning_response.error)

      _ ->
        base
    end

    # Add metadata if requested
    base = if state.include_metadata do
      Map.put(base, :metadata, sanitize_metadata(metadata, state))
    else
      base
    end

    # Add statistics if requested
    base = if state.include_statistics do
      Map.put(base, :statistics, extract_statistics(planning_response, metadata))
    else
      base
    end

    base
  end

  defp sanitize_actions(actions, state) do
    if state.sanitize_output do
      # Remove internal implementation details
      Enum.map(actions || [], fn action ->
        action
        |> Map.drop([:__internal__, :__debug__, :__metadata__])
        |> sanitize_action_parameters()
      end)
    else
      actions || []
    end
  end

  defp sanitize_action_parameters(action) do
    # Ensure parameters are in a clean format
    case Map.get(action, :parameters) do
      params when is_list(params) ->
        # Keep list format
        action

      params when is_map(params) ->
        # Convert map to list of key-value pairs for consistency
        param_list = Enum.map(params, fn {k, v} -> {k, v} end)
        Map.put(action, :parameters, param_list)

      _ ->
        # Ensure parameters field exists
        Map.put(action, :parameters, [])
    end
  end

  defp sanitize_timeline(timeline, state) do
    if state.sanitize_output do
      # Remove internal implementation details from timeline events
      Enum.map(timeline || [], fn event ->
        event
        |> Map.drop([:__internal__, :__debug__, :__metadata__])
      end)
    else
      timeline || []
    end
  end

  defp sanitize_metadata(metadata, state) do
    if state.sanitize_output do
      # Remove sensitive or internal metadata
      (metadata || %{})
      |> Map.drop([:__internal__, :__debug__, :process_id, :node_info])
      |> Map.take([
        :strategy, :execution_time_ms, :aggregation_status,
        :request_id, :executed_at, :aggregated_at, :formatted_at
      ])
    else
      metadata || %{}
    end
  end

  defp extract_timeline_events(planning_response) do
    case planning_response.timeline do
      timeline when is_list(timeline) -> timeline
      _ -> []
    end
  end

  defp calculate_total_duration(planning_response) do
    timeline = extract_timeline_events(planning_response)

    if length(timeline) > 0 do
      max_time = Enum.max_by(timeline, fn event -> Map.get(event, :time, 0) end)
      Map.get(max_time, :time, 0)
    else
      0
    end
  end

  defp count_actions(planning_response) do
    case planning_response.actions do
      actions when is_list(actions) -> length(actions)
      _ -> 0
    end
  end

  defp extract_gltf_nodes(planning_response) do
    # Extract entities/objects that will be animated
    actions = planning_response.actions || []

    actions
    |> Enum.flat_map(fn action ->
      # Extract entity references from action parameters
      case Map.get(action, :parameters) do
        params when is_list(params) ->
          Enum.filter_map(params,
            fn {_key, value} -> is_binary(value) and String.contains?(value, "_") end,
            fn {_key, value} -> value end
          )
        _ -> []
      end
    end)
    |> Enum.uniq()
    |> Enum.map(fn entity_id ->
      %{
        id: entity_id,
        type: "entity",
        properties: %{}
      }
    end)
  end

  defp extract_gltf_behaviors(planning_response) do
    # Convert actions to glTF behaviors
    actions = planning_response.actions || []

    Enum.map(actions, fn action ->
      %{
        id: "behavior_#{action.name}",
        type: "action",
        trigger: %{
          type: "time",
          value: Map.get(action, :start_time, 0)
        },
        action: %{
          name: action.name,
          parameters: Map.get(action, :parameters, []),
          duration: Map.get(action, :duration, 1)
        }
      }
    end)
  end

  defp extract_gltf_variables(planning_response) do
    # Extract state variables that change during execution
    timeline = extract_timeline_events(planning_response)

    timeline
    |> Enum.flat_map(fn event ->
      case Map.get(event, :effects) do
        effects when is_list(effects) -> effects
        _ -> []
      end
    end)
    |> Enum.uniq_by(fn {subject, predicate, _value} -> {subject, predicate} end)
    |> Enum.map(fn {subject, predicate, value} ->
      %{
        id: "#{subject}_#{predicate}",
        type: "state_variable",
        initial_value: value,
        subject: subject,
        predicate: predicate
      }
    end)
  end

  defp extract_statistics(planning_response, metadata) do
    %{
      action_count: count_actions(planning_response),
      timeline_duration: calculate_total_duration(planning_response),
      strategy_used: planning_response.strategy,
      execution_time_ms: Map.get(metadata || %{}, :execution_time_ms),
      aggregation_time_ms: Map.get(metadata || %{}, :aggregation_time_ms),
      format_time_ms: Map.get(metadata || %{}, :format_time_ms)
    }
  end

  defp create_error_response(request_id, error_message, output_format) do
    base_error = %{
      request_id: request_id,
      status: :error,
      error: error_message,
      formatted_at: DateTime.utc_now()
    }

    case output_format do
      :json ->
        case Jason.encode(base_error) do
          {:ok, json} -> json
          {:error, _} -> inspect(base_error)
        end

      _ ->
        base_error
    end
  end

  defp update_formatting_stats(stats, result, format_time_ms) do
    new_total = stats.total_responses + 1

    updated_stats = case result do
      :success ->
        %{stats |
          total_responses: new_total,
          successful_formats: stats.successful_formats + 1
        }

      :error ->
        %{stats |
          total_responses: new_total,
          failed_formats: stats.failed_formats + 1
        }
    end

    # Update average format time
    if format_time_ms > 0 do
      current_avg = stats.average_format_time_ms
      new_avg = ((current_avg * (new_total - 1)) + format_time_ms) / new_total

      %{updated_stats | average_format_time_ms: new_avg}
    else
      updated_stats
    end
  end
end
