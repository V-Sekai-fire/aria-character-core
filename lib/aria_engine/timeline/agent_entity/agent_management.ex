# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.AgentEntity.AgentManagement do
  @moduledoc """
  Agent creation and management operations for Timeline.AgentEntity.

  Handles the creation, validation, and basic operations for agents in the
  timeline system.
  """

  @type agent :: Timeline.AgentEntity.agent()
  @type participant :: Timeline.AgentEntity.participant()

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

      iex> agent = Timeline.AgentEntity.AgentManagement.create_agent(
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
  Checks if a participant is an agent.

  ## Examples

      iex> agent = Timeline.AgentEntity.AgentManagement.create_agent("aria", "Aria VTuber")
      iex> Timeline.AgentEntity.AgentManagement.agent?(agent)
      true

  """
  @spec agent?(participant()) :: boolean()
  def agent?(%{type: :agent}), do: true
  def agent?(_), do: false

  @doc """
  Validates that an agent is properly formed.

  ## Examples

      iex> agent = Timeline.AgentEntity.AgentManagement.create_agent("aria", "Aria VTuber")
      iex> Timeline.AgentEntity.AgentManagement.valid_agent?(agent)
      true

  """
  @spec valid_agent?(participant()) :: boolean()
  def valid_agent?(%{type: :agent, id: id, name: name, capabilities: capabilities})
      when is_binary(id) and is_binary(name) and is_list(capabilities) do
    String.length(id) > 0 and String.length(name) > 0
  end

  def valid_agent?(_), do: false

  @doc """
  Gets the default agent capabilities.
  """
  @spec default_agent_capabilities() :: [atom()]
  def default_agent_capabilities do
    [
      :decision_making,
      :action_execution,
      :communication,
      :learning,
      :goal_setting
    ]
  end
end
