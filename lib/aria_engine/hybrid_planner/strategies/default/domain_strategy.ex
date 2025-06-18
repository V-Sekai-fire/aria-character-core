# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.HybridPlanner.Strategies.Default.DomainStrategy do
  @moduledoc """
  Default domain strategy implementation wrapping existing domain operations.
  
  This strategy encapsulates domain queries and metadata operations while
  providing the clean strategy interface defined in ADR-091.
  """

  @behaviour AriaEngine.HybridPlanner.Strategies.DomainStrategy

  require Logger

  @impl true
  def get_action_metadata(domain, action_name, _opts \\ []) do
    try do
      case Map.get(domain.actions, action_name) do
        action_fn when is_function(action_fn) ->
          # Get basic metadata about the action
          metadata = %{
            name: action_name,
            arity: :erlang.fun_info(action_fn, :arity) |> elem(1),
            type: :primitive_action,
            available: true
          }
          {:ok, metadata}
        
        nil ->
          {:error, "Action #{action_name} not found in domain"}
      end
    rescue
      e ->
        {:error, "DomainStrategy action metadata error: #{Exception.message(e)}"}
    end
  end

  @impl true
  def get_task_methods(domain, task_name, _opts \\ []) do
    try do
      case Map.get(domain.task_methods, task_name) do
        methods when is_list(methods) ->
          {:ok, methods}
        
        nil ->
          {:ok, []}
      end
    rescue
      e ->
        {:error, "DomainStrategy task methods error: #{Exception.message(e)}"}
    end
  end

  @impl true
  def get_goal_methods(domain, goal_spec, _opts \\ []) do
    try do
      case goal_spec do
        {predicate, subject, _value} ->
          # Look for unigoal methods for this predicate
          goal_key = "#{predicate}_#{subject}"
          case Map.get(domain.unigoal_methods, goal_key) do
            methods when is_list(methods) ->
              {:ok, methods}
            nil ->
              # Also check for generic predicate methods
              case Map.get(domain.unigoal_methods, predicate) do
                methods when is_list(methods) -> {:ok, methods}
                nil -> {:ok, []}
              end
          end
        
        _ ->
          {:ok, []}
      end
    rescue
      e ->
        {:error, "DomainStrategy goal methods error: #{Exception.message(e)}"}
    end
  end

  @impl true
  def validate_domain(domain, _opts \\ []) do
    try do
      errors = []
      
      # Check actions
      errors = if is_map(domain.actions) do
        errors
      else
        ["Actions must be a map" | errors]
      end
      
      # Check task methods
      errors = if is_map(domain.task_methods) do
        errors
      else
        ["Task methods must be a map" | errors]
      end
      
      # Check unigoal methods
      errors = if is_map(domain.unigoal_methods) do
        errors
      else
        ["Unigoal methods must be a map" | errors]
      end
      
      # Check multigoal methods
      errors = if is_list(domain.multigoal_methods) do
        errors
      else
        ["Multigoal methods must be a list" | errors]
      end
      
      case errors do
        [] -> {:ok, true}
        error_list -> {:error, "Domain validation failed: #{Enum.join(error_list, ", ")}"}
      end
    rescue
      e ->
        {:error, "DomainStrategy validation error: #{Exception.message(e)}"}
    end
  end

  def strategy_info do
    %{
      name: "Domain Strategy",
      version: "1.0.0",
      description: "Default domain query and metadata strategy",
      capabilities: [:action_metadata, :method_queries, :domain_validation],
      underlying_implementation: "AriaEngine.Domain.Core"
    }
  end
end
