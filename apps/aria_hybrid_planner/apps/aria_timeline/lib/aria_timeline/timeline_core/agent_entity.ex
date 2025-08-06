# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimeline.TimelineCore.AgentEntity do
  @moduledoc """
  Mock implementation of AriaTimeline.TimelineCore.AgentEntity for compilation.

  This module provides agent entity management functionality.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: map()

  @doc """
  Create a new entity.
  """
  @spec create_entity(String.t(), String.t(), map(), list()) :: t()
  def create_entity(entity_id, name, properties, _opts) do
    %{
      id: entity_id,
      name: name,
      properties: properties,
      capabilities: [],
      is_agent: false
    }
  end

  @doc """
  Add capabilities to an entity.
  """
  @spec add_capabilities(t(), list()) :: t()
  def add_capabilities(entity, new_capabilities) do
    current_capabilities = Map.get(entity, :capabilities, [])
    updated_capabilities = current_capabilities ++ new_capabilities

    entity
    |> Map.put(:capabilities, updated_capabilities)
    |> Map.put(:is_agent, length(updated_capabilities) > 0)
  end

  @doc """
  Check if entity is currently an agent.
  """
  @spec is_currently_agent?(t()) :: boolean()
  def is_currently_agent?(entity) do
    capabilities = Map.get(entity, :capabilities, [])
    length(capabilities) > 0
  end

  @doc """
  Check if value is an entity.
  """
  @spec entity?(term()) :: boolean()
  def entity?(%{id: _id}), do: true
  def entity?(_), do: false
end
