# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.AgentEntity do
  @moduledoc "Defines the semantic distinction between agents and entities in the timeline system.\n\nThis module implements the agent vs entity distinction as specified in ADR-046,\nproviding clear semantic types and operations for different kinds of temporal\nparticipants.\n\n## Definitions\n\n### Agent\nAn autonomous entity capable of:\n- Making decisions\n- Taking actions\n- Having intentions and goals\n- Responding to events\n- Initiating temporal processes\n\nExamples: AI characters, NPCs, players, autonomous systems\n\n### Entity\nA passive object that:\n- Exists in time\n- Can be acted upon\n- Has properties that change over time\n- Does not initiate actions independently\n- Participates in temporal relationships\n\nExamples: items, locations, resources, states, conditions\n\n## Specialized Modules\n\nThis module delegates to specialized sub-modules for different aspects of functionality:\n\n- `Timeline.AgentEntity.AgentManagement` - Agent creation and validation\n- `Timeline.AgentEntity.EntityManagement` - Entity creation and validation\n- `Timeline.AgentEntity.CapabilityManagement` - Capability checking and management\n- `Timeline.AgentEntity.StateTransitions` - Agent/entity state transitions\n- `Timeline.AgentEntity.PropertyManagement` - Property getting/setting\n- `Timeline.AgentEntity.OwnershipManagement` - Entity ownership operations\n- `Timeline.AgentEntity.Validation` - Participant validation\n\n## Usage\n\n    iex> alias Timeline.AgentEntity\n    iex> agent = AgentEntity.create_agent(\"aria\", \"Aria VTuber\", %{personality: \"helpful\"})\n    iex> AgentEntity.agent?(agent)\n    true\n    iex> entity = AgentEntity.create_entity(\"conference_room\", \"Conference Room A\", %{capacity: 10})\n    iex> AgentEntity.entity?(entity)\n    true\n\n## References\n\n- ADR-046: Interval Notation Usability (agent vs entity debate)\n- ADR-078: Timeline Module PC-2 STN Implementation\n"
  alias Timeline.AgentEntity.AgentManagement
  alias Timeline.AgentEntity.EntityManagement
  alias Timeline.AgentEntity.CapabilityManagement
  alias Timeline.AgentEntity.StateTransitions
  alias Timeline.AgentEntity.PropertyManagement
  alias Timeline.AgentEntity.OwnershipManagement
  alias Timeline.AgentEntity.Validation

  @type agent :: %{
          type: :agent,
          id: String.t(),
          name: String.t(),
          capabilities: [atom()],
          properties: map(),
          metadata: map()
        }
  @type entity :: %{
          type: :entity,
          id: String.t(),
          name: String.t(),
          owner_agent_id: String.t() | nil,
          properties: map(),
          metadata: map()
        }
  @type hybrid :: %{
          type: :hybrid,
          id: String.t(),
          name: String.t(),
          current_mode: :agent | :entity,
          agent_capabilities: [atom()],
          properties: map(),
          metadata: map()
        }
  @type participant :: agent() | entity() | hybrid()
  @doc "Creates a new agent.\n\nDelegates to `Timeline.AgentEntity.AgentManagement.create_agent/4`.\n"
  defdelegate create_agent(id, name, properties \\ %{}, opts \\ []), to: AgentManagement

  @doc "Checks if a participant is an agent.\n\nDelegates to `Timeline.AgentEntity.AgentManagement.agent?/1`.\n"
  defdelegate agent?(participant), to: AgentManagement

  @doc "Creates a new entity.\n\nDelegates to `Timeline.AgentEntity.EntityManagement.create_entity/4`.\n"
  defdelegate create_entity(id, name, properties \\ %{}, opts \\ []), to: EntityManagement

  @doc "Checks if a participant is an entity.\n\nDelegates to `Timeline.AgentEntity.EntityManagement.entity?/1`.\n"
  defdelegate entity?(participant), to: EntityManagement

  @doc "Checks if an agent has a specific capability.\n\nDelegates to `Timeline.AgentEntity.CapabilityManagement.has_capability?/2`.\n"
  defdelegate has_capability?(participant, capability), to: CapabilityManagement

  @doc "Adds a capability to an agent.\n\nDelegates to `Timeline.AgentEntity.CapabilityManagement.add_capability/2`.\n"
  defdelegate add_capability(agent, capability), to: CapabilityManagement

  @doc "Removes action capabilities from a participant.\n\nDelegates to `Timeline.AgentEntity.CapabilityManagement.remove_capabilities/2`.\n"
  defdelegate remove_capabilities(participant, capabilities_to_remove), to: CapabilityManagement

  @doc "Adds action capabilities to a participant.\n\nDelegates to `Timeline.AgentEntity.CapabilityManagement.add_capabilities/2`.\n"
  defdelegate add_capabilities(participant, new_capabilities), to: CapabilityManagement

  @doc "Checks if a participant can perform an action.\n\nDelegates to `Timeline.AgentEntity.CapabilityManagement.can_perform_action?/2`.\n"
  defdelegate can_perform_action?(participant, action), to: CapabilityManagement

  @doc "Dynamically determines if a participant is currently acting as an agent.\n\nDelegates to `Timeline.AgentEntity.CapabilityManagement.is_currently_agent?/1`.\n"
  defdelegate is_currently_agent?(participant), to: CapabilityManagement

  @doc "Transitions a participant to agent state.\n\nDelegates to `Timeline.AgentEntity.StateTransitions.transition_to_agent/2`.\n"
  defdelegate transition_to_agent(participant, action_capabilities), to: StateTransitions

  @doc "Transitions a participant to entity state.\n\nDelegates to `Timeline.AgentEntity.StateTransitions.transition_to_entity/1`.\n"
  defdelegate transition_to_entity(participant), to: StateTransitions

  @doc "Updates properties of a participant.\n\nDelegates to `Timeline.AgentEntity.PropertyManagement.update_properties/2`.\n"
  defdelegate update_properties(participant, new_properties), to: PropertyManagement

  @doc "Gets a property value from a participant.\n\nDelegates to `Timeline.AgentEntity.PropertyManagement.get_property/2`.\n"
  defdelegate get_property(participant, property_key), to: PropertyManagement

  @doc "Sets a property value for a participant.\n\nDelegates to `Timeline.AgentEntity.PropertyManagement.set_property/3`.\n"
  defdelegate set_property(participant, property_key, value), to: PropertyManagement

  @doc "Checks if an entity is owned by a specific agent.\n\nDelegates to `Timeline.AgentEntity.OwnershipManagement.owned_by?/2`.\n"
  defdelegate owned_by?(entity, agent_id), to: OwnershipManagement

  @doc "Checks if an entity has an owner.\n\nDelegates to `Timeline.AgentEntity.OwnershipManagement.has_owner?/1`.\n"
  defdelegate has_owner?(entity), to: OwnershipManagement

  @doc "Transfers ownership of an entity to a new agent.\n\nDelegates to `Timeline.AgentEntity.OwnershipManagement.transfer_ownership/2`.\n"
  defdelegate transfer_ownership(entity, new_owner_id), to: OwnershipManagement

  @doc "Removes ownership from an entity.\n\nDelegates to `Timeline.AgentEntity.OwnershipManagement.remove_ownership/1`.\n"
  defdelegate remove_ownership(entity), to: OwnershipManagement

  @doc "Validates that a participant is properly formed.\n\nDelegates to `Timeline.AgentEntity.Validation.valid?/1`.\n"
  defdelegate valid?(participant), to: Validation
end
