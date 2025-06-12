# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerator.Plans do
  @moduledoc """
  Character generation planning templates and workflow definitions.
  
  This module provides pre-defined TODO lists (plans) for common character
  generation workflows, making it easy to execute complex character generation
  tasks through the AriaEngine planner.
  """

  @doc """
  Creates a basic character generation plan.
  
  This plan generates a character with optional preset and validates the result.
  
  ## Parameters
  - `char_id`: Character identifier
  - `preset`: Optional preset name (default: nil)
  - `seed`: Optional random seed (default: nil)
  
  ## Returns
  A list of TODO items for character generation.
  """
  def basic_character_generation_plan(char_id, preset \\ nil, seed \\ nil) do
    base_todos = [
      {"generate_character_with_constraints", %{char_id: char_id, preset: preset}},
      {"validate_character_coherence", %{char_id: char_id}},
      {"generate_character_prompt", %{char_id: char_id}}
    ]

    # Add seed setup if provided
    if seed do
      [{:set_character_attribute, [char_id, "random_seed", seed]} | base_todos]
    else
      base_todos
    end
  end

  @doc """
  Creates a comprehensive character generation plan with full validation.
  
  This plan includes extensive validation, conflict resolution, and quality checks.
  
  ## Parameters
  - `char_id`: Character identifier
  - `preset`: Optional preset name
  - `customizations`: Optional customization map
  
  ## Returns
  A list of TODO items for comprehensive character generation.
  """
  def comprehensive_character_generation_plan(char_id, preset \\ nil, customizations \\ %{}) do
    todos = [
      {"randomize_character", %{char_id: char_id}},
      {"validate_all_constraints", %{char_id: char_id}}
    ]

    # Add preset application if provided
    todos = if preset do
      todos ++ [{"apply_character_preset", %{char_id: char_id, preset: preset}}]
    else
      todos
    end

    # Add customizations if provided
    todos = if map_size(customizations) > 0 do
      todos ++ [{"customize_preset", %{char_id: char_id, customizations: customizations}}]
    else
      todos
    end

    # Add final validation and prompt generation
    todos ++ [
      {"resolve_all_conflicts", %{char_id: char_id}},
      {"validate_character_coherence", %{char_id: char_id}},
      {"generate_character_prompt", %{char_id: char_id}}
    ]
  end

  @doc """
  Creates a validation-only plan for existing characters.
  
  This plan validates and fixes an existing character without regenerating attributes.
  
  ## Parameters
  - `char_id`: Character identifier
  
  ## Returns
  A list of TODO items for character validation.
  """
  def validation_only_plan(char_id) do
    [
      {"validate_all_constraints", %{char_id: char_id}},
      {"resolve_all_conflicts", %{char_id: char_id}},
      {"validate_character_coherence", %{char_id: char_id}}
    ]
  end

  @doc """
  Creates a preset application plan.
  
  This plan applies a preset to an existing character with validation.
  
  ## Parameters
  - `char_id`: Character identifier
  - `preset_name`: Name of the preset to apply
  - `validate`: Whether to validate after application (default: true)
  
  ## Returns
  A list of TODO items for preset application.
  """
  def preset_application_plan(char_id, preset_name, validate \\ true) do
    base_todos = [
      {"apply_preset_with_validation", %{char_id: char_id, preset: preset_name}}
    ]

    if validate do
      base_todos ++ [
        {"validate_character_coherence", %{char_id: char_id}},
        {"generate_character_prompt", %{char_id: char_id}}
      ]
    else
      base_todos ++ [
        {"generate_character_prompt", %{char_id: char_id}}
      ]
    end
  end

  @doc """
  Creates a customization plan for character modifications.
  
  This plan applies custom attributes to a character with validation.
  
  ## Parameters
  - `char_id`: Character identifier
  - `customizations`: Map of attributes to customize
  - `validate`: Whether to validate after customization (default: true)
  
  ## Returns
  A list of TODO items for character customization.
  """
  def customization_plan(char_id, customizations, validate \\ true) do
    base_todos = [
      {"customize_preset", %{char_id: char_id, customizations: customizations}}
    ]

    if validate do
      base_todos ++ [
        {"validate_character_coherence", %{char_id: char_id}},
        {"generate_character_prompt", %{char_id: char_id}}
      ]
    else
      base_todos ++ [
        {"generate_character_prompt", %{char_id: char_id}}
      ]
    end
  end

  @doc """
  Creates a batch character generation plan.
  
  This plan generates multiple characters with different configurations.
  
  ## Parameters
  - `character_configs`: List of character configuration maps
    Each config should have: %{char_id: id, preset: name, customizations: map}
  
  ## Returns
  A list of TODO items for batch character generation.
  """
  def batch_generation_plan(character_configs) do
    Enum.flat_map(character_configs, fn config ->
      char_id = Map.get(config, :char_id) || UUID.uuid4()
      preset = Map.get(config, :preset)
      customizations = Map.get(config, :customizations, %{})

      comprehensive_character_generation_plan(char_id, preset, customizations)
    end)
  end

  @doc """
  Creates a demo character generation plan for testing and examples.
  
  This is a simplified plan suitable for demonstrations and quick testing.
  
  ## Parameters
  - `char_id`: Character identifier
  - `preset`: Preset name (default: "fantasy_cyber")
  
  ## Returns
  A list of TODO items for demo character generation.
  """
  def demo_character_generation_plan(char_id, preset \\ "fantasy_cyber") do
    [
      {"generate_character_with_constraints", %{char_id: char_id, preset: preset}},
      {"validate_character_coherence", %{char_id: char_id}},
      {"generate_character_prompt", %{char_id: char_id}}
    ]
  end

  @doc """
  Creates a prompt regeneration plan for existing characters.
  
  This plan regenerates the prompt for a character without changing attributes.
  
  ## Parameters
  - `char_id`: Character identifier
  
  ## Returns
  A list of TODO items for prompt regeneration.
  """
  def prompt_regeneration_plan(char_id) do
    [
      {"generate_character_prompt", %{char_id: char_id}}
    ]
  end

  @doc """
  Creates a character quality assurance plan.
  
  This plan performs comprehensive quality checks and optimizations.
  
  ## Parameters
  - `char_id`: Character identifier
  
  ## Returns
  A list of TODO items for character quality assurance.
  """
  def quality_assurance_plan(char_id) do
    [
      {"validate_all_constraints", %{char_id: char_id}},
      {"resolve_all_conflicts", %{char_id: char_id}},
      {"validate_character_coherence", %{char_id: char_id}},
      {"generate_character_prompt", %{char_id: char_id}},
      # Quality checks
      {:validate_attributes, [char_id]},
      {:mark_character_valid, [char_id]}
    ]
  end

  @doc """
  Creates a plan from a character generation request.
  
  This is a convenience function that creates an appropriate plan based on
  the provided options.
  
  ## Parameters
  - `options`: Map of generation options including:
    - `:char_id` - Character identifier (generated if not provided)
    - `:preset` - Preset name
    - `:customizations` - Customization map
    - `:seed` - Random seed
    - `:validate` - Whether to validate (default: true)
    - `:plan_type` - Type of plan (:basic, :comprehensive, :demo, default: :basic)
  
  ## Returns
  A tuple of `{char_id, todo_list}`.
  """
  def plan_from_options(options) do
    char_id = Map.get(options, :char_id) || UUID.uuid4()
    preset = Map.get(options, :preset)
    customizations = Map.get(options, :customizations, %{})
    seed = Map.get(options, :seed)
    validate = Map.get(options, :validate, true)
    plan_type = Map.get(options, :plan_type, :basic)

    todo_list = case plan_type do
      :comprehensive ->
        comprehensive_character_generation_plan(char_id, preset, customizations)
      
      :demo ->
        demo_character_generation_plan(char_id, preset || "fantasy_cyber")
      
      :validation ->
        validation_only_plan(char_id)
      
      :preset ->
        preset_application_plan(char_id, preset, validate)
      
      :customization ->
        customization_plan(char_id, customizations, validate)
      
      :quality ->
        quality_assurance_plan(char_id)
      
      _ -> # :basic or default
        basic_character_generation_plan(char_id, preset, seed)
    end

    {char_id, todo_list}
  end
end
