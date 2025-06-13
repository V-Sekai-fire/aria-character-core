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

  @type action_result :: State.t() | false
  @type char_id :: String.t()
  @type attribute_name :: String.t()
  @type attribute_value :: String.t() | number()
  @type preset_name :: String.t()
  @type customizations :: %{String.t() => String.t() | number()}

  @doc """
  Sets a character attribute in the state.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, attribute, value]`: Character ID, attribute name, and value
  
  ## Returns
  Updated state with the attribute set, or false if invalid.
  """
  @spec set_character_attribute(State.t(), [char_id() | attribute_name() | attribute_value()]) :: action_result()
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
  @spec randomize_character_attributes(State.t(), [char_id()]) :: action_result()
  def randomize_character_attributes(state, [char_id]) do
    # Get seed from state if available
    seed = State.get_object(state, "random:seed", char_id)
    
    # Generate randomized attributes
    attributes = Utils.randomize_character_sliders(seed)
    
    # Set all attributes in state
    new_state = Enum.reduce(attributes, state, fn {attr, value}, acc_state ->
      State.set_object(acc_state, "character:#{attr}", char_id, value)
    end)
    
    new_state
  end

  @doc """
  Applies a preset configuration to a character.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset_name]`: Character ID and preset name
  
  ## Returns
  Updated state with preset applied.
  """
  @spec apply_preset(State.t(), [char_id() | preset_name()]) :: action_result()
  def apply_preset(state, [char_id, preset_name]) do
    # Get current attributes from state
    current_attributes = get_character_attributes_from_state(state, char_id)
    
    # Apply preset using generator logic
    updated_attributes = AriaEngine.CharacterGenerator.Generator.apply_preset(current_attributes, preset_name)
    
    # Update state with new attributes
    new_state = Enum.reduce(updated_attributes, state, fn {attr, value}, acc_state ->
      State.set_object(acc_state, "character:#{attr}", char_id, value)
    end)
    
    new_state
  end

  @doc """
  Validates character attributes and records violations.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to validate
  
  ## Returns
  Updated state with validation results.
  """
  @spec validate_attributes(State.t(), [char_id()]) :: action_result()
  def validate_attributes(state, [char_id]) do
    # Get current attributes from state
    attributes = get_character_attributes_from_state(state, char_id)
    
    # Check for violations
    violations = Utils.check_constraint_violations(attributes)
    
    # Record validation results in state
    new_state = state
    |> State.set_object("validation:violations", char_id, violations)
    |> State.set_object("validation:status", char_id, if(length(violations) == 0, do: "valid", else: "invalid"))
    
    new_state
  end

  @doc """
  Resolves character attribute conflicts automatically.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to resolve conflicts for
  
  ## Returns
  Updated state with conflicts resolved.
  """
  @spec resolve_conflicts(State.t(), [char_id()]) :: action_result()
  def resolve_conflicts(state, [char_id]) do
    # Get current attributes from state
    attributes = get_character_attributes_from_state(state, char_id)
    
    # Resolve conflicts using utility logic
    resolved_attributes = Utils.resolve_conflicts(attributes)
    
    # Update state with resolved attributes
    new_state = Enum.reduce(resolved_attributes, state, fn {attr, value}, acc_state ->
      State.set_object(acc_state, "character:#{attr}", char_id, value)
    end)
    
    new_state
  end

  @doc """
  Generates a character prompt from current attributes.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to generate prompt for
  
  ## Returns
  Updated state with generated prompt.
  """
  @spec generate_prompt(State.t(), [char_id()]) :: action_result()
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
  @spec check_constraint_violations(State.t(), [char_id()]) :: action_result()
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
  @spec mark_character_valid(State.t(), [char_id()]) :: action_result()
  def mark_character_valid(state, [char_id]) do
    new_state = state
    |> State.set_object("validation:status", char_id, "valid")
    |> State.set_object("validation:timestamp", char_id, System.system_time(:millisecond))
    
    new_state
  end

  @doc """
  Applies preset attributes to a character.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset_name]`: Character ID and preset name
  
  ## Returns
  Updated state with preset attributes applied.
  """
  @spec apply_preset_attributes(State.t(), [char_id() | preset_name()]) :: action_result()
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
  @spec merge_customizations(State.t(), [char_id() | customizations()]) :: action_result()
  def merge_customizations(state, [char_id, customizations]) when is_map(customizations) do
    # Apply each customization
    new_state = Enum.reduce(customizations, state, fn {attr, value}, acc_state ->
      State.set_object(acc_state, "character:#{attr}", char_id, value)
    end)
    
    new_state
  end

  @doc """
  Validates preset compliance for a character.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset_name]`: Character ID and expected preset
  
  ## Returns
  Updated state with preset compliance status.
  """
  @spec validate_preset_compliance(State.t(), [char_id() | preset_name()]) :: action_result()
  def validate_preset_compliance(state, [char_id, preset_name]) do
    # Get current attributes
    attributes = get_character_attributes_from_state(state, char_id)
    
    # Apply preset to empty attributes to get expected values
    expected_attributes = AriaEngine.CharacterGenerator.Generator.apply_preset(%{}, preset_name)
    
    # Check compliance (simplified check - could be more sophisticated)
    compliant = Enum.all?(expected_attributes, fn {attr, expected_value} ->
      Map.get(attributes, attr) == expected_value
    end)
    
    new_state = state
    |> State.set_object("preset:compliance", char_id, compliant)
    |> State.set_object("preset:name", char_id, preset_name)
    
    new_state
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
