# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincExecutor.ExecutorBehaviour do
  @moduledoc """
  Behaviour for MiniZinc execution to enable testing and mocking.

  This behaviour defines the interface for executing MiniZinc models,
  allowing for easy testing with mock implementations.
  """

  @doc """
  Execute raw MiniZinc content and return the result.

  ## Parameters
  - `minizinc_content` - Raw MiniZinc model content as string
  - `options` - Execution options including timeout

  ## Returns
  - `{:ok, result}` - Successfully executed with solution data
  - `{:error, reason}` - Failed to execute or solve
  """
  @callback exec_raw(minizinc_content :: String.t(), options :: keyword()) ::
              {:ok, map()} | {:error, term()}

  @doc """
  Check if MiniZinc is available on the system.

  ## Returns
  - `{:ok, version}` - MiniZinc is available with version information
  - `{:error, reason}` - MiniZinc is not available or accessible
  """
  @callback check_availability() :: {:ok, String.t()} | {:error, term()}
end
