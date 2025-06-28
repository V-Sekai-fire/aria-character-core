# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore do
  @moduledoc """
  AriaEngine Core - Unified Planning API

  This module provides the main entry point for the AriaEngine planning system,
  implementing the R25W1398085 unified durative action specification.

  ## Quick Start

      # Plan and execute with intelligent recovery
      {:ok, final_state} = AriaEngineCore.Planner.run_lazy(domain, state, goals)
      IO.puts("Success! Goals achieved.")

  ## Main Modules

  - `AriaEngineCore.Planner` - Primary planning interface with `run_lazy/4` and `plan/4`
  - `AriaEngineCore.Domain` - Domain definition and management
  - `AriaEngineCore.State` - State representation and manipulation

  ## Features

  - **GTpyHOP-style Interface**: Familiar planning patterns with lazy refinement
  - **Unified Durative Action Specification**: Complete R25W1398085 implementation
  - **Intelligent Recovery**: Automatic replanning on execution failures
  - **Validated Plans**: All output plans are guaranteed to be valid and executable
  - **Clean External API**: No configuration complexity exposed to users

  For detailed usage, see `AriaEngineCore.Planner` documentation.
  """

  @doc """
  Get the version of AriaEngine Core.

  ## Examples

      iex> AriaEngineCore.version()
      "0.1.0"
  """
  @spec version() :: String.t()
  def version do
    case Application.spec(:aria_engine_core, :vsn) do
      vsn when is_list(vsn) -> List.to_string(vsn)
      _ -> "unknown"
    end
  end
end
