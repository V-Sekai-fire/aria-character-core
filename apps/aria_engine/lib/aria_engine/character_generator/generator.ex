# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerator.Generator do
  @moduledoc """
  Main character generator module that orchestrates the generation process.
  
  This module provides the public API for generating characters, applying presets,
  validating constraints, and producing text prompts for AI character generation.
  """

  alias AriaEngine.CharacterGenerator.{Config, Utils}

  @type character_attributes :: %{String.t() => any()}
  @type generation_result :: %{
    character_id: String.t(),
    attributes: character_attributes(),
    prompt: String.t(),
    seed: integer() | nil,
    violations: [String.t()]
  }

  @doc """
  Generates a complete character with random attributes.
  
  ## Parameters
  - `opts`: Keyword list of options
    - `:seed` - Random seed for deterministic generation
    - `:preset` - Preset configuration to apply
    - `:validate` - Whether to validate and resolve constraints (default: true)
  
  ## Returns
  A generation result map with character data and prompt.
  
  ## Examples
      
      iex> AriaEngine.CharacterGenerator.Generator.generate_character()
      %{
        character_id: "550e8400-e29b-41d4-a716-446655440000",
        attributes: %{"species" => "SPECIES_SEMI_HUMANOID", ...},
        prompt: "Adult feminine happy semi-humanoid character...",
        seed: nil,
        violations: []
      }
  """
  def generate_character(opts \\ []) do
    seed = Keyword.get(opts, :seed)
    preset = Keyword.get(opts, :preset)
    validate = Keyword.get(opts, :validate, true)
    
    character_id = UUID.uuid4(:default)
    
    # Start with randomized attributes
    attributes = Utils.randomize_character_sliders(seed)
    
    # Apply preset if specified
    attributes = if preset do
      apply_preset(attributes, preset)
    else
      attributes
    end
    
    # Validate and resolve conflicts if requested
    {attributes, violations} = if validate do
      violations = Utils.check_constraint_violations(attributes)
      if length(violations) > 0 do
        corrected_attributes = Utils.resolve_conflicts(attributes)
        final_violations = Utils.check_constraint_violations(corrected_attributes)
        {corrected_attributes, final_violations}
      else
        {attributes, []}
      end
    else
      {attributes, []}
    end
    
    # Generate descriptive prompt
    prompt = Utils.construct_character_prompt(attributes)
    
    %{
      character_id: character_id,
      attributes: attributes,
      prompt: prompt,
      seed: seed,
      violations: violations
    }
  end

  @doc """
  Generates a batch of characters.
  
  ## Parameters
  - `count`: Number of characters to generate
  - `opts`: Keyword list of options (same as generate_character/1)
  
  ## Returns
  A list of generation result maps.
  """
  def generate_character_batch(count, opts \\ []) do
    Enum.map(1..count, fn _i ->
      # Use different seeds for each character if base seed provided
      batch_opts = case Keyword.get(opts, :seed) do
        nil -> opts
        base_seed -> Keyword.put(opts, :seed, base_seed + :rand.uniform(100_000))
      end
      
      generate_character(batch_opts)
    end)
  end

  @doc """
  Applies a preset configuration to character attributes.
  
  ## Parameters
  - `attributes`: Current character attributes map
  - `preset_name`: Name of the preset to apply
  
  ## Returns
  Updated attributes map with preset values applied.
  
  ## Available Presets
  - `"fantasy_cyber"` - Fantasy character with cyber elements
  - `"cyber_cat_person"` - Cyberpunk cat person
  - `"traditional_shrine_maiden"` - Traditional Japanese shrine maiden
  - `"casual_tech"` - Casual techwear style
  """
  def apply_preset(attributes, preset_name) do
    case preset_name do
      "fantasy_cyber" ->
        attributes
        |> Map.put("species", "SPECIES_HUMANOID")
        |> Map.put("primary_theme", "PRIMARY_THEME_PASTEL_CYBER")
        |> Map.put("cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_TRUE")
        |> Map.put("fantasy_magical_talismans_presence", "FANTASY_TALISMANS_TRUE")
        |> Map.put("style_kei", "STYLE_KEI_SCI_FI_FUTURISTIC")

      "cyber_cat_person" ->
        attributes
        |> Map.put("species", "SPECIES_SEMI_HUMANOID")
        |> Map.put("humanoid_archetype", "HUMANOID_ARCHETYPE_CAT_PERSON")
        |> Map.put("kemonomimi_animal_ears_presence", "KEMONOMIMI_EARS_TRUE")
        |> Map.put("kemonomimi_animal_tail_presence", "KEMONOMIMI_TAIL_TRUE")
        |> Map.put("primary_theme", "PRIMARY_THEME_CYBERPREP_TECHWEAR")
        |> Map.put("cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_TRUE")

      "traditional_shrine_maiden" ->
        attributes
        |> Map.put("species", "SPECIES_HUMANOID")
        |> Map.put("primary_theme", "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN")
        |> Map.put("traditional_ritual_items_presence", "TRADITIONAL_RITUAL_ITEMS_TRUE")
        |> Map.put("traditional_kanzashi_presence", "TRADITIONAL_KANZASHI_TRUE")
        |> Map.put("style_kei", "STYLE_KEI_ANIME")
        |> Map.put("color_palette_preset", "COLOR_PALETTE_PRESET_WHITE_RED_BLACK_TRADITIONAL")

      "casual_tech" ->
        attributes
        |> Map.put("species", "SPECIES_HUMANOID")
        |> Map.put("primary_theme", "PRIMARY_THEME_CASUAL_TECH_STREETWEAR")
        |> Map.put("style_kei", "STYLE_KEI_CASUAL_STREETWEAR")
        |> Map.put("layering_style", "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR")
        |> Map.put("color_palette_preset", "COLOR_PALETTE_PRESET_TAN_BLUE_ORANGE_TECHWEAR")

      _ ->
        # Unknown preset, return unchanged
        attributes
    end
  end

  @doc """
  Customizes specific character attributes.
  
  ## Parameters
  - `attributes`: Current character attributes map
  - `customizations`: Map of attribute names to desired values
  
  ## Returns
  Updated attributes map with customizations applied.
  
  ## Examples
      
      iex> Generator.customize_character(%{}, %{"species" => "SPECIES_ANIMAL", "emotion" => "EMOTION_HAPPY"})
      %{"species" => "SPECIES_ANIMAL", "emotion" => "EMOTION_HAPPY"}
  """
  def customize_character(attributes, customizations) do
    Map.merge(attributes, customizations)
  end

  @doc """
  Validates character attributes and returns any constraint violations.
  
  ## Parameters
  - `attributes`: Character attributes map to validate
  
  ## Returns
  A list of violation messages (empty if valid).
  """
  def validate_character(attributes) do
    Utils.check_constraint_violations(attributes)
  end

  @doc """
  Generates a prompt-only result without full character data.
  
  This is useful for quickly generating AI prompts without needing
  the full character generation overhead.
  
  ## Parameters
  - `opts`: Same options as generate_character/1
  
  ## Returns
  A map with `:prompt`, `:attributes`, and `:seed` keys.
  """
  def generate_prompt_only(opts \\ []) do
    seed = Keyword.get(opts, :seed)
    preset = Keyword.get(opts, :preset)
    
    attributes = Utils.randomize_character_sliders(seed)
    
    attributes = if preset do
      apply_preset(attributes, preset)
    else
      attributes
    end
    
    # Auto-resolve conflicts for prompt generation
    attributes = Utils.resolve_conflicts(attributes)
    prompt = Utils.construct_character_prompt(attributes)
    
    %{
      prompt: prompt,
      attributes: attributes,
      seed: seed
    }
  end

  @doc """
  Returns a list of all available character attributes.
  
  ## Returns
  A list of attribute name strings.
  """
  def list_attributes do
    Config.character_sliders() |> Map.keys() |> Enum.sort()
  end

  @doc """
  Returns configuration information for a specific attribute.
  
  ## Parameters
  - `attribute_name`: Name of the attribute to get info for
  
  ## Returns
  Attribute configuration map or nil if not found.
  """
  def get_attribute_info(attribute_name) do
    Config.get_slider_config(attribute_name)
  end

  @doc """
  Returns available options for a categorical attribute.
  
  ## Parameters
  - `attribute_name`: Name of the categorical attribute
  
  ## Returns
  List of available option strings, or empty list if not categorical.
  """
  def get_attribute_options(attribute_name) do
    case Config.get_slider_config(attribute_name) do
      %{type: "categorical", options: options} -> options
      _ -> []
    end
  end

  @doc """
  Returns a human-readable description for an attribute option.
  
  ## Parameters
  - `option`: Option string to get description for
  
  ## Returns
  Description string or the option itself if no description found.
  """
  def get_option_description(option) do
    Config.get_option_description(option) || option
  end

  @doc """
  Returns statistics about the character generation system.
  
  ## Returns
  A map with system statistics.
  """
  def get_system_stats do
    sliders = Config.character_sliders()
    
    categorical_count = sliders 
                       |> Enum.count(fn {_, config} -> config.type == "categorical" end)
    
    numeric_count = sliders 
                   |> Enum.count(fn {_, config} -> config.type == "numeric" end)
    
    total_options = sliders
                   |> Enum.filter(fn {_, config} -> config.type == "categorical" end)
                   |> Enum.map(fn {_, config} -> length(config.options) end)
                   |> Enum.sum()

    %{
      total_attributes: map_size(sliders),
      categorical_attributes: categorical_count,
      numeric_attributes: numeric_count,
      total_options: total_options,
      descriptions_available: map_size(Config.option_descriptions())
    }
  end
end
