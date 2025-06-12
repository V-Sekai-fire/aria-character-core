# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerator.Actions do
  @moduledoc """
  Character generation actions for the AriaEngine planner.
  
  Actions are atomic operations that modify the world state. These actions
  handle the low-level character attribute manipulation, validation, and
  prompt generation operations.
  """

  alias AriaEngine.State
  alias AriaEngine.CharacterGenerator.{Config, Utils}

  @doc """
  Sets a character attribute in the state.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, attribute, value]`: Character ID, attribute name, and value
  
  ## Returns
  Updated state with the attribute set, or false if invalid.
  """
  def set_character_attribute(state, [char_id, attribute, value]) do
    # Validate the attribute exists in configuration
    if Config.get_slider_config(attribute) do
      State.set_object(state, "character:#{attribute}", char_id, value)
    else
      false
    end
  end

  @doc """
  Randomizes character attributes using weighted selection.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to randomize
  
  ## Returns
  Updated state with randomized attributes.
  """
  def randomize_character_attributes(state, [char_id]) do
    # Get seed from state if available
    seed = State.get_object(state, "random:seed", char_id)
    
    # Generate randomized attributes
    attributes = Utils.randomize_character_sliders(seed)
    
    # Set all attributes in state
    Enum.reduce(attributes, state, fn {attr, value}, acc_state ->
      State.set_object(acc_state, "character:#{attr}", char_id, value)
    end)
  end

  @doc """
  Applies a preset configuration to a character.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset_name]`: Character ID and preset name
  
  ## Returns
  Updated state with preset applied.
  """
  def apply_preset(state, [char_id, preset_name]) do
    # Get current attributes from state
    current_attributes = get_character_attributes_from_state(state, char_id)
    
    # Apply preset using generator logic
    updated_attributes = AriaEngine.CharacterGenerator.Generator.apply_preset(current_attributes, preset_name)
    
    # Update state with new attributes
    Enum.reduce(updated_attributes, state, fn {attr, value}, acc_state ->
      State.set_object(acc_state, "character:#{attr}", char_id, value)
    end)
  end

  @doc """
  Validates character attributes and records violations.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to validate
  
  ## Returns
  Updated state with validation results.
  """
  def validate_attributes(state, [char_id]) do
    # Get current attributes from state
    attributes = get_character_attributes_from_state(state, char_id)
    
    # Check for violations
    violations = Utils.check_constraint_violations(attributes)
    
    # Record validation results in state
    state
    |> State.set_object("validation:violations", char_id, violations)
    |> State.set_object("validation:status", char_id, if(length(violations) == 0, do: "valid", else: "invalid"))
  end

  @doc """
  Resolves character attribute conflicts automatically.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to resolve conflicts for
  
  ## Returns
  Updated state with conflicts resolved.
  """
  def resolve_conflicts(state, [char_id]) do
    # Get current attributes from state
    attributes = get_character_attributes_from_state(state, char_id)
    
    # Resolve conflicts using utility logic
    resolved_attributes = Utils.resolve_conflicts(attributes)
    
    # Update state with resolved attributes
    Enum.reduce(resolved_attributes, state, fn {attr, value}, acc_state ->
      State.set_object(acc_state, "character:#{attr}", char_id, value)
    end)
  end

  @doc """
  Generates a character prompt from current attributes.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to generate prompt for
  
  ## Returns
  Updated state with generated prompt.
  """
  def generate_prompt(state, [char_id]) do
    # Get current attributes from state
    attributes = get_character_attributes_from_state(state, char_id)
    
    # Generate prompt using utility logic
    prompt = Utils.construct_character_prompt(attributes)
    
    # Store prompt in state
    State.set_object(state, "generated:prompt", char_id, prompt)
  end

  @doc """
  Checks constraint violations and records them.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to check
  
  ## Returns
  Updated state with violation check results.
  """
  def check_constraint_violations(state, [char_id]) do
    # Get current attributes from state
    attributes = get_character_attributes_from_state(state, char_id)
    
    # Check violations
    violations = Utils.check_constraint_violations(attributes)
    
    # Record results
    State.set_object(state, "validation:constraint_violations", char_id, violations)
  end

  @doc """
  Marks a character as valid in the state.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to mark as valid
  
  ## Returns
  Updated state with character marked as valid.
  """
  def mark_character_valid(state, [char_id]) do
    state
    |> State.set_object("validation:status", char_id, "valid")
    |> State.set_object("validation:timestamp", char_id, System.system_time(:millisecond))
  end

  @doc """
  Applies preset attributes to a character.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset_name]`: Character ID and preset name
  
  ## Returns
  Updated state with preset attributes applied.
  """
  def apply_preset_attributes(state, [char_id, preset_name]) do
    apply_preset(state, [char_id, preset_name])
  end

  @doc """
  Merges customizations with existing character attributes.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, customizations]`: Character ID and customization map
  
  ## Returns
  Updated state with customizations merged.
  """
  def merge_customizations(state, [char_id, customizations]) when is_map(customizations) do
    # Apply each customization
    Enum.reduce(customizations, state, fn {attr, value}, acc_state ->
      State.set_object(acc_state, "character:#{attr}", char_id, value)
    end)
  end

  @doc """
  Validates preset compliance for a character.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset_name]`: Character ID and expected preset
  
  ## Returns
  Updated state with preset compliance status.
  """
  def validate_preset_compliance(state, [char_id, preset_name]) do
    # Get current attributes
    attributes = get_character_attributes_from_state(state, char_id)
    
    # Apply preset to empty attributes to get expected values
    expected_attributes = AriaEngine.CharacterGenerator.Generator.apply_preset(%{}, preset_name)
    
    # Check compliance (simplified check - could be more sophisticated)
    compliant = Enum.all?(expected_attributes, fn {attr, expected_value} ->
      Map.get(attributes, attr) == expected_value
    end)
    
    state
    |> State.set_object("preset:compliance", char_id, compliant)
    |> State.set_object("preset:name", char_id, preset_name)
  end

  # Private helper function to extract character attributes from state
  defp get_character_attributes_from_state(state, char_id) do
    # Get all character: prefixed facts for this character
    all_character_facts = Config.character_sliders()
    |> Map.keys()
    |> Enum.reduce(%{}, fn attr, acc ->
      case State.get_object(state, "character:#{attr}", char_id) do
        nil -> acc
        value -> Map.put(acc, attr, value)
      end
    end)
    
    all_character_facts
  end
end
