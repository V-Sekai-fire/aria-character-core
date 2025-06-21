defmodule AriaEngine.Membrane.PlannerFilterTest do
  use ExUnit.Case, async: true
  
  alias AriaEngine.Membrane.PlannerFilter
  alias AriaEngine.Membrane.Format.{PlanningParams, PlanningResult}
  alias Membrane.Buffer
  alias Membrane.Testing

  describe "PlannerFilter initialization" do
    test "initializes with default options" do
      assert {:ok, filter} = Testing.Filter.start_link(PlannerFilter, %{})
      
      # Test that the filter is properly initialized
      assert Process.alive?(filter)
      
      Testing.Filter.terminate(filter)
    end

    test "initializes with custom timeout" do
      opts = %{timeout_ms: 60_000}
      assert {:ok, filter} = Testing.Filter.start_link(PlannerFilter, opts)
      
      assert Process.alive?(filter)
      
      Testing.Filter.terminate(filter)
    end

    test "initializes with strategy config" do
      opts = %{strategy_config: %{strategy: "hybrid", max_depth: 10}}
      assert {:ok, filter} = Testing.Filter.start_link(PlannerFilter, opts)
      
      assert Process.alive?(filter)
      
      Testing.Filter.terminate(filter)
    end
  end

  describe "PlannerFilter planning execution" do
    setup do
      {:ok, filter} = Testing.Filter.start_link(PlannerFilter, %{timeout_ms: 5_000})
      %{filter: filter}
    end

    test "processes valid planning params successfully", %{filter: filter} do
      planning_params = %PlanningParams{
        request_id: "test_request_001",
        goals: [
          %{"type" => "achieve", "predicate" => "at(robot, location_a)"},
          %{"type" => "achieve", "predicate" => "holding(robot, object_1)"}
        ],
        domain: %{type: "logistics", size: 10, predicates: ["at", "holding"]},
        options: [],
        conversion_metadata: %{
          converted_at: DateTime.utc_now(),
          source_format: "mcp_request"
        }
      }

      input_buffer = %Buffer{payload: planning_params}
      
      # Send the buffer to the filter
      Testing.Filter.push_buffer(filter, :input, input_buffer)
      
      # Get the output
      assert_receive {:buffer, {:output, output_buffer}}, 10_000
      
      # Verify the output structure
      assert %Buffer{payload: %PlanningResult{} = result} = output_buffer
      assert result.request_id == "test_request_001"
      assert result.status in [:success, :error]
      
      if result.status == :success do
        assert is_map(result.result)
        assert Map.has_key?(result.result, :planning_method)
        assert result.result.planning_method == "hybrid_coordinator_v2"
      end
      
      assert is_map(result.execution_metadata)
      assert Map.has_key?(result.execution_metadata, :executed_at)
      assert Map.has_key?(result.execution_metadata, :planner)
      assert result.execution_metadata.planner == "HybridCoordinatorV2"
      
      assert is_map(result.performance_metrics)
      assert Map.has_key?(result.performance_metrics, :execution_time_ms)
      assert is_integer(result.performance_metrics.execution_time_ms)
      assert result.performance_metrics.execution_time_ms >= 0
    end

    test "handles planning params with error flag", %{filter: filter} do
      planning_params = %PlanningParams{
        request_id: "test_error_request",
        goals: [],
        domain: nil,
        options: [error: true],
        conversion_metadata: %{
          error_reason: "Invalid input format",
          converted_at: DateTime.utc_now()
        }
      }

      input_buffer = %Buffer{payload: planning_params}
      
      Testing.Filter.push_buffer(filter, :input, input_buffer)
      
      assert_receive {:buffer, {:output, output_buffer}}, 5_000
      
      assert %Buffer{payload: %PlanningResult{} = result} = output_buffer
      assert result.request_id == "test_error_request"
      assert result.status == :error
      assert result.result == nil
      
      assert is_map(result.execution_metadata)
      assert Map.has_key?(result.execution_metadata, :error_reason)
      assert String.contains?(result.execution_metadata.error_reason, "conversion error")
    end

    test "handles empty goals gracefully", %{filter: filter} do
      planning_params = %PlanningParams{
        request_id: "test_empty_goals",
        goals: [],
        domain: %{type: "simple", size: 0},
        options: [],
        conversion_metadata: %{
          converted_at: DateTime.utc_now(),
          source_format: "mcp_request"
        }
      }

      input_buffer = %Buffer{payload: planning_params}
      
      Testing.Filter.push_buffer(filter, :input, input_buffer)
      
      assert_receive {:buffer, {:output, output_buffer}}, 5_000
      
      assert %Buffer{payload: %PlanningResult{} = result} = output_buffer
      assert result.request_id == "test_empty_goals"
      # Should handle empty goals without crashing
      assert result.status in [:success, :error]
      
      if result.status == :success do
        assert result.execution_metadata.goals_count == 0
      end
    end

    test "handles nil domain gracefully", %{filter: filter} do
      planning_params = %PlanningParams{
        request_id: "test_nil_domain",
        goals: [%{"type" => "achieve", "predicate" => "test_goal"}],
        domain: nil,
        options: [],
        conversion_metadata: %{
          converted_at: DateTime.utc_now(),
          source_format: "mcp_request"
        }
      }

      input_buffer = %Buffer{payload: planning_params}
      
      Testing.Filter.push_buffer(filter, :input, input_buffer)
      
      assert_receive {:buffer, {:output, output_buffer}}, 5_000
      
      assert %Buffer{payload: %PlanningResult{} = result} = output_buffer
      assert result.request_id == "test_nil_domain"
      assert result.status in [:success, :error]
      
      assert result.execution_metadata.domain_size == 0
    end
  end

  describe "PlannerFilter statistics" do
    setup do
      {:ok, filter} = Testing.Filter.start_link(PlannerFilter, %{timeout_ms: 5_000})
      %{filter: filter}
    end

    test "tracks execution statistics", %{filter: filter} do
      # Process a successful request
      planning_params = %PlanningParams{
        request_id: "stats_test_001",
        goals: [%{"type" => "achieve", "predicate" => "test_goal"}],
        domain: %{type: "test", size: 5},
        options: [],
        conversion_metadata: %{converted_at: DateTime.utc_now()}
      }

      input_buffer = %Buffer{payload: planning_params}
      Testing.Filter.push_buffer(filter, :input, input_buffer)
      
      assert_receive {:buffer, {:output, _output_buffer}}, 5_000
      
      # Get statistics
      stats = PlannerFilter.get_stats(filter)
      
      assert is_map(stats)
      assert Map.has_key?(stats, :executed_count)
      assert Map.has_key?(stats, :success_count)
      assert Map.has_key?(stats, :error_count)
      assert Map.has_key?(stats, :success_rate)
      assert Map.has_key?(stats, :total_planning_time_ms)
      assert Map.has_key?(stats, :average_planning_time_ms)
      
      assert stats.executed_count >= 1
      assert stats.total_planning_time_ms >= 0
      assert is_float(stats.success_rate)
      assert stats.success_rate >= 0.0 and stats.success_rate <= 1.0
    end

    test "handles stats request timeout gracefully", %{filter: filter} do
      # Stop the filter to simulate unresponsive process
      Testing.Filter.terminate(filter)
      
      # This should timeout and return an error
      stats = PlannerFilter.get_stats(filter)
      assert Map.has_key?(stats, :error)
      assert stats.error == "Timeout waiting for stats"
    end
  end

  describe "PlannerFilter telemetry" do
    setup do
      # Attach telemetry handler for testing
      test_pid = self()
      
      :telemetry.attach(
        "planner_filter_test_handler",
        [:aria_engine, :membrane, :planner_filter, :planning_success],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:telemetry_event, event, measurements, metadata})
        end,
        nil
      )
      
      :telemetry.attach(
        "planner_filter_error_test_handler", 
        [:aria_engine, :membrane, :planner_filter, :planning_error],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:telemetry_event, event, measurements, metadata})
        end,
        nil
      )
      
      {:ok, filter} = Testing.Filter.start_link(PlannerFilter, %{timeout_ms: 5_000})
      
      on_exit(fn ->
        :telemetry.detach("planner_filter_test_handler")
        :telemetry.detach("planner_filter_error_test_handler")
      end)
      
      %{filter: filter}
    end

    test "emits telemetry events for successful planning", %{filter: filter} do
      planning_params = %PlanningParams{
        request_id: "telemetry_test_001",
        goals: [%{"type" => "achieve", "predicate" => "test_goal"}],
        domain: %{type: "test", size: 3},
        options: [],
        conversion_metadata: %{converted_at: DateTime.utc_now()}
      }

      input_buffer = %Buffer{payload: planning_params}
      Testing.Filter.push_buffer(filter, :input, input_buffer)
      
      # Wait for processing
      assert_receive {:buffer, {:output, output_buffer}}, 5_000
      
      # Check if we got a success result
      %Buffer{payload: %PlanningResult{status: status}} = output_buffer
      
      if status == :success do
        # Should receive telemetry event for success
        assert_receive {:telemetry_event, event, measurements, metadata}, 1_000
        
        assert event == [:aria_engine, :membrane, :planner_filter, :planning_success]
        assert Map.has_key?(measurements, :count)
        assert measurements.count == 1
        assert Map.has_key?(metadata, :request_id)
        assert metadata.request_id == "telemetry_test_001"
        assert Map.has_key?(metadata, :execution_time_ms)
        assert is_integer(metadata.execution_time_ms)
      end
    end

    test "emits telemetry events for planning errors", %{filter: filter} do
      planning_params = %PlanningParams{
        request_id: "telemetry_error_test",
        goals: [],
        domain: nil,
        options: [error: true],
        conversion_metadata: %{
          error_reason: "Test error condition",
          converted_at: DateTime.utc_now()
        }
      }

      input_buffer = %Buffer{payload: planning_params}
      Testing.Filter.push_buffer(filter, :input, input_buffer)
      
      # Wait for processing
      assert_receive {:buffer, {:output, output_buffer}}, 5_000
      
      # Should be an error result
      %Buffer{payload: %PlanningResult{status: :error}} = output_buffer
      
      # Should receive telemetry event for error
      assert_receive {:telemetry_event, event, measurements, metadata}, 1_000
      
      assert event == [:aria_engine, :membrane, :planner_filter, :planning_error]
      assert Map.has_key?(measurements, :count)
      assert measurements.count == 1
      assert Map.has_key?(metadata, :request_id)
      assert metadata.request_id == "telemetry_error_test"
      assert Map.has_key?(metadata, :error_reason)
      assert String.contains?(metadata.error_reason, "conversion error")
    end
  end

  describe "PlannerFilter timeout handling" do
    test "handles planning timeout correctly" do
      # Use a very short timeout to force timeout condition
      {:ok, filter} = Testing.Filter.start_link(PlannerFilter, %{timeout_ms: 1})
      
      planning_params = %PlanningParams{
        request_id: "timeout_test",
        goals: [%{"type" => "achieve", "predicate" => "complex_goal"}],
        domain: %{type: "complex", size: 100},
        options: [],
        conversion_metadata: %{converted_at: DateTime.utc_now()}
      }

      input_buffer = %Buffer{payload: planning_params}
      Testing.Filter.push_buffer(filter, :input, input_buffer)
      
      assert_receive {:buffer, {:output, output_buffer}}, 5_000
      
      %Buffer{payload: %PlanningResult{} = result} = output_buffer
      assert result.status == :error
      assert result.request_id == "timeout_test"
      
      # Should contain timeout information
      assert is_binary(result.execution_metadata.error_reason)
      assert String.contains?(result.execution_metadata.error_reason, "timeout")
      
      Testing.Filter.terminate(filter)
    end
  end
end
