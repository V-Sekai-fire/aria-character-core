# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Membrane.PipelineManager do
  @moduledoc """
  Production pipeline manager for Membrane Framework pipelines.

  This module manages the lifecycle of Membrane pipelines and supports
  both testing and production topologies with dynamic switching based
  on configuration.
  """
  use Membrane.Pipeline
  require Logger

  @doc """
  Starts a new pipeline with the specified topology.

  ## Topologies

  - `:testing` - MCPSource → ScheduleFilter → EchoFilter → ResponseFilter → MCPSink
  - `:production` - MCPSource → PlanFilter → PlannerFilter → ResponseFilter → MCPSink

  ## Options

  - `topology` - Pipeline topology (:testing or :production)
  - `source_config` - Configuration for MCPSource
  - `sink_config` - Configuration for MCPSink
  - `telemetry_prefix` - Telemetry event prefix
  """
  @spec start_pipeline(atom(), keyword()) :: {:ok, pid()} | {:error, term()}
  def start_pipeline(topology, opts \\ []) do
    pipeline_opts = [
      topology: topology,
      source_config: Keyword.get(opts, :source_config, %{}),
      sink_config: Keyword.get(opts, :sink_config, %{}),
      telemetry_prefix: Keyword.get(opts, :telemetry_prefix, [:aria_engine, :membrane, :pipeline])
    ]

    Membrane.Pipeline.start_link(__MODULE__, pipeline_opts)
  end

  @impl true
  def handle_init(_ctx, opts) do
    topology = Keyword.get(opts, :topology, :production)
    source_config = Keyword.get(opts, :source_config, %{})
    sink_config = Keyword.get(opts, :sink_config, %{})
    telemetry_prefix = Keyword.get(opts, :telemetry_prefix, [:aria_engine, :membrane, :pipeline])

    Logger.info("PipelineManager initializing with topology: #{topology}")

    spec = build_pipeline_spec(topology, source_config, sink_config, telemetry_prefix)

    emit_telemetry(telemetry_prefix, :pipeline_initialized, %{
      topology: topology,
      element_count: count_elements(spec)
    })

    {[spec: spec], %{topology: topology, telemetry_prefix: telemetry_prefix}}
  end

  @impl true
  def handle_child_notification({:mcp_tool_call, tool_name, parameters, metadata}, :mcp_source, _ctx, state) do
    Logger.debug("PipelineManager forwarding tool call: #{tool_name}")

    emit_telemetry(state.telemetry_prefix, :tool_call_received, %{
      tool_name: tool_name,
      topology: state.topology
    })

    {[], state}
  end

  @impl true
  def handle_child_notification({:mcp_request, mcp_params}, :mcp_source, _ctx, state) do
    Logger.debug("PipelineManager forwarding MCP request")

    emit_telemetry(state.telemetry_prefix, :mcp_request_received, %{
      topology: state.topology
    })

    {[], state}
  end

  @impl true
  def handle_child_notification(notification, child, _ctx, state) do
    Logger.debug("PipelineManager received notification from #{child}: #{inspect(notification)}")
    {[], state}
  end

  @impl true
  def handle_info({:switch_topology, new_topology}, _ctx, state) do
    Logger.info("PipelineManager switching topology from #{state.topology} to #{new_topology}")

    # Note: In a real implementation, you would need to gracefully shut down
    # the current pipeline and start a new one. For now, we just log the request.
    emit_telemetry(state.telemetry_prefix, :topology_switch_requested, %{
      from_topology: state.topology,
      to_topology: new_topology
    })

    new_state = %{state | topology: new_topology}
    {[], new_state}
  end

  @impl true
  def handle_info({:get_pipeline_status, from}, _ctx, state) do
    status = %{
      topology: state.topology,
      telemetry_prefix: state.telemetry_prefix,
      uptime: System.monotonic_time(:second)
    }

    send(from, {:pipeline_status, status})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("PipelineManager received unknown message: #{inspect(msg)}")
    {[], state}
  end

  defp build_pipeline_spec(:testing, source_config, sink_config, telemetry_prefix) do
    [
      child(:mcp_source, Membrane.MCPSource)
      |> child(:schedule_filter, Membrane.ScheduleFilter)
      |> child(:echo_filter, %Membrane.EchoFilter{telemetry_prefix: telemetry_prefix})
      |> child(:response_filter, Membrane.ResponseFilter)
      |> child(:mcp_sink, %Membrane.MCPSink{storage_mode: :memory})
    ]
    |> configure_source(source_config)
    |> configure_sink(sink_config)
  end

  defp build_pipeline_spec(:production, source_config, sink_config, telemetry_prefix) do
    [
      child(:mcp_source, Membrane.MCPSource)
      |> child(:plan_filter, Membrane.PlanFilter)
      |> child(:planner_filter, Membrane.PlannerFilter)
      |> child(:response_filter, Membrane.ResponseFilter)
      |> child(:mcp_sink, Membrane.MCPSink)
    ]
    |> configure_source(source_config)
    |> configure_sink(sink_config)
    |> configure_telemetry(telemetry_prefix)
  end

  defp build_pipeline_spec(topology, _source_config, _sink_config, _telemetry_prefix) do
    Logger.error("Unknown pipeline topology: #{topology}")
    raise ArgumentError, "Unknown pipeline topology: #{topology}"
  end

  defp configure_source(spec, source_config) when source_config != %{} do
    # Update the MCPSource configuration
    Enum.map(spec, fn
      {:child, :mcp_source, {module, _opts}} ->
        {:child, :mcp_source, {module, source_config}}

      other ->
        other
    end)
  end

  defp configure_source(spec, _source_config), do: spec

  defp configure_sink(spec, sink_config) when sink_config != %{} do
    # Update the MCPSink configuration
    Enum.map(spec, fn
      {:child, :mcp_sink, {module, _opts}} ->
        {:child, :mcp_sink, {module, sink_config}}

      other ->
        other
    end)
  end

  defp configure_sink(spec, _sink_config), do: spec

  defp configure_telemetry(spec, telemetry_prefix) do
    # Update telemetry configuration for all elements
    Enum.map(spec, fn
      {:child, name, {module, opts}} when is_map(opts) ->
        updated_opts = Map.put(opts, :telemetry_prefix, telemetry_prefix ++ [name])
        {:child, name, {module, updated_opts}}

      other ->
        other
    end)
  end

  defp count_elements(spec) do
    Enum.count(spec, fn
      {:child, _name, _module} -> true
      _ -> false
    end)
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  @doc "Gets the current status of the pipeline."
  @spec get_pipeline_status(pid()) :: map()
  def get_pipeline_status(pipeline_pid) do
    send(pipeline_pid, {:get_pipeline_status, self()})

    receive do
      {:pipeline_status, status} -> status
    after
      5000 -> %{error: "Timeout waiting for pipeline status"}
    end
  end

  @doc "Sends an MCP tool call to the pipeline."
  @spec send_tool_call(pid(), String.t(), map(), map()) :: :ok
  def send_tool_call(pipeline_pid, tool_name, parameters, metadata \\ %{}) do
    Membrane.Pipeline.notify_child(pipeline_pid, :mcp_source, {:mcp_tool_call, tool_name, parameters, metadata})
  end

  @doc "Sends a legacy MCP request to the pipeline."
  @spec send_mcp_request(pid(), map()) :: :ok
  def send_mcp_request(pipeline_pid, mcp_params) do
    Membrane.Pipeline.notify_child(pipeline_pid, :mcp_source, {:mcp_request, mcp_params})
  end

  @doc "Requests a topology switch (for future implementation)."
  @spec switch_topology(pid(), atom()) :: :ok
  def switch_topology(pipeline_pid, new_topology) do
    send(pipeline_pid, {:switch_topology, new_topology})
    :ok
  end
end

# Simple EchoFilter for testing topology
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

  def_input_pad(:input, accepted_format: PlanningParams, flow_control: :manual)
  def_output_pad(:output, accepted_format: PlanningResult, flow_control: :manual)

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
