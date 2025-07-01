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

  # Missing external API functions
  @doc "Start link for compatibility with external API."
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    topology = Keyword.get(opts, :topology, :production)
    start_pipeline(topology, opts)
  end

  @doc "Create a pipeline (alias for start_pipeline)."
  @spec create_pipeline(map()) :: {:ok, pid()} | {:error, term()}
  def create_pipeline(config) when is_map(config) do
    topology = Map.get(config, :topology, :production)
    opts = Map.to_list(config)
    start_pipeline(topology, opts)
  end

  @doc "Create a testing pipeline."
  @spec create_testing_pipeline(atom()) :: {:ok, pid()} | {:error, term()}
  def create_testing_pipeline(topology \\ :echo_pipeline) do
    # Map topology names to internal testing topology
    internal_topology = case topology do
      :echo_pipeline -> :testing
      other -> other
    end
    start_pipeline(internal_topology, [])
  end

  @doc "Configure pipeline topology (placeholder)."
  @spec configure_pipeline_topology(pid(), map()) :: :ok
  def configure_pipeline_topology(pipeline_pid, _config) do
    # For now, just acknowledge the configuration
    # In a full implementation, this would reconfigure the running pipeline
    Logger.info("Pipeline topology configuration requested for #{inspect(pipeline_pid)}")
    :ok
  end

  @doc "List active pipelines (placeholder)."
  @spec list_active_pipelines() :: [pid()]
  def list_active_pipelines() do
    # Placeholder implementation
    # In a full implementation, this would track active pipeline processes
    []
  end

  @doc "Stop a pipeline."
  @spec stop_pipeline(pid()) :: :ok
  def stop_pipeline(pipeline_pid) do
    # Use Membrane's built-in pipeline termination
    if Process.alive?(pipeline_pid) do
      Process.exit(pipeline_pid, :normal)
    end
    :ok
  end

  @doc "Send request to pipeline (alias for send_mcp_request)."
  @spec send_request_to_pipeline(pid(), map()) :: :ok
  def send_request_to_pipeline(pipeline_pid, mcp_params) do
    send_mcp_request(pipeline_pid, mcp_params)
  end

  @doc "Get manager statistics (placeholder)."
  @spec get_manager_stats() :: map()
  def get_manager_stats() do
    %{
      active_pipelines: length(list_active_pipelines()),
      implementation: :membrane_framework,
      uptime: System.monotonic_time(:second)
    }
  end
end
