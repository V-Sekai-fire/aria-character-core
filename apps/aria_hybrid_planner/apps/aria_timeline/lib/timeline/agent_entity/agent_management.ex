# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.AgentEntity.AgentManagement do
  @moduledoc "Agent creation and management operations for Timeline.AgentEntity.\n\nHandles the creation, validation, and basic operations for agents in the\ntimeline system.\n"
  @type agent :: Timeline.AgentEntity.agent()
  @type participant :: Timeline.AgentEntity.participant()
  @doc "Creates a new agent.\n\n## Parameters\n\n- `id`: Unique identifier for the agent\n- `name`: Human-readable name\n- `properties`: Agent-specific properties (e.g., personality, skills)\n- `opts`: Optional parameters including:\n  - `:capabilities` - List of agent capabilities\n  - `:metadata` - Additional metadata\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.AgentManagement.create_agent(\n    ...>   \"aria\",\n    ...>   \"Aria VTuber\",\n    ...>   %{personality: \"helpful\", skill_level: \"expert\"},\n    ...>   capabilities: [:decision_making, :communication, :problem_solving]\n    ...> )\n    iex> agent.type\n    :agent\n    iex> agent.name\n    \"Aria VTuber\"\n\n"
  @spec create_agent(String.t(), String.t(), map(), keyword()) :: agent()
  def create_agent(id, name, properties \\ %{}, opts \\ [])

  def create_agent(id, name, opts, []) when is_list(opts) do
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

  @doc "Checks if a participant is an agent.\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.AgentManagement.create_agent(\"aria\", \"Aria VTuber\")\n    iex> Timeline.AgentEntity.AgentManagement.agent?(agent)\n    true\n\n"
  @spec agent?(participant()) :: boolean()
  def agent?(%{type: :agent}) do
    true
  end

  def agent?(_) do
    false
  end

  @doc "Validates that an agent is properly formed.\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.AgentManagement.create_agent(\"aria\", \"Aria VTuber\")\n    iex> Timeline.AgentEntity.AgentManagement.valid_agent?(agent)\n    true\n\n"
  @spec valid_agent?(participant()) :: boolean()
  def valid_agent?(%{type: :agent, id: id, name: name, capabilities: capabilities})
      when is_binary(id) and is_binary(name) and is_list(capabilities) do
    String.length(id) > 0 and String.length(name) > 0
  end

  def valid_agent?(_) do
    false
  end

  @doc "Gets the default agent capabilities.\n"
  @spec default_agent_capabilities() :: [atom()]
  def default_agent_capabilities do
    [:decision_making, :action_execution, :communication, :learning, :goal_setting]
  end
end
