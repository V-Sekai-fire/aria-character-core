# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.AgentEntity.PropertyManagement do
  @moduledoc """
  Property management operations for Timeline.AgentEntity.

  Handles getting, setting, and updating properties for agents and entities.
  """

  @type participant :: AriaEngine.Timeline.AgentEntity.participant()

  @doc """
  Updates properties of a participant (agent or entity).

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent("aria", "Aria VTuber")
      iex> updated_agent = Timeline.AgentEntity.PropertyManagement.update_properties(
      ...>   agent, 
      ...>   %{mood: "happy", energy: 100}
      ...> )
      iex> updated_agent.properties.mood
      "happy"

  """
  @spec update_properties(participant(), map()) :: participant()
  def update_properties(participant, new_properties) do
    updated_properties = Map.merge(participant.properties, new_properties)
    %{participant | properties: updated_properties}
  end

  @doc """
  Gets a property value from a participant.

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent(
      ...>   "aria", 
      ...>   "Aria VTuber",
      ...>   %{personality: "helpful"}
      ...> )
      iex> Timeline.AgentEntity.PropertyManagement.get_property(agent, :personality)
      "helpful"
      iex> Timeline.AgentEntity.PropertyManagement.get_property(agent, :unknown)
      nil

  """
  @spec get_property(participant(), atom()) :: any()
  def get_property(participant, property_key) do
    Map.get(participant.properties, property_key)
  end

  @doc """
  Sets a property value for a participant.

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent("aria", "Aria VTuber")
      iex> updated_agent = Timeline.AgentEntity.PropertyManagement.set_property(agent, :mood, "excited")
      iex> Timeline.AgentEntity.PropertyManagement.get_property(updated_agent, :mood)
      "excited"

  """
  @spec set_property(participant(), atom(), any()) :: participant()
  def set_property(participant, property_key, value) do
    updated_properties = Map.put(participant.properties, property_key, value)
    %{participant | properties: updated_properties}
  end
end
