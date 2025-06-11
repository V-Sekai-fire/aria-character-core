# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.Tasks.CommandTracing do
  @moduledoc """
  Command tracing tasks for SOP execution.

  Provides command execution tracing without external service dependencies.
  Focuses on local command execution with timing and error capture.
  """

  require Logger

  @doc """
  Traces the start of command execution.
  """
  def trace_command_start(state, args \\ %{}) do
    command = Map.get(args, :command, "unknown")
    trace_id = Map.get(args, :trace_id, generate_trace_id())

    trace_info = %{
      trace_id: trace_id,
      command: command,
      start_time: System.os_time(:millisecond),
      start_datetime: DateTime.utc_now(),
      args: Map.get(args, :args, []),
      env: Map.get(args, :env, %{}),
      status: :started
    }

    Logger.info("Command trace started: #{trace_id} - #{command}")

    # Store trace in state
    traces = Map.get(state, :command_traces, %{})
    new_traces = Map.put(traces, trace_id, trace_info)
    new_state = Map.put(state, :command_traces, new_traces)

    {:ok, new_state, trace_id}
  end

  @doc """
  Traces the end of command execution.
  """
  def trace_command_end(state, args \\ %{}) do
    trace_id = Map.get(args, :trace_id)
    exit_code = Map.get(args, :exit_code, 0)

    if trace_id do
      traces = Map.get(state, :command_traces, %{})

      case Map.get(traces, trace_id) do
        nil ->
          Logger.warning("Trace not found: #{trace_id}")
          {:error, :trace_not_found}

        trace_info ->
          end_time = System.os_time(:millisecond)
          duration_ms = end_time - trace_info.start_time

          updated_trace = Map.merge(trace_info, %{
            end_time: end_time,
            end_datetime: DateTime.utc_now(),
            duration_ms: duration_ms,
            duration_seconds: duration_ms / 1000.0,
            exit_code: exit_code,
            status: if(exit_code == 0, do: :success, else: :failed)
          })

          Logger.info("Command trace ended: #{trace_id} - #{updated_trace.status} (#{updated_trace.duration_seconds}s)")

          # Move to completed traces
          completed_traces = Map.get(state, :completed_traces, %{})
          new_completed = Map.put(completed_traces, trace_id, updated_trace)
          new_traces = Map.delete(traces, trace_id)

          new_state = state
          |> Map.put(:command_traces, new_traces)
          |> Map.put(:completed_traces, new_completed)

          {:ok, new_state, updated_trace}
      end
    else
      Logger.warning("No trace_id provided for command end")
      {:error, :missing_trace_id}
    end
  end

  @doc """
  Captures command output during execution.
  """
  def capture_command_output(state, args \\ %{}) do
    trace_id = Map.get(args, :trace_id)
    stdout = Map.get(args, :stdout, "")
    stderr = Map.get(args, :stderr, "")

    if trace_id do
      traces = Map.get(state, :command_traces, %{})

      case Map.get(traces, trace_id) do
        nil ->
          {:error, :trace_not_found}

        trace_info ->
          # Store output in proper structure
          updated_trace = Map.merge(trace_info, %{
            outputs: %{
              stdout: stdout,
              stderr: stderr
            },
            last_output_capture: DateTime.utc_now()
          })

          new_traces = Map.put(traces, trace_id, updated_trace)
          new_state = Map.put(state, :command_traces, new_traces)

          {:ok, new_state}
      end
    else
      {:error, :missing_trace_id}
    end
  end

  @doc """
  Handles command execution errors.
  """
  def handle_command_error(state, args \\ %{}) do
    trace_id = Map.get(args, :trace_id)
    error = Map.get(args, :error)
    error_type = Map.get(args, :error_type, :execution_error)

    if trace_id do
      traces = Map.get(state, :command_traces, %{})

      case Map.get(traces, trace_id) do
        nil ->
          {:error, :trace_not_found}

        trace_info ->
          error_info = %{
            error_type: error_type,
            error: error,
            error_message: get_error_message(error_type, error),
            error_time: DateTime.utc_now(),
            exit_code: Map.get(args, :exit_code),
            recoverable: Map.get(args, :recoverable, false)
          }

          updated_trace = Map.merge(trace_info, %{
            status: :error,
            error: error_info
          })

          Logger.error("Command error in trace #{trace_id}: #{inspect(error)}")

          new_traces = Map.put(traces, trace_id, updated_trace)
          new_state = Map.put(state, :command_traces, new_traces)

          {:ok, new_state}
      end
    else
      {:error, :missing_trace_id}
    end
  end

  # Private helper functions

  defp generate_trace_id do
    timestamp = System.os_time(:millisecond)
    random = :rand.uniform(10000)
    "trace_#{timestamp}_#{random}"
  end

  defp get_error_message(:timeout, _error), do: "Command timed out after 30 seconds"
  defp get_error_message(:execution_error, error), do: "Execution error: #{inspect(error)}"
  defp get_error_message(error_type, error), do: "#{error_type}: #{inspect(error)}"
end
