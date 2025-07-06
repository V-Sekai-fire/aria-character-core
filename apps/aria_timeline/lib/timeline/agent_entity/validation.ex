# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.AgentEntity.Validation do
  @moduledoc "Validation operations for Timeline.AgentEntity.\n\nHandles validation of participants to ensure they are properly formed\nand meet the requirements for agents and entities.\n"
  alias Timeline.AgentEntity.AgentManagement
  alias Timeline.AgentEntity.EntityManagement
  @type participant :: Timeline.AgentEntity.participant()
  @doc "Validates that a participant is properly formed.\n\n## Examples\n\n    iex> agent = Timeline.AgentEntity.create_agent(\"aria\", \"Aria VTuber\")\n    iex> Timeline.AgentEntity.Validation.valid?(agent)\n    true\n\n"
  @spec valid?(participant()) :: boolean()
  def valid?(%{type: :agent} = participant) do
    AgentManagement.valid_agent?(participant)
  end

  def valid?(%{type: :entity} = participant) do
    EntityManagement.valid_entity?(participant)
  end

  def valid?(_) do
    false
  end
end
