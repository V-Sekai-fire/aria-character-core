# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.AgentEntity.StateTransitions do
  @moduledoc """
  State transition operations for Timeline.AgentEntity.

  Handles transitions between agent and entity states based on capabilities
  and dynamic state changes.
  """

  alias Timeline.AgentEntity.CapabilityManagement

  @type participant :: Timeline.AgentEntity.participant()

  @doc """
  Transitions a participant between agent and entity states based on capabilities.

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity("car", "Tesla Model 3")
      iex> agent = Timeline.AgentEntity.StateTransitions.transition_to_agent(entity, [:autonomous_driving, :decision_making])
      iex> Timeline.AgentEntity.CapabilityManagement.is_currently_agent?(agent)
      true
      
      iex> back_to_entity = Timeline.AgentEntity.StateTransitions.transition_to_entity(agent)
      iex> Timeline.AgentEntity.CapabilityManagement.is_currently_agent?(back_to_entity)
      false

  """
  @spec transition_to_agent(participant(), [atom()]) :: participant()
  def transition_to_agent(participant, action_capabilities) when is_list(action_capabilities) do
    participant
    |> CapabilityManagement.add_capabilities(action_capabilities)
    |> Map.put(:type, :agent)
  end

  @spec transition_to_entity(participant()) :: participant()
  def transition_to_entity(participant) do
    participant
    |> Map.put(:capabilities, [])
    |> Map.put(:type, :entity)
  end
end
