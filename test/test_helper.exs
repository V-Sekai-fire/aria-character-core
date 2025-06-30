# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# Cross-app dependency analysis: No violations found
# Cross-app dependency analysis: No violations found
# SPDX-License-Identifier: MIT

ExUnit.start()

defmodule TestOutput do
  @moduledoc "Conditional test output helpers that respect trace mode.\n\nAccording to INST-006: Passing tests should be silent and produce no log output.\nOnly --trace mode should provide normal logging output.\n"
  require Logger

  @doc "Log debug message only when running in trace mode (mix test --trace).\nSilent during normal test execution.\n"
  def trace_puts(message) do
    if trace_mode?() do
      Logger.debug(message)
    end
  end

  @doc "Inspect and log data only in trace mode.\n"
  def trace_inspect(data, opts \\ []) do
    if trace_mode?() do
      Logger.debug(inspect(data, opts))
      data
    else
      data
    end
  end

  @doc "Check if ExUnit is running in trace mode.\n"
  def trace_mode?() do
    ExUnit.configuration()[:trace] == true
  end

  @doc "Execute a function only in trace mode (for complex output logic).\n"
  def trace_only(func) when is_function(func, 0) do
    if trace_mode?() do
      func.()
    end
  end
end
