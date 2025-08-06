# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.AgentEntity.CapabilityManagement do
  @moduledoc "Capability management operations for Timeline.AgentEntity.\n\nHandles capability checking, addition, removal, and action-based\nclassification for agents and entities.\n"
  @type participant :: Timeline.AgentEntity.participant()
  @type agent :: Timeline.AgentEntity.agent()
  @doc "Checks if an agent has a specific capability.\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.create_agent(\n    ...>   \"aria\", \n    ...>   \"Aria VTuber\",\n    ...>   %{},\n    ...>   capabilities: [:decision_making, :communication]\n    ...> )\n    iex> Timeline.AgentEntity.CapabilityManagement.has_capability?(agent, :decision_making)\n    true\n    iex> Timeline.AgentEntity.CapabilityManagement.has_capability?(agent, :flight)\n    false\n\n"
  @spec has_capability?(participant(), atom()) :: boolean()
  def has_capability?(%{capabilities: capabilities}, capability) when is_list(capabilities) do
    capability in capabilities
  end

  def has_capability?(%{properties: %{capabilities: capabilities}}, capability)
      when is_list(capabilities) do
    capability in capabilities
  end

  def has_capability?(%{properties: properties}, capability) when is_list(properties) do
    case Keyword.get(properties, :capabilities) do
      capabilities when is_list(capabilities) -> capability in capabilities
      _ -> false
    end
  end

  def has_capability?(_, _) do
    false
  end

  @doc "Adds a capability to an agent.\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.create_agent(\"aria\", \"Aria VTuber\")\n    iex> updated_agent = Timeline.AgentEntity.CapabilityManagement.add_capability(agent, :new_skill)\n    iex> Timeline.AgentEntity.CapabilityManagement.has_capability?(updated_agent, :new_skill)\n    true\n\n"
  @spec add_capability(agent(), atom()) :: agent()
  def add_capability(%{type: :agent, capabilities: capabilities} = agent, capability) do
    if capability in capabilities do
      agent
    else
      %{agent | capabilities: [capability | capabilities]}
    end
  end

  @doc "Removes action capabilities from a participant, potentially transitioning it to entity status.\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.create_agent(\n    ...>   \"aria\", \n    ...>   \"Aria VTuber\",\n    ...>   %{},\n    ...>   capabilities: [:decision_making, :communication]\n    ...> )\n    iex> updated_agent = Timeline.AgentEntity.CapabilityManagement.remove_capabilities(agent, [:decision_making])\n    iex> Timeline.AgentEntity.CapabilityManagement.has_capability?(updated_agent, :decision_making)\n    false\n\n"
  @spec remove_capabilities(participant(), [atom()]) :: participant()
  def remove_capabilities(participant, capabilities_to_remove)
      when is_list(capabilities_to_remove) do
    current_capabilities = Map.get(participant, :capabilities, [])
    updated_capabilities = current_capabilities -- capabilities_to_remove
    Map.put(participant, :capabilities, updated_capabilities)
  end

  @doc "Adds action capabilities to a participant, potentially transitioning it to agent status.\n\n## Examples\n\n    iex> entity = Timeline.AgentEntity.create_entity(\"car\", \"Tesla\")\n    iex> Timeline.AgentEntity.CapabilityManagement.is_currently_agent?(entity)\n    false\n    \n    iex> agent = Timeline.AgentEntity.CapabilityManagement.add_capabilities(entity, [:autonomous_driving])\n    iex> Timeline.AgentEntity.CapabilityManagement.is_currently_agent?(agent)\n    true\n\n"
  @spec add_capabilities(participant(), [atom()]) :: participant()
  def add_capabilities(participant, new_capabilities) when is_list(new_capabilities) do
    current_capabilities = Map.get(participant, :capabilities, [])
    updated_capabilities = Enum.uniq(current_capabilities ++ new_capabilities)
    Map.put(participant, :capabilities, updated_capabilities)
  end

  @doc "Checks if a participant can perform an action.\n\nThis is the core capability-based classification: if you can perform actions,\nyou're an agent; otherwise, you're an entity.\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.create_agent(\n    ...>   \"aria\", \n    ...>   \"Aria VTuber\",\n    ...>   %{},\n    ...>   capabilities: [:decision_making]\n    ...> )\n    iex> Timeline.AgentEntity.CapabilityManagement.can_perform_action?(agent, :make_decision)\n    true\n    iex> entity = Timeline.AgentEntity.create_entity(\"room\", \"Conference Room\")\n    iex> Timeline.AgentEntity.CapabilityManagement.can_perform_action?(entity, :make_decision)\n    false\n\n"
  @spec can_perform_action?(participant(), atom()) :: boolean()
  def can_perform_action?(participant, action) do
    case participant do
      %{capabilities: capabilities} when is_list(capabilities) ->
        required_capability = action_to_capability(action)
        required_capability in capabilities

      %{type: :agent, capabilities: capabilities} when is_list(capabilities) ->
        required_capability = action_to_capability(action)
        required_capability in capabilities

      _ ->
        false
    end
  end

  @doc "Dynamically determines if a participant is currently acting as an agent.\n\nBased on capability-based classification: agents have action capabilities,\nentities do not. This allows for dynamic state transitions.\n\n## Examples\n\n    iex> car = Timeline.AgentEntity.create_entity(\n    ...>   \"car1\", \n    ...>   \"Tesla Model 3\",\n    ...>   %{autonomous_mode: false}\n    ...> )\n    iex> Timeline.AgentEntity.CapabilityManagement.is_currently_agent?(car)\n    false\n    \n    iex> autonomous_car = Timeline.AgentEntity.CapabilityManagement.add_capabilities(car, [:autonomous_driving, :decision_making])\n    iex> Timeline.AgentEntity.CapabilityManagement.is_currently_agent?(autonomous_car)\n    true\n\n"
  @spec is_currently_agent?(participant()) :: boolean()
  def is_currently_agent?(participant) do
    case participant do
      %{capabilities: capabilities} when is_list(capabilities) and capabilities != [] ->
        Enum.any?(capabilities, &is_action_capability?/1)

      _ ->
        false
    end
  end

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
