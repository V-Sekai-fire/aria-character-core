# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.AgentEntity.Validation do
  @moduledoc """
  Validation operations for Timeline.AgentEntity.

  Handles validation of participants to ensure they are properly formed
  and meet the requirements for agents and entities.
  """

  alias Timeline.AgentEntity.AgentManagement
  alias Timeline.AgentEntity.EntityManagement

  @type participant :: Timeline.AgentEntity.participant()

  @doc """
  Validates that a participant is properly formed.

  ## Examples

      iex> agent = Timeline.AgentEntity.create_agent("aria", "Aria VTuber")
      iex> Timeline.AgentEntity.Validation.valid?(agent)
      true

  """
  @spec valid?(participant()) :: boolean()
  def valid?(%{type: :agent} = participant) do
    AgentManagement.valid_agent?(participant)
  end

  def valid?(%{type: :entity} = participant) do
    EntityManagement.valid_entity?(participant)
  end

  def valid?(_), do: false
end
