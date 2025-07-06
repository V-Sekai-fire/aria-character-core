# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.EchoFilter do
  @moduledoc """
  Simple echo filter for testing pipeline topology.

  This filter passes through PlanningParams unchanged, useful for testing
  pipeline connectivity without actual planning execution.
  """
  use Membrane.Filter
  require Logger
  alias Membrane.Format.{PlanningParams, PlanningResult}
  alias Membrane.Buffer

  def_input_pad(:input, accepted_format: PlanningParams, flow_control: :manual, demand_unit: :buffers)
  def_output_pad(:output, accepted_format: PlanningResult, flow_control: :manual, demand_unit: :buffers)

  def_options(
    telemetry_prefix: [
      spec: [atom()],
      default: [:aria_engine, :membrane, :echo_filter],
      description: "Telemetry event prefix for monitoring"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      echo_count: 0
    }

    Logger.info("EchoFilter initialized")
    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: planning_params}, _ctx, state) do
    Logger.debug("EchoFilter echoing request: #{planning_params.request_id}")

    # Create a simple success result
    planning_result = PlanningResult.success(
      [%{echo: "success", original_goal: planning_params.goal}],
      %{
        echo_filter: true,
        processed_at: DateTime.utc_now(),
        echo_count: state.echo_count + 1
      },
      planning_params.request_id
    )

    emit_telemetry(state.telemetry_prefix, :echo_processed, %{
      request_id: planning_params.request_id,
      echo_count: state.echo_count + 1
    })

    output_buffer = %Buffer{payload: planning_result}
    new_state = %{state | echo_count: state.echo_count + 1}

    {[buffer: {:output, output_buffer}], new_state}
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end
end
