# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.AgentEntity do
  @moduledoc """
  Defines the semantic distinction between agents and entities in the timeline system.

  This module implements the agent vs entity distinction as specified in ADR-046,
  providing clear semantic types and operations for different kinds of temporal
  participants.

  ## Definitions

  ### Agent
  An autonomous entity capable of:
  - Making decisions
  - Taking actions
  - Having intentions and goals
  - Responding to events
  - Initiating temporal processes

  Examples: AI characters, NPCs, players, autonomous systems

  ### Entity
  A passive object that:
  - Exists in time
  - Can be acted upon
  - Has properties that change over time
  - Does not initiate actions independently
  - Participates in temporal relationships

  Examples: items, locations, resources, states, conditions

  ## Usage

      iex> alias Timeline.AgentEntity
      iex> agent = AgentEntity.create_agent("aria", "Aria VTuber", %{personality: "helpful"})
      iex> AgentEntity.agent?(agent)
      true
      iex> entity = AgentEntity.create_entity("conference_room", "Conference Room A", %{capacity: 10})
      iex> AgentEntity.entity?(entity)
      true

  ## References

  - ADR-046: Interval Notation Usability (agent vs entity debate)
  - ADR-078: Timeline Module PC-2 STN Implementation
  """

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

  @doc """
  Creates a new agent.

  ## Parameters

  - `id`: Unique identifier for the agent
  - `name`: Human-readable name
  - `properties`: Agent-specific properties (e.g., personality, skills)
  - `opts`: Optional parameters including:
    - `:capabilities` - List of agent capabilities
    - `:metadata` - Additional metadata

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent(
      ...>   "aria",
      ...>   "Aria VTuber",
      ...>   %{personality: "helpful", skill_level: "expert"},
      ...>   capabilities: [:decision_making, :communication, :problem_solving]
      ...> )
      iex> agent.type
      :agent
      iex> agent.name
      "Aria VTuber"

  """
  @spec create_agent(String.t(), String.t(), map(), keyword()) :: agent()
  def create_agent(id, name, properties \\ %{}, opts \\ [])

  def create_agent(id, name, opts, []) when is_list(opts) do
    # Handle case where properties is omitted and opts is passed as third argument
    create_agent(id, name, %{}, opts)
  end

  def create_agent(id, name, properties, opts) do
    %{
      type: :agent,
      id: id,
      name: name,
      capabilities: Keyword.get(opts, :capabilities, default_agent_capabilities()),
      properties: properties,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Creates a new entity.

  ## Parameters

  - `id`: Unique identifier for the entity
  - `name`: Human-readable name
  - `properties`: Entity-specific properties (e.g., location, state)
  - `opts`: Optional parameters including:
    - `:owner_agent_id` - ID of the agent that owns this entity
    - `:metadata` - Additional metadata

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity(
      ...>   "conference_room",
      ...>   "Conference Room A",
      ...>   %{capacity: 10, location: "Building 1, Floor 2"},
      ...>   owner_agent_id: "facility_manager",
      ...>   metadata: %{building_id: "bldg_1"}
      ...> )
      iex> entity.type
      :entity
      iex> entity.name
      "Conference Room A"

  """
  @spec create_entity(String.t(), String.t(), map(), keyword()) :: entity()
  def create_entity(id, name, properties \\ %{}, opts \\ []) do
    %{
      type: :entity,
      id: id,
      name: name,
      owner_agent_id: Keyword.get(opts, :owner_agent_id),
      properties: properties,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Checks if a participant is an agent.

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent("aria", "Aria VTuber")
      iex> Timeline.AgentEntity.agent?(agent)
      true

  """
  @spec agent?(participant()) :: boolean()
  def agent?(%{type: :agent}), do: true
  def agent?(_), do: false

  @doc """
  Checks if a participant is an entity.

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity("room", "Conference Room")
      iex> Timeline.AgentEntity.entity?(entity)
      true

  """
  @spec entity?(participant()) :: boolean()
  def entity?(%{type: :entity}), do: true
  def entity?(_), do: false

  @doc """
  Checks if an agent has a specific capability.

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent(
      ...>   "aria", 
      ...>   "Aria VTuber",
      ...>   %{},
      ...>   capabilities: [:decision_making, :communication]
      ...> )
      iex> Timeline.AgentEntity.has_capability?(agent, :decision_making)
      true
      iex> Timeline.AgentEntity.has_capability?(agent, :flight)
      false

  """
  @spec has_capability?(participant(), atom()) :: boolean()
  def has_capability?(%{capabilities: capabilities}, capability) when is_list(capabilities) do
    capability in capabilities
  end

  def has_capability?(%{properties: %{capabilities: capabilities}}, capability)
      when is_list(capabilities) do
    capability in capabilities
  end

  def has_capability?(%{properties: properties}, capability) when is_list(properties) do
    # Handle case where properties is a keyword list with capabilities
    case Keyword.get(properties, :capabilities) do
      capabilities when is_list(capabilities) -> capability in capabilities
      _ -> false
    end
  end

  def has_capability?(_, _), do: false

  @doc """
  Adds a capability to an agent.

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent("aria", "Aria VTuber")
      iex> updated_agent = Timeline.AgentEntity.add_capability(agent, :new_skill)
      iex> Timeline.AgentEntity.has_capability?(updated_agent, :new_skill)
      true

  """
  @spec add_capability(agent(), atom()) :: agent()
  def add_capability(%{type: :agent, capabilities: capabilities} = agent, capability) do
    if capability in capabilities do
      agent
    else
      %{agent | capabilities: [capability | capabilities]}
    end
  end

  @doc """
  Removes action capabilities from a participant, potentially transitioning it to entity status.

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent(
      ...>   "aria", 
      ...>   "Aria VTuber",
      ...>   %{},
      ...>   capabilities: [:decision_making, :communication]
      ...> )
      iex> updated_agent = Timeline.AgentEntity.remove_capabilities(agent, [:decision_making])
      iex> Timeline.AgentEntity.has_capability?(updated_agent, :decision_making)
      false

  """
  @spec remove_capabilities(participant(), [atom()]) :: participant()
  def remove_capabilities(participant, capabilities_to_remove)
      when is_list(capabilities_to_remove) do
    current_capabilities = Map.get(participant, :capabilities, [])
    updated_capabilities = current_capabilities -- capabilities_to_remove

    Map.put(participant, :capabilities, updated_capabilities)
  end

  @doc """
  Transitions a participant between agent and entity states based on capabilities.

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity("car", "Tesla Model 3")
      iex> agent = Timeline.AgentEntity.transition_to_agent(entity, [:autonomous_driving, :decision_making])
      iex> Timeline.AgentEntity.is_currently_agent?(agent)
      true
      
      iex> back_to_entity = Timeline.AgentEntity.transition_to_entity(agent)
      iex> Timeline.AgentEntity.is_currently_agent?(back_to_entity)
      false

  """
  @spec transition_to_agent(participant(), [atom()]) :: participant()
  def transition_to_agent(participant, action_capabilities) when is_list(action_capabilities) do
    participant
    |> add_capabilities(action_capabilities)
    |> Map.put(:type, :agent)
  end

  @spec transition_to_entity(participant()) :: participant()
  def transition_to_entity(participant) do
    participant
    |> Map.put(:capabilities, [])
    |> Map.put(:type, :entity)
  end

  @doc """
  Updates properties of a participant (agent or entity).

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent("aria", "Aria VTuber")
      iex> updated_agent = Timeline.AgentEntity.update_properties(
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
      iex> Timeline.AgentEntity.get_property(agent, :personality)
      "helpful"
      iex> Timeline.AgentEntity.get_property(agent, :unknown)
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
      iex> updated_agent = Timeline.AgentEntity.set_property(agent, :mood, "excited")
      iex> Timeline.AgentEntity.get_property(updated_agent, :mood)
      "excited"

  """
  @spec set_property(participant(), atom(), any()) :: participant()
  def set_property(participant, property_key, value) do
    updated_properties = Map.put(participant.properties, property_key, value)
    %{participant | properties: updated_properties}
  end

  @doc """
  Checks if an entity is owned by a specific agent.

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity(
      ...>   "room",
      ...>   "Conference Room",
      ...>   %{},
      ...>   owner_agent_id: "facility_manager"
      ...> )
      iex> Timeline.AgentEntity.owned_by?(entity, "facility_manager")
      true
      iex> Timeline.AgentEntity.owned_by?(entity, "other_agent")
      false

  """
  @spec owned_by?(entity(), String.t()) :: boolean()
  def owned_by?(%{type: :entity, owner_agent_id: owner_id}, agent_id) do
    owner_id == agent_id
  end

  def owned_by?(_, _), do: false

  @doc """
  Checks if an entity has an owner.

  ## Examples

      iex> owned_entity = Timeline.AgentEntity.create_entity(
      ...>   "room",
      ...>   "Conference Room",
      ...>   %{},
      ...>   owner_agent_id: "facility_manager"
      ...> )
      iex> Timeline.AgentEntity.has_owner?(owned_entity)
      true
      iex> unowned_entity = Timeline.AgentEntity.create_entity("item", "Free Item")
      iex> Timeline.AgentEntity.has_owner?(unowned_entity)
      false

  """
  @spec has_owner?(entity()) :: boolean()
  def has_owner?(%{type: :entity, owner_agent_id: owner_id}) do
    not is_nil(owner_id)
  end

  def has_owner?(_), do: false

  @doc """
  Transfers ownership of an entity to a new agent.

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity(
      ...>   "room",
      ...>   "Conference Room",
      ...>   %{},
      ...>   owner_agent_id: "old_manager"
      ...> )
      iex> updated_entity = Timeline.AgentEntity.transfer_ownership(entity, "new_manager")
      iex> updated_entity.owner_agent_id
      "new_manager"

  """
  @spec transfer_ownership(entity(), String.t()) :: entity()
  def transfer_ownership(%{type: :entity} = entity, new_owner_id) do
    %{entity | owner_agent_id: new_owner_id}
  end

  @doc """
  Removes ownership from an entity (makes it unowned).

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity(
      ...>   "room",
      ...>   "Conference Room",
      ...>   %{},
      ...>   owner_agent_id: "manager"
      ...> )
      iex> unowned_entity = Timeline.AgentEntity.remove_ownership(entity)
      iex> unowned_entity.owner_agent_id
      nil

  """
  @spec remove_ownership(entity()) :: entity()
  def remove_ownership(%{type: :entity} = entity) do
    %{entity | owner_agent_id: nil}
  end

  @doc """
  Checks if a participant can perform an action.

  This is the core capability-based classification: if you can perform actions,
  you're an agent; otherwise, you're an entity.

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent(
      ...>   "aria", 
      ...>   "Aria VTuber",
      ...>   %{},
      ...>   capabilities: [:decision_making]
      ...> )
      iex> Timeline.AgentEntity.can_perform_action?(agent, :make_decision)
      true
      iex> entity = Timeline.AgentEntity.create_entity("room", "Conference Room")
      iex> Timeline.AgentEntity.can_perform_action?(entity, :make_decision)
      false

  """
  @spec can_perform_action?(participant(), atom()) :: boolean()
  def can_perform_action?(participant, action) do
    # Capability-based determination: if you have action capabilities, you're an agent
    case participant do
      %{capabilities: capabilities} when is_list(capabilities) ->
        required_capability = action_to_capability(action)
        required_capability in capabilities

      %{type: :agent, capabilities: capabilities} when is_list(capabilities) ->
        required_capability = action_to_capability(action)
        required_capability in capabilities

      # No action capabilities = entity behavior
      _ ->
        false
    end
  end

  @doc """
  Dynamically determines if a participant is currently acting as an agent.

  Based on capability-based classification: agents have action capabilities,
  entities do not. This allows for dynamic state transitions.

  ## Examples

      iex> car = Timeline.AgentEntity.create_entity(
      ...>   "car1", 
      ...>   "Tesla Model 3",
      ...>   %{autonomous_mode: false}
      ...> )
      iex> Timeline.AgentEntity.is_currently_agent?(car)
      false
      
      iex> autonomous_car = Timeline.AgentEntity.add_capabilities(car, [:autonomous_driving, :decision_making])
      iex> Timeline.AgentEntity.is_currently_agent?(autonomous_car)
      true

  """
  @spec is_currently_agent?(participant()) :: boolean()
  def is_currently_agent?(participant) do
    case participant do
      %{capabilities: capabilities} when is_list(capabilities) and capabilities != [] ->
        # Has action capabilities = currently acting as agent
        Enum.any?(capabilities, &is_action_capability?/1)

      _ ->
        false
    end
  end

  @doc """
  Adds action capabilities to a participant, potentially transitioning it to agent status.

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity("car", "Tesla")
      iex> Timeline.AgentEntity.is_currently_agent?(entity)
      false
      
      iex> agent = Timeline.AgentEntity.add_capabilities(entity, [:autonomous_driving])
      iex> Timeline.AgentEntity.is_currently_agent?(agent)
      true

  """
  @spec add_capabilities(participant(), [atom()]) :: participant()
  def add_capabilities(participant, new_capabilities) when is_list(new_capabilities) do
    current_capabilities = Map.get(participant, :capabilities, [])
    updated_capabilities = Enum.uniq(current_capabilities ++ new_capabilities)

    Map.put(participant, :capabilities, updated_capabilities)
  end

  @doc """
  Validates that a participant is properly formed.

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent("aria", "Aria VTuber")
      iex> Timeline.AgentEntity.valid?(agent)
      true

  """
  @spec valid?(participant()) :: boolean()
  def valid?(%{type: :agent, id: id, name: name, capabilities: capabilities})
      when is_binary(id) and is_binary(name) and is_list(capabilities) do
    String.length(id) > 0 and String.length(name) > 0
  end

  def valid?(%{type: :entity, id: id, name: name})
      when is_binary(id) and is_binary(name) do
    String.length(id) > 0 and String.length(name) > 0
  end

  def valid?(_), do: false

  # Private helper functions

  defp default_agent_capabilities do
    [
      :decision_making,
      :action_execution,
      :communication,
      :learning,
      :goal_setting
    ]
  end

  # Maps action types to required capabilities
  defp action_to_capability(action) do
    case action do
      :make_decision -> :decision_making
      :communicate -> :communication
      :learn -> :learning
      :set_goal -> :goal_setting
      :execute_action -> :action_execution
      :move -> :movement
      :interact -> :interaction
      :observe -> :observation
      :plan -> :planning
      :reason -> :reasoning
      :autonomous_driving -> :autonomous_driving
      :navigate -> :navigation
      :respond_to_environment -> :environmental_response
      _ -> :general_capability
    end
  end

  # Determines if a capability represents the ability to take actions
  defp is_action_capability?(capability) do
    capability in [
      :decision_making,
      :action_execution,
      :movement,
      :autonomous_driving,
      :autonomous_operation,
      :navigation,
      :interaction,
      :planning,
      :goal_setting,
      :environmental_response,
      :general_capability,
      :communication,
      :manual_operation,
      :data_transmission,
      :diagnostic_analysis,
      :repair_operations
    ]
  end
end
