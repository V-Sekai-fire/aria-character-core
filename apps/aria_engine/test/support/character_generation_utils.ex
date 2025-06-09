# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerationUtils do
  @moduledoc """
  Utility functions for character generation workflows.
  
  This module provides text-only character generation capabilities
  including weighted random choice, attribute randomization, prompt
  construction, and batch generation workflows. These utilities
  support both test scenarios and direct character generation outside
  of the GTN planner system.
  """

  @doc """
  Weighted random choice utility (ported from Python op_custom_weighted_random_choice).
  
  Selects a random option from a list based on probability weights.
  
  ## Parameters
  - options: List of choices to select from
  - weights: List of probability weights (must match length of options)
  
  ## Returns
  - Selected option or nil if invalid input
  """
  def weighted_random_choice(options, weights) do
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

  @doc """
  Randomizes character sliders (ported from Python op_complex_randomize_sliders).
  
  Generates random values for all character attributes using weighted
  probability distributions where available.
  
  ## Parameters
  - seed: Optional random seed for deterministic generation
  
  ## Returns
  - Map of attribute names to randomly selected values
  """
  def randomize_character_sliders(seed \\ nil) do
    if seed, do: :rand.seed(:exsplus, {seed, seed + 1, seed + 2})

    character_sliders = get_character_sliders()
    slider_weights = get_slider_weights()

    Enum.reduce(character_sliders, %{}, fn {slider_name, slider_info}, acc ->
      chosen_value = case Map.get(slider_info, :type, "categorical") do
        "categorical" ->
          options = Map.get(slider_info, :options, [])
          weights = Map.get(slider_weights, slider_name)

          if weights && length(weights) == length(options) && length(options) > 0 do
            weighted_random_choice(options, weights)
          else
            case options do
              [] -> Map.get(slider_info, :default)
              _ -> Enum.random(options)
            end
          end

        "numeric" ->
          min_val = Map.get(slider_info, :min, 1)
          max_val = Map.get(slider_info, :max, 10)
          range = max_val - min_val
          min_val + (:rand.uniform() * range) |> round()

        _ ->
          Map.get(slider_info, :default)
      end

      chosen_value = chosen_value || Map.get(slider_info, :default)
      Map.put(acc, slider_name, chosen_value)
    end)
  end

  @doc """
  Constructs a character prompt from attributes (ported from Python op_complex_construct_prompt).
  
  Builds a descriptive text prompt suitable for AI image generation
  from character attribute values.
  
  ## Parameters
  - attributes: Map of character attributes
  
  ## Returns
  - Formatted character description string
  """
  def construct_character_prompt(attributes) do
    required_keys = [
      "species", "emotion", "style_kei", "color_palette",
      "key_motifs", "layering_style", "detail_level",
      "age", "avatar_gender_appearance"
    ]

    character_sliders = get_character_sliders()
    option_descriptions = get_option_descriptions()

    descriptions = Enum.reduce(required_keys, %{}, fn key, acc ->
      value = Map.get(attributes, key) || Map.get(character_sliders[key], :default)

      description = if key == "detail_level" do
        to_string(value)
      else
        Map.get(option_descriptions, value, value)
      end

      Map.put(acc, key, description)
    end)

    "#{descriptions["age"]} #{descriptions["avatar_gender_appearance"]} #{descriptions["emotion"]} #{descriptions["species"]} " <>
    "in #{descriptions["style_kei"]} style. Color palette: #{descriptions["color_palette"]}. " <>
    "Key motifs: #{descriptions["key_motifs"]}. Layering: #{descriptions["layering_style"]}. " <>
    "Detail level #{descriptions["detail_level"]}. " <>
    "Full body shot, A-Pose (arms slightly down, not T-Pose), clear view of hands and feet. 3D modeling concept art."
  end

  @doc """
  Single prompt generation workflow (ported from Python m_workflow_generate_prompt_only).
  
  Generates a complete character with randomized attributes and builds
  a descriptive prompt.
  
  ## Parameters
  - seed: Optional random seed for deterministic generation
  
  ## Returns
  - Tuple of {attributes_map, prompt_string}
  """
  def workflow_generate_prompt_only(seed \\ nil) do
    attributes = randomize_character_sliders(seed)
    prompt = construct_character_prompt(attributes)
    {attributes, prompt}
  end

  @doc """
  Batch prompt generation workflow (ported from Python m_workflow_generate_prompt_batch).
  
  Generates multiple character prompts with unique seeds and metadata.
  
  ## Parameters
  - num_prompts: Number of prompts to generate
  
  ## Returns
  - List of maps containing prompt_id, seed, iteration, attributes, and prompt
  """
  def workflow_generate_prompt_batch(num_prompts) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    Enum.map(0..(num_prompts - 1), fn i ->
      seed = :rand.uniform(1_000_000)
      prompt_id = "#{timestamp}_#{i}"
      {attributes, prompt} = workflow_generate_prompt_only(seed)

      %{
        prompt_id: prompt_id,
        seed: seed,
        iteration: i,
        attributes: attributes,
        prompt: prompt
      }
    end)
  end

  @doc """
  Runs prompt-only pipeline (ported from Python m_run_prompt_only_pipeline).
  
  Orchestrates batch generation of character prompts.
  
  ## Parameters
  - num_prompts: Number of prompts to generate
  
  ## Returns
  - List of prompt generation results
  """
  def run_prompt_only_pipeline(num_prompts) do
    workflow_generate_prompt_batch(num_prompts)
  end

  # Private helper functions

  defp get_character_sliders do
    %{
      "species" => %{
        type: "categorical",
        options: [
          "SPECIES_HUMANOID",
          "SPECIES_SEMI_HUMANOID", 
          "SPECIES_ANIMAL",
          "SPECIES_ELEMENTAL",
          "SPECIES_MECHANICAL",
          "SPECIES_OTHER"
        ],
        default: "SPECIES_SEMI_HUMANOID"
      },
      "emotion" => %{
        type: "categorical",
        options: [
          "EMOTION_NEUTRAL",
          "EMOTION_HAPPY",
          "EMOTION_PLAYFUL",
          "EMOTION_CONFIDENT",
          "EMOTION_SHY",
          "EMOTION_SERIOUS",
          "EMOTION_MISCHIEVOUS",
          "EMOTION_DREAMY",
          "EMOTION_MYSTERIOUS"
        ],
        default: "EMOTION_NEUTRAL"
      },
      "style_kei" => %{
        type: "categorical",
        options: [
          "STYLE_KEI_ANIME",
          "STYLE_KEI_E_GIRL_E_BOY",
          "STYLE_KEI_ROBOTIC_CYBORG",
          "STYLE_KEI_TRADITIONAL_JAPANESE",
          "STYLE_KEI_GOTHIC_LOLITA",
          "STYLE_KEI_STEAMPUNK_VICTORIAN",
          "STYLE_KEI_CYBERPUNK_STREET",
          "STYLE_KEI_CASUAL_STREETWEAR",
          "STYLE_KEI_ELEGANT_FORMAL"
        ],
        default: "STYLE_KEI_ANIME"
      },
      "color_palette" => %{
        type: "categorical",
        options: [
          "COLOR_PALETTE_ANIME_INSPIRED",
          "COLOR_PALETTE_PASTEL_SOFT",
          "COLOR_PALETTE_VIBRANT_BOLD",
          "COLOR_PALETTE_DARK_GOTHIC",
          "COLOR_PALETTE_EARTH_NATURAL",
          "COLOR_PALETTE_NEON_CYBER",
          "COLOR_PALETTE_VINTAGE_SEPIA",
          "COLOR_PALETTE_MONOCHROME_BW"
        ],
        default: "COLOR_PALETTE_ANIME_INSPIRED"
      },
      "key_motifs" => %{
        type: "categorical",
        options: [
          "KEY_MOTIFS_GLOWING_ACCENTS",
          "KEY_MOTIFS_FANTASY_APPENDAGES",
          "KEY_MOTIFS_TECH_INTEGRATION",
          "KEY_MOTIFS_NATURE_ELEMENTS",
          "KEY_MOTIFS_GEOMETRIC_PATTERNS",
          "KEY_MOTIFS_CULTURAL_SYMBOLS",
          "KEY_MOTIFS_MAGICAL_AURAS",
          "KEY_MOTIFS_MECHANICAL_PARTS",
          "KEY_MOTIFS_FABRIC_TEXTURES",
          "KEY_MOTIFS_ARTISTIC_DETAILS"
        ],
        default: "KEY_MOTIFS_GLOWING_ACCENTS"
      },
      "layering_style" => %{
        type: "categorical",
        options: [
          "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR",
          "LAYERING_STYLE_MINIMALIST_SLEEK",
          "LAYERING_STYLE_ELABORATE_ORNATE",
          "LAYERING_STYLE_FUNCTIONAL_TACTICAL",
          "LAYERING_STYLE_FLOWING_ETHEREAL",
          "LAYERING_STYLE_STRUCTURED_FORMAL",
          "LAYERING_STYLE_DECONSTRUCTED_AVANT_GARDE",
          "LAYERING_STYLE_VINTAGE_CLASSIC"
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
        options: [
          "AGE_YOUNG_ADULT",
          "AGE_ADULT"
        ],
        default: "AGE_YOUNG_ADULT"
      },
      "avatar_gender_appearance" => %{
        type: "categorical",
        options: [
          "AVATAR_GENDER_APPEARANCE_FEMININE",
          "AVATAR_GENDER_APPEARANCE_MASCULINE", 
          "AVATAR_GENDER_APPEARANCE_OTHER"
        ],
        default: "AVATAR_GENDER_APPEARANCE_FEMININE"
      }
    }
  end

  defp get_slider_weights do
    %{
      "species" => [0.35, 0.54, 0.02, 0.02, 0.01, 0.06],
      "avatar_gender_appearance" => [0.17, 0.72, 0.11],
      "emotion" => [0.2, 0.15, 0.05, 0.05, 0.1, 0.2, 0.15, 0.05, 0.05],
      "style_kei" => [0.2, 0.25, 0.15, 0.05, 0.15, 0.05, 0.05, 0.05, 0.05],
      "color_palette" => [0.15, 0.2, 0.15, 0.1, 0.1, 0.05, 0.05, 0.2],
      "key_motifs" => [0.1, 0.15, 0.2, 0.05, 0.15, 0.05, 0.05, 0.1, 0.05, 0.1],
      "layering_style" => [0.25, 0.15, 0.05, 0.1, 0.05, 0.1, 0.25, 0.05],
      "age" => [0.4, 0.6]
    }
  end

  defp get_option_descriptions do
    %{
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
      "AGE_ADULT" => "A character appearing to be a mature individual, typically from mid-twenties onwards, conveying experience or established presence.",
      "AGE_YOUNG_ADULT" => "A character appearing to be in their late teens to early twenties, often exuding youthfulness and energy.",
      "AVATAR_GENDER_APPEARANCE_FEMININE" => "An appearance characterized by features typically associated with female individuals.",
      "AVATAR_GENDER_APPEARANCE_MASCULINE" => "An appearance characterized by features typically associated with male individuals.",
      "AVATAR_GENDER_APPEARANCE_OTHER" => "An appearance that is androgynous, non-binary, or otherwise does not strictly conform to typical masculine or feminine presentations."
    }
  end
end
