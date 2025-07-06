# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule TestOutput do
  @moduledoc """
  Test output helper for aria_storage tests.

  Provides trace output functionality for debugging and benchmarking tests.
  """

  @doc """
  Outputs trace information during tests.

  This function can be used to provide debugging output during test execution.
  """
  def trace_puts(message) when is_binary(message) do
    if System.get_env("TEST_TRACE") == "true" do
      Logger.debug(message)
    end
    :ok
  end
end
