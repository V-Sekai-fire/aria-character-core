# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCharacterCore do
  @moduledoc """
  AriaCharacterCore is a comprehensive character AI system that provides:

  - Hybrid planning capabilities through AriaEngine
  - RDF knowledge base management through AriaTown  
  - Workflow execution and management through AriaWorkflow
  - Web coordination interface through AriaCoordinate
  - Authentication and security services
  - Storage and file management
  - Monitoring and telemetry
  - AI/ML interpretation services

  This module consolidates all the functionality that was previously distributed
  across multiple umbrella applications into a single, cohesive application.
  """

  @doc """
  Returns the version of AriaCharacterCore.
  """
  @spec version() :: String.t()
  def version, do: "0.2.0"
end
