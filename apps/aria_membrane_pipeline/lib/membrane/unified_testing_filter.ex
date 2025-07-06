# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.UnifiedTestingFilter do
  @moduledoc """
  Unified testing filter for Membrane pipeline tests.

  This module consolidates functionality from EchoFilter, FormatTransformerFilter,
  and Testing.Filter to provide comprehensive testing capabilities including:
  - Simple echo/passthrough functionality
  - Format transformation with mock scenarios
  - Configurable delays and telemetry
  - Multiple testing modes for different pipeline scenarios

  ## Testing Modes

  - `:echo` - Simple echo functionality (from EchoFilter)
  - `:passthrough` - Pass data unchanged (from FormatTransformerFilter)
  - `:transform` - Apply custom transformation function
  - `:mock_success` - Generate mock success responses
  - `:mock_error` - Generate mock error responses
  - `:delay` - Add artificial processing delays

  ## Usage

      # Simple echo mode
      %Membrane.UnifiedTestingFilter{mode: :echo}

      # Transform mode with custom function
      %Membrane.UnifiedTestingFilter{
        mode: :transform,
        transform_fn: fn data -> Map.put(data, :test_flag, true) end
      }

      # Mock success with delay
      %Membrane.UnifiedTestingFilter{
        mode: :mock_success,
        delay_ms: 100
      }
  """
  use Membrane.Filter
  require Logger
  alias Membrane.Format.{PlanningParams, PlanningResult}
  alias Membrane.Buffer

  def_input_pad(:input, accepted_format: _any, flow_control: :auto)
  def_output_pad(:output, accepted_format: _any, flow_control: :auto)

  def_options(
    mode: [
      spec: :echo | :passthrough | :transform | :mock_success | :mock_error | :delay,
      default: :passthrough,
      description: "Testing mode to use"
    ],
    telemetry_prefix: [
      spec: [atom()],
      default: [:membrane, :unified_testing, :filter],
      description: "Telemetry event prefix for monitoring"
    ],
    transform_fn: [
      spec: (term() -> term()) | nil,
      default: nil,
      description: "Optional transformation function to apply to buffers"
    ],
    delay_ms: [
      spec: non_neg_integer(),
      default: 0,
      description: "Artificial delay in milliseconds for testing timing"
    ],
    mock_scenario: [
      spec: atom(),
      default: :default,
      description: "Mock scenario for generating test responses"
    ]
  )

  @typedoc "Internal state of the Unified Testing Filter element"
  @type state :: %{
          mode: atom(),
          telemetry_prefix: [atom()],
          transform_fn: (term() -> term()) | nil,
          delay_ms: non_neg_integer(),
          mock_scenario: atom(),
          processed_count: non_neg_integer(),
          echo_count: non_neg_integer()
        }

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      mode: opts.mode,
      telemetry_prefix: opts.telemetry_prefix,
      transform_fn: opts.transform_fn,
      delay_ms: opts.delay_ms,
      mock_scenario: opts.mock_scenario,
      processed_count: 0,
      echo_count: 0
    }

    Logger.info("UnifiedTestingFilter initialized with mode: #{opts.mode}")

    emit_telemetry(state.telemetry_prefix, :initialized, %{
      mode: opts.mode,
      delay_ms: opts.delay_ms,
      mock_scenario: opts.mock_scenario,
      has_transform_fn: not is_nil(opts.transform_fn)
    })

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: payload} = buffer, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)

    # Apply artificial delay if configured
    if state.delay_ms > 0 do
      Process.sleep(state.delay_ms)
    end

    # Process based on mode
    result = case state.mode do
      :echo ->
        handle_echo_mode(payload, state)

      :passthrough ->
        handle_passthrough_mode(payload, state)

      :transform ->
        handle_transform_mode(payload, state)

      :mock_success ->
        handle_mock_success_mode(payload, state)

      :mock_error ->
        handle_mock_error_mode(payload, state)

      :delay ->
        handle_delay_mode(payload, state)

      _ ->
        Logger.warning("Unknown testing mode: #{state.mode}, using passthrough")
        handle_passthrough_mode(payload, state)
    end

    processing_time = System.monotonic_time(:microsecond) - start_time

    emit_telemetry(state.telemetry_prefix, :buffer_processed, %{
      mode: state.mode,
      processing_time: processing_time,
      has_transformation: not is_nil(state.transform_fn)
    })

    case result do
      {:ok, transformed_payload, new_state} ->
        output_buffer = %Buffer{buffer | payload: transformed_payload}
        updated_state = %{new_state | processed_count: new_state.processed_count + 1}
        {[buffer: {:output, output_buffer}], updated_state}

      {:error, reason, new_state} ->
        Logger.error("UnifiedTestingFilter processing error: #{reason}")
        updated_state = %{new_state | processed_count: new_state.processed_count + 1}
        {[], updated_state}
    end
  end

  # Echo mode - creates success responses like EchoFilter
  defp handle_echo_mode(%PlanningParams{} = planning_params, state) do
    Logger.debug("UnifiedTestingFilter echoing request: #{planning_params.request_id}")

    planning_result = PlanningResult.success(
      [%{echo: "success", original_goal: planning_params.goal}],
      %{
        echo_filter: true,
        processed_at: DateTime.utc_now(),
        echo_count: state.echo_count + 1,
        testing_mode: :echo
      },
      planning_params.request_id
    )

    new_state = %{state | echo_count: state.echo_count + 1}
    {:ok, planning_result, new_state}
  end

  defp handle_echo_mode(payload, state) do
    # For non-PlanningParams, just echo back with metadata
    echoed_payload = case payload do
      %{} = map ->
        Map.merge(map, %{
          echo: true,
          echo_count: state.echo_count + 1,
          echoed_at: DateTime.utc_now()
        })

      other ->
        %{
          original: other,
          echo: true,
          echo_count: state.echo_count + 1,
          echoed_at: DateTime.utc_now()
        }
    end

    new_state = %{state | echo_count: state.echo_count + 1}
    {:ok, echoed_payload, new_state}
  end

  # Passthrough mode - data unchanged
  defp handle_passthrough_mode(payload, state) do
    {:ok, payload, state}
  end

  # Transform mode - apply custom transformation
  defp handle_transform_mode(payload, state) do
    if state.transform_fn do
      try do
        transformed_payload = state.transform_fn.(payload)
        {:ok, transformed_payload, state}
      rescue
        error ->
          Logger.error("Transform function error: #{inspect(error)}")
          {:error, "Transform function failed: #{Exception.message(error)}", state}
      end
    else
      # No transform function, act like passthrough
      {:ok, payload, state}
    end
  end

  # Mock success mode - generate success responses
  defp handle_mock_success_mode(payload, state) do
    mock_response = generate_mock_success_response(payload, state.mock_scenario)
    {:ok, mock_response, state}
  end

  # Mock error mode - generate error responses
  defp handle_mock_error_mode(payload, state) do
    mock_response = generate_mock_error_response(payload, state.mock_scenario)
    {:ok, mock_response, state}
  end

  # Delay mode - just add delay and pass through
  defp handle_delay_mode(payload, state) do
    # Delay already applied in main handler
    {:ok, payload, state}
  end

  defp generate_mock_success_response(%PlanningParams{} = planning_params, scenario) do
    mock_data = case scenario do
      :widget_assembly ->
        [%{
          action: "assemble_widget",
          components: ["part_a", "part_b", "part_c"],
          duration: 300,
          success: true
        }]

      :schedule_activities ->
        [%{
          activity: "mock_activity",
          start_time: 0,
          duration: 60,
          status: "scheduled"
        }]

      _ ->
        [%{
          mock: true,
          scenario: scenario,
          success: true,
          timestamp: DateTime.utc_now()
        }]
    end

    PlanningResult.success(
      mock_data,
      %{
        mock_scenario: scenario,
        testing_mode: :mock_success,
        generated_at: DateTime.utc_now()
      },
      planning_params.request_id
    )
  end

  defp generate_mock_success_response(payload, scenario) do
    %{
      original: payload,
      mock_success: true,
      scenario: scenario,
      generated_at: DateTime.utc_now()
    }
  end

  defp generate_mock_error_response(%PlanningParams{} = planning_params, scenario) do
    error_message = case scenario do
      :widget_assembly -> "Mock widget assembly failure"
      :schedule_activities -> "Mock scheduling conflict"
      _ -> "Mock error for scenario: #{scenario}"
    end

    PlanningResult.error(
      error_message,
      %{
        mock_scenario: scenario,
        testing_mode: :mock_error,
        generated_at: DateTime.utc_now()
      },
      planning_params.request_id
    )
  end

  defp generate_mock_error_response(payload, scenario) do
    %{
      original: payload,
      mock_error: true,
      scenario: scenario,
      error_message: "Mock error for scenario: #{scenario}",
      generated_at: DateTime.utc_now()
    }
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    stats = %{
      mode: state.mode,
      processed_count: state.processed_count,
      echo_count: state.echo_count,
      delay_ms: state.delay_ms,
      mock_scenario: state.mock_scenario,
      has_transform_fn: not is_nil(state.transform_fn)
    }

    send(from, {:unified_testing_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("UnifiedTestingFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  @doc "Gets the current processing statistics of the Unified Testing Filter element."
  @spec get_stats(pid(), timeout()) :: map()
  def get_stats(filter_pid, timeout \\ 5000) do
    send(filter_pid, {:get_stats, self()})

    receive do
      {:unified_testing_filter_stats, stats} -> stats
    after
      timeout -> %{error: "Timeout waiting for stats"}
    end
  end

  @doc "Creates a simple identity transformation function for testing."
  @spec identity_transform() :: (term() -> term())
  def identity_transform() do
    fn x -> x end
  end

  @doc "Creates a transformation function that adds metadata to payloads."
  @spec add_metadata_transform(map()) :: (term() -> term())
  def add_metadata_transform(metadata) when is_map(metadata) do
    fn payload ->
      case payload do
        %{} = map -> Map.merge(map, metadata)
        other -> %{original: other, metadata: metadata}
      end
    end
  end

  @doc "Creates a transformation function that simulates processing delays."
  @spec delay_transform(non_neg_integer()) :: (term() -> term())
  def delay_transform(delay_ms) when is_integer(delay_ms) and delay_ms >= 0 do
    fn payload ->
      Process.sleep(delay_ms)
      payload
    end
  end
end
