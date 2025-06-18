defmodule StateV2Mock do
  @moduledoc """
  Mock StateV2 module for testing AST translator functionality.
  
  This is a simplified mock implementation that provides the basic
  functionality needed for AST translator tests.
  """

  @type t :: %__MODULE__{
    facts: map()
  }

  defstruct facts: %{}

  @doc """
  Create a new StateV2 instance.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{facts: %{}}
  end

  @doc """
  Set a fact in the state.
  
  ## Parameters
  - `state`: StateV2 instance
  - `entity_id`: Entity identifier (string)
  - `property`: Property name (string)
  - `value`: Value to set
  
  ## Returns
  - Updated StateV2 instance
  """
  @spec set_fact(t(), String.t(), String.t(), any()) :: t()
  def set_fact(state, entity_id, property, value) do
    entity_facts = Map.get(state.facts, entity_id, %{})
    updated_entity_facts = Map.put(entity_facts, property, value)
    updated_facts = Map.put(state.facts, entity_id, updated_entity_facts)
    
    %{state | facts: updated_facts}
  end

  @doc """
  Get a fact from the state.
  
  ## Parameters
  - `state`: StateV2 instance
  - `entity_id`: Entity identifier (string)
  - `property`: Property name (string)
  
  ## Returns
  - The fact value or nil if not found
  """
  @spec get_fact(t(), String.t(), String.t()) :: any()
  def get_fact(state, entity_id, property) do
    case Map.get(state.facts, entity_id) do
      nil -> nil
      entity_facts -> Map.get(entity_facts, property)
    end
  end

  @doc """
  Check if a fact exists in the state.
  
  ## Parameters
  - `state`: StateV2 instance
  - `entity_id`: Entity identifier (string)
  - `property`: Property name (string)
  
  ## Returns
  - Boolean indicating if the fact exists
  """
  @spec has_fact?(t(), String.t(), String.t()) :: boolean()
  def has_fact?(state, entity_id, property) do
    case Map.get(state.facts, entity_id) do
      nil -> false
      entity_facts -> Map.has_key?(entity_facts, property)
    end
  end

  @doc """
  Delete a fact from the state.
  
  ## Parameters
  - `state`: StateV2 instance
  - `entity_id`: Entity identifier (string)
  - `property`: Property name (string)
  
  ## Returns
  - Updated StateV2 instance
  """
  @spec delete_fact(t(), String.t(), String.t()) :: t()
  def delete_fact(state, entity_id, property) do
    case Map.get(state.facts, entity_id) do
      nil -> state
      entity_facts ->
        updated_entity_facts = Map.delete(entity_facts, property)
        updated_facts = if map_size(updated_entity_facts) == 0 do
          Map.delete(state.facts, entity_id)
        else
          Map.put(state.facts, entity_id, updated_entity_facts)
        end
        %{state | facts: updated_facts}
    end
  end

  @doc """
  Get all facts for an entity.
  
  ## Parameters
  - `state`: StateV2 instance
  - `entity_id`: Entity identifier (string)
  
  ## Returns
  - Map of property-value pairs for the entity
  """
  @spec get_entity_facts(t(), String.t()) :: map()
  def get_entity_facts(state, entity_id) do
    Map.get(state.facts, entity_id, %{})
  end

  @doc """
  Get all entity IDs in the state.
  
  ## Parameters
  - `state`: StateV2 instance
  
  ## Returns
  - List of entity identifiers
  """
  @spec get_entity_ids(t()) :: [String.t()]
  def get_entity_ids(state) do
    Map.keys(state.facts)
  end

  @doc """
  Clear all facts from the state.
  
  ## Parameters
  - `state`: StateV2 instance
  
  ## Returns
  - Empty StateV2 instance
  """
  @spec clear(t()) :: t()
  def clear(_state) do
    new()
  end

  @doc """
  Merge two state instances.
  
  ## Parameters
  - `state1`: First StateV2 instance
  - `state2`: Second StateV2 instance (takes precedence)
  
  ## Returns
  - Merged StateV2 instance
  """
  @spec merge(t(), t()) :: t()
  def merge(state1, state2) do
    merged_facts = Map.merge(state1.facts, state2.facts, fn _key, v1, v2 ->
      Map.merge(v1, v2)
    end)
    
    %{state1 | facts: merged_facts}
  end

  @doc """
  Convert state to a readable map format.
  
  ## Parameters
  - `state`: StateV2 instance
  
  ## Returns
  - Map representation of the state
  """
  @spec to_map(t()) :: map()
  def to_map(state) do
    %{facts: state.facts}
  end
end
