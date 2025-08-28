# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaEngineCore.Domain.BehaviourImpl do
  @moduledoc """
  Behaviour implementation for AriaEngineCore.Domain that delegates to AriaCore.

  This module provides behaviour implementation for domain operations,
  delegating to the migrated functionality in AriaCore.
  """

  @doc """
  Get all task methods from a domain.
  """
  @spec task_methods(map()) :: map()
  def task_methods(domain) do
    Map.get(domain, :task_methods, %{})
  end

  @doc """
  Get all unigoal methods from a domain.
  """
  @spec unigoal_methods(map()) :: map()
  def unigoal_methods(domain) do
    Map.get(domain, :unigoal_methods, %{})
  end

  @doc """
  Get all durative actions from a domain.
  """
  @spec durative_actions(map()) :: map()
  def durative_actions(domain) do
    Map.get(domain, :durative_actions, %{})
  end
end
