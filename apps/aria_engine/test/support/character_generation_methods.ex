# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerationMethods do
  @moduledoc """
  Character generation methods for the AriaEngine GTN (Goal-Task-Network) planner.
  
  This module provides hierarchical task methods for character generation,
  including constraint-aware generation with automatic backtracking when
  conflicts are detected. The methods implement a multi-level planning
  approach that can handle complex character generation scenarios.
  
  Key features:
  - Constraint-aware character generation with backtracking
  - Preset-based character configuration
  - Safe attribute randomization with conflict detection
  - Hierarchical task decomposition with fallback strategies
  - Feature dependency resolution
  - Thematic conflict resolution
  """

  @doc """
  Main constraint-aware character generation method.
  
  Implements a comprehensive character generation pipeline with:
  1. Preset configuration
  2. Constraint validation and resolution
  3. Safe attribute randomization
  4. Final validation
  5. Prompt generation
  
  If any step fails due to constraints, the GTN planner will automatically
  backtrack and try alternative methods.
  """
  def generate_character_with_constraints(_state, [char_id, preset]) do
    [
      {:log_generation_step, [char_id, "Starting constraint-aware character generation"]},
      {"configure_character_presets", [char_id, preset]},
      {"validate_and_resolve_constraints", [char_id]},
      {"randomize_remaining_attributes_safely", [char_id]},
      {"final_constraint_validation", [char_id]},
      {"generate_detailed_prompt", [char_id]},
      {:log_generation_step, [char_id, "Constraint-aware character generation complete"]}
    ]
  end

  @doc """
  Fallback method for character generation if constraints fail.
  
  Uses a simpler preset and more conservative randomization to increase
  the likelihood of generating a valid character when the primary method
  encounters irreconcilable conflicts.
  """
  def generate_character_with_constraints_fallback(_state, [char_id, _preset]) do
    [
      {:log_generation_step, [char_id, "Retrying character generation with simpler preset"]},
      {"configure_simple_preset", [char_id]},
      {"validate_and_resolve_constraints", [char_id]},
      {"randomize_remaining_attributes_safely", [char_id]},
      {"generate_detailed_prompt", [char_id]},
      {:log_generation_step, [char_id, "Fallback character generation complete"]}
    ]
  end

  @doc """
  Basic character generation without constraint checking.
  
  Simpler method for cases where constraint validation is not required
  or when rapid generation is preferred over correctness.
  """
  def generate_character(_state, [char_id, preset]) do
    [
      {:log_generation_step, [char_id, "Starting character generation"]},
      {"configure_character_presets", [char_id, preset]},
      {"randomize_remaining_attributes", [char_id]},
      {"generate_detailed_prompt", [char_id]},
      {:log_generation_step, [char_id, "Character generation complete"]}
    ]
  end

  @doc """
  Configures character attributes based on preset templates.
  
  Supports multiple presets:
  - fantasy_cyber_preset: Combines fantasy and cyberpunk elements
  - cyber_cat_person: Cat-like character with tech elements
  - default: Basic humanoid configuration
  """
  def configure_character_presets(_state, [char_id, preset]) do
    case preset do
      "fantasy_cyber_preset" ->
        [
          {:set_character_attribute, [char_id, "species_base_type", "SPECIES_BASE_HUMANOID"]},
          {:set_character_attribute, [char_id, "primary_theme", "PRIMARY_THEME_PASTEL_CYBER"]},
          {:set_character_attribute, [char_id, "cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_TRUE"]},
          {:set_character_attribute, [char_id, "fantasy_magical_talismans_presence", "FANTASY_TALISMANS_TRUE"]},
          {:log_generation_step, [char_id, "Applied fantasy cyber preset"]}
        ]
      
      "cyber_cat_person" ->
        [
          {:set_character_attribute, [char_id, "species_base_type", "SPECIES_BASE_SEMI_HUMANOID"]},
          {:set_character_attribute, [char_id, "humanoid_archetype", "HUMANOID_ARCHETYPE_CAT_PERSON"]},
          {:set_character_attribute, [char_id, "kemonomimi_animal_ears_presence", "KEMONOMIMI_EARS_TRUE"]},
          {:set_character_attribute, [char_id, "kemonomimi_animal_tail_presence", "KEMONOMIMI_TAIL_TRUE"]},
          {:set_character_attribute, [char_id, "primary_theme", "PRIMARY_THEME_CYBERPREP_TECHWEAR"]},
          {:log_generation_step, [char_id, "Applied cyber cat person preset"]}
        ]
      
      _ ->
        [
          {:set_character_attribute, [char_id, "species_base_type", "SPECIES_BASE_HUMANOID"]},
          {:log_generation_step, [char_id, "Applied default preset"]}
        ]
    end
  end

  @doc """
  Validates constraints and attempts automatic resolution.
  
  Checks for constraint violations and attempts to auto-correct them.
  If violations persist after correction, the method fails, triggering
  GTN backtracking to try alternative approaches.
  """
  def validate_and_resolve_constraints(state, [char_id]) do
    attributes = get_character_attributes(state, char_id)
    violations = check_constraint_violations(attributes)

    if length(violations) > 0 do
      [
        {:log_generation_step, [char_id, "Found #{length(violations)} constraint violations - attempting resolution"]},
        {:auto_correct_conflicts, [char_id]},
        {:validate_constraints, [char_id]}
      ]
    else
      [
        {:log_generation_step, [char_id, "All constraints validated successfully"]}
      ]
    end
  end

  @doc """
  Alternative constraint resolution method with attribute reset.
  
  If auto-correction fails, this method resets problematic attributes
  to safe defaults to resolve conflicts.
  """
  def validate_and_resolve_constraints_reset(state, [char_id]) do
    [
      {:log_generation_step, [char_id, "Auto-correction failed - resetting problematic attributes"]},
      {"reset_conflicting_attributes", [char_id]},
      {:validate_constraints, [char_id]}
    ]
  end

  @doc """
  Safely randomizes remaining unset attributes with constraint checking.
  
  Randomizes attributes that haven't been set by presets, performing
  constraint checks after each randomization. If a constraint violation
  is detected, the GTN planner will backtrack and try alternatives.
  """
  def randomize_remaining_attributes_safely(state, [char_id]) do
    # Get attributes that haven't been set yet
    set_attributes = get_set_attributes(state, char_id)
    available_attributes = ["species", "emotion", "style_kei", "color_palette", 
                           "key_motifs", "layering_style", "detail_level",
                           "age", "avatar_gender_appearance"]
    
    unset_attributes = available_attributes
    |> Enum.reject(fn attr -> MapSet.member?(set_attributes, attr) end)
    |> Enum.take(8)  # Limit for performance

    # Build randomization actions with constraint checks
    randomize_actions = Enum.flat_map(unset_attributes, fn attr ->
      [
        {:randomize_attribute, [char_id, attr]},
        {"check_attribute_constraints", [char_id, attr]}
      ]
    end)

    randomize_actions ++ [
      {:log_generation_step, [char_id, "Safely randomized #{length(unset_attributes)} attributes"]}
    ]
  end

  @doc """
  Fallback safe randomization using only low-risk attributes.
  
  If constraint checking fails repeatedly, this method only randomizes
  attributes that rarely cause conflicts.
  """
  def randomize_remaining_attributes_safely_fallback(state, [char_id]) do
    safe_attributes = ["detail_level", "age", "avatar_gender_appearance", "emotion"]
    set_attributes = get_set_attributes(state, char_id)

    unset_safe_attributes = safe_attributes
    |> Enum.reject(fn attr -> MapSet.member?(set_attributes, attr) end)

    randomize_actions = Enum.map(unset_safe_attributes, fn attr ->
      {:randomize_attribute, [char_id, attr]}
    end)

    randomize_actions ++ [
      {:log_generation_step, [char_id, "Fallback: randomized #{length(unset_safe_attributes)} safe attributes"]}
    ]
  end

  @doc """
  Checks if a newly set attribute causes constraint violations.
  
  This method fails (returns empty task list) if the attribute causes
  violations, triggering GTN backtracking to try different values.
  """
  def check_attribute_constraints(state, [char_id, attribute]) do
    attributes = get_character_attributes(state, char_id)
    violations = check_constraint_violations(attributes)

    if length(violations) > 0 do
      attribute_violations = Enum.filter(violations, fn violation ->
        String.contains?(String.downcase(violation), String.downcase(attribute))
      end)

      if length(attribute_violations) > 0 do
        []  # Empty task list causes method failure and backtracking
      else
        [
          {:log_generation_step, [char_id, "Attribute #{attribute} constraints OK"]}
        ]
      end
    else
      [
        {:log_generation_step, [char_id, "Attribute #{attribute} constraints OK"]}
      ]
    end
  end

  @doc """
  Fallback constraint checking that always succeeds.
  
  Used when constraint checking needs to be bypassed to ensure
  generation completion.
  """
  def check_attribute_constraints_fallback(_state, [char_id, attribute]) do
    [
      {:log_generation_step, [char_id, "Skipping constraint check for #{attribute} (fallback mode)"]}
    ]
  end

  @doc """
  Final constraint validation that must pass.
  
  Performs a final check that must succeed for the generation to be
  considered complete. If this fails, the entire generation fails.
  """
  def final_constraint_validation(_state, [char_id]) do
    [
      {:validate_constraints, [char_id]},
      {:log_generation_step, [char_id, "Final constraint validation passed"]}
    ]
  end

  @doc """
  Configures a simple, low-conflict preset.
  
  Used as a fallback when complex presets cause irreconcilable conflicts.
  """
  def configure_simple_preset(_state, [char_id]) do
    [
      {:set_character_attribute, [char_id, "species", "SPECIES_HUMANOID"]},
      {:set_character_attribute, [char_id, "style_kei", "STYLE_KEI_ANIME"]},
      {:set_character_attribute, [char_id, "emotion", "EMOTION_NEUTRAL"]},
      {:log_generation_step, [char_id, "Applied safe simple preset"]}
    ]
  end

  @doc """
  Resets attributes that commonly cause conflicts.
  
  Sets problematic attributes to nil/safe defaults to resolve conflicts.
  """
  def reset_conflicting_attributes(_state, [char_id]) do
    conflicting_attrs = [
      "kemonomimi_animal_ears_presence",
      "kemonomimi_animal_tail_presence", 
      "cyber_visible_cybernetics_presence",
      "fantasy_magical_talismans_presence"
    ]

    reset_actions = Enum.map(conflicting_attrs, fn attr ->
      {:set_character_attribute, [char_id, attr, nil]}
    end)

    reset_actions ++ [
      {:log_generation_step, [char_id, "Reset #{length(conflicting_attrs)} conflicting attributes"]}
    ]
  end

  @doc """
  Basic attribute randomization without constraint checking.
  
  Simpler method for rapid generation when constraint validation
  is not required.
  """
  def randomize_remaining_attributes(state, [char_id]) do
    set_attributes = get_set_attributes(state, char_id)
    available_attributes = ["species", "emotion", "style_kei", "color_palette",
                           "key_motifs", "layering_style", "detail_level", 
                           "age", "avatar_gender_appearance"]

    unset_attributes = available_attributes
    |> Enum.reject(fn attr -> MapSet.member?(set_attributes, attr) end)
    |> Enum.take(5)  # Limit to 5 for demo

    randomize_actions = Enum.map(unset_attributes, fn attr ->
      {:randomize_attribute, [char_id, attr]}
    end)

    randomize_actions ++ [
      {:log_generation_step, [char_id, "Randomized #{length(unset_attributes)} attributes"]}
    ]
  end

  @doc """
  Generates detailed character prompt.
  
  Combines text prompt generation with logging.
  """
  def generate_detailed_prompt(_state, [char_id]) do
    [
      {:generate_text_prompt, [char_id]},
      {:log_generation_step, [char_id, "Generated text prompt"]}
    ]
  end

  @doc """
  Customizes character species.
  
  Sets the species attribute and logs the change.
  """
  def customize_species(_state, [char_id, species_type]) do
    [
      {:set_character_attribute, [char_id, "species_base_type", species_type]},
      {:log_generation_step, [char_id, "Set species to #{species_type}"]}
    ]
  end

  @doc """
  Customizes character archetype.
  
  Sets the humanoid archetype and logs the change.
  """
  def customize_archetype(_state, [char_id, archetype]) do
    [
      {:set_character_attribute, [char_id, "humanoid_archetype", archetype]},
      {:log_generation_step, [char_id, "Set archetype to #{archetype}"]}
    ]
  end

  @doc """
  Customizes character theme.
  
  Sets the primary theme and logs the change.
  """
  def customize_theme(_state, [char_id, theme]) do
    [
      {:set_character_attribute, [char_id, "primary_theme", theme]},
      {:log_generation_step, [char_id, "Set theme to #{theme}"]}
    ]
  end

  @doc """
  Finalizes character and generates prompt.
  
  Completes character generation by creating the final prompt.
  """
  def finalize_character_prompt(_state, [char_id]) do
    [
      {"generate_detailed_prompt", [char_id]},
      {:log_generation_step, [char_id, "Character finalized"]}
    ]
  end

  @doc """
  Resolves feature dependencies.
  
  Handles interdependencies between character features, such as ensuring
  kemonomimi archetypes when animal features are present.
  """
  def resolve_feature_dependencies(state, [char_id]) do
    # Handle kemonomimi feature dependencies
    actions = []

    # Check if we have animal ears/tail but human archetype
    ears = AriaEngine.get_fact(state, "character_kemonomimi_animal_ears_presence", char_id)
    tail = AriaEngine.get_fact(state, "character_kemonomimi_animal_tail_presence", char_id)
    archetype = AriaEngine.get_fact(state, "character_humanoid_archetype", char_id)

    actions = if (ears == "KEMONOMIMI_EARS_TRUE" or tail == "KEMONOMIMI_TAIL_TRUE") and
                 archetype == "HUMANOID_ARCHETYPE_HUMAN_FEATURED" do
      [
        {:set_character_attribute, [char_id, "humanoid_archetype", "HUMANOID_ARCHETYPE_CAT_PERSON"]},
        {:log_generation_step, [char_id, "Auto-corrected archetype for kemonomimi features"]} | actions
      ]
    else
      actions
    end

    # Handle presence flags vs specific types
    fantasy_presence = AriaEngine.get_fact(state, "character_fantasy_magical_talismans_presence", char_id)
    actions = if fantasy_presence == "FANTASY_TALISMANS_FALSE" do
      [
        {:set_character_attribute, [char_id, "fantasy_magical_talismans_type", nil]},
        {:log_generation_step, [char_id, "Cleared talisman type (no talismans present)"]} | actions
      ]
    else
      actions
    end

    Enum.reverse(actions)
  end

  @doc """
  Resolves thematic conflicts.
  
  Handles conflicts between different style themes and elements,
  such as traditional themes conflicting with cybernetic elements.
  """
  def resolve_thematic_conflicts(state, [char_id]) do
    style_kei = AriaEngine.get_fact(state, "character_style_kei", char_id)
    primary_theme = AriaEngine.get_fact(state, "character_primary_theme", char_id)
    species = AriaEngine.get_fact(state, "character_species", char_id)

    actions = []

    # Fix robotic + furry conflicts
    actions = if style_kei == "STYLE_KEI_ROBOTIC_CYBORG" and species == "SPECIES_ANIMAL" do
      [
        {:set_character_attribute, [char_id, "species", "SPECIES_HUMANOID_ROBOT_OR_CYBORG"]},
        {:log_generation_step, [char_id, "Resolved robotic style + animal species conflict"]} | actions
      ]
    else
      actions
    end

    # Fix traditional theme + cyber elements conflicts
    actions = if primary_theme == "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN" do
      cyber_presence = AriaEngine.get_fact(state, "character_cyber_visible_cybernetics_presence", char_id)
      if cyber_presence == "CYBER_CYBERNETICS_TRUE" do
        [
          {:set_character_attribute, [char_id, "cyber_visible_cybernetics_presence", "CYBER_CYBERNETICS_FALSE"]},
          {:log_generation_step, [char_id, "Disabled cybernetics for traditional theme"]} | actions
        ]
      else
        actions
      end
    else
      actions
    end

    Enum.reverse(actions)
  end

  # Private helper functions

  defp get_character_attributes(state, char_id) do
    state.data
    |> Enum.filter(fn {{category, id}, _} ->
      String.starts_with?(category, "character_") and id == char_id
    end)
    |> Enum.into(%{}, fn {{category, _id}, value} ->
      attr_name = String.replace(category, "character_", "")
      {attr_name, value}
    end)
  end

  defp get_set_attributes(state, char_id) do
    state.data
    |> Enum.filter(fn {{category, id}, _} ->
      String.starts_with?(category, "character_") and id == char_id
    end)
    |> Enum.map(fn {{category, _id}, _value} ->
      String.replace(category, "character_", "")
    end)
    |> MapSet.new()
  end

  defp check_constraint_violations(_attributes) do
    # Placeholder - would implement actual constraint checking
    []
  end
end
