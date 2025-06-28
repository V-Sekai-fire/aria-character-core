# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Domain.BehaviourImpl do
  @moduledoc """
  Mock implementation of AriaEngineCore.Domain.BehaviourImpl for compilation.

  This module provides behaviour implementation for domain operations.
  Currently mocked with basic functionality to enable compilation.
  """

  @doc """
  Get all actions from a domain.
  """
  @spec actions(map()) :: map()
  def actions(domain) do
    Map.get(domain, :actions, %{})
  end

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
  Get all multigoal methods from a domain.
  """
  @spec multigoal_methods(map()) :: map()
  def multigoal_methods(domain) do
    Map.get(domain, :multigoal_methods, %{})
  end

  @doc """
  Get all durative actions from a domain.
  """
  @spec durative_actions(map()) :: map()
  def durative_actions(domain) do
    Map.get(domain, :durative_actions, %{})
  end
end
