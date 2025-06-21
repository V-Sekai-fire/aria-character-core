defmodule AriaEngine.Membrane.PipelineManagerTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Membrane.PipelineManager
  alias AriaEngine.Membrane.{MCPSource, EchoFilter, MCPSink}

  setup do
    # Start the PipelineManager for each test, handling already started case
    case PipelineManager.start_link() do
      {:ok, manager_pid} ->
        on_exit(fn ->
          if Process.alive?(manager_pid) do
            Process.exit(manager_pid, :normal)
          end
        end)
        %{manager: manager_pid}
      
      {:error, {:already_started, manager_pid}} ->
        %{manager: manager_pid}
    end
  end

  describe "pipeline creation" do
    test "creates pipeline with default configuration" do
      config = %{
        topology: :linear,
        elements: [
          %{type: MCPSource, id: :source, config: %{}},
          %{type: EchoFilter, id: :echo, config: %{mock_scenario: :success}},
          %{type: MCPSink, id: :sink, config: %{}}
        ],
        connections: [
          %{from: {:source, :output}, to: {:echo, :input}},
          %{from: {:echo, :output}, to: {:sink, :input}}
        ],
        supervision_strategy: :one_for_one
      }

      assert {:ok, pipeline_pid} = PipelineManager.create_pipeline(config)
      assert is_pid(pipeline_pid)
      assert Process.alive?(pipeline_pid)
    end

    test "creates testing pipeline with predefined configuration" do
      assert {:ok, pipeline_pid} = PipelineManager.create_testing_pipeline(:echo_pipeline)
      assert is_pid(pipeline_pid)
      assert Process.alive?(pipeline_pid)
    end

    test "creates full processing pipeline" do
      assert {:ok, pipeline_pid} = PipelineManager.create_testing_pipeline(:full_pipeline)
      assert is_pid(pipeline_pid)
      assert Process.alive?(pipeline_pid)
    end

    test "handles unknown topology gracefully" do
      assert {:ok, pipeline_pid} = PipelineManager.create_testing_pipeline(:unknown_topology)
      assert is_pid(pipeline_pid)
      assert Process.alive?(pipeline_pid)
    end
  end

  describe "pipeline management" do
    test "lists active pipelines" do
      {:ok, pipeline1} = PipelineManager.create_testing_pipeline(:echo_pipeline)
      {:ok, pipeline2} = PipelineManager.create_testing_pipeline(:full_pipeline)

      pipelines = PipelineManager.list_active_pipelines()

      assert length(pipelines) == 2
      pipeline_pids = Enum.map(pipelines, & &1.pid)
      assert pipeline1 in pipeline_pids
      assert pipeline2 in pipeline_pids
    end

    test "gets pipeline status" do
      {:ok, pipeline_pid} = PipelineManager.create_testing_pipeline(:echo_pipeline)

      status = PipelineManager.get_pipeline_status(pipeline_pid)

      assert status.pipeline_pid == pipeline_pid
      assert status.status == :running
      assert status.topology == :echo_testing
      assert is_binary(status.id)
      assert status.request_count == 0
      assert is_integer(status.uptime_seconds)
      assert status.element_count == 3
    end

    test "returns error for non-existent pipeline status" do
      fake_pid = spawn(fn -> :ok end)
      status = PipelineManager.get_pipeline_status(fake_pid)

      assert %{error: "Pipeline not found"} = status
    end

    test "stops pipeline successfully" do
      {:ok, pipeline_pid} = PipelineManager.create_testing_pipeline(:echo_pipeline)

      assert :ok = PipelineManager.stop_pipeline(pipeline_pid)

      # Pipeline should no longer be in active list
      pipelines = PipelineManager.list_active_pipelines()
      pipeline_pids = Enum.map(pipelines, & &1.pid)
      refute pipeline_pid in pipeline_pids
    end

    test "returns error when stopping non-existent pipeline" do
      fake_pid = spawn(fn -> :ok end)

      assert {:error, :pipeline_not_found} = PipelineManager.stop_pipeline(fake_pid)
    end
  end

  describe "request handling" do
    test "sends request to pipeline successfully" do
      {:ok, pipeline_pid} = PipelineManager.create_testing_pipeline(:echo_pipeline)

      mcp_params = %{
        "schedule_name" => "test_schedule",
        "activities" => [%{"name" => "test_activity"}],
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      assert :ok = PipelineManager.send_request_to_pipeline(pipeline_pid, mcp_params)

      # Check that request count was incremented
      status = PipelineManager.get_pipeline_status(pipeline_pid)
      assert status.request_count == 1
    end

    test "returns error when sending request to non-existent pipeline" do
      fake_pid = spawn(fn -> :ok end)

      mcp_params = %{"schedule_name" => "test"}

      assert {:error, :pipeline_not_found} =
               PipelineManager.send_request_to_pipeline(fake_pid, mcp_params)
    end
  end

  describe "pipeline configuration" do
    test "configures pipeline topology" do
      {:ok, pipeline_pid} = PipelineManager.create_testing_pipeline(:echo_pipeline)

      new_config = %{
        topology: :custom,
        elements: [
          %{type: MCPSource, id: :source, config: %{}},
          %{type: EchoFilter, id: :echo, config: %{mock_scenario: :error}},
          %{type: MCPSink, id: :sink, config: %{}}
        ],
        connections: [
          %{from: {:source, :output}, to: {:echo, :input}},
          %{from: {:echo, :output}, to: {:sink, :input}}
        ],
        supervision_strategy: :one_for_one
      }

      assert :ok = PipelineManager.configure_pipeline_topology(pipeline_pid, new_config)

      # Verify configuration was updated
      status = PipelineManager.get_pipeline_status(pipeline_pid)
      assert status.topology == :custom
    end

    test "returns error when configuring non-existent pipeline" do
      fake_pid = spawn(fn -> :ok end)

      config = %{
        topology: :custom,
        elements: [],
        connections: [],
        supervision_strategy: :one_for_one
      }

      assert {:error, :pipeline_not_found} =
               PipelineManager.configure_pipeline_topology(fake_pid, config)
    end
  end

  describe "manager statistics" do
    test "gets manager statistics" do
      # Create a few pipelines
      {:ok, _pipeline1} = PipelineManager.create_testing_pipeline(:echo_pipeline)
      {:ok, _pipeline2} = PipelineManager.create_testing_pipeline(:full_pipeline)

      stats = PipelineManager.get_manager_stats()

      assert stats.active_pipeline_count == 2
      assert stats.total_pipelines_created == 2
      assert length(stats.pipeline_ids) == 2
      assert Enum.all?(stats.pipeline_ids, &is_binary/1)
    end

    test "returns zero stats when no pipelines created" do
      stats = PipelineManager.get_manager_stats()

      assert stats.active_pipeline_count == 0
      assert stats.total_pipelines_created == 0
      assert stats.pipeline_ids == []
    end
  end

  describe "pipeline lifecycle" do
    test "tracks pipeline creation and destruction" do
      initial_stats = PipelineManager.get_manager_stats()

      # Create pipeline
      {:ok, pipeline_pid} = PipelineManager.create_testing_pipeline(:echo_pipeline)

      after_create_stats = PipelineManager.get_manager_stats()
      assert after_create_stats.active_pipeline_count == initial_stats.active_pipeline_count + 1

      assert after_create_stats.total_pipelines_created ==
               initial_stats.total_pipelines_created + 1

      # Stop pipeline
      :ok = PipelineManager.stop_pipeline(pipeline_pid)

      after_stop_stats = PipelineManager.get_manager_stats()
      assert after_stop_stats.active_pipeline_count == initial_stats.active_pipeline_count
      assert after_stop_stats.total_pipelines_created == initial_stats.total_pipelines_created + 1
    end

    test "handles multiple pipeline operations" do
      # Create multiple pipelines
      {:ok, pipeline1} = PipelineManager.create_testing_pipeline(:echo_pipeline)
      {:ok, pipeline2} = PipelineManager.create_testing_pipeline(:full_pipeline)
      {:ok, pipeline3} = PipelineManager.create_testing_pipeline(:echo_pipeline)

      # Send requests to pipelines
      mcp_params = %{"schedule_name" => "test", "activities" => []}

      :ok = PipelineManager.send_request_to_pipeline(pipeline1, mcp_params)
      :ok = PipelineManager.send_request_to_pipeline(pipeline2, mcp_params)
      # Second request
      :ok = PipelineManager.send_request_to_pipeline(pipeline1, mcp_params)

      # Check request counts
      status1 = PipelineManager.get_pipeline_status(pipeline1)
      status2 = PipelineManager.get_pipeline_status(pipeline2)
      status3 = PipelineManager.get_pipeline_status(pipeline3)

      assert status1.request_count == 2
      assert status2.request_count == 1
      assert status3.request_count == 0

      # Stop one pipeline
      :ok = PipelineManager.stop_pipeline(pipeline2)

      # Verify remaining pipelines
      pipelines = PipelineManager.list_active_pipelines()
      assert length(pipelines) == 2

      pipeline_pids = Enum.map(pipelines, & &1.pid)
      assert pipeline1 in pipeline_pids
      assert pipeline3 in pipeline_pids
      refute pipeline2 in pipeline_pids
    end
  end
end
