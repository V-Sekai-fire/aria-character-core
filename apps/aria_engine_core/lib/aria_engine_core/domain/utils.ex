# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Domain.Utils do
  @moduledoc """
  Mock implementation of AriaEngineCore.Domain.Utils for compilation.

  This module provides utility functions for domain operations.
  Currently mocked with basic functionality to enable compilation.
  """

  @doc """
  Infer method name from a function.
  """
  @spec infer_method_name(function()) :: String.t()
  def infer_method_name(fun) when is_function(fun) do
    # Basic implementation - extract function name
    info = Function.info(fun)
    case Keyword.get(info, :name) do
      name when is_atom(name) -> Atom.to_string(name)
      _ -> "unknown_method"
    end
  end

  def infer_method_name(_), do: "unknown_method"

  @doc """
  Verify goal implementation (mock).
  """
  @spec verify_goal(term(), String.t(), term(), list(), term(), integer(), boolean()) :: boolean()
  def verify_goal(_state, _method_name, _state_var, _args, _desired_values, _depth, _verbose) do
    true
  end

  @doc """
  Get domain summary.
  """
  @spec summary(map()) :: String.t()
  def summary(domain) do
    actions_count = domain |> Map.get(:actions, %{}) |> map_size()
    task_methods_count = domain |> Map.get(:task_methods, %{}) |> map_size()
    unigoal_methods_count = domain |> Map.get(:unigoal_methods, %{}) |> map_size()

    "Domain Summary: #{actions_count} actions, #{task_methods_count} task methods, #{unigoal_methods_count} unigoal methods"
  end

  @doc """
  Add porcelain actions to domain.
  """
  @spec add_porcelain_actions(map()) :: map()
  def add_porcelain_actions(domain) do
    # Mock implementation - just return domain as-is
    domain
  end

  @doc """
  Create a complete domain with default name.
  """
  @spec create_complete_domain(String.t()) :: map()
  def create_complete_domain(name \\ "complete") do
    %{
      name: name,
      actions: %{},
      task_methods: %{},
      unigoal_methods: %{},
      multigoal_methods: %{},
      multitodo_methods: %{}
    }
  end
end
