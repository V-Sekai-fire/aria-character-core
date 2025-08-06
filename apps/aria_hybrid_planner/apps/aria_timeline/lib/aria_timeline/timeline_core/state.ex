# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimeline.TimelineCore.State do
  @moduledoc """
  Mock implementation of AriaTimeline.TimelineCore.State for compilation.

  This module provides state management functionality for timelines.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: map()

  @doc """
  Set a fact in the state.
  """
  @spec set_fact(t(), String.t(), String.t(), term()) :: t()
  def set_fact(state, entity_id, predicate, value) do
    entity_facts = Map.get(state, entity_id, %{})
    updated_entity_facts = Map.put(entity_facts, predicate, value)
    Map.put(state, entity_id, updated_entity_facts)
  end

  @doc """
  Get properties for an entity.
  """
  @spec get_properties(t(), String.t()) :: map()
  def get_properties(state, entity_id) do
    Map.get(state, entity_id, %{})
  end
end
