# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerator.Generator do
  @moduledoc """
  Main character generator module that orchestrates the generation process.
  
  This module provides the public API for generating characters, applying presets,
  validating constraints, and producing text prompts for AI character generation.
  
  Now integrated with AriaEngine's hierarchical task planning system.
  """

  alias AriaEngine.CharacterGenerator.{Config, Utils, Domain, Plans}

  @type character_attributes :: %{String.t() => any()}
  @type generation_result :: %{
    character_id: String.t(),
    attributes: character_attributes(),
    prompt: String.t(),
    seed: integer() | nil,
    violations: [String.t()]
  }

  @doc """
  Generates a complete character with random attributes using the planning system.
  
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
    case generate_character_with_planner(opts) do
      {:error, _reason} ->
        # Fallback to simple generation if planning fails
        generate_character_simple(opts)
      result ->
        result
    end
  end

  # New planning-based generation
  defp generate_character_with_planner(opts) do
    seed = Keyword.get(opts, :seed)
    preset = Keyword.get(opts, :preset)
    validate = Keyword.get(opts, :validate, true)
    
    character_id = UUID.uuid4(:default)
    
    # Create domain and initial state
    domain = Domain.build_character_generation_domain()
    state = AriaEngine.create_state()
    
    # Set seed if provided
    state = if seed do
      AriaEngine.set_fact(state, "random:seed", character_id, seed)
    else
      state
    end
    
    # Choose appropriate plan based on options
    plan_opts = %{
      char_id: character_id,
      preset: preset,
      validate: validate
    }
    
    {_char_id, todos} = Plans.plan_from_options(plan_opts)
    
    # Execute the plan
    case AriaEngine.plan(domain, state, todos, verbose: 0) do
      {:ok, plan} ->
        case AriaEngine.execute_plan(domain, state, plan) do
          {:ok, final_state} ->
            extract_generation_result(final_state, character_id, seed)
          {:error, reason} ->
            {:error, "Plan execution failed: #{inspect(reason)}"}
          {:fail, reason} ->
            {:error, "Plan execution failed: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Planning failed: #{inspect(reason)}"}
    end
  end

  # Simple fallback generation when planning fails
  defp generate_character_simple(opts) do
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

  # Extract results from planning system state
  defp extract_generation_result(state, character_id, seed) do
    # Extract attributes from state
    attributes = extract_character_attributes(state, character_id)
    
    # Extract prompt
    prompt = case AriaEngine.get_fact(state, "generated:prompt", character_id) do
      nil -> Utils.construct_character_prompt(attributes)
      prompt_text -> prompt_text
    end
    
    # Extract validation status
    violations = case AriaEngine.get_fact(state, "validation:violations", character_id) do
      violation_list when is_list(violation_list) -> violation_list
      _ -> []
    end
    
    %{
      character_id: character_id,
      attributes: attributes,
      prompt: prompt,
      seed: seed,
      violations: violations
    }
  end

  # Extract character attributes from planning state
  defp extract_character_attributes(state, character_id) do
    # Get all facts that match the pattern "character:*" -> character_id -> value
    Config.character_sliders()
    |> Map.keys()
    |> Enum.reduce(%{}, fn attr_name, acc ->
      case AriaEngine.get_fact(state, "character:#{attr_name}", character_id) do
        nil -> acc
        value -> Map.put(acc, attr_name, value)
      end
    end)
  end

  @doc """
  Generates a batch of characters using the planning system.
  
  ## Parameters
  - `count`: Number of characters to generate
  - `opts`: Keyword list of options (same as generate_character/1)
  
  ## Returns
  A list of generation result maps.
  """
  def generate_character_batch(count, opts \\ []) do
    case generate_batch_with_planner(count, opts) do
      {:error, _reason} ->
        # Fallback to simple batch generation
        generate_batch_simple(count, opts)
      result ->
        result
    end
  end

  # Planning-based batch generation
  defp generate_batch_with_planner(count, opts) do
    # For batch generation, we can use a specialized batch plan
    domain = Domain.build_character_generation_domain()
    state = AriaEngine.create_state()
    
    # Create character configurations from count and options
    character_configs = Enum.map(1..count, fn _i ->
      %{
        char_id: UUID.uuid4(),
        preset: Keyword.get(opts, :preset),
        customizations: Keyword.get(opts, :customizations, %{})
      }
    end)
    
    # Create batch plan
    todos = Plans.batch_generation_plan(character_configs)
    
    case AriaEngine.plan(domain, state, todos, verbose: 0) do
      {:ok, plan} ->
        case AriaEngine.execute_plan(domain, state, plan) do
          {:ok, final_state} ->
            extract_batch_results(final_state, count, opts)
          {:error, reason} ->
            {:error, "Batch plan execution failed: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Batch planning failed: #{inspect(reason)}"}
    end
  end

  # Simple batch generation fallback
  defp generate_batch_simple(count, opts) do
    Enum.map(1..count, fn _i ->
      # Use different seeds for each character if base seed provided
      batch_opts = case Keyword.get(opts, :seed) do
        nil -> opts
        base_seed -> Keyword.put(opts, :seed, base_seed + :rand.uniform(100_000))
      end
      
      generate_character_simple(batch_opts)
    end)
  end

  # Extract batch results from planning state
  defp extract_batch_results(state, count, opts) do
    # Extract character IDs from the planning state
    # For now, we'll need to implement proper batch extraction
    # This is a placeholder that generates characters individually
    Enum.map(1..count, fn i ->
      character_id = "batch_char_#{i}_#{UUID.uuid4()}"
      extract_generation_result(state, character_id, Keyword.get(opts, :seed))
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
  Generates a prompt-only result using the planning system.
  
  This is useful for quickly generating AI prompts without needing
  the full character generation overhead.
  
  ## Parameters
  - `opts`: Same options as generate_character/1
  
  ## Returns
  A map with `:prompt`, `:attributes`, and `:seed` keys.
  """
  def generate_prompt_only(opts \\ []) do
    case generate_prompt_with_planner(opts) do
      {:error, _reason} ->
        # Fallback to simple prompt generation
        generate_prompt_simple(opts)
      result ->
        result
    end
  end

  # Planning-based prompt generation
  defp generate_prompt_with_planner(opts) do
    seed = Keyword.get(opts, :seed)
    preset = Keyword.get(opts, :preset)
    
    character_id = UUID.uuid4(:default)
    domain = Domain.build_character_generation_domain()
    state = AriaEngine.create_state()
    
    # Set seed if provided
    state = if seed do
      AriaEngine.set_fact(state, "generation:seed", character_id, seed)
    else
      state
    end
    
    # Create a simple plan for prompt generation only
    todos = [
      {"randomize_character_attributes", [character_id]},
      {"apply_preset", [character_id, preset]},
      {"resolve_conflicts", [character_id]},
      {"generate_prompt", [character_id]}
    ]
    
    case AriaEngine.plan(domain, state, todos, verbose: 0) do
      {:ok, plan} ->
        case AriaEngine.execute_plan(domain, state, plan) do
          {:ok, final_state} ->
            attributes = extract_character_attributes(final_state, character_id)
            prompt = case AriaEngine.get_fact(final_state, "generated:prompt", character_id) do
              nil -> Utils.construct_character_prompt(attributes)
              prompt_text -> prompt_text
            end
            
            %{
              prompt: prompt,
              attributes: attributes,
              seed: seed
            }
          {:error, reason} ->
            {:error, "Prompt generation execution failed: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Prompt generation planning failed: #{inspect(reason)}"}
    end
  end

  # Simple prompt generation fallback
  defp generate_prompt_simple(opts) do
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
  Generates a character using a specific planning workflow.
  
  ## Parameters
  - `plan_name`: Name of the plan to use (atom or string)
  - `opts`: Options for character generation
  
  ## Available Plans
  - `:basic` - Basic character generation
  - `:comprehensive` - Full validation and constraint resolution
  - `:demo` - Simplified demo generation
  - `:validation_only` - Just validation workflow
  - `:preset_application` - Apply preset workflow
  
  ## Returns
  Same format as generate_character/1
  """
  def generate_with_plan(plan_name, opts \\ []) do
    character_id = UUID.uuid4(:default)
    domain = Domain.build_character_generation_domain()
    state = AriaEngine.create_state()
    
    # Set seed if provided
    seed = Keyword.get(opts, :seed)
    state = if seed do
      AriaEngine.set_fact(state, "generation:seed", character_id, seed)
    else
      state
    end
    
    # Get the appropriate plan
    todos = case plan_name do
      :basic -> Plans.basic_character_generation_plan(character_id, %{})
      :comprehensive -> Plans.comprehensive_character_generation_plan(character_id, %{}, opts)
      :demo -> Plans.demo_character_generation_plan(character_id)
      :validation_only -> Plans.validation_only_plan(character_id)
      :preset_application -> 
        preset = Keyword.get(opts, :preset)
        Plans.preset_application_plan(character_id, preset, %{})
      _ -> Plans.basic_character_generation_plan(character_id, %{})
    end
    
    case AriaEngine.plan(domain, state, todos, verbose: 0) do
      {:ok, plan} ->
        case AriaEngine.execute_plan(domain, state, plan) do
          {:ok, final_state} ->
            extract_generation_result(final_state, character_id, seed)
          error ->
            {:error, "Plan execution failed: #{inspect(error)}"}
        end
      error ->
        {:error, "Planning failed: #{inspect(error)}"}
    end
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
