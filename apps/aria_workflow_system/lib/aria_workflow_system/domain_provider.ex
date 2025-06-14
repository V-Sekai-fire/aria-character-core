# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflowSystem.DomainProvider do
  @moduledoc """
  Domain provider for workflow system functionality.
  """

  @behaviour AriaEngine.DomainProvider

  @impl true
  def domain_type, do: "workflow_system"

  @impl true
  def create_domain do
    AriaWorkflowSystem.create_domain()
  end
end
