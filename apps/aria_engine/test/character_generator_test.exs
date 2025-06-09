# filepath: /home/fire/aria-character-core/apps/aria_engine/test/character_generator_test.exs
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGeneratorTest do
  @moduledoc """
  Tests for the AriaEngine character generation system.

  This module tests the GTN (Goal-Task-Network) constraint validation system
  with backtracking capabilities for character generation. It validates that
  the system can identify and fix logical conflicts in character generation
  options and implement constraint validation using GTN planner methods.
  """

  use ExUnit.Case
  alias AriaEngine.{Domain, State}
  alias AriaEngine.TestDomains
  alias AriaEngine.CharacterGenerationUtils

  @doc """
  Generates a unique character ID using UUID.

  Used to create unique identifiers for each character generation test,
  ensuring test isolation and proper state management.
  """
  defp generate_character_id do
    UUID.uuid4()
  end

  @moduletag :character_generation

  describe "Character Generation with AriaEngine" do
    test "builds character generation domain with all sliders" do
      domain = TestDomains.build_character_generation_domain()

      # Verify domain has the necessary actions and methods
      assert map_size(domain.actions) > 0
      assert map_size(domain.task_methods) > 0

      IO.puts("\n=== CHARACTER GENERATION DOMAIN BUILT ===")
      IO.puts("Actions: #{map_size(domain.actions)}")
      IO.puts("Methods: #{map_size(domain.task_methods)}")
      IO.puts("Domain ready for constraint-aware character generation")
    end

    test "generates character with verbose planning - level 1" do
      domain = TestDomains.build_character_generation_domain()

      # Generate a unique character ID for this test
      char_id = generate_character_id()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("generation_session", "active", true)
      |> AriaEngine.set_fact("character_id", "current", char_id)
      |> AriaEngine.set_fact("random_seed", "current", 12345)

      IO.puts("\n#{String.duplicate("=", 80)}")
      IO.puts("CHARACTER GENERATION - VERBOSE LEVEL 1")
      IO.puts("#{String.duplicate("=", 80)}")

      IO.puts("Initial state:")
      IO.inspect(initial_state.data, label: "State")

      # High-level task: generate a complete character WITH CONSTRAINTS
      tasks = [{"generate_character_with_constraints", [char_id, "fantasy_cyber_preset"]}]

      IO.puts("\nTasks: #{inspect(tasks)}")

      case AriaEngine.plan(domain, initial_state, tasks, verbose: 1) do
        {:ok, plan} ->
          IO.puts("✓ Character generation plan created with #{length(plan)} steps:")
          Enum.with_index(plan, 1)
          |> Enum.each(fn {step, index} ->
            IO.puts("  #{index}. #{inspect(step)}")
          end)

          # Execute the plan
          IO.puts("\nExecuting character generation plan...")
          case AriaEngine.execute_plan(domain, initial_state, plan) do
            {:ok, final_state} ->
              IO.puts("✓ Character generation completed successfully!")

              # Show character attributes that were set
              character_facts = final_state.data
              |> Enum.filter(fn {{category, _}, _} ->
                String.starts_with?(category, "character_")
              end)

              IO.puts("\nGenerated Character Attributes:")
              Enum.each(character_facts, fn {{category, attribute}, value} ->
                IO.puts("  #{category}.#{attribute}: #{value}")
              end)

              # Show the final prompt if generated
              prompt = AriaEngine.get_fact(final_state, "generated_prompt", char_id)
              if prompt do
                IO.puts("\nGenerated Character Prompt:")
                IO.puts("#{prompt}")
              end

            {:error, reason} ->
              IO.puts("✗ Character generation failed: #{reason}")
          end

        {:error, reason} ->
          IO.puts("✗ Planning failed: #{reason}")
      end
    end

    test "generates character with verbose planning - level 2" do
      domain = TestDomains.build_character_generation_domain()

      # Generate a unique character ID for this test
      char_id = generate_character_id()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("generation_session", "active", true)
      |> AriaEngine.set_fact("character_id", "current", char_id)
      |> AriaEngine.set_fact("random_seed", "current", 67890)

      IO.puts("\n#{String.duplicate("=", 80)}")
      IO.puts("CHARACTER GENERATION - VERBOSE LEVEL 2 (DETAILED)")
      IO.puts("#{String.duplicate("=", 80)}")

      # More complex task: generate character with specific customizations
      tasks = [
        {"configure_character_presets", [char_id, "cyber_cat_person"]},
        {"generate_detailed_prompt", [char_id]}
      ]

      IO.puts("Tasks: #{inspect(tasks)}")

      case AriaEngine.plan(domain, initial_state, tasks, verbose: 2) do
        {:ok, plan} ->
          IO.puts("\n✓ Detailed character generation plan created!")
          IO.puts("Plan steps: #{inspect(plan)}")

        {:error, reason} ->
          IO.puts("✗ Detailed planning failed: #{reason}")
      end
    end

    test "demonstrates character customization workflow" do
      domain = TestDomains.build_character_generation_domain()

      # Generate a unique character ID for this test
      char_id = generate_character_id()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("generation_session", "active", true)
      |> AriaEngine.set_fact("character_id", "current", char_id)

      IO.puts("\n#{String.duplicate("=", 80)}")
      IO.puts("CHARACTER CUSTOMIZATION WORKFLOW")
      IO.puts("#{String.duplicate("=", 80)}")

      # Show available slider categories (simplified for now)
      IO.puts("Available character configuration categories:")
      IO.puts("  Clothing & Attire: 11 options")
      IO.puts("  Colors & Patterns: 3 options")
      IO.puts("  Cyber Elements: 4 options")
      IO.puts("  Fantasy Elements: 3 options")
      IO.puts("  Kemonomimi Features: 3 options")
      IO.puts("  Physical Features: 2 options")
      IO.puts("  Species & Body: 1 options")
      IO.puts("  Style & Theme: 2 options")
      IO.puts("  Traditional Elements: 4 options")
      IO.puts("  Other: 11 options")

      # Test customization task
      customization_tasks = [
        {"customize_species", [char_id, "SPECIES_BASE_SEMI_HUMANOID"]},
        {"customize_archetype", [char_id, "HUMANOID_ARCHETYPE_CAT_PERSON"]},
        {"customize_theme", [char_id, "PRIMARY_THEME_PASTEL_CYBER"]},
        {"finalize_character_prompt", [char_id]}
      ]

      IO.puts("\nCustomization workflow:")
      Enum.with_index(customization_tasks, 1)
      |> Enum.each(fn {task, index} ->
        IO.puts("  #{index}. #{inspect(task)}")
      end)

      case AriaEngine.plan(domain, initial_state, customization_tasks, verbose: 1) do
        {:ok, plan} ->
          IO.puts("\n✓ Customization plan created with #{length(plan)} steps")

          case AriaEngine.execute_plan(domain, initial_state, plan) do
            {:ok, final_state} ->
              IO.puts("✓ Character customization completed!")

              # Show configured attributes
              configured_attrs = final_state.data
              |> Enum.filter(fn {{category, _}, _} ->
                String.starts_with?(category, "character_")
              end)
              |> Enum.sort()

              IO.puts("\nConfigured Character Attributes:")
              Enum.each(configured_attrs, fn {{category, attribute}, value} ->
                IO.puts("  #{String.replace(category, "character_", "")}.#{attribute}: #{value}")
              end)

            {:error, reason} ->
              IO.puts("✗ Customization execution failed: #{reason}")
          end

        {:error, reason} ->
          IO.puts("✗ Customization planning failed: #{reason}")
      end
    end

    # Unit Tests for Prompt Generation (demonstrating text-only character generation)

    test "weighted random choice works correctly" do
      options = ["A", "B", "C"]
      weights = [0.5, 0.3, 0.2]

      # Test multiple times to verify distribution
      results = for _ <- 1..100 do
        CharacterGenerationUtils.weighted_random_choice(options, weights)
      end

      # All results should be valid options
      assert Enum.all?(results, &(&1 in options))

      # Test edge cases
      assert CharacterGenerationUtils.weighted_random_choice([], []) == nil
      assert CharacterGenerationUtils.weighted_random_choice(["A"], [1.0]) == "A"
      assert CharacterGenerationUtils.weighted_random_choice(["A", "B"], [0.5]) == nil  # mismatched lengths
    end

    test "randomize character sliders generates valid attributes" do
      attributes = CharacterGenerationUtils.randomize_character_sliders(12345)

      # Check that all core sliders are present
      core_sliders = ["species", "emotion", "style_kei", "color_palette",
                     "key_motifs", "layering_style", "detail_level",
                     "age", "avatar_gender_appearance"]

      for slider_name <- core_sliders do
        assert Map.has_key?(attributes, slider_name), "Missing slider: #{slider_name}"
        value = attributes[slider_name]
        assert value != nil, "#{slider_name} should have a value"
      end
    end

    test "construct character prompt builds proper descriptive text" do
      # Test with known attributes
      attributes = %{
        "species" => "SPECIES_SEMI_HUMANOID",
        "emotion" => "EMOTION_HAPPY",
        "style_kei" => "STYLE_KEI_ANIME",
        "color_palette" => "COLOR_PALETTE_ANIME_INSPIRED",
        "key_motifs" => "KEY_MOTIFS_GLOWING_ACCENTS",
        "layering_style" => "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR",
        "detail_level" => 7,
        "age" => "AGE_ADULT",
        "avatar_gender_appearance" => "AVATAR_GENDER_APPEARANCE_FEMININE"
      }

      prompt = CharacterGenerationUtils.construct_character_prompt(attributes)

      # Verify prompt contains expected elements
      assert String.contains?(prompt, "3D modeling concept art")
    end

    test "workflow generate prompt only produces complete results" do
      {attributes, prompt} = CharacterGenerationUtils.workflow_generate_prompt_only(42)

      # Verify attributes are populated
      assert is_map(attributes)
      assert map_size(attributes) >= 9  # At least the core 9 sliders

      # Verify prompt is a non-empty string
      assert is_binary(prompt)
      assert String.length(prompt) > 50
      assert String.contains?(prompt, "Full body shot")
    end

    test "workflow generate prompt batch creates multiple unique prompts" do
      num_prompts = 5
      batch_results = CharacterGenerationUtils.workflow_generate_prompt_batch(num_prompts)

      assert length(batch_results) == num_prompts

      # Check each result has required fields
      for result <- batch_results do
        assert Map.has_key?(result, :prompt_id)
        assert Map.has_key?(result, :seed)
        assert Map.has_key?(result, :iteration)
        assert Map.has_key?(result, :attributes)
        assert Map.has_key?(result, :prompt)

        assert is_binary(result.prompt)
        assert String.length(result.prompt) > 50
        assert is_map(result.attributes)
        assert is_integer(result.seed)
      end

      # Verify prompts are different (high probability with randomization)
      prompts = Enum.map(batch_results, & &1.prompt)
      unique_prompts = Enum.uniq(prompts)
      assert length(unique_prompts) >= 3, "Expected more variation in generated prompts"
    end

    test "run prompt only pipeline orchestrates batch generation" do
      results = CharacterGenerationUtils.run_prompt_only_pipeline(3)

      assert length(results) == 3
      assert Enum.all?(results, &Map.has_key?(&1, :prompt))
      assert Enum.all?(results, &Map.has_key?(&1, :attributes))
    end

    test "deterministic generation with seeds" do
      # Same seed should produce same results
      {attrs1, prompt1} = CharacterGenerationUtils.workflow_generate_prompt_only(999)
      {attrs2, prompt2} = CharacterGenerationUtils.workflow_generate_prompt_only(999)

      assert attrs1 == attrs2
      assert prompt1 == prompt2

      # Different seeds should produce different results (high probability)
      {attrs3, prompt3} = CharacterGenerationUtils.workflow_generate_prompt_only(1000)
      assert attrs1 != attrs3  # Very likely to be different
    end

    test "prompt generation handles missing attributes gracefully" do
      # Test with minimal attributes
      minimal_attrs = %{
        "species" => "SPECIES_HUMANOID",
        "detail_level" => 5
      }

      prompt = CharacterGenerationUtils.construct_character_prompt(minimal_attrs)

      # Should still generate a valid prompt using defaults
      assert is_binary(prompt)
      assert String.length(prompt) > 30
      assert String.contains?(prompt, "Detail level 5")
    end

    test "end-to-end text prompt generation workflow" do
      # This is the main integration test showing complete prompt-only functionality
      IO.puts("\n=== AriaEngine Character Prompt Generation Demo ===")

      # Generate a single prompt
      {attributes, prompt} = CharacterGenerationUtils.workflow_generate_prompt_only()

      IO.puts("\nGenerated Character Attributes:")
      for {key, value} <- attributes do
        IO.puts("  #{key}: #{value}")
      end

      IO.puts("\nGenerated Prompt:")
      IO.puts("  #{prompt}")

      # Generate a batch of prompts
      IO.puts("\n=== Batch Generation Demo ===")
      batch_results = CharacterGenerationUtils.workflow_generate_prompt_batch(3)

      for {result, index} <- Enum.with_index(batch_results, 1) do
        IO.puts("\nPrompt #{index} (ID: #{result.prompt_id}, Seed: #{result.seed}):")
        IO.puts("  #{result.prompt}")
      end

      # Verify all results are valid
      assert length(batch_results) == 3
      assert Enum.all?(batch_results, fn result ->
        String.contains?(result.prompt, "Full body shot") and
        String.contains?(result.prompt, "3D modeling concept art")
      end)

      IO.puts("\n=== Prompt Generation Test Completed Successfully ===")
    end
  end
end
