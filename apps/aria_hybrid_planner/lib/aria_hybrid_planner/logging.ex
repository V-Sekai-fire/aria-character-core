# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.Logging do
  @moduledoc """
  Logging functions for HybridCoordinatorV2.

  Handles progress logging, error logging, and structured logging operations.
  """

  require Logger

  @doc """
  Log progress for different phases of planning and execution.
  """
  @spec log_progress(String.t(), map(), keyword()) :: :ok
  def log_progress(phase, progress, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 0 do
      case phase do
        "planning" ->
          message = "Planning phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        "temporal_validation" ->
          message = "Temporal validation: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        "execution" ->
          message = "Execution phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        "replanning" ->
          message = "Replanning phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        _ ->
          message = "#{phase}: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)
      end
    else
      :ok
    end
  end

  @doc """
  Log errors with context and metadata.
  """
  @spec log_error(term(), map(), keyword()) :: :ok
  def log_error(error, context, opts) do
    error_message = case error do
      %{__exception__: true} = exception -> "Exception: #{Exception.message(exception)}"
      error_string when is_binary(error_string) -> error_string
      other -> "Error: #{inspect(other)}"
    end

    error_metadata = Map.merge(context, %{
      type: :error,
      timestamp: System.system_time(:millisecond)
    })

    log(:error, error_message, error_metadata, opts)
  end

  @doc """
  Generic logging function with structured metadata.
  """
  @spec log(atom(), String.t(), map(), keyword()) :: :ok
  def log(level, message, metadata, opts) do
    try do
      logger_level = case level do
        :debug -> :debug
        :info -> :info
        :warning -> :warning
        :error -> :error
        _ -> :info
      end

      enhanced_metadata = Map.merge(metadata, %{
        timestamp: System.system_time(:millisecond),
        strategy_source: "HybridPlanner"
      })

      verbose = Keyword.get(opts, :verbose, 0)

      formatted_message = if verbose > 2 and map_size(enhanced_metadata) > 0 do
        "#{message} | Metadata: #{inspect(enhanced_metadata)}"
      else
        message
      end

      Logger.log(logger_level, formatted_message)
      :ok
    rescue
      _ ->
        Logger.debug("Logger: #{level} - #{message}")
        :ok
    end
  end
end
