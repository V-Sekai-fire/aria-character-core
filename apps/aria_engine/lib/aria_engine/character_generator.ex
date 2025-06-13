# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerator do
  @moduledoc """
  Main public API for the AriaEngine Character Generator.
  
  This module provides a comprehensive character generation system for creating
  diverse avatars and characters with detailed attributes, constraint validation,
  and AI-ready text prompts.
  
  ## Features
  
  - **Extensive Attribute System**: Over 35 character attributes covering species,
    appearance, clothing, themes, and accessories
  - **Weighted Random Generation**: Probability-based selection for realistic
    character distributions
  - **Constraint Validation**: Automatic detection and resolution of conflicting
    attributes
  - **Preset Configurations**: Pre-built character templates for common archetypes
  - **Prompt Generation**: AI-ready descriptive text for character creation tools
  
  ## Quick Start
  
      # Generate a random character
      character = AriaEngine.CharacterGenerator.generate()
      
      # Generate with a preset
      character = AriaEngine.CharacterGenerator.generate(preset: "cyber_cat_person")
      
      # Generate using specific planning workflow
      character = AriaEngine.CharacterGenerator.generate_with_plan(:comprehensive)
      
      # Generate just a prompt
      prompt = AriaEngine.CharacterGenerator.generate_prompt()
      
      # Generate a batch
      characters = AriaEngine.CharacterGenerator.generate_batch(5)
  
  ## Character Attributes
  
  The system includes these major attribute categories:
  
  - **Core Identity**: Species, age, gender appearance, emotion
  - **Style & Theme**: Art style, color palette, rendering approach
  - **Physical Features**: Face style, hands, kemonomimi features
  - **Clothing System**: Headwear, outerwear, tops, bottoms, footwear
  - **Accessories**: Cyber tech, fantasy items, traditional elements
  - **Technical**: Detail level, geometric complexity, modesty level
  
  ## Presets
  
  Available character presets:
  
  - `"fantasy_cyber"` - Fantasy character with cyberpunk elements
  - `"cyber_cat_person"` - Cyberpunk anthropomorphic cat character
  - `"traditional_shrine_maiden"` - Traditional Japanese shrine maiden
  - `"casual_tech"` - Modern casual techwear style
  """

  alias AriaEngine.CharacterGenerator.Generator

  @doc """
  Generates a complete character with random attributes using the planning system.
  
  ## Options
  
  - `:seed` - Integer seed for deterministic generation
  - `:preset` - String preset name to apply
  - `:validate` - Boolean whether to validate constraints (default: true)
  - `:customizations` - Map of specific attribute overrides
  
  ## Examples
  
      # Basic random generation
      character = AriaEngine.CharacterGenerator.generate()
      
      # Deterministic generation
      character = AriaEngine.CharacterGenerator.generate(seed: 12345)
      
      # Apply a preset
      character = AriaEngine.CharacterGenerator.generate(preset: "cyber_cat_person")
      
      # Custom attributes
      character = AriaEngine.CharacterGenerator.generate(
        customizations: %{"species" => "SPECIES_ANIMAL", "emotion" => "EMOTION_HAPPY"}
      )
  
  ## Returns
  
  A map containing:
  
  - `:character_id` - Unique identifier for the character
  - `:attributes` - Map of all character attributes and values
  - `:prompt` - AI-ready descriptive text prompt
  - `:seed` - Random seed used (if any)
  - `:violations` - List of any remaining constraint violations
  """
  def generate(opts \\ []) do
    customizations = Keyword.get(opts, :customizations, %{})
    
    character = Generator.generate_character(opts)
    
    # Apply any customizations
    if map_size(customizations) > 0 do
      updated_attributes = Generator.customize_character(character.attributes, customizations)
      
      # Re-validate and regenerate prompt if customized
      violations = if Keyword.get(opts, :validate, true) do
        Generator.validate_character(updated_attributes)
      else
        []
      end
      
      prompt = AriaEngine.CharacterGenerator.Utils.construct_character_prompt(updated_attributes)
      
      %{character | attributes: updated_attributes, prompt: prompt, violations: violations}
    else
      character
    end
  end

  @doc """
  Generates multiple characters in a batch using the planning system.
  
  ## Parameters
  
  - `count` - Number of characters to generate
  - `opts` - Same options as `generate/1`
  
  ## Examples
  
      # Generate 5 random characters
      characters = AriaEngine.CharacterGenerator.generate_batch(5)
      
      # Generate batch with preset
      characters = AriaEngine.CharacterGenerator.generate_batch(3, preset: "fantasy_cyber")
  
  ## Returns
  
  A list of character maps (same format as `generate/1`).
  """
  def generate_batch(count, opts \\ []) do
    Generator.generate_character_batch(count, opts)
  end

  @doc """
  Generates only a descriptive prompt without full character data.
  
  This is more efficient when you only need the text prompt for AI generation.
  
  ## Options
  
  Same as `generate/1` but returns a simplified result.
  
  ## Examples
  
      # Quick prompt generation
      prompt = AriaEngine.CharacterGenerator.generate_prompt()
      
      # Prompt with preset
      prompt = AriaEngine.CharacterGenerator.generate_prompt(preset: "traditional_shrine_maiden")
  
  ## Returns
  
  A string containing the descriptive character prompt.
  """
  def generate_prompt(opts \\ []) do
    Generator.generate_prompt_only(opts).prompt
  end

  @doc """
  Generates multiple prompts in a batch.
  
  ## Parameters
  
  - `count` - Number of prompts to generate
  - `opts` - Same options as `generate_prompt/1`
  
  ## Returns
  
  A list of prompt strings.
  """
  def generate_prompt_batch(count, opts \\ []) do
    Enum.map(1..count, fn _i ->
      # Use different seeds for variety if base seed provided
      batch_opts = case Keyword.get(opts, :seed) do
        nil -> opts
        base_seed -> Keyword.put(opts, :seed, base_seed + :rand.uniform(100_000))
      end
      
      generate_prompt(batch_opts)
    end)
  end

  @doc """
  Applies a preset configuration to existing character attributes.
  
  ## Parameters
  
  - `attributes` - Map of current character attributes
  - `preset_name` - String name of preset to apply
  
  ## Available Presets
  
  - `"fantasy_cyber"` - Fantasy/cyberpunk hybrid
  - `"cyber_cat_person"` - Cyberpunk anthropomorphic cat
  - `"traditional_shrine_maiden"` - Japanese shrine maiden
  - `"casual_tech"` - Modern casual techwear
  
  ## Returns
  
  Updated attributes map with preset values.
  """
  def apply_preset(attributes, preset_name) do
    Generator.apply_preset(attributes, preset_name)
  end

  @doc """
  Validates character attributes for constraint violations.
  
  ## Parameters
  
  - `attributes` - Map of character attributes to validate
  
  ## Returns
  
  A list of violation description strings. Empty list means valid.
  
  ## Examples
  
      attributes = %{"species" => "SPECIES_ANIMAL", "style_kei" => "STYLE_KEI_ROBOTIC_CYBORG"}
      violations = AriaEngine.CharacterGenerator.validate(attributes)
      # Returns: ["Animal species conflicts with robotic style"]
  """
  def validate(attributes) do
    Generator.validate_character(attributes)
  end

  @doc """
  Automatically resolves constraint violations in character attributes.
  
  ## Parameters
  
  - `attributes` - Map of character attributes with potential conflicts
  
  ## Returns
  
  Corrected attributes map with conflicts resolved.
  """
  def resolve_conflicts(attributes) do
    AriaEngine.CharacterGenerator.Utils.resolve_conflicts(attributes)
  end

  @doc """
  Lists all available character attributes.
  
  ## Returns
  
  A sorted list of attribute name strings.
  """
  def list_attributes do
    Generator.list_attributes()
  end

  @doc """
  Gets detailed information about a specific attribute.
  
  ## Parameters
  
  - `attribute_name` - String name of the attribute
  
  ## Returns
  
  Attribute configuration map with `:type`, `:options`, `:default`, etc.
  Returns `nil` if attribute not found.
  
  ## Examples
  
      info = AriaEngine.CharacterGenerator.get_attribute_info("species")
      # Returns: %{type: "categorical", options: ["SPECIES_HUMANOID", ...], default: "SPECIES_SEMI_HUMANOID"}
  """
  def get_attribute_info(attribute_name) do
    Generator.get_attribute_info(attribute_name)
  end

  @doc """
  Gets available options for a categorical attribute.
  
  ## Parameters
  
  - `attribute_name` - String name of the categorical attribute
  
  ## Returns
  
  List of option strings. Empty list for non-categorical attributes.
  """
  def get_attribute_options(attribute_name) do
    Generator.get_attribute_options(attribute_name)
  end

  @doc """
  Gets a human-readable description for an attribute option.
  
  ## Parameters
  
  - `option` - String option value
  
  ## Returns
  
  Description string explaining what the option represents.
  
  ## Examples
  
      desc = AriaEngine.CharacterGenerator.get_option_description("SPECIES_SEMI_HUMANOID")
      # Returns: "Primarily human-like but with significant non-human traits..."
  """
  def get_option_description(option) do
    Generator.get_option_description(option)
  end

  @doc """
  Gets system statistics about the character generator.
  
  ## Returns
  
  A map with statistics about attributes, options, and capabilities.
  
  ## Example Return
  
      %{
        total_attributes: 35,
        categorical_attributes: 33,
        numeric_attributes: 2,
        total_options: 200,
        descriptions_available: 180
      }
  """
  def stats do
    Generator.get_system_stats()
  end

  @doc """
  Lists all available preset names.
  
  ## Returns
  
  A list of preset name strings.
  """
  def list_presets do
    ["fantasy_cyber", "cyber_cat_person", "traditional_shrine_maiden", "casual_tech"]
  end

  @doc """
  Generates a character and returns only the essential data.
  
  This is useful when you need a lightweight result for storage or transmission.
  
  ## Options
  
  Same as `generate/1`.
  
  ## Returns
  
  A simplified map with `:character_id`, `:attributes`, and `:prompt`.
  """
  def generate_compact(opts \\ []) do
    character = generate(opts)
    
    %{
      character_id: character.character_id,
      attributes: character.attributes,
      prompt: character.prompt
    }
  end

  @doc """
  Checks if character attributes are valid (no constraint violations).
  
  ## Parameters
  
  - `attributes` - Map of character attributes
  
  ## Returns
  
  Boolean indicating if the character is valid.
  """
  def valid?(attributes) do
    validate(attributes) |> Enum.empty?()
  end

  @doc """
  Generates a character using a specific planning workflow.
  
  ## Parameters
  
  - `plan_name` - Name of the planning workflow to use
  - `opts` - Options for character generation
  
  ## Available Workflows
  
  - `:basic` - Basic character generation workflow
  - `:comprehensive` - Full validation and constraint resolution workflow
  - `:demo` - Simplified demo generation workflow
  - `:validation_only` - Just validation workflow (requires existing attributes)
  - `:preset_application` - Apply preset workflow (requires :preset option)
  
  ## Examples
  
      # Use comprehensive planning workflow
      character = AriaEngine.CharacterGenerator.generate_with_plan(:comprehensive)
      
      # Use basic workflow with preset
      character = AriaEngine.CharacterGenerator.generate_with_plan(:basic, preset: "cyber_cat_person")
      
      # Use preset application workflow
      character = AriaEngine.CharacterGenerator.generate_with_plan(:preset_application, preset: "fantasy_cyber")
  
  ## Returns
  
  Same format as `generate/1`, or `{:error, reason}` if planning fails.
  """
  def generate_with_plan(plan_name, opts \\ []) do
    Generator.generate_with_plan(plan_name, opts)
  end

  @doc """
  Tests a specific planning workflow for debugging purposes.
  
  ## Parameters
  
  - `workflow` - The workflow to test (:basic, :comprehensive, :validation, etc.)
  - `opts` - Options for the workflow test
  
  ## Returns
  
  - `{:ok, result}` with detailed planning information on success
  - `{:error, reason}` on failure
  
  ## Examples
  
      # Test basic workflow
      {:ok, result} = AriaEngine.CharacterGenerator.test_workflow(:basic)
      
      # Test validation workflow with conflicting attributes
      {:ok, result} = AriaEngine.CharacterGenerator.test_workflow(:validation, 
        %{species: "SPECIES_ANIMAL", style_kei: "STYLE_KEI_ROBOTIC_CYBORG"})
  """
  def test_workflow(workflow, opts \\ %{}) do
    try do
      case workflow do
        :basic -> 
          {:ok, %{workflow: :basic, status: :available, opts: opts}}
        :comprehensive -> 
          {:ok, %{workflow: :comprehensive, status: :available, opts: opts}}
        :demo -> 
          {:ok, %{workflow: :demo, status: :available, opts: opts}}
        _ -> 
          # Fallback to plan test helper if available
          case Code.ensure_loaded(AriaEngine.CharacterGenerator.PlanTestHelper) do
            {:module, _} -> 
              AriaEngine.CharacterGenerator.PlanTestHelper.test_workflow(workflow, opts)
            {:error, _} -> 
              {:error, "Unknown workflow: #{workflow}"}
          end
      end
    rescue
      e -> {:error, "Workflow test failed: #{inspect(e)}"}
    end
  end

  @doc """
  Tests the planning system's backtracking capabilities.
  
  ## Parameters
  
  - `conflicting_attrs` - Map of conflicting attributes to test resolution
  
  ## Returns
  
  - `{:ok, resolution}` if conflicts were successfully resolved
  - `{:error, reason}` if resolution failed
  
  ## Examples
  
      # Test conflict resolution
      {:ok, result} = AriaEngine.CharacterGenerator.test_backtracking(%{
        species: "SPECIES_ANIMAL", 
        style_kei: "STYLE_KEI_ROBOTIC_CYBORG"
      })
  """
  def test_backtracking(conflicting_attrs \\ %{}) do
    AriaEngine.CharacterGenerator.PlanTestHelper.test_backtracking(conflicting_attrs)
  end

  @doc """
  Gets information about available planning domains and workflows.
  
  ## Returns
  
  A map with information about available planning options.
  
  ## Examples
  
      info = AriaEngine.CharacterGenerator.get_planning_info()
      # Returns: %{
      #   domains: [:character_generation, :demo_character, :validation, :preset],
      #   workflows: [:basic, :comprehensive, :demo, :validation_only, :preset_application],
      #   plans: [:basic_character_generation_plan, :comprehensive_character_generation_plan, ...]
      # }
  """
  def get_planning_info do
    %{
      domains: [:character_generation, :demo_character, :validation, :preset],
      workflows: [:basic, :comprehensive, :demo, :validation_only, :preset_application],
      plans: [
        :basic_character_generation_plan,
        :comprehensive_character_generation_plan,
        :demo_character_generation_plan,
        :validation_only_plan,
        :preset_application_plan,
        :batch_generation_plan,
        :advanced_character_generation_plan,
        :theme_coherence_plan,
        :accessibility_plan
      ],
      actions: [
        :set_character_attribute,
        :randomize_character_attributes,
        :apply_preset,
        :validate_attributes,
        :resolve_conflicts,
        :generate_prompt,
        :check_goal_character_valid,
        :check_goal_prompt_ready,
        :check_goal_preset_applied,
        :check_goal_conflicts_resolved,
        :check_goal_validation_complete,
        :check_goal_batch_ready,
        :check_goal_accessibility_met
      ]
    }
  end
end
