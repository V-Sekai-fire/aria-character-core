# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domains.WorkflowSystem do
  @moduledoc """
  Bridge module to AriaWorkflowSystem domain.

  This module provides the expected interface for tests while delegating
  to the actual AriaWorkflowSystem implementation.
  """

  require Logger

  @doc """
  Creates a workflow system domain.
  """
  def create_domain do
    if Code.ensure_loaded?(AriaWorkflowSystem) do
      AriaWorkflowSystem.create_domain()
    else
      Logger.debug("AriaWorkflowSystem module not available")
      AriaEngine.Domain.new("workflow_system_fallback")
    end
  end
end
