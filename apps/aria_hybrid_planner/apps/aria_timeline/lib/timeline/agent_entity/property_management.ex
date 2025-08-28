# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.AgentEntity.PropertyManagement do
  @moduledoc "Property management operations for Timeline.AgentEntity.\n\nHandles getting, setting, and updating properties for agents and entities.\n"
  @type participant :: Timeline.AgentEntity.participant()
  @doc "Updates properties of a participant (agent or entity).\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.create_agent(\"aria\", \"Aria VTuber\")\n    iex> updated_agent = Timeline.AgentEntity.PropertyManagement.update_properties(\n    ...>   agent, \n    ...>   %{mood: \"happy\", energy: 100}\n    ...> )\n    iex> updated_agent.properties.mood\n    \"happy\"\n\n"
  @spec update_properties(participant(), map()) :: participant()
  def update_properties(participant, new_properties) do
    updated_properties = Map.merge(participant.properties, new_properties)
    %{participant | properties: updated_properties}
  end

  @doc "Gets a property value from a participant.\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.create_agent(\n    ...>   \"aria\", \n    ...>   \"Aria VTuber\",\n    ...>   %{personality: \"helpful\"}\n    ...> )\n    iex> Timeline.AgentEntity.PropertyManagement.get_property(agent, :personality)\n    \"helpful\"\n    iex> Timeline.AgentEntity.PropertyManagement.get_property(agent, :unknown)\n    nil\n\n"
  @spec get_property(participant(), atom()) :: any()
  def get_property(participant, property_key) do
    Map.get(participant.properties, property_key)
  end

  @doc "Sets a property value for a participant.\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.create_agent(\"aria\", \"Aria VTuber\")\n    iex> updated_agent = Timeline.AgentEntity.PropertyManagement.set_property(agent, :mood, \"excited\")\n    iex> Timeline.AgentEntity.PropertyManagement.get_property(updated_agent, :mood)\n    \"excited\"\n\n"
  @spec set_property(participant(), atom(), any()) :: participant()
  def set_property(participant, property_key, value) do
    updated_properties = Map.put(participant.properties, property_key, value)
    %{participant | properties: updated_properties}
  end
end
