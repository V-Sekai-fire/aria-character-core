# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.DefaultLoggingStrategy do
  @moduledoc """
  Default logging strategy for membrane planning filters.

  Provides simple logging functionality for planning operations,
  progress tracking, and error reporting.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W035DLOG"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  require Logger

  @doc """
  Logs progress information for a planning operation.
  """
  @spec log_progress(String.t(), map(), keyword()) :: :ok
  def log_progress(operation, progress_data, _options) do
    Logger.info("📊 #{operation} progress: #{inspect(progress_data, pretty: true)}")
    :ok
  end

  @doc """
  Logs error information for a planning operation.
  """
  @spec log_error(String.t(), map(), keyword()) :: :ok
  def log_error(error_message, error_context, _options) do
    Logger.error("❌ Planning error: #{error_message}")
    Logger.error("❌ Context: #{inspect(error_context, pretty: true)}")
    :ok
  end

  @doc """
  Logs debug information for a planning operation.
  """
  @spec log_debug(String.t(), map(), keyword()) :: :ok
  def log_debug(debug_message, debug_data, _options) do
    Logger.debug("🔍 #{debug_message}: #{inspect(debug_data, pretty: true)}")
    :ok
  end

  @doc """
  Logs timing information for a planning operation.
  """
  @spec log_timing(String.t(), non_neg_integer(), keyword()) :: :ok
  def log_timing(operation, duration_ms, _options) do
    Logger.info("⏱️ #{operation} completed in #{duration_ms}ms")
    :ok
  end

  @doc """
  Logs metrics information for a planning operation.
  """
  @spec log_metrics(String.t(), map(), keyword()) :: :ok
  def log_metrics(operation, metrics, _options) do
    Logger.info("📈 #{operation} metrics: #{inspect(metrics, pretty: true)}")
    :ok
  end
end
