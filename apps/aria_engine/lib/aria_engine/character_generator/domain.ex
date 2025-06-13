# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerator.Domain do
  @moduledoc """
  Character generation domain definitions for the AriaEngine planner.
  
  This module defines the planning domain for character generation, including
  actions, methods, and domain-specific knowledge for character creation workflows.
  """

  import AriaEngine
  alias AriaEngine.CharacterGenerator.{Actions, Methods}

  @doc """
  Builds the main character generation domain with all necessary actions and methods.
  
  This domain supports hierarchical task planning for character generation,
  validation, and prompt creation.
  """
  @spec build_character_generation_domain() :: AriaEngine.domain()
  def build_character_generation_domain() do
    create_domain("character_generation")
    # Character attribute actions
    |> add_action(:set_character_attribute, &Actions.set_character_attribute/2)
    |> add_action(:randomize_character_attributes, &Actions.randomize_character_attributes/2)
    |> add_action(:apply_preset, &Actions.apply_preset/2)
    |> add_action(:validate_attributes, &Actions.validate_attributes/2)
    |> add_action(:resolve_conflicts, &Actions.resolve_conflicts/2)
    |> add_action(:generate_prompt, &Actions.generate_prompt/2)
    |> add_action(:check_constraint_violations, &Actions.check_constraint_violations/2)
    |> add_action(:mark_character_valid, &Actions.mark_character_valid/2)
    
    # Task methods for hierarchical planning
    |> add_task_method("generate_character_with_constraints", &Methods.generate_character_with_constraints/2)
    |> add_task_method("validate_character_coherence", &Methods.validate_character_coherence/2)
    |> add_task_method("generate_character_prompt", &Methods.generate_character_prompt/2)
    |> add_task_method("apply_character_preset", &Methods.apply_character_preset/2)
    |> add_task_method("randomize_character", &Methods.randomize_character/2)
    |> add_task_method("validate_all_constraints", &Methods.validate_all_constraints/2)
    |> add_task_method("resolve_all_conflicts", &Methods.resolve_all_conflicts/2)
    |> add_task_method("customize_preset", &Methods.customize_preset/2)
    |> add_task_method("apply_preset_with_validation", &Methods.apply_preset_with_validation/2)
    
    # Goal methods for achieving character properties
    |> add_unigoal_method("character_attribute", &Methods.achieve_character_attribute/2)
    |> add_unigoal_method("character_valid", &Methods.achieve_character_valid/2)
    |> add_unigoal_method("character_prompt_ready", &Methods.achieve_character_prompt_ready/2)
  end

  @doc """
  Builds a demo character generation domain for testing and examples.
  
  This is a simplified version of the main domain for demonstration purposes.
  """
  @spec build_demo_character_domain() :: AriaEngine.domain()
  def build_demo_character_domain() do
    create_domain("demo_character_generation")
    # Essential actions for demo
    |> add_action(:set_character_attribute, &Actions.set_character_attribute/2)
    |> add_action(:apply_preset, &Actions.apply_preset/2)
    |> add_action(:generate_prompt, &Actions.generate_prompt/2)
    
    # Demo task methods
    |> add_task_method("generate_character_with_constraints", &Methods.demo_generate_character/2)
    |> add_task_method("validate_character_coherence", &Methods.demo_validate_character/2)
    |> add_task_method("generate_character_prompt", &Methods.demo_generate_prompt/2)
  end

  @doc """
  Builds a validation-focused domain for character constraint checking.
  
  This domain is specialized for validation workflows and conflict resolution.
  """
  @spec build_validation_domain() :: AriaEngine.domain()
  def build_validation_domain() do
    create_domain("character_validation")
    |> add_action(:check_constraint_violations, &Actions.check_constraint_violations/2)
    |> add_action(:resolve_conflicts, &Actions.resolve_conflicts/2)
    |> add_action(:mark_character_valid, &Actions.mark_character_valid/2)
    
    |> add_task_method("validate_all_constraints", &Methods.validate_all_constraints/2)
    |> add_task_method("resolve_all_conflicts", &Methods.resolve_all_conflicts/2)
    
    |> add_unigoal_method("character_valid", &Methods.achieve_character_valid/2)
    |> add_unigoal_method("constraint_satisfied", &Methods.achieve_constraint_satisfied/2)
  end

  @doc """
  Builds a preset application domain for character template processing.
  
  This domain handles preset application and customization workflows.
  """
  @spec build_preset_domain() :: AriaEngine.domain()
  def build_preset_domain() do
    create_domain("character_presets")
    |> add_action(:apply_preset_attributes, &Actions.apply_preset_attributes/2)
    |> add_action(:merge_customizations, &Actions.merge_customizations/2)
    |> add_action(:validate_preset_compliance, &Actions.validate_preset_compliance/2)
    
    |> add_task_method("apply_preset_with_validation", &Methods.apply_preset_with_validation/2)
    |> add_task_method("customize_preset", &Methods.customize_preset/2)
    
    |> add_unigoal_method("preset_applied", &Methods.achieve_preset_applied/2)
    |> add_unigoal_method("customization_applied", &Methods.achieve_customization_applied/2)
  end
end
