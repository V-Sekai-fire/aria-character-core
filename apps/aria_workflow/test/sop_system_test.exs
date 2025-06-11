# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.SOPSystemTest do
  @moduledoc """
  Integration tests for the SOP system with basic timing and command tracing operations.
  """

  use ExUnit.Case, async: false
  require Logger

  alias AriaWorkflow.{SOPRegistry, SOPEngine}
  alias AriaEngine.State

  setup do
    # Start the SOP registry for each test
    {:ok, registry_pid} = SOPRegistry.start_link(name: :"test_registry_#{:rand.uniform(1000)}")
    
    on_exit(fn ->
      if Process.alive?(registry_pid) do
        GenServer.stop(registry_pid)
      end
    end)
    
    %{registry: registry_pid}
  end

  describe "SOP Registry" do
    test "lists built-in SOPs", %{registry: registry} do
      sops = SOPRegistry.list_all(registry: registry)
      
      assert length(sops) >= 2
      sop_ids = Enum.map(sops, & &1.id)
      assert "basic_timing" in sop_ids
      assert "command_tracing" in sop_ids
    end

    test "retrieves basic timing SOP", %{registry: registry} do
      {:ok, sop} = SOPRegistry.get("basic_timing", registry: registry)
      
      assert sop.id == "basic_timing"
      assert length(sop.goals) == 3
      assert length(sop.tasks) == 5
      assert length(sop.methods) == 2
      assert sop.metadata.version == "1.0"
    end

    test "retrieves command tracing SOP", %{registry: registry} do
      {:ok, sop} = SOPRegistry.get("command_tracing", registry: registry)
      
      assert sop.id == "command_tracing"
      assert length(sop.goals) == 3
      assert length(sop.tasks) == 4
      assert length(sop.methods) == 2
      assert sop.metadata.version == "1.0"
    end

    test "returns error for non-existent SOP", %{registry: registry} do
      result = SOPRegistry.get("non_existent_sop", registry: registry)
      assert {:error, :not_found} = result
    end

    test "gets current time information" do
      time_info = SOPRegistry.get_current_time_info()
      
      assert %{utc: utc, local: local, timezone: tz, offset_seconds: offset} = time_info
      assert %DateTime{} = utc
      assert %DateTime{} = local
      assert is_binary(tz)
      assert is_integer(offset)
    end
  end

  describe "Basic Timing Tasks" do
    test "gets current time" do
      state = %{}
      {:ok, updated_state} = AriaWorkflow.Tasks.BasicTiming.get_current_time(state)
      
      assert Map.has_key?(updated_state, :current_time_info)
      time_info = updated_state.current_time_info
      assert %{utc: _, local: _, timezone: _, offset_seconds: _, timestamp_ms: _} = time_info
    end

    test "starts and stops a timer" do
      state = %{}
      
      # Start timer
      {:ok, state_with_timer} = AriaWorkflow.Tasks.BasicTiming.start_timer(state, %{
        timer_id: "test_timer",
        command: "test_command"
      })
      
      assert Map.has_key?(state_with_timer, :active_timers)
      assert Map.has_key?(state_with_timer.active_timers, "test_timer")
      
      # Small delay to ensure different timestamps
      :timer.sleep(10)
      
      # Stop timer
      {:ok, final_state, timer_result} = AriaWorkflow.Tasks.BasicTiming.stop_timer(state_with_timer, %{
        timer_id: "test_timer",
        status: :completed
      })
      
      assert timer_result.duration_ms > 0
      assert timer_result.duration_seconds > 0
      assert timer_result.status == :completed
      assert not Map.has_key?(final_state.active_timers, "test_timer")
    end

    test "gets timezone information" do
      state = %{}
      {:ok, updated_state} = AriaWorkflow.Tasks.BasicTiming.get_timezone_info(state)
      
      assert Map.has_key?(updated_state, :timezone_info)
      tz_info = updated_state.timezone_info
      assert %{name: _, offset_seconds: _, abbreviation: _} = tz_info
    end
  end

  describe "Command Tracing Tasks" do
    test "starts and ends command trace" do
      state = %{}
      
      # Start trace
      {:ok, state_with_trace, trace_id} = AriaWorkflow.Tasks.CommandTracing.trace_command_start(state, %{
        command: "echo",
        args: ["test"]
      })
      
      assert is_binary(trace_id)
      assert Map.has_key?(state_with_trace, :command_traces)
      assert Map.has_key?(state_with_trace.command_traces, trace_id)
      
      # Small delay
      :timer.sleep(10)
      
      # End trace
      {:ok, final_state, trace_result} = AriaWorkflow.Tasks.CommandTracing.trace_command_end(state_with_trace, %{
        trace_id: trace_id,
        exit_code: 0
      })
      
      assert trace_result.duration_ms > 0
      assert trace_result.exit_code == 0
      assert trace_result.status == :success
      assert Map.has_key?(final_state, :completed_traces)
      assert Map.has_key?(final_state.completed_traces, trace_id)
    end

    test "handles missing trace_id gracefully" do
      state = %{}
      
      result = AriaWorkflow.Tasks.CommandTracing.trace_command_end(state, %{
        exit_code: 0
      })
      
      assert {:error, :missing_trace_id} = result
    end

    test "captures command output" do
      state = %{command_traces: %{"test_trace" => %{}}}
      
      {:ok, updated_state} = AriaWorkflow.Tasks.CommandTracing.capture_command_output(state, %{
        trace_id: "test_trace",
        stdout: "Hello, World!",
        stderr: ""
      })
      
      trace = updated_state.command_traces["test_trace"]
      assert trace.outputs.stdout == "Hello, World!"
      assert trace.outputs.stderr == ""
    end
  end

  describe "Basic Timing Methods" do
    test "times command execution" do
      state = %{}
      
      {:ok, final_state, result} = AriaWorkflow.Methods.BasicTiming.time_command_execution(state, %{
        command: "echo",
        args: ["Hello, timing!"]
      })
      
      assert result.duration_seconds > 0
      assert result.exit_code == 0
      assert result.status == :success
      assert String.contains?(result.output, "Hello, timing!")
    end

    test "generates timing report" do
      # Create state with some completed timers
      state = %{
        completed_timers: %{
          "timer1" => %{duration_seconds: 1.5, status: :completed},
          "timer2" => %{duration_seconds: 0.8, status: :completed}
        }
      }
      
      {:ok, _final_state, report} = AriaWorkflow.Methods.BasicTiming.generate_timing_report(state)
      
      assert report.summary_statistics.count == 2
      assert report.summary_statistics.total_time == 2.3
      assert report.summary_statistics.average_time == 1.15
    end
  end

  describe "Command Tracing Methods" do
    test "executes command with tracing" do
      state = %{}
      
      {:ok, final_state, result} = AriaWorkflow.Methods.CommandTracing.execute_with_tracing(state, %{
        command: "echo",
        args: ["Hello, tracing!"]
      })
      
      assert is_binary(result.trace_id)
      assert result.execution_result.duration_seconds > 0
      assert result.execution_result.exit_code == 0
      assert Map.has_key?(final_state, :completed_traces)
    end

    test "generates execution summary" do
      # Create state with completed traces
      state = %{
        completed_traces: %{
          "trace1" => %{duration_seconds: 1.2, status: :success, exit_code: 0},
          "trace2" => %{duration_seconds: 0.9, status: :success, exit_code: 0}
        }
      }
      
      {:ok, _final_state, summary} = AriaWorkflow.Methods.CommandTracing.generate_execution_summary(state)
      
      assert summary.statistics.total_executions == 2
      assert summary.statistics.successful_executions == 2
      assert summary.statistics.failed_executions == 0
      assert summary.statistics.average_duration == 1.05
    end
  end

  describe "Integration Tests" do
    test "full basic timing workflow" do
      state = %{}
      
      # Get current time
      {:ok, state1} = AriaWorkflow.Tasks.BasicTiming.get_current_time(state)
      
      # Start timer
      {:ok, state2} = AriaWorkflow.Tasks.BasicTiming.start_timer(state1, %{
        timer_id: "integration_timer",
        command: "integration_test"
      })
      
      # Simulate work
      :timer.sleep(50)
      
      # Stop timer
      {:ok, state3, _timer_result} = AriaWorkflow.Tasks.BasicTiming.stop_timer(state2, %{
        timer_id: "integration_timer",
        status: :completed
      })
      
      # Generate report
      {:ok, _final_state, report} = AriaWorkflow.Methods.BasicTiming.generate_timing_report(state3)
      
      assert report.summary_statistics.count >= 1
      assert report.summary_statistics.total_time > 0
    end

    test "full command tracing workflow" do
      state = %{}
      
      # Execute command with full tracing
      {:ok, final_state, result} = AriaWorkflow.Methods.CommandTracing.execute_with_tracing(state, %{
        command: "date",
        args: []
      })
      
      assert result.execution_result.exit_code == 0
      assert result.execution_result.duration_seconds > 0
      
      # Generate summary
      {:ok, _summary_state, summary} = AriaWorkflow.Methods.CommandTracing.generate_execution_summary(final_state)
      
      assert summary.statistics.total_executions >= 1
      assert summary.statistics.successful_executions >= 1
    end
  end
end
