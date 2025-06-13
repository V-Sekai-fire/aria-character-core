# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerator.Utils do
  @moduledoc """
  Utility functions for character generation including weighted random selection,
  prompt building, and validation helpers.
  """

  alias AriaEngine.CharacterGenerator.Config

  @doc """
  Performs weighted random choice from a list of options.
  
  ## Examples
      
      iex> AriaEngine.CharacterGenerator.Utils.weighted_random_choice(["A", "B", "C"], [0.5, 0.3, 0.2])
      "A"  # (most likely result due to higher weight)
  """
  def weighted_random_choice(options, weights) do
    if length(options) != length(weights) or Enum.empty?(options) do
      nil
    else
      # Create cumulative weights
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
  Randomizes all character sliders using weighted selection.
  
  ## Parameters
  - `seed`: Optional random seed for deterministic results
  
  ## Returns
  A map of attribute names to selected values.
  """
  def randomize_character_sliders(seed \\ nil) do
    if seed, do: :rand.seed(:exsplus, {seed, seed + 1, seed + 2})

    Config.character_sliders()
    |> Enum.reduce(%{}, fn {slider_name, slider_info}, acc ->
      chosen_value = case Map.get(slider_info, :type, "categorical") do
        "categorical" ->
          options = Map.get(slider_info, :options, [])
          weights = Config.get_slider_weights(slider_name)

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
  Constructs a descriptive character prompt from attributes.
  
  ## Parameters
  - `attributes`: Map of character attributes
  
  ## Returns
  A formatted string describing the character for AI generation.
  """
  def construct_character_prompt(attributes) do
    required_keys = [
      "species", "emotion", "style_kei", "color_palette",
      "key_motifs", "layering_style", "detail_level",
      "age", "avatar_gender_appearance", "primary_theme"
    ]

    # Build descriptions map
    descriptions = Enum.reduce(required_keys, %{}, fn key, acc ->
      value = Map.get(attributes, key) || get_default_value(key)

      description = if key == "detail_level" do
        to_string(value)
      else
        Config.get_option_description(value) || value
      end

      Map.put(acc, key, description)
    end)

    "#{descriptions["age"]} #{descriptions["avatar_gender_appearance"]} #{descriptions["emotion"]} #{descriptions["species"]} " <>
    "#{descriptions["style_kei"]} #{descriptions["color_palette"]} " <>
    "#{descriptions["primary_theme"]} #{descriptions["key_motifs"]} #{descriptions["layering_style"]} " <>
    "Detail level #{descriptions["detail_level"]}. " <>
    Config.prompt_suffix()
  end

  @doc """
  Generates a single character with attributes and prompt.
  
  ## Parameters
  - `seed`: Optional random seed for deterministic results
  
  ## Returns
  A tuple of `{attributes, prompt}`.
  """
  def workflow_generate_prompt_only(seed \\ nil) do
    attributes = randomize_character_sliders(seed)
    prompt = construct_character_prompt(attributes)
    {attributes, prompt}
  end

  @doc """
  Generates a batch of character prompts.
  
  ## Parameters
  - `num_prompts`: Number of characters to generate
  
  ## Returns
  A list of maps with `:prompt_id`, `:seed`, `:iteration`, `:attributes`, and `:prompt` keys.
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
  Validates a character's attributes for constraint violations.
  
  ## Parameters
  - `attributes`: Map of character attributes
  
  ## Returns
  A list of constraint violation messages (empty if valid).
  """
  def check_constraint_violations(attributes) do
    violations = []

    # Check kemonomimi feature consistency
    violations = check_kemonomimi_consistency(attributes, violations)

    # Check presence/type consistency
    violations = check_presence_type_consistency(attributes, violations)

    # Check thematic conflicts
    violations = check_thematic_conflicts(attributes, violations)

    # Check species/style consistency
    violations = check_species_style_consistency(attributes, violations)

    violations
  end

  @doc """
  Automatically resolves conflicts in character attributes.
  
  ## Parameters
  - `attributes`: Map of character attributes
  
  ## Returns
  A corrected map of character attributes.
  """
  def resolve_conflicts(attributes) do
    attributes
    |> resolve_kemonomimi_conflicts()
    |> resolve_presence_type_conflicts()
    |> resolve_thematic_conflicts()
    |> resolve_species_style_conflicts()
  end

  # Private helper functions

  defp get_default_value(attribute) do
    case Config.get_slider_config(attribute) do
      %{default: default} -> default
      _ -> nil
    end
  end

  defp check_kemonomimi_consistency(attributes, violations) do
    ears = Map.get(attributes, "kemonomimi_animal_ears_presence")
    tail = Map.get(attributes, "kemonomimi_animal_tail_presence")
    archetype = Map.get(attributes, "humanoid_archetype")
    tail_style = Map.get(attributes, "kemonomimi_animal_tail_style")

    violations = if (ears == "KEMONOMIMI_EARS_TRUE" or tail == "KEMONOMIMI_TAIL_TRUE") and
                    archetype == "HUMANOID_ARCHETYPE_HUMAN_FEATURED" do
      ["Animal features with human archetype" | violations]
    else
      violations
    end

    violations = if tail == "KEMONOMIMI_TAIL_FALSE" and tail_style != nil do
      ["Tail style set but no tail present" | violations]
    else
      violations
    end

    violations
  end

  defp check_presence_type_consistency(attributes, violations) do
    violations = check_feature_presence_type(attributes, violations,
      "fantasy_magical_talismans_presence", "FANTASY_TALISMANS_FALSE",
      "fantasy_magical_talismans_type", "Fantasy talisman type set but no talismans present")

    violations = check_feature_presence_type(attributes, violations,
      "cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_FALSE",
      "cyber_tech_accessories_type", "Cyber accessory type set but no accessories present")

    violations = check_feature_presence_type(attributes, violations,
      "cyber_visible_cybernetics_presence", "CYBER_CYBERNETICS_FALSE",
      "cyber_visible_cybernetics_placement", "Cybernetics placement set but no cybernetics present")

    violations
  end

  defp check_feature_presence_type(attributes, violations, presence_key, false_value, type_key, error_message) do
    presence = Map.get(attributes, presence_key)
    type_value = Map.get(attributes, type_key)

    if presence == false_value and type_value != nil do
      [error_message | violations]
    else
      violations
    end
  end

  defp check_thematic_conflicts(attributes, violations) do
    style_kei = Map.get(attributes, "style_kei")
    primary_theme = Map.get(attributes, "primary_theme")
    cyber_presence = Map.get(attributes, "cyber_visible_cybernetics_presence")
    fantasy_presence = Map.get(attributes, "fantasy_magical_talismans_presence")

    violations = if primary_theme == "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN" and
                    cyber_presence == "CYBER_CYBERNETICS_TRUE" do
      ["Traditional shrine maiden theme conflicts with cybernetics" | violations]
    else
      violations
    end

    violations = if style_kei == "STYLE_KEI_ROBOTIC_CYBORG" and
                    fantasy_presence == "FANTASY_TALISMANS_TRUE" do
      ["Robotic style conflicts with fantasy talismans" | violations]
    else
      violations
    end

    violations
  end

  defp check_species_style_consistency(attributes, violations) do
    species = Map.get(attributes, "species")
    style_kei = Map.get(attributes, "style_kei")

    violations = if species == "SPECIES_ANIMAL" and style_kei == "STYLE_KEI_ROBOTIC_CYBORG" do
      ["Animal species conflicts with robotic style" | violations]
    else
      violations
    end

    violations = if species == "SPECIES_HUMANOID_ROBOT_OR_CYBORG" and style_kei == "STYLE_KEI_FURRY" do
      ["Robot/cyborg species conflicts with furry style" | violations]
    else
      violations
    end

    violations
  end

  defp resolve_kemonomimi_conflicts(attributes) do
    ears = Map.get(attributes, "kemonomimi_animal_ears_presence")
    tail = Map.get(attributes, "kemonomimi_animal_tail_presence")
    archetype = Map.get(attributes, "humanoid_archetype")

    # If we have animal features but human archetype, change to cat person
    if (ears == "KEMONOMIMI_EARS_TRUE" or tail == "KEMONOMIMI_TAIL_TRUE") and
       archetype == "HUMANOID_ARCHETYPE_HUMAN_FEATURED" do
      Map.put(attributes, "humanoid_archetype", "HUMANOID_ARCHETYPE_CAT_PERSON")
    else
      attributes
    end
  end

  defp resolve_presence_type_conflicts(attributes) do
    attributes
    |> clear_type_if_not_present("fantasy_magical_talismans_presence", "FANTASY_TALISMANS_FALSE", "fantasy_magical_talismans_type")
    |> clear_type_if_not_present("cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_FALSE", "cyber_tech_accessories_type")
    |> clear_type_if_not_present("cyber_visible_cybernetics_presence", "CYBER_CYBERNETICS_FALSE", "cyber_visible_cybernetics_placement")
  end

  defp clear_type_if_not_present(attributes, presence_key, false_value, type_key) do
    if Map.get(attributes, presence_key) == false_value do
      Map.put(attributes, type_key, nil)
    else
      attributes
    end
  end

  defp resolve_thematic_conflicts(attributes) do
    primary_theme = Map.get(attributes, "primary_theme")

    # If traditional theme, disable conflicting modern elements
    if primary_theme == "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN" do
      attributes
      |> Map.put("cyber_visible_cybernetics_presence", "CYBER_CYBERNETICS_FALSE")
      |> Map.put("cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_FALSE")
    else
      attributes
    end
  end

  defp resolve_species_style_conflicts(attributes) do
    species = Map.get(attributes, "species")
    style_kei = Map.get(attributes, "style_kei")

    cond do
      species == "SPECIES_ANIMAL" and style_kei == "STYLE_KEI_ROBOTIC_CYBORG" ->
        # Prioritize style, change species to match
        Map.put(attributes, "species", "SPECIES_HUMANOID_ROBOT_OR_CYBORG")

      species == "SPECIES_HUMANOID_ROBOT_OR_CYBORG" and style_kei == "STYLE_KEI_FURRY" ->
        # Prioritize species, change style to match
        Map.put(attributes, "style_kei", "STYLE_KEI_ROBOTIC_CYBORG")

      true ->
        attributes
    end
  end
end
