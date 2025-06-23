# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Membrane.Testing.Filter do
  @moduledoc """
  Migration tool with serial number: R25W023TEST

  Decode: mix migrate.decode_serial R25W023TEST
  """

  @serial_number "R25W023TEST"

  @moduledoc """
  Mock testing filter for Membrane pipeline tests.

  This module provides a simple pass-through filter that can be used
  in tests to verify pipeline structure and data flow without complex
  processing logic.
  """

  use Membrane.Filter

  require Logger

  alias Membrane.Buffer

  def_input_pad(:input,
    accepted_format: _any,
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: _any,
    flow_control: :auto
  )

  def_options(
    telemetry_prefix: [
      spec: [atom()],
      default: [:membrane, :testing, :filter],
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
    ]
  )

  @typedoc "Internal state of the Testing Filter element"
  @type state :: %{
          telemetry_prefix: [atom()],
          transform_fn: (term() -> term()) | nil,
          delay_ms: non_neg_integer(),
          processed_count: non_neg_integer()
        }

  # ==================== Membrane Callbacks ====================

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      transform_fn: opts.transform_fn,
      delay_ms: opts.delay_ms,
      processed_count: 0
    }

    Logger.debug("Testing Filter initialized with delay: #{opts.delay_ms}ms")

    emit_telemetry(state.telemetry_prefix, :initialized, %{
      delay_ms: opts.delay_ms,
      has_transform_fn: not is_nil(opts.transform_fn)
    })

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: payload} = buffer, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)

    # Add artificial delay if configured
    if state.delay_ms > 0 do
      Process.sleep(state.delay_ms)
    end

    # Apply transformation if provided
    transformed_payload =
      if state.transform_fn do
        state.transform_fn.(payload)
      else
        payload
      end

    processing_time = System.monotonic_time(:microsecond) - start_time

    emit_telemetry(state.telemetry_prefix, :buffer_processed, %{
      processing_time: processing_time,
      has_transformation: not is_nil(state.transform_fn)
    })

    output_buffer = %Buffer{buffer | payload: transformed_payload}
    new_state = %{state | processed_count: state.processed_count + 1}

    {[buffer: {:output, output_buffer}], new_state}
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    stats = %{
      processed_count: state.processed_count,
      delay_ms: state.delay_ms,
      has_transform_fn: not is_nil(state.transform_fn)
    }

    send(from, {:testing_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("Testing Filter received unknown message: #{inspect(msg)}")
    {[], state}
  end

  # ==================== PRIVATE FUNCTIONS ====================

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  # ==================== PUBLIC API FOR TESTING ====================

  @doc """
  Starts a testing filter with the given options.

  This function provides compatibility with the expected `start_link/2` interface
  that tests are looking for.
  """
  @spec start_link(keyword(), keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(filter_opts \\ [], process_opts \\ []) do
    # Create a simple pipeline with just this filter for testing
    import Membrane.ChildrenSpec

    spec = [
      child(:testing_filter, %__MODULE__{
        telemetry_prefix:
          Keyword.get(filter_opts, :telemetry_prefix, [:membrane, :testing, :filter]),
        transform_fn: Keyword.get(filter_opts, :transform_fn),
        delay_ms: Keyword.get(filter_opts, :delay_ms, 0)
      })
    ]

    Membrane.Testing.Pipeline.start_link([spec: spec] ++ process_opts)
  end

  @doc """
  Gets the current processing statistics of the Testing Filter element.
  """
  @spec get_stats(pid(), timeout()) :: map()
  def get_stats(filter_pid, timeout \\ 5000) do
    send(filter_pid, {:get_stats, self()})

    receive do
      {:testing_filter_stats, stats} -> stats
    after
      timeout -> %{error: "Timeout waiting for stats"}
    end
  end

  @doc """
  Creates a simple identity transformation function for testing.
  """
  @spec identity_transform() :: (term() -> term())
  def identity_transform(), do: fn x -> x end

  @doc """
  Creates a transformation function that adds metadata to payloads.
  """
  @spec add_metadata_transform(map()) :: (term() -> term())
  def add_metadata_transform(metadata) when is_map(metadata) do
    fn payload ->
      case payload do
        %{} = map -> Map.merge(map, metadata)
        other -> %{original: other, metadata: metadata}
      end
    end
  end
end
