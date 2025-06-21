defmodule AriaEngine.Membrane.PipelineManager do
  @moduledoc """
  Manager for Membrane pipeline lifecycle and dynamic topology configuration.

  Handles pipeline creation, element linking, supervision, and runtime
  reconfiguration of the planning pipeline.
  """

  use GenServer
  require Logger

  alias AriaEngine.Membrane.{MCPSource, FormatTransformerFilter, MCPSink}

  @type pipeline_config :: %{
          topology: :linear | :parallel | :multi_strategy | :custom,
          elements: [map()],
          connections: [map()],
          supervision_strategy: atom()
        }

  @type pipeline_state :: %{
          active_pipelines: map(),
          default_config: pipeline_config(),
          telemetry_prefix: [atom()],
          pipeline_counter: non_neg_integer()
        }

  # Public API

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec create_pipeline(pipeline_config()) :: {:ok, pid()} | {:error, term()}
  def create_pipeline(config) do
    GenServer.call(__MODULE__, {:create_pipeline, config})
  end

  @spec create_testing_pipeline(atom()) :: {:ok, pid()} | {:error, term()}
  def create_testing_pipeline(topology \\ :echo_pipeline) do
    config = get_predefined_config(topology)
    create_pipeline(config)
  end

  @spec configure_pipeline_topology(pid(), pipeline_config()) :: :ok | {:error, term()}
  def configure_pipeline_topology(pipeline_pid, config) do
    GenServer.call(__MODULE__, {:configure_topology, pipeline_pid, config})
  end

  @spec get_pipeline_status(pid()) :: map()
  def get_pipeline_status(pipeline_pid) do
    GenServer.call(__MODULE__, {:get_status, pipeline_pid})
  end

  @spec list_active_pipelines() :: [map()]
  def list_active_pipelines() do
    GenServer.call(__MODULE__, :list_pipelines)
  end

  @spec stop_pipeline(pid()) :: :ok
  def stop_pipeline(pipeline_pid) do
    GenServer.call(__MODULE__, {:stop_pipeline, pipeline_pid})
  end

  @spec send_request_to_pipeline(pid(), map()) :: :ok | {:error, term()}
  def send_request_to_pipeline(pipeline_pid, mcp_params) do
    GenServer.call(__MODULE__, {:send_request, pipeline_pid, mcp_params})
  end

  # GenServer callbacks

  @impl true
  def init(opts) do
    default_config = %{
      topology: :linear,
      elements: [
        %{type: MCPSource, id: :source, config: %{}},
        %{type: FormatTransformerFilter, id: :echo, config: %{mock_scenario: :success}},
        %{type: MCPSink, id: :mcp_sink, config: %{}}
      ],
      connections: [
        %{from: {:source, :output}, to: {:echo, :input}},
        %{from: {:echo, :output}, to: {:mcp_sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }

    state = %{
      active_pipelines: %{},
      default_config: default_config,
      telemetry_prefix:
        Keyword.get(opts, :telemetry_prefix, [:aria_engine, :membrane, :pipeline]),
      pipeline_counter: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:create_pipeline, config}, _from, state) do
    pipeline_id = "pipeline_#{state.pipeline_counter}"

    {:ok, pipeline_info} = build_pipeline(config, pipeline_id)
    
    new_pipelines =
      Map.put(state.active_pipelines, pipeline_info.pid, %{
        config: config,
        id: pipeline_id,
        created_at: DateTime.utc_now(),
        status: :running,
        request_count: 0,
        source_pid: pipeline_info.source_pid
      })

    new_state = %{
      state
      | active_pipelines: new_pipelines,
        pipeline_counter: state.pipeline_counter + 1
    }

    emit_telemetry(state.telemetry_prefix, :pipeline_created, %{
      pipeline_id: pipeline_id,
      topology: config.topology
    })

    {:reply, {:ok, pipeline_info.pid}, new_state}
  end

  @impl true
  def handle_call({:configure_topology, pipeline_pid, config}, _from, state) do
    case Map.get(state.active_pipelines, pipeline_pid) do
      nil ->
        {:reply, {:error, :pipeline_not_found}, state}

      pipeline_info ->
        :ok = reconfigure_pipeline(pipeline_pid, config)
        
        updated_info =
          Map.merge(pipeline_info, %{
            config: config,
            reconfigured_at: DateTime.utc_now()
          })

        new_pipelines = Map.put(state.active_pipelines, pipeline_pid, updated_info)
        new_state = %{state | active_pipelines: new_pipelines}

        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:get_status, pipeline_pid}, _from, state) do
    status = get_pipeline_status_info(pipeline_pid, state.active_pipelines)
    {:reply, status, state}
  end

  @impl true
  def handle_call(:list_pipelines, _from, state) do
    pipelines =
      Enum.map(state.active_pipelines, fn {pid, info} ->
        %{
          pid: pid,
          id: info.id,
          topology: info.config.topology,
          status: info.status,
          created_at: info.created_at,
          request_count: info.request_count
        }
      end)

    {:reply, pipelines, state}
  end

  @impl true
  def handle_call({:stop_pipeline, pipeline_pid}, _from, state) do
    case Map.get(state.active_pipelines, pipeline_pid) do
      nil ->
        {:reply, {:error, :pipeline_not_found}, state}

      pipeline_info ->
        # Stop the pipeline process
        try do
          Process.exit(pipeline_pid, :normal)

          emit_telemetry(state.telemetry_prefix, :pipeline_stopped, %{
            pipeline_id: pipeline_info.id
          })

          new_pipelines = Map.delete(state.active_pipelines, pipeline_pid)
          new_state = %{state | active_pipelines: new_pipelines}
          {:reply, :ok, new_state}
        rescue
          error ->
            Logger.error("Error stopping pipeline: #{inspect(error)}")
            {:reply, {:error, error}, state}
        end
    end
  end

  @impl true
  def handle_call({:send_request, pipeline_pid, mcp_params}, _from, state) do
    case Map.get(state.active_pipelines, pipeline_pid) do
      nil ->
        {:reply, {:error, :pipeline_not_found}, state}

      pipeline_info ->
        case pipeline_info.source_pid do
          nil ->
            {:reply, {:error, :source_not_available}, state}

          source_pid ->
            try do
              # Send message to source process (simplified for testing)
              send(source_pid, {:mcp_request, mcp_params})

              # Update request count
              updated_info = Map.update(pipeline_info, :request_count, 1, &(&1 + 1))
              new_pipelines = Map.put(state.active_pipelines, pipeline_pid, updated_info)
              new_state = %{state | active_pipelines: new_pipelines}

              {:reply, :ok, new_state}
            rescue
              error ->
                Logger.error("Error sending request to pipeline: #{inspect(error)}")
                {:reply, {:error, error}, state}
            end
        end
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      active_pipeline_count: map_size(state.active_pipelines),
      total_pipelines_created: state.pipeline_counter,
      pipeline_ids: Enum.map(state.active_pipelines, fn {_pid, info} -> info.id end)
    }

    {:reply, stats, state}
  end

  # Private functions

  defp build_pipeline(_config, pipeline_id) do
    # Create a simple pipeline structure for testing
    # In a full implementation, this would use Membrane.Pipeline

    # For now, create a mock pipeline with element processes
    source_pid =
      spawn(fn ->
        receive do
          {:mcp_request, _params} -> :ok
        end
      end)

    pipeline_pid =
      spawn(fn ->
        Process.monitor(source_pid)
        pipeline_loop(pipeline_id, source_pid)
      end)

    {:ok, %{pid: pipeline_pid, source_pid: source_pid}}
  end

  defp pipeline_loop(pipeline_id, source_pid) do
    receive do
      {:DOWN, _ref, :process, ^source_pid, _reason} ->
        Logger.info("Pipeline #{pipeline_id} source process terminated")

      {:stop} ->
        Logger.info("Pipeline #{pipeline_id} stopping")

      msg ->
        Logger.debug("Pipeline #{pipeline_id} received: #{inspect(msg)}")
        pipeline_loop(pipeline_id, source_pid)
    end
  end

  defp reconfigure_pipeline(_pipeline_pid, _config) do
    # Implementation would reconfigure existing pipeline
    # For now, just return success
    :ok
  end

  defp get_pipeline_status_info(pipeline_pid, active_pipelines) do
    case Map.get(active_pipelines, pipeline_pid) do
      nil ->
        %{error: "Pipeline not found"}

      info ->
        %{
          pipeline_pid: pipeline_pid,
          id: info.id,
          status: info.status,
          topology: info.config.topology,
          created_at: info.created_at,
          request_count: info.request_count,
          uptime_seconds: DateTime.diff(DateTime.utc_now(), info.created_at),
          element_count: length(info.config.elements)
        }
    end
  end

  # Pipeline 1: Simplest - Direct MCPSource -> FormatTransformer -> MCPSink
  defp get_predefined_config(:direct_pipeline) do
    %{
      topology: :direct_passthrough,
      elements: [
        %{type: MCPSource, id: :source, config: %{}},
        %{
          type: FormatTransformerFilter,
          id: :passthrough,
          config: %{mock_scenario: :mcp_request_to_response}
        },
        %{type: MCPSink, id: :sink, config: %{}}
      ],
      connections: [
        %{from: {:source, :output}, to: {:passthrough, :input}},
        %{from: {:passthrough, :output}, to: {:sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }
  end

  # Pipeline 2: Simple echo - MCPSource -> FormatTransformerFilter -> MCPSink
  defp get_predefined_config(:echo_pipeline) do
    %{
      topology: :echo_testing,
      elements: [
        %{type: MCPSource, id: :source, config: %{}},
        %{type: FormatTransformerFilter, id: :echo, config: %{mock_scenario: :success}},
        %{type: MCPSink, id: :sink, config: %{}}
      ],
      connections: [
        %{from: {:source, :output}, to: {:echo, :input}},
        %{from: {:echo, :output}, to: {:sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }
  end

  # Pipeline 3: MCP filtering - MCPSource -> MCPScheduleFilter -> FormatTransformer -> MCPSink
  defp get_predefined_config(:mcp_filter_pipeline) do
    %{
      topology: :mcp_filtering,
      elements: [
        %{type: MCPSource, id: :source, config: %{}},
        %{
          type: AriaEngine.Membrane.MCPScheduleFilter,
          id: :mcp_filter,
          config: %{strict_filtering: false}
        },
        %{
          type: FormatTransformerFilter,
          id: :format_converter,
          config: %{mock_scenario: :mcp_request_to_response}
        },
        %{type: MCPSink, id: :sink, config: %{}}
      ],
      connections: [
        %{from: {:source, :output}, to: {:mcp_filter, :input}},
        %{from: {:mcp_filter, :output}, to: {:format_converter, :input}},
        %{from: {:format_converter, :output}, to: {:sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }
  end

  # Pipeline 4: Schedule processing - MCPSource -> MCPScheduleFilter -> SchedulePlannerFilter -> FormatTransformer -> MCPSink
  defp get_predefined_config(:schedule_transform_pipeline) do
    %{
      topology: :schedule_transformation,
      elements: [
        %{type: MCPSource, id: :source, config: %{}},
        %{type: AriaEngine.Membrane.MCPScheduleFilter, id: :mcp_filter, config: %{}},
        %{
          type: AriaEngine.Membrane.SchedulePlannerFilter,
          id: :schedule_filter,
          config: %{strict_validation: false}
        },
        %{
          type: FormatTransformerFilter,
          id: :format_converter,
          config: %{mock_scenario: :planning_params_to_response}
        },
        %{type: MCPSink, id: :sink, config: %{}}
      ],
      connections: [
        %{from: {:source, :output}, to: {:mcp_filter, :input}},
        %{from: {:mcp_filter, :output}, to: {:schedule_filter, :input}},
        %{from: {:schedule_filter, :output}, to: {:format_converter, :input}},
        %{from: {:format_converter, :output}, to: {:sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }
  end

  # Pipeline 5: Mock planning - MCPSource -> MCPScheduleFilter -> SchedulePlannerFilter -> FormatTransformerFilter -> PlannerMCPFilter -> MCPSink
  defp get_predefined_config(:mock_planning_pipeline) do
    %{
      topology: :mock_planning,
      elements: [
        %{type: MCPSource, id: :source, config: %{}},
        %{type: AriaEngine.Membrane.MCPScheduleFilter, id: :mcp_filter, config: %{}},
        %{
          type: AriaEngine.Membrane.SchedulePlannerFilter,
          id: :schedule_filter,
          config: %{strict_validation: false}
        },
        %{
          type: FormatTransformerFilter,
          id: :mock_planner,
          config: %{mock_scenario: :planning_success}
        },
        %{type: AriaEngine.Membrane.PlannerMCPFilter, id: :response_filter, config: %{}},
        %{type: MCPSink, id: :sink, config: %{}}
      ],
      connections: [
        %{from: {:source, :output}, to: {:mcp_filter, :input}},
        %{from: {:mcp_filter, :output}, to: {:schedule_filter, :input}},
        %{from: {:schedule_filter, :output}, to: {:mock_planner, :input}},
        %{from: {:mock_planner, :output}, to: {:response_filter, :input}},
        %{from: {:response_filter, :output}, to: {:sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }
  end

  # Pipeline 6: Full schedule pipeline - MCPSource -> MCPScheduleFilter -> SchedulePlannerFilter -> PlannerFilter -> PlannerMCPFilter -> MCPSink
  defp get_predefined_config(:schedule_pipeline) do
    %{
      topology: :schedule_processing,
      elements: [
        %{type: MCPSource, id: :mcp_source, config: %{}},
        %{type: AriaEngine.Membrane.MCPScheduleFilter, id: :mcp_schedule_filter, config: %{}},
        %{
          type: AriaEngine.Membrane.SchedulePlannerFilter,
          id: :schedule_planner_filter,
          config: %{strict_validation: true}
        },
        %{
          type: AriaEngine.Membrane.PlannerFilter,
          id: :planner_filter,
          config: %{timeout_ms: 30_000}
        },
        %{type: AriaEngine.Membrane.PlannerMCPFilter, id: :planner_mcp_filter, config: %{}},
        %{type: MCPSink, id: :mcp_sink, config: %{}}
      ],
      connections: [
        %{from: {:mcp_source, :output}, to: {:mcp_schedule_filter, :input}},
        %{from: {:mcp_schedule_filter, :output}, to: {:schedule_planner_filter, :input}},
        %{from: {:schedule_planner_filter, :output}, to: {:planner_filter, :input}},
        %{from: {:planner_filter, :output}, to: {:planner_mcp_filter, :input}},
        %{from: {:planner_mcp_filter, :output}, to: {:mcp_sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }
  end

  # Pipeline 7: Plan transformation - MCPSource -> PlanFilter -> FormatTransformerFilter -> MCPSink
  defp get_predefined_config(:plan_transform_pipeline) do
    %{
      topology: :plan_transformation,
      elements: [
        %{type: MCPSource, id: :source, config: %{}},
        %{type: AriaEngine.Membrane.PlanFilter, id: :plan_filter, config: %{}},
        %{
          type: FormatTransformerFilter,
          id: :format_transformer,
          config: %{mock_scenario: :planning_params_to_response}
        },
        %{type: MCPSink, id: :sink, config: %{}}
      ],
      connections: [
        %{from: {:source, :output}, to: {:plan_filter, :input}},
        %{from: {:plan_filter, :output}, to: {:format_transformer, :input}},
        %{from: {:format_transformer, :output}, to: {:sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }
  end

  # Pipeline 8: Full pipeline - MCPSource -> SchedulePlannerFilter -> PlannerFilter -> MCPSink
  defp get_predefined_config(:full_pipeline) do
    %{
      topology: :full_processing,
      elements: [
        %{type: MCPSource, id: :source, config: %{}},
        %{
          type: AriaEngine.Membrane.SchedulePlannerFilter,
          id: :schedule_filter,
          config: %{strict_validation: false}
        },
        %{
          type: AriaEngine.Membrane.PlannerFilter,
          id: :planner_filter,
          config: %{timeout_ms: 30_000}
        },
        %{type: MCPSink, id: :sink, config: %{}}
      ],
      connections: [
        %{from: {:source, :output}, to: {:schedule_filter, :input}},
        %{from: {:schedule_filter, :output}, to: {:planner_filter, :input}},
        %{from: {:planner_filter, :output}, to: {:sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }
  end

  # Pipeline 9: Validation pipeline - MCPSource -> ValidationPipelineFilter -> MCPSink
  defp get_predefined_config(:validation_pipeline) do
    %{
      topology: :validation_processing,
      elements: [
        %{type: MCPSource, id: :source, config: %{}},
        %{
          type: AriaEngine.Membrane.ValidationPipelineFilter,
          id: :validation_filter,
          config: %{timeout_ms: 60_000}
        },
        %{type: MCPSink, id: :sink, config: %{}}
      ],
      connections: [
        %{from: {:source, :output}, to: {:validation_filter, :input}},
        %{from: {:validation_filter, :output}, to: {:sink, :input}}
      ],
      supervision_strategy: :one_for_one
    }
  end

  defp get_predefined_config(topology) do
    Logger.warning("Unknown predefined topology: #{topology}, using default")
    get_predefined_config(:echo_pipeline)
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  # Public API for testing

  @doc """
  Gets statistics for all active pipelines.
  """
  @spec get_manager_stats() :: map()
  def get_manager_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end

end
