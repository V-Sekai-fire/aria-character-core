# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.TasksAndMethodsTest do
  @moduledoc """
  Unit tests for individual tasks and methods in the SOP system.
  """

  use ExUnit.Case, async: true
  require Logger

  describe "BasicTiming Tasks" do
    test "get_current_time updates state correctly" do
      state = %{}
      {:ok, updated_state} = AriaWorkflow.Tasks.BasicTiming.get_current_time(state)
      
      assert Map.has_key?(updated_state, :current_time_info)
      time_info = updated_state.current_time_info
      
      assert %DateTime{} = time_info.utc
      assert is_binary(time_info.local)
      assert is_binary(time_info.timezone)
      assert is_integer(time_info.offset_seconds)
      assert is_integer(time_info.timestamp_ms)
    end

    test "get_timezone_info returns proper timezone data" do
      state = %{}
      {:ok, updated_state} = AriaWorkflow.Tasks.BasicTiming.get_timezone_info(state)
      
      assert Map.has_key?(updated_state, :timezone_info)
      tz_info = updated_state.timezone_info
      
      assert is_binary(tz_info.name)
      assert is_integer(tz_info.offset_seconds)
      assert is_binary(tz_info.abbreviation)
    end

    test "start_timer creates timer in state" do
      state = %{}
      timer_args = %{timer_id: "test_timer", command: "test_command"}
      
      {:ok, updated_state} = AriaWorkflow.Tasks.BasicTiming.start_timer(state, timer_args)
      
      assert Map.has_key?(updated_state, :active_timers)
      assert Map.has_key?(updated_state.active_timers, "test_timer")
      
      timer = updated_state.active_timers["test_timer"]
      assert timer.timer_id == "test_timer"
      assert timer.command == "test_command"
      assert is_integer(timer.start_time)
      assert %DateTime{} = timer.start_datetime
    end

    test "stop_timer calculates duration correctly" do
      # First start a timer
      state = %{}
      {:ok, state_with_timer} = AriaWorkflow.Tasks.BasicTiming.start_timer(state, %{
        timer_id: "duration_test",
        command: "duration_command"
      })
      
      # Wait a small amount
      :timer.sleep(10)
      
      # Stop the timer
      {:ok, final_state, timer_result} = AriaWorkflow.Tasks.BasicTiming.stop_timer(state_with_timer, %{
        timer_id: "duration_test",
        status: :completed
      })
      
      # Verify duration calculation
      assert timer_result.duration_ms >= 10
      assert timer_result.duration_seconds >= 0.01
      assert timer_result.status == :completed
      
      # Timer should be moved to completed_timers
      assert not Map.has_key?(final_state.active_timers, "duration_test")
      assert Map.has_key?(final_state, :completed_timers)
      assert Map.has_key?(final_state.completed_timers, "duration_test")
    end

    test "log_execution creates execution log" do
      state = %{}
      log_args = %{
        operation: "test_operation",
        duration_seconds: 1.234,
        status: :success,
        details: %{command: "echo test"}
      }
      
      {:ok, updated_state} = AriaWorkflow.Tasks.BasicTiming.log_execution(state, log_args)
      
      assert Map.has_key?(updated_state, :execution_log)
      assert is_list(updated_state.execution_log)
      assert length(updated_state.execution_log) == 1
      
      log_entry = List.first(updated_state.execution_log)
      assert log_entry.operation == "test_operation"
      assert log_entry.duration_seconds == 1.234
      assert log_entry.status == :success
    end
  end

  describe "CommandTracing Tasks" do
    test "trace_command_start generates trace ID" do
      state = %{}
      args = %{command: "echo", args: ["test"]}
      
      {:ok, updated_state, trace_id} = AriaWorkflow.Tasks.CommandTracing.trace_command_start(state, args)
      
      assert is_binary(trace_id)
      assert String.length(trace_id) > 0
      assert Map.has_key?(updated_state, :command_traces)
      assert Map.has_key?(updated_state.command_traces, trace_id)
      
      trace = updated_state.command_traces[trace_id]
      assert trace.command == "echo"
      assert trace.args == ["test"]
      assert trace.status == :started
    end

    test "trace_command_end completes trace" do
      state = %{}
      
      # Start trace
      {:ok, state_with_trace, trace_id} = AriaWorkflow.Tasks.CommandTracing.trace_command_start(state, %{
        command: "test_command"
      })
      
      :timer.sleep(5)
      
      # End trace
      {:ok, final_state, trace_result} = AriaWorkflow.Tasks.CommandTracing.trace_command_end(state_with_trace, %{
        trace_id: trace_id,
        exit_code: 0
      })
      
      assert trace_result.duration_ms >= 5
      assert trace_result.exit_code == 0
      assert trace_result.status == :success
      
      # Should move from active to completed traces
      assert not Map.has_key?(final_state.command_traces, trace_id)
      assert Map.has_key?(final_state, :completed_traces)
      assert Map.has_key?(final_state.completed_traces, trace_id)
    end

    test "capture_command_output stores output" do
      trace_id = "test_trace"
      state = %{command_traces: %{trace_id => %{}}}
      
      {:ok, updated_state} = AriaWorkflow.Tasks.CommandTracing.capture_command_output(state, %{
        trace_id: trace_id,
        stdout: "Success output",
        stderr: "Warning message"
      })
      
      trace = updated_state.command_traces[trace_id]
      assert trace.outputs.stdout == "Success output"
      assert trace.outputs.stderr == "Warning message"
    end

    test "handle_command_error processes errors" do
      trace_id = "error_trace"
      state = %{command_traces: %{trace_id => %{}}}
      
      {:ok, updated_state} = AriaWorkflow.Tasks.CommandTracing.handle_command_error(state, %{
        trace_id: trace_id,
        error_type: :timeout,
        error_message: "Command timed out after 30 seconds",
        exit_code: 124
      })
      
      trace = updated_state.command_traces[trace_id]
      assert trace.error.error_type == :timeout
      assert trace.error.error_message == "Command timed out after 30 seconds"
      assert trace.error.exit_code == 124
    end
  end

  describe "BasicTiming Methods" do
    test "time_command_execution runs command with timing" do
      state = %{}
      
      {:ok, final_state, result} = AriaWorkflow.Methods.BasicTiming.time_command_execution(state, %{
        command: "echo",
        args: ["Hello, World!"]
      })
      
      assert result.duration_seconds > 0
      assert result.exit_code == 0
      assert result.status == :success
      assert String.contains?(result.output, "Hello, World!")
      assert Map.has_key?(final_state, :last_command_execution)
    end

    test "time_command_execution handles command errors" do
      state = %{}
      
      {:ok, _final_state, result} = AriaWorkflow.Methods.BasicTiming.time_command_execution(state, %{
        command: "false"  # Command that always returns exit code 1
      })
      
      assert result.duration_seconds > 0
      assert result.exit_code == 1
      assert result.status == :failed
    end

    test "generate_timing_report creates comprehensive report" do
      # Create state with some completed timers
      state = %{
        completed_timers: %{
          "timer1" => %{duration_seconds: 1.5, status: :completed, command: "cmd1"},
          "timer2" => %{duration_seconds: 0.8, status: :completed, command: "cmd2"},
          "timer3" => %{duration_seconds: 2.1, status: :failed, command: "cmd3"}
        }
      }
      
      {:ok, _final_state, report} = AriaWorkflow.Methods.BasicTiming.generate_timing_report(state)
      
      assert report.summary_statistics.count == 3
      assert report.summary_statistics.total_time == 4.4
      assert_in_delta report.summary_statistics.average_time, 1.47, 0.01
      assert report.summary_statistics.successful_count == 2
      assert report.summary_statistics.failed_count == 1
      
      assert length(report.detailed_timings) == 3
      assert %DateTime{} = report.generated_at
    end
  end

  describe "CommandTracing Methods" do
    test "execute_with_tracing provides complete trace lifecycle" do
      state = %{}
      
      {:ok, final_state, result} = AriaWorkflow.Methods.CommandTracing.execute_with_tracing(state, %{
        command: "echo",
        args: ["Traced execution"]
      })
      
      assert is_binary(result.trace_id)
      assert result.execution_result.duration_seconds > 0
      assert result.execution_result.exit_code == 0
      assert String.contains?(result.execution_result.output, "Traced execution")
      
      # Should have completed trace in state
      assert Map.has_key?(final_state, :completed_traces)
      assert Map.has_key?(final_state.completed_traces, result.trace_id)
    end

    test "execute_with_tracing handles timeouts" do
      state = %{}
      
      {:ok, _final_state, result} = AriaWorkflow.Methods.CommandTracing.execute_with_tracing(state, %{
        command: "sleep",
        args: ["10"],
        timeout_ms: 100  # Very short timeout
      })
      
      assert is_binary(result.trace_id)
      assert result.execution_result.status == :timeout
      assert result.execution_result.exit_code != 0
    end

    test "generate_execution_summary analyzes completed traces" do
      # Create state with completed traces
      state = %{
        completed_traces: %{
          "trace1" => %{duration_seconds: 1.2, status: :success, exit_code: 0, command: "cmd1"},
          "trace2" => %{duration_seconds: 0.9, status: :success, exit_code: 0, command: "cmd2"},
          "trace3" => %{duration_seconds: 0.5, status: :failed, exit_code: 1, command: "cmd3"}
        }
      }
      
      {:ok, _final_state, summary} = AriaWorkflow.Methods.CommandTracing.generate_execution_summary(state)
      
      assert summary.statistics.total_executions == 3
      assert summary.statistics.successful_executions == 2
      assert summary.statistics.failed_executions == 1
      assert_in_delta summary.statistics.average_duration, 0.87, 0.01
      assert summary.statistics.total_duration == 2.6
      
      assert length(summary.execution_details) == 3
      assert %DateTime{} = summary.generated_at
    end
  end

  describe "Edge Cases and Error Handling" do
    test "handles empty state gracefully" do
      state = %{}
      
      # These should not crash with empty state
      {:ok, _} = AriaWorkflow.Tasks.BasicTiming.get_current_time(state)
      {:ok, _} = AriaWorkflow.Tasks.BasicTiming.get_timezone_info(state)
      {:ok, _, _} = AriaWorkflow.Methods.BasicTiming.generate_timing_report(state)
      {:ok, _, _} = AriaWorkflow.Methods.CommandTracing.generate_execution_summary(state)
    end

    test "handles missing timer ID in stop_timer" do
      state = %{active_timers: %{}}
      
      result = AriaWorkflow.Tasks.BasicTiming.stop_timer(state, %{
        timer_id: "non_existent_timer"
      })
      
      assert {:error, :timer_not_found} = result
    end

    test "handles missing trace ID in command tracing" do
      state = %{}
      
      result = AriaWorkflow.Tasks.CommandTracing.trace_command_end(state, %{
        exit_code: 0
      })
      
      assert {:error, :missing_trace_id} = result
    end

    test "handles non-existent commands gracefully" do
      state = %{}
      
      {:ok, _final_state, result} = AriaWorkflow.Methods.BasicTiming.time_command_execution(state, %{
        command: "definitely_not_a_real_command_12345"
      })
      
      # Should fail but not crash
      assert result.status == :failed
      assert result.exit_code != 0
    end
  end
end
