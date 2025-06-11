# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.Methods.CommandTracing do
  @moduledoc """
  Command tracing methods for SOP execution.
  
  Provides compound operations that combine multiple command tracing tasks
  to achieve higher-level command execution monitoring goals.
  """

  require Logger
  alias AriaWorkflow.Tasks.{CommandTracing, BasicTiming}

  @doc """
  Executes a command with full tracing capabilities.
  
  This method combines command tracing, timing, and error handling
  to provide comprehensive command execution monitoring.
  """
  def execute_with_tracing(state, args \\ %{}) do
    command = Map.get(args, :command)
    command_args = Map.get(args, :args, [])
    timeout_ms = Map.get(args, :timeout_ms, 30_000)
    
    unless command do
      {:error, :missing_command}
    end
    
    Logger.info("Executing with tracing: #{command}")
    
    # Add timeout to state for use in execute_command_safely
    state_with_timeout = Map.put(state, :timeout_ms, timeout_ms)
    
    # Start command trace
    with {:ok, state1, trace_id} <- CommandTracing.trace_command_start(state_with_timeout, %{
           command: command,
           args: command_args
         }),
         
         # Start timing
         {:ok, state2} <- BasicTiming.start_timer(state1, %{
           timer_id: trace_id,
           command: command
         }),
         
         # Execute command
         {state3, execution_result} <- execute_command_safely(state2, command, command_args, trace_id),
         
         # Stop timing
         {:ok, state4, _timer_result} <- BasicTiming.stop_timer(state3, %{
           timer_id: trace_id,
           status: get_execution_status(execution_result)
         }),
         
         # End trace
         {:ok, final_state, trace_result} <- CommandTracing.trace_command_end(state4, %{
           trace_id: trace_id,
           exit_code: get_exit_code(execution_result)
         }) do
      
      Logger.info("Command tracing completed: #{trace_id}")
      
      # Create a properly formatted execution result
      formatted_execution_result = %{
        duration_seconds: trace_result.duration_seconds,
        exit_code: trace_result.exit_code,
        status: Map.get(execution_result, :status, trace_result.status),
        output: execution_result.output || ""
      }
      
      {:ok, final_state, %{
        trace_id: trace_id, 
        execution_result: formatted_execution_result
      }}
    else
      error ->
        Logger.error("Command tracing failed: #{inspect(error)}")
        error
    end
  end

  @doc """
  Generates an execution summary from traced commands.
  """
  def generate_execution_summary(state, args \\ %{}) do
    Logger.info("Generating execution summary")
    
    completed_traces = Map.get(state, :completed_traces, %{})
    active_traces = Map.get(state, :command_traces, %{})
    
    # Analyze completed traces
    success_count = completed_traces
    |> Map.values()
    |> Enum.count(&(&1.status == :success))
    
    failure_count = completed_traces
    |> Map.values()
    |> Enum.count(&(&1.status == :failed))
    
    error_count = completed_traces
    |> Map.values()
    |> Enum.count(&(&1.status == :error))
    
    # Calculate timing statistics
    durations = completed_traces
    |> Map.values()
    |> Enum.map(&Map.get(&1, :duration_seconds))
    |> Enum.filter(&is_number/1)
    
    timing_stats = case durations do
      [] -> %{count: 0}
      _ ->
        %{
          count: length(durations),
          total_duration: Enum.sum(durations),
          average_duration: Enum.sum(durations) / length(durations),
          min_duration: Enum.min(durations),
          max_duration: Enum.max(durations)
        }
    end
    
    # Find recent failures
    recent_failures = completed_traces
    |> Map.values()
    |> Enum.filter(&(&1.status in [:failed, :error]))
    |> Enum.filter(&Map.has_key?(&1, :end_datetime))  # Only include traces with end_datetime
    |> Enum.sort_by(&(&1.end_datetime), {:desc, DateTime})
    |> Enum.take(5)
    
    # Create summary
    summary = %{
      generated_at: DateTime.utc_now(),
      statistics: %{
        total_executions: map_size(completed_traces),
        active_executions: map_size(active_traces),
        successful_executions: success_count,
        failed_executions: failure_count,
        success_count: success_count,
        failure_count: failure_count,
        error_count: error_count,
        success_rate: calculate_success_rate(success_count, map_size(completed_traces)),
        average_duration: case durations do
          [] -> 0.0
          _ -> Enum.sum(durations) / length(durations)
        end,
        total_duration: Enum.sum(durations)
      },
      timing_statistics: timing_stats,
      recent_failures: recent_failures,
      most_used_commands: get_command_usage_stats(completed_traces),
      execution_details: Map.values(completed_traces)
    }
    
    # Log summary
    total = summary.statistics.total_executions
    success_rate = summary.statistics.success_rate
    Logger.info("Execution summary: #{total} total, #{success_rate}% success rate")
    
    # Store summary in state
    summaries = Map.get(state, :execution_summaries, [])
    new_summaries = [summary | summaries]
    new_state = Map.put(state, :execution_summaries, new_summaries)
    
    {:ok, new_state, summary}
  end

  # Private helper functions

  defp execute_command_safely(state, command, args, trace_id) do
    timeout_ms = Map.get(state, :timeout_ms, 30_000)  # Default 30 seconds
    
    try do
      task = Task.async(fn ->
        System.cmd(command, args, stderr_to_stdout: true)
      end)
      
      case Task.yield(task, timeout_ms) do
        {:ok, {output, exit_code}} ->
          # Capture output
          {:ok, state_with_output} = CommandTracing.capture_command_output(state, %{
            trace_id: trace_id,
            stdout: output
          })
          
          execution_result = %{
            status: if(exit_code == 0, do: :success, else: :failed),
            exit_code: exit_code,
            output: output
          }
          
          {state_with_output, execution_result}
          
        nil ->
          # Timeout occurred
          Task.shutdown(task, :brutal_kill)
          
          execution_result = %{
            status: :timeout,
            exit_code: 124,  # Standard timeout exit code
            output: "Command timed out after #{timeout_ms}ms"
          }
          
          {state, execution_result}
          
        {:exit, reason} ->
          # Task exited abnormally
          execution_result = %{
            status: :timeout,
            exit_code: 124,
            output: "Command failed with exit reason: #{inspect(reason)}"
          }
          
          {state, execution_result}
      end
    rescue
      error ->
        # Handle execution error
        {:ok, state_with_error} = CommandTracing.handle_command_error(state, %{
          trace_id: trace_id,
          error: error,
          error_type: :execution_exception
        })
        
        execution_result = %{
          status: :error,
          exit_code: -1,
          output: "Error: #{inspect(error)}"
        }
        
        {state_with_error, execution_result}
    end
  end

  defp get_execution_status(%{status: status}), do: status
  defp get_execution_status(_), do: :unknown

  defp get_exit_code(%{exit_code: code}), do: code
  defp get_exit_code(_), do: -1

  defp calculate_success_rate(_, 0), do: 0.0
  defp calculate_success_rate(success_count, total_count) do
    Float.round(success_count / total_count * 100, 2)
  end

  defp get_command_usage_stats(completed_traces) do
    completed_traces
    |> Map.values()
    |> Enum.filter(&Map.has_key?(&1, :command))  # Only include traces with command field
    |> Enum.group_by(& &1.command)
    |> Enum.map(fn {command, traces} ->
      %{
        command: command,
        usage_count: length(traces),
        success_count: Enum.count(traces, &(&1.status == :success)),
        average_duration: calculate_average_duration(traces)
      }
    end)
    |> Enum.sort_by(& &1.usage_count, :desc)
    |> Enum.take(10)
  end

  defp calculate_average_duration(traces) do
    durations = traces
    |> Enum.map(&Map.get(&1, :duration_seconds))
    |> Enum.filter(&is_number/1)
    
    case durations do
      [] -> 0.0
      _ -> Enum.sum(durations) / length(durations)
    end
  end
end
