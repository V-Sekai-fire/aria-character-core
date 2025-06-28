# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore do
  @moduledoc """
  AriaEngine Core - Unified Planning API

  This module provides the main entry point for the AriaEngine planning system,
  implementing the R25W1398085 unified durative action specification.

  ## Quick Start

      # Plan and execute with intelligent recovery
      {:ok, final_state} = AriaEngineCore.run_lazy(domain, state, goals)
      IO.puts("Success! Goals achieved.")

      # Just planning, no execution
      {:ok, plan} = AriaEngineCore.plan(domain, state, goals)

  ## Main API Functions

  - `run_lazy/3` - Plan and execute with automatic recovery (recommended)
  - `plan/3` - Just planning, no execution

  ## Inner Modules

  - `AriaEngineCore.Planner` - Primary planning interface implementation
  - `AriaEngineCore.Domain` - Domain definition and management
  - `AriaEngineCore.State` - State representation and manipulation

  ## Features

  - **GTpyHOP-style Interface**: Familiar planning patterns with lazy refinement
  - **Unified Durative Action Specification**: Complete R25W1398085 implementation
  - **Intelligent Recovery**: Automatic replanning on execution failures
  - **Validated Plans**: All output plans are guaranteed to be valid and executable
  - **Clean External API**: No configuration complexity exposed to users

  ## Advanced Usage

  For advanced usage, you can access the inner modules directly:

      # Direct access to planner module
      {:ok, final_state} = AriaEngineCore.Planner.run_lazy(domain, state, goals)

      # Domain and state creation
      domain = AriaEngineCore.Domain.new("my_domain")
      state = AriaEngineCore.State.new()
  """

  # Type aliases for the main API
  @type domain :: AriaEngineCore.Domain.t()
  @type state :: AriaEngineCore.State.t()
  @type goal :: term()
  @type plan :: [term()]

  # Delegate primary planning functions to Planner module
  defdelegate run_lazy(domain, state, goals), to: AriaEngineCore.Planner
  defdelegate plan(domain, state, goals), to: AriaEngineCore.Planner

  # Expose inner modules for advanced usage
  alias AriaEngineCore.{Domain, State, Planner}

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
