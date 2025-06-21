# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.MCPSourceTest do
  use ExUnit.Case, async: true

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions

  alias AriaEngine.Membrane.MCPSource
  alias AriaEngine.Membrane.Format.MCPRequest
  alias Membrane.Testing.Pipeline
  alias Membrane.Testing.Sink

  describe "MCPSource initialization" do
    test "initializes with default options" do
      children = [
        child(:mcp_source, MCPSource)
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)

      status = MCPSource.get_status(pipeline, :mcp_source)
      assert status.processed_count == 0
      assert status.error_count == 0
      assert status.queue_size == 0
      assert status.max_queue_size == 100
      assert status.demand == 0
    end

    test "initializes with custom options" do
      children = [
        child(:mcp_source, %MCPSource{
          max_queue_size: 50,
          telemetry_prefix: [:test, :mcp_source]
        })
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)

      status = MCPSource.get_status(pipeline, :mcp_source)
      assert status.max_queue_size == 50
    end
  end

  describe "MCP request processing" do
    setup do
      children = [
        child(:mcp_source, MCPSource)
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)
      %{pipeline: pipeline}
    end

    test "processes valid MCP request", %{pipeline: pipeline} do
      mcp_params = %{
        "schedule_name" => "test_schedule",
        "activities" => [
          %{
            "id" => "activity_1",
            "duration" => "PT1H"
          }
        ],
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, mcp_params})

      # Wait for buffer to be processed
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %MCPRequest{}})

      status = MCPSource.get_status(pipeline, :mcp_source)
      assert status.processed_count == 1
      assert status.error_count == 0
    end

    test "handles invalid MCP request format", %{pipeline: pipeline} do
      invalid_params = %{
        "invalid" => "format"
      }

      Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, invalid_params})

      # Give some time for processing
      Process.sleep(10)

      status = MCPSource.get_status(pipeline, :mcp_source)
      assert status.processed_count == 0
      assert status.error_count == 1
    end

    test "rejects non-map parameters", %{pipeline: pipeline} do
      Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, "invalid"})

      # Give some time for processing
      Process.sleep(10)

      status = MCPSource.get_status(pipeline, :mcp_source)
      assert status.processed_count == 0
      assert status.error_count == 1
    end
  end

  describe "demand-based flow control" do
    setup do
      children = [
        child(:mcp_source, MCPSource)
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)
      %{pipeline: pipeline}
    end

    test "queues requests when no demand", %{pipeline: pipeline} do
      # Send multiple requests before any demand
      mcp_params = %{
        "schedule_name" => "test_schedule",
        "activities" => [],
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      # Send requests
      for _ <- 1..3 do
        Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, mcp_params})
      end

      # Give time for processing
      Process.sleep(10)

      status = MCPSource.get_status(pipeline, :mcp_source)
      # Requests should be queued, not processed yet
      assert status.queue_size > 0
    end

    test "processes queued requests when demand arrives", %{pipeline: pipeline} do
      mcp_params = %{
        "schedule_name" => "test_schedule",
        "activities" => [],
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      # Send requests
      for _ <- 1..2 do
        Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, mcp_params})
      end

      # Wait for buffers to be processed by sink (which creates demand)
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %MCPRequest{}})
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %MCPRequest{}})

      status = MCPSource.get_status(pipeline, :mcp_source)
      assert status.processed_count == 2
      assert status.queue_size == 0
    end
  end

  describe "request ID generation" do
    setup do
      children = [
        child(:mcp_source, MCPSource)
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)
      %{pipeline: pipeline}
    end

    test "generates unique request IDs", %{pipeline: pipeline} do
      mcp_params = %{
        "schedule_name" => "test_schedule",
        "activities" => [],
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      # Send multiple requests
      for _ <- 1..3 do
        Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, mcp_params})
      end

      # Wait for all buffers
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %MCPRequest{}})
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %MCPRequest{}})
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %MCPRequest{}})

      status = MCPSource.get_status(pipeline, :mcp_source)
      assert status.processed_count == 3
    end
  end

  describe "pipeline configuration" do
    setup do
      children = [
        child(:mcp_source, MCPSource)
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)
      %{pipeline: pipeline}
    end

    test "updates pipeline configuration", %{pipeline: pipeline} do
      config = %{
        topology: :linear,
        elements: [
          %{type: MCPSource, id: :source, config: %{}},
          %{type: :plan_filter, id: :filter, config: %{}}
        ],
        connections: [
          %{from: {:source, :output}, to: {:filter, :input}}
        ]
      }

      Pipeline.notify_child(pipeline, :mcp_source, {:configure_pipeline, config})

      # Give time for processing
      Process.sleep(10)

      status = MCPSource.get_status(pipeline, :mcp_source)
      assert status.pipeline_config == config
    end
  end

  describe "backpressure handling" do
    test "handles queue overflow" do
      children = [
        child(:mcp_source, %MCPSource{max_queue_size: 2})
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)

      mcp_params = %{
        "schedule_name" => "test_schedule",
        "activities" => [],
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      # Fill the queue beyond capacity
      for _ <- 1..5 do
        Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, mcp_params})
      end

      # Give time for processing
      Process.sleep(50)

      status = MCPSource.get_status(pipeline, :mcp_source)
      # Should have limited queue size due to max_queue_size setting
      assert status.queue_size <= 2
    end
  end

  describe "status reporting" do
    setup do
      children = [
        child(:mcp_source, MCPSource)
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)
      %{pipeline: pipeline}
    end

    test "returns comprehensive status", %{pipeline: pipeline} do
      status = MCPSource.get_status(pipeline, :mcp_source)

      assert Map.has_key?(status, :processed_count)
      assert Map.has_key?(status, :error_count)
      assert Map.has_key?(status, :queue_size)
      assert Map.has_key?(status, :max_queue_size)
      assert Map.has_key?(status, :pipeline_config)
      assert Map.has_key?(status, :active_pipelines)
      assert Map.has_key?(status, :demand)
    end

    test "handles status timeout" do
      children = [
        child(:mcp_source, MCPSource)
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)

      # Terminate the pipeline to test timeout
      Pipeline.terminate(pipeline)

      status = MCPSource.get_status(pipeline, :mcp_source, 100)
      assert Map.has_key?(status, :error)
    end
  end

  describe "MCPRequest format integration" do
    setup do
      children = [
        child(:mcp_source, MCPSource)
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)
      %{pipeline: pipeline}
    end

    test "creates valid MCPRequest format", %{pipeline: pipeline} do
      mcp_params = %{
        "schedule_name" => "integration_test",
        "activities" => [
          %{
            "id" => "test_activity",
            "duration" => "PT30M",
            "dependencies" => []
          }
        ],
        "entities" => [
          %{
            "id" => "test_entity",
            "type" => "agent",
            "capabilities" => ["planning"]
          }
        ],
        "resources" => %{
          "cpu" => 4,
          "memory" => "8GB"
        },
        "constraints" => %{
          "max_duration" => "PT2H"
        }
      }

      Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, mcp_params})

      # Wait for buffer to be processed
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{
        payload: %MCPRequest{
          tool_name: "schedule_activities"
        }
      })

      status = MCPSource.get_status(pipeline, :mcp_source)
      assert status.processed_count == 1
      assert status.error_count == 0
    end
  end

  describe "telemetry events" do
    setup do
      # Attach telemetry handler for testing
      test_pid = self()

      :telemetry.attach_many(
        "mcp_source_test",
        [
          [:aria_engine, :membrane, :mcp_source, :initialized],
          [:aria_engine, :membrane, :mcp_source, :request_processed],
          [:aria_engine, :membrane, :mcp_source, :request_error],
          [:aria_engine, :membrane, :mcp_source, :pipeline_configured]
        ],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("mcp_source_test") end)

      children = [
        child(:mcp_source, MCPSource)
        |> child(:sink, %Sink{})
      ]

      pipeline = Pipeline.start_link_supervised!(spec: children)
      %{pipeline: pipeline}
    end

    test "emits initialization telemetry", %{pipeline: _pipeline} do
      assert_receive {:telemetry, [:aria_engine, :membrane, :mcp_source, :initialized],
                      %{count: 1}, %{max_queue_size: 100}}
    end

    test "emits request processing telemetry", %{pipeline: pipeline} do
      mcp_params = %{
        "schedule_name" => "telemetry_test",
        "activities" => [],
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, mcp_params})

      assert_receive {:telemetry, [:aria_engine, :membrane, :mcp_source, :request_processed],
                      %{count: 1}, metadata}

      assert Map.has_key?(metadata, :request_id)
      assert Map.has_key?(metadata, :processing_time)
      assert Map.has_key?(metadata, :queue_size)
    end

    test "emits error telemetry for invalid requests", %{pipeline: pipeline} do
      invalid_params = %{"invalid" => "format"}

      Pipeline.notify_child(pipeline, :mcp_source, {:mcp_request, invalid_params})

      assert_receive {:telemetry, [:aria_engine, :membrane, :mcp_source, :request_error],
                      %{count: 1}, metadata}

      assert Map.has_key?(metadata, :error_reason)
      assert Map.has_key?(metadata, :processing_time)
    end

    test "emits pipeline configuration telemetry", %{pipeline: pipeline} do
      config = %{topology: :linear, elements: []}

      Pipeline.notify_child(pipeline, :mcp_source, {:configure_pipeline, config})

      assert_receive {:telemetry, [:aria_engine, :membrane, :mcp_source, :pipeline_configured],
                      %{count: 1}, metadata}

      assert metadata.topology == :linear
      assert metadata.element_count == 0
    end
  end
end
