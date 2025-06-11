# Copyright (c) 2025-present K. S.      # Add execution log entry
      # Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.Methods.BasicTiming do
  @moduledoc """
  Basic timing methods for SOP execution.

  Provides compound operations that combine multiple timing tasks
  to achieve higher-level timing and measurement goals.
  """

  require Logger
  alias AriaWorkflow.Tasks.BasicTiming

  @doc """
  Times the execution of a command or operation.

  This method combines starting a timer, executing an operation,
  and stopping the timer to provide complete timing information.
  """
  def time_command_execution(state, args \\ %{}) do
    operation = Map.get(args, :operation, "unknown_operation")
    timer_id = Map.get(args, :timer_id, operation)

    Logger.info("Starting timed execution: #{operation}")

    with {:ok, state1} <- BasicTiming.start_timer(state, %{timer_id: timer_id, command: operation}),
         {:ok, state2, result} <- execute_operation(state1, args),
         {:ok, state3, timer_result} <- BasicTiming.stop_timer(state2, %{timer_id: timer_id, status: :completed}) do

      # Calculate duration from timer result
      duration = Map.get(timer_result, :duration_seconds, 0)

      # Log execution details
      {:ok, final_state} = BasicTiming.log_execution(state3, %{
        operation: operation,
        status: :info,
        duration_seconds: duration,
        details: %{
          timer_id: timer_id,
          result: result
        }
      })

      # Store last command execution for tests
      final_state_with_last = Map.put(final_state, :last_command_execution, %{
        operation: operation,
        duration_seconds: duration,
        status: if(result.exit_code == 0, do: :success, else: :failed),
        result: result
      })

      {:ok, final_state_with_last, %{
        timer_id: timer_id,
        duration_seconds: duration,
        operation: operation,
        result: result,
        exit_code: result.exit_code,
        status: Map.get(result, :status, if(result.exit_code == 0, do: :success, else: :failed)),
        output: result.output
      }}
    else
      {:error, reason} ->
        Logger.error("Timed execution failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Measures the duration of multiple sequential operations.

  This method tracks timing for a series of operations and provides
  aggregate timing statistics.
  """
  def time_sequential_operations(state, args \\ %{}) do
    operations = Map.get(args, :operations, [])
    session_id = Map.get(args, :session_id, "seq_#{:erlang.unique_integer()}")

    Logger.info("Starting sequential timing session: #{session_id}")

    # Start session timer
    {:ok, state1} = BasicTiming.start_timer(state, %{timer_id: session_id, command: "sequential_operations"})

    # Execute each operation with timing
    {final_state, results} = Enum.reduce_while(operations, {state1, []}, fn operation, {current_state, acc_results} ->
      case time_single_operation(current_state, operation) do
        {:ok, new_state, result} ->
          {:cont, {new_state, [result | acc_results]}}

        {:error, reason} ->
          {:halt, {{:error, reason}, acc_results}}
      end
    end)

    case final_state do
      {:error, _} = error ->
        error

      _ ->
        # Stop session timer
        {:ok, state2, session_result} = BasicTiming.stop_timer(final_state, %{timer_id: session_id, status: :completed})

        total_duration = Map.get(session_result, :duration_seconds, 0)
        operation_count = length(results)

        {:ok, state2, %{
          session_id: session_id,
          total_duration_seconds: total_duration,
          operation_count: operation_count,
          results: Enum.reverse(results)
        }}
    end
  end

  @doc """
  Generates a timing report from collected timing data.
  """
  def generate_timing_report(state, _args \\ %{}) do
    Logger.info("Generating timing report")

    completed_timers = Map.get(state, :completed_timers, %{})
    execution_log = Map.get(state, :execution_log, [])
    current_time_info = Map.get(state, :current_time_info, %{})

    # Calculate summary statistics
    durations = completed_timers
    |> Map.values()
    |> Enum.map(& &1.duration_seconds)
    |> Enum.filter(&is_number/1)

    summary_stats = case durations do
      [] -> %{count: 0}
      _ ->
        successful_count = completed_timers
        |> Map.values()
        |> Enum.count(& &1.status == :completed)

        failed_count = map_size(completed_timers) - successful_count

        %{
          count: length(durations),
          total_time: Enum.sum(durations),
          total_duration: Enum.sum(durations),
          average_time: Enum.sum(durations) / length(durations),
          average_duration: Enum.sum(durations) / length(durations),
          min_duration: Enum.min(durations),
          max_duration: Enum.max(durations),
          successful_count: successful_count,
          failed_count: failed_count
        }
    end

    # Create comprehensive report
    report = %{
      generated_at: DateTime.utc_now(),
      timezone_info: Map.get(state, :timezone_info, %{}),
      current_time_info: current_time_info,
      summary_statistics: summary_stats,
      completed_operations: completed_timers,
      detailed_timings: Map.values(completed_timers),
      execution_log_entries: length(execution_log),
      recent_log_entries: Enum.take(execution_log, 10)
    }

    # Log report summary
    Logger.info("Timing report generated: #{summary_stats.count} operations, total: #{summary_stats[:total_duration] || 0}s")

    # Store report in state
    reports = Map.get(state, :timing_reports, [])
    new_reports = [report | reports]
    new_state = Map.put(state, :timing_reports, new_reports)

    {:ok, new_state, report}
  end

  # Private helper functions

  # Private helper to time a single operation
  defp time_single_operation(state, operation) do
    operation_id = Map.get(operation, :id, "op_#{:erlang.unique_integer()}")

    time_command_execution(state, %{
      timer_id: operation_id,
      operation: Map.get(operation, :name, "unknown"),
      command: Map.get(operation, :command),
      timeout: Map.get(operation, :timeout, 30_000)
    })
  end

  # Private helper to execute an operation
  defp execute_operation(state, args) do
    command = Map.get(args, :command)
    command_args = Map.get(args, :args, [])
    timeout = Map.get(args, :timeout, 30_000)

    if command do
      # Execute with timeout
      task = Task.async(fn ->
        if command_args != [] do
          # Execute with separate command and args
          System.cmd(command, command_args, stderr_to_stdout: true)
        else
          # Execute as shell command
          System.cmd("sh", ["-c", command], stderr_to_stdout: true)
        end
      end)

      try do
        result = Task.await(task, timeout)
        {output, exit_code} = result

        {:ok, state, %{
          output: output,
          exit_code: exit_code,
          command: if(command_args != [], do: "#{command} #{Enum.join(command_args, " ")}", else: command)
        }}
      catch
        :exit, {:timeout, _} ->
          Task.shutdown(task, :brutal_kill)
          {:ok, state, %{
            output: "Command timed out",
            exit_code: 124,
            command: if(command_args != [], do: "#{command} #{Enum.join(command_args, " ")}", else: command),
            status: :timeout
          }}
      end
    else
      # Simulate operation for testing
      Process.sleep(100)
      {:ok, state, %{
        output: "simulated output",
        exit_code: 0,
        command: "simulated_command"
      }}
    end
  end
end
