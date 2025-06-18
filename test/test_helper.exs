# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

ExUnit.start()

defmodule TestOutput do
  @moduledoc """
  Conditional test output helpers that respect trace mode.
  
  According to INST-006: Passing tests should be silent and produce no log output.
  Only --trace mode should provide normal logging output.
  """

  @doc """
  Print output only when running in trace mode (mix test --trace).
  Silent during normal test execution.
  """
  def trace_puts(message) do
    if trace_mode?() do
      IO.puts(message)
    end
  end

  @doc """
  Inspect and print data only in trace mode.
  """
  def trace_inspect(data, opts \\ []) do
    if trace_mode?() do
      IO.inspect(data, opts)
    else
      data
    end
  end

  @doc """
  Check if ExUnit is running in trace mode.
  """
  def trace_mode?() do
    # ExUnit sets trace mode via configuration
    ExUnit.configuration()[:trace] == true
  end

  @doc """
  Execute a function only in trace mode (for complex output logic).
  """
  def trace_only(func) when is_function(func, 0) do
    if trace_mode?() do
      func.()
    end
  end
end
