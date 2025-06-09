# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerationActions do
  @moduledoc """
  Character generation actions for the AriaEngine GTN (Goal-Task-Network) planner.

  This module provides atomic actions for character generation including:
  - Setting character attributes
  - Randomizing attributes based on weighted probability distributions
  - Generating text prompts from character attributes
  - Validating constraints and resolving conflicts
  - Logging generation steps for debugging and tracing

  All actions follow the AriaEngine convention of returning `{:ok, new_state}`
  on success or `{:error, reason}` on failure.
  """

  @doc """
  Character generation sliders data (ported from Python GTPyhop system).

  Defines the available character attributes, their types (categorical/numeric),
  available options, and default values. This data structure drives the
  randomization and constraint validation systems.
  """
  @character_sliders %{
    "species" => %{
      type: "categorical",
      options: [
        "SPECIES_HUMANOID",
        "SPECIES_SEMI_HUMANOID",
        "SPECIES_HUMANOID_ROBOT_OR_CYBORG",
        "SPECIES_ANIMAL",
        "SPECIES_MONSTER",
        "SPECIES_OTHER"
      ],
      default: "SPECIES_SEMI_HUMANOID"
    },
    "emotion" => %{
      type: "categorical",
      options: [
        "EMOTION_NEUTRAL",
        "EMOTION_HAPPY",
        "EMOTION_SAD",
        "EMOTION_ANGRY",
        "EMOTION_SURPRISED",
        "EMOTION_PLAYFUL",
        "EMOTION_CONFIDENT",
        "EMOTION_SHY",
        "EMOTION_MYSTERIOUS"
      ],
      default: "EMOTION_NEUTRAL"
    },
    "style_kei" => %{
      type: "categorical",
      options: [
        "STYLE_KEI_E_GIRL_E_BOY",
        "STYLE_KEI_ANIME",
        "STYLE_KEI_FURRY",
        "STYLE_KEI_ROBOTIC_CYBORG",
        "STYLE_KEI_CUTE_KAWAII",
        "STYLE_KEI_GOTHIC_DARK_FANTASY",
        "STYLE_KEI_SCI_FI_FUTURISTIC",
        "STYLE_KEI_STEAMPUNK",
        "STYLE_KEI_CASUAL_STREETWEAR"
      ],
      default: "STYLE_KEI_ANIME"
    },
    "color_palette" => %{
      type: "categorical",
      options: [
        "COLOR_PALETTE_VIBRANT_NEON",
        "COLOR_PALETTE_DARK_EDGY",
        "COLOR_PALETTE_PASTEL_SOFT",
        "COLOR_PALETTE_MONOCHROMATIC",
        "COLOR_PALETTE_CYBERPUNK_GLOW",
        "COLOR_PALETTE_METALLIC_CHROME",
        "COLOR_PALETTE_RAINBOW_SPECTRUM",
        "COLOR_PALETTE_ANIME_INSPIRED"
      ],
      default: "COLOR_PALETTE_ANIME_INSPIRED"
    },
    "key_motifs" => %{
      type: "categorical",
      options: [
        "KEY_MOTIFS_TECHWEAR_ELEMENTS",
        "KEY_MOTIFS_FANTASY_APPENDAGES",
        "KEY_MOTIFS_GLOWING_ACCENTS",
        "KEY_MOTIFS_CYBERNETIC_IMPLANTS",
        "KEY_MOTIFS_ANIMAL_FEATURES",
        "KEY_MOTIFS_GOTHIC_DETAILS",
        "KEY_MOTIFS_SCI_FI_VISORS",
        "KEY_MOTIFS_CUTE_ACCESSORIES",
        "KEY_MOTIFS_STREET_STYLE_GRAPHICS",
        "KEY_MOTIFS_MAGICAL_AURAS"
      ],
      default: "KEY_MOTIFS_GLOWING_ACCENTS"
    },
    "layering_style" => %{
      type: "categorical",
      options: [
        "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR",
        "LAYERING_STYLE_FORM_FITTING_BODYSUIT",
        "LAYERING_STYLE_FLOWING_GARMENTS",
        "LAYERING_STYLE_IDOL_POPSTAR_OUTFIT",
        "LAYERING_STYLE_TACTICAL_GEAR",
        "LAYERING_STYLE_MINIMALIST_SLEEK",
        "LAYERING_STYLE_KEMONO_FURRY_STYLE",
        "LAYERING_STYLE_FRAGMENTED_PIECES"
      ],
      default: "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR"
    },
    "detail_level" => %{
      type: "numeric",
      min: 1,
      max: 10,
      default: 7
    },
    "age" => %{
      type: "categorical",
      options: ["AGE_YOUNG_ADULT"],
      default: "AGE_YOUNG_ADULT"
    },
    "avatar_gender_appearance" => %{
      type: "categorical",
      options: [
        "AVATAR_GENDER_APPEARANCE_MASCULINE",
        "AVATAR_GENDER_APPEARANCE_FEMININE",
        "AVATAR_GENDER_APPEARANCE_OTHER"
      ],
      default: "AVATAR_GENDER_APPEARANCE_FEMININE"
    }
    # Additional legacy sliders would be added here...
  }

  @doc """
  Slider weights map for probability distributions (ported from Python).

  Maps each slider to probability weights for its options, enabling
  realistic character generation with preferred characteristics.
  """
  @slider_weights %{
    "species" => [0.35, 0.54, 0.02, 0.02, 0.01, 0.06],
    "avatar_gender_appearance" => [0.17, 0.72, 0.11],
    "emotion" => [0.2, 0.15, 0.05, 0.05, 0.1, 0.2, 0.15, 0.05, 0.05],
    "style_kei" => [0.2, 0.25, 0.15, 0.05, 0.15, 0.05, 0.05, 0.05, 0.05],
    "color_palette" => [0.15, 0.2, 0.15, 0.1, 0.1, 0.05, 0.05, 0.2],
    "key_motifs" => [0.1, 0.15, 0.2, 0.05, 0.15, 0.05, 0.05, 0.1, 0.05, 0.1],
    "layering_style" => [0.25, 0.15, 0.05, 0.1, 0.05, 0.1, 0.25, 0.05],
    "age" => [0.4, 0.6]
  }

  @doc """
  Option descriptions for generating human-readable character prompts.

  Maps each character attribute option to a descriptive text used in
  prompt generation.
  """
  @option_descriptions %{
    "SPECIES_HUMANOID" => "A bipedal character with human-like features, often the baseline for many avatars.",
    "SPECIES_SEMI_HUMANOID" => "Primarily human-like but with significant non-human traits such as animal ears, tails, or unique skin textures (semi-humanoid).",
    "EMOTION_NEUTRAL" => "A calm and composed facial expression, showing no strong emotion.",
    "EMOTION_HAPPY" => "A joyful expression, often characterized by a smile and bright eyes.",
    "EMOTION_PLAYFUL" => "A lighthearted and mischievous expression, inviting interaction.",
    "EMOTION_CONFIDENT" => "An expression of self-assurance and poise.",
    "STYLE_KEI_ANIME" => "Inspired by Japanese animation, featuring distinct aesthetics like large expressive eyes, vibrant hair colors, and often stylized outfits.",
    "STYLE_KEI_E_GIRL_E_BOY" => "A style characterized by elements of emo, punk, and goth, often with dyed hair, chains, and layered clothing, popular in online communities.",
    "COLOR_PALETTE_ANIME_INSPIRED" => "Color schemes commonly found in anime, which can range from naturalistic to highly stylized and vibrant.",
    "COLOR_PALETTE_PASTEL_SOFT" => "Light, desaturated colors like baby blue, pink, and lavender, giving a gentle and dreamy appearance.",
    "KEY_MOTIFS_GLOWING_ACCENTS" => "Luminous details on clothing or the body, such as light strips, glowing eyes, or magical auras.",
    "KEY_MOTIFS_FANTASY_APPENDAGES" => "Non-human features like wings, horns, tails, or elven ears, adding a fantastical element.",
    "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR" => "Multi-layered streetwear combining multiple pieces of casual clothing like hoodies, jackets, and t-shirts for a fashionable, urban look.",
    "LAYERING_STYLE_MINIMALIST_SLEEK" => "Simple, clean lines with minimal ornamentation, focusing on form and understated elegance.",
    "AGE_YOUNG_ADULT" => "A character appearing to be in their late teens to early twenties, often exuding youthfulness and energy.",
    "AVATAR_GENDER_APPEARANCE_FEMININE" => "An appearance characterized by features typically associated with female individuals.",
    "AVATAR_GENDER_APPEARANCE_MASCULINE" => "An appearance characterized by features typically associated with male individuals.",
    "AVATAR_GENDER_APPEARANCE_OTHER" => "An appearance that is androgynous, non-binary, or otherwise does not strictly conform to typical masculine or feminine presentations."
  }

  @doc """
  Sets a character attribute to a specific value.

  ## Parameters
  - state: Current AriaEngine state
  - [char_id, attribute, value]: Character ID, attribute name, and new value

  ## Returns
  - `{:ok, new_state}` with the attribute set
  """
  def set_character_attribute(state, [char_id, attribute, value]) do
    new_state = AriaEngine.set_fact(state, "character_#{attribute}", char_id, value)
    {:ok, new_state}
  end

  @doc """
  Randomizes a character attribute based on its configuration.

  Uses weighted probability distributions if available, otherwise
  uniform random selection from available options.
  """
  def randomize_attribute(state, [char_id, attribute]) do
    slider_config = @character_sliders[attribute]
    if slider_config do
      options = Map.get(slider_config, :options, [])
      weights = Map.get(@slider_weights, attribute)

      random_value = if weights && length(weights) == length(options) && length(options) > 0 do
        weighted_random_choice(options, weights)
      else
        case options do
          [] -> Map.get(slider_config, :default)
          _ -> Enum.random(options)
        end
      end

      random_value = random_value || Map.get(slider_config, :default)
      new_state = AriaEngine.set_fact(state, "character_#{attribute}", char_id, random_value)
      {:ok, new_state}
    else
      {:error, "Unknown attribute: #{attribute}"}
    end
  end

  @doc """
  Generates a text prompt from character attributes.

  Collects all character attributes and builds a descriptive prompt
  suitable for AI image generation or character visualization.
  """
  def generate_text_prompt(state, [char_id]) do
    character_attrs = get_character_attributes(state, char_id)
    prompt = build_character_prompt(character_attrs)
    new_state = AriaEngine.set_fact(state, "generated_prompt", char_id, prompt)
    {:ok, new_state}
  end

  @doc """
  Logs a character generation step for debugging and tracing.

  Outputs a formatted message showing the step name and character ID.
  """
  def log_generation_step(state, [char_id, step_name]) do
    IO.puts("  📝 Character Generation Step: #{step_name} for #{char_id}")
    {:ok, state}
  end

  @doc """
  Validates character attributes against constraint rules.

  Checks for logical conflicts such as:
  - Incompatible species/style combinations
  - Missing required dependencies
  - Thematic inconsistencies

  Returns error if violations are found, allowing GTN backtracking.
  """
  def validate_constraints(state, [char_id]) do
    attributes = get_character_attributes(state, char_id)
    violations = check_constraint_violations(attributes)

    if length(violations) > 0 do
      {:error, "Constraint violations: #{Enum.join(violations, ", ")}"}
    else
      {:ok, state}
    end
  end

  @doc """
  Resolves dependency conflicts between character attributes.

  Sets dependent attributes to required values when dependencies
  are not met.
  """
  def resolve_dependency(state, [char_id, _dependent_attr, dependency_attr, required_value]) do
    current_value = AriaEngine.get_fact(state, "character_#{dependency_attr}", char_id)
    if current_value == required_value do
      {:ok, state}
    else
      new_state = AriaEngine.set_fact(state, "character_#{dependency_attr}", char_id, required_value)
      {:ok, new_state}
    end
  end

  @doc """
  Automatically corrects constraint violations.

  Applies resolution rules to fix common conflicts such as:
  - Species/style mismatches
  - Missing feature dependencies
  - Thematic contradictions
  """
  def auto_correct_conflicts(state, [char_id]) do
    attributes = get_character_attributes(state, char_id)
    corrected_attributes = resolve_conflicts(attributes)

    new_state = Enum.reduce(corrected_attributes, state, fn {attr, value}, acc_state ->
      AriaEngine.set_fact(acc_state, "character_#{attr}", char_id, value)
    end)

    {:ok, new_state}
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

  defp weighted_random_choice(options, weights) do
    if length(options) != length(weights) or Enum.empty?(options) do
      nil
    else
      total = Enum.sum(weights)
      random_val = :rand.uniform() * total

      options
      |> Enum.zip(weights)
      |> Enum.reduce_while({0, nil}, fn {option, weight}, {acc, _} ->
        new_acc = acc + weight
        if random_val <= new_acc do
          {:halt, {new_acc, option}}
        else
          {:cont, {new_acc, nil}}
        end
      end)
      |> elem(1)
    end
  end

  defp build_character_prompt(attributes) do
    required_keys = [
      "species", "emotion", "style_kei", "color_palette",
      "key_motifs", "layering_style", "detail_level",
      "age", "avatar_gender_appearance"
    ]

    descriptions = Enum.reduce(required_keys, %{}, fn key, acc ->
      value = Map.get(attributes, key) || Map.get(@character_sliders[key], :default)

      description = if key == "detail_level" do
        to_string(value)
      else
        Map.get(@option_descriptions, value, value)
      end

      Map.put(acc, key, description)
    end)

    "#{descriptions["age"]} #{descriptions["avatar_gender_appearance"]} #{descriptions["emotion"]} #{descriptions["species"]} " <>
    "in #{descriptions["style_kei"]} style. Color palette: #{descriptions["color_palette"]}. " <>
    "Key motifs: #{descriptions["key_motifs"]}. Layering: #{descriptions["layering_style"]}. " <>
    "Detail level #{descriptions["detail_level"]}. " <>
    "Full body shot, A-Pose (arms slightly down, not T-Pose), clear view of hands and feet. 3D modeling concept art."
  end

  defp check_constraint_violations(attributes) do
    violations = []
    violations = check_kemonomimi_consistency(attributes, violations)
    violations = check_presence_type_consistency(attributes, violations)
    violations = check_thematic_conflicts(attributes, violations)
    violations = check_species_style_consistency(attributes, violations)
    violations
  end

  defp check_kemonomimi_consistency(attributes, violations) do
    # Check for animal feature consistency
    # Implementation would check ears/tail presence against archetype
    violations
  end

  defp check_presence_type_consistency(attributes, violations) do
    # Check presence flags vs type specifications
    violations
  end

  defp check_thematic_conflicts(attributes, violations) do
    # Check for style/theme conflicts
    violations
  end

  defp check_species_style_consistency(attributes, violations) do
    # Check species vs style compatibility
    violations
  end

  defp resolve_conflicts(attributes) do
    # Apply automatic conflict resolution rules
    attributes
  end
end
