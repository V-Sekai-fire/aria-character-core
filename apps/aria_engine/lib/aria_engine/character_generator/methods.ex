# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerator.Methods do
  @moduledoc """
  Character generation methods for the AriaEngine planner.
  
  Methods are high-level task decompositions that break complex character
  generation workflows into sequences of simpler actions and subtasks.
  """

  alias AriaEngine.State

  @doc """
  Decomposes character generation with constraints into subtasks.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset]`: Character ID and optional preset
  
  ## Returns
  List of subtasks to execute, or false if preconditions not met.
  """
  def generate_character_with_constraints(state, [char_id, preset]) when is_map(preset) do
    # If preset is provided as a map, extract the preset name
    preset_name = Map.get(preset, :preset) || Map.get(preset, "preset")
    # Ensure it returns a list or false
    if preset_name do
      generate_character_with_constraints(state, [char_id, preset_name])
    else
      # If preset_name is nil (not found in map), it's a precondition failure
      false
    end
  end

  def generate_character_with_constraints(_state, [char_id, preset_name]) when is_binary(preset_name) do
    # Basic precondition check (char_id should be a string, for example)
    # This is illustrative; more robust checks might be needed.
    if is_binary(char_id) do
      [
        {"randomize_character", [char_id]},
        {"apply_character_preset", [char_id, preset_name]},
        {"validate_character_coherence", [char_id]}
      ]
    else
      false
    end
  end

  def generate_character_with_constraints(_state, [char_id, _preset]) do
    # No preset provided, just randomize and validate
    if is_binary(char_id) do
      [
        {"randomize_character", [char_id]},
        {"validate_character_coherence", [char_id]}
      ]
    else
      false
    end
  end

  @doc """
  Decomposes character validation into constraint checking and conflict resolution.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to validate
  
  ## Returns
  List of validation subtasks.
  """
  def validate_character_coherence(state, [char_id]) do
    [
      {:validate_attributes, [char_id]},
      {:resolve_conflicts, [char_id]},
      {:validate_attributes, [char_id]}  # Re-validate after conflict resolution
    ]
  end

  @doc """
  Decomposes prompt generation into attribute gathering and text construction.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to generate prompt for
  
  ## Returns
  List of prompt generation subtasks.
  """
  def generate_character_prompt(_state, [char_id]) do
    [
      {:generate_prompt, [char_id]}
    ]
  end

  @doc """
  Decomposes preset application into attribute setting and validation.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset_name]`: Character ID and preset name
  
  ## Returns
  List of preset application subtasks.
  """
  def apply_character_preset(_state, [char_id, preset_name]) do
    [
      {:apply_preset, [char_id, preset_name]},
      {:validate_attributes, [char_id]}
    ]
  end

  @doc """
  Decomposes character randomization into weighted attribute selection.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to randomize
  
  ## Returns
  List of randomization subtasks.
  """
  def randomize_character(_state, [char_id]) do
    [
      {:randomize_character_attributes, [char_id]}
    ]
  end

  @doc """
  Achieves a specific character attribute goal.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, attribute, value]`: Character ID, attribute name, and desired value
  
  ## Returns
  List of actions to achieve the attribute goal.
  """
  def achieve_character_attribute(state, [char_id, attribute, value]) do
    # Check if attribute is already set to the desired value
    current_value = State.get_object(state, "character:#{attribute}", char_id)
    
    # Precondition: char_id and attribute should be valid
    if not (is_binary(char_id) and is_binary(attribute)) do
      false
    else
      if current_value == value do
        []  # Goal already achieved
      else
        [{:set_character_attribute, [char_id, attribute, value]}]
      end
    end
  end

  @doc """
  Achieves character validity goal through validation and conflict resolution.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to make valid
  
  ## Returns
  List of actions to achieve validity.
  """
  def achieve_character_valid(state, [char_id]) do
    # Check current validation status
    validation_status = State.get_object(state, "validation:status", char_id)
    
    if not is_binary(char_id) do
      false
    else
      if validation_status == "valid" do
        []  # Already valid
      else
        [
          {:validate_attributes, [char_id]},
          {:resolve_conflicts, [char_id]},
          {:mark_character_valid, [char_id]}
        ]
      end
    end
  end

  @doc """
  Achieves character prompt readiness goal.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to generate prompt for
  
  ## Returns
  List of actions to achieve prompt readiness.
  """
  def achieve_character_prompt_ready(state, [char_id]) do
    # Check if prompt already exists
    existing_prompt = State.get_object(state, "generated:prompt", char_id)
    
    if not is_binary(char_id) do
      false
    else
      if existing_prompt && String.length(existing_prompt) > 0 do
        []  # Prompt already ready
      else
        [{:generate_prompt, [char_id]}]
      end
    end
  end

  @doc """
  Validates all character constraints systematically.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to validate
  
  ## Returns
  List of comprehensive validation subtasks.
  """
  def validate_all_constraints(_state, [char_id]) do
    [
      {:check_constraint_violations, [char_id]},
      {:validate_attributes, [char_id]}
    ]
  end

  @doc """
  Resolves all character attribute conflicts.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id]`: Character ID to resolve conflicts for
  
  ## Returns
  List of conflict resolution subtasks.
  """
  def resolve_all_conflicts(_state, [char_id]) do
    [
      {:resolve_conflicts, [char_id]},
      {:validate_attributes, [char_id]}  # Re-validate after resolution
    ]
  end

  @doc """
  Achieves constraint satisfaction goal.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, constraint_name]`: Character ID and constraint to satisfy
  
  ## Returns
  List of actions to satisfy the constraint.
  """
  def achieve_constraint_satisfied(_state, [char_id, _constraint_name]) do
    # This is a simplified implementation - could be expanded for specific constraints
    [
      {:validate_attributes, [char_id]},
      {:resolve_conflicts, [char_id]}
    ]
  end

  @doc """
  Applies preset with full validation workflow.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset_name]`: Character ID and preset name
  
  ## Returns
  List of preset application and validation subtasks.
  """
  def apply_preset_with_validation(_state, [char_id, preset_name]) do
    [
      {:apply_preset_attributes, [char_id, preset_name]},
      {:validate_preset_compliance, [char_id, preset_name]},
      {:validate_attributes, [char_id]}
    ]
  end

  @doc """
  Customizes a preset with additional modifications.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, customizations]`: Character ID and customization map
  
  ## Returns
  List of customization subtasks.
  """
  def customize_preset(_state, [char_id, customizations]) do
    [
      {:merge_customizations, [char_id, customizations]},
      {:validate_attributes, [char_id]}
    ]
  end

  @doc """
  Achieves preset application goal.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, preset_name]`: Character ID and preset name
  
  ## Returns
  List of actions to achieve preset application.
  """
  def achieve_preset_applied(state, [char_id, preset_name]) do
    # Check if preset is already applied
    current_preset = State.get_object(state, "preset:name", char_id)
    
    if not (is_binary(char_id) and is_binary(preset_name)) do
      false
    else
      if current_preset == preset_name do
        []  # Preset already applied
      else
        [{:apply_preset_attributes, [char_id, preset_name]}]
      end
    end
  end

  @doc """
  Achieves customization application goal.
  
  ## Parameters
  - `state`: Current world state
  - `[char_id, customizations]`: Character ID and customizations
  
  ## Returns
  List of actions to achieve customization application.
  """
  def achieve_customization_applied(_state, [char_id, customizations]) do
    [{:merge_customizations, [char_id, customizations]}]
  end

  # Demo methods for simplified planning (for demo domain)

  @doc """
  Demo method for character generation - simplified workflow.
  """
  def demo_generate_character(_state, [char_id, preset]) do
    preset_name = case preset do
      %{preset: name} -> name
      name when is_binary(name) -> name
      _ -> "fantasy_cyber" # default or could be a failure point if preset is mandatory
    end
    
    if is_binary(char_id) do
      [
        {:randomize_character_attributes, [char_id]},
        {:apply_preset, [char_id, preset_name]}
      ]
    else
      false # char_id precondition failed
    end
  end

  @doc """
  Demo method for character validation - simplified workflow.
  """
  def demo_validate_character(_state, [char_id]) do
    [
      {:validate_attributes, [char_id]}
    ]
  end

  @doc """
  Demo method for prompt generation - simplified workflow.
  """
  def demo_generate_prompt(_state, [char_id]) do
    [
      {:generate_prompt, [char_id]}
    ]
  end
end
