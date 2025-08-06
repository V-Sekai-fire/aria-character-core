# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaFate do
  @moduledoc """
  AriaFate is a Fate Core RPG character sheet generator and game master assistant
  that leverages the aria_hybrid_planner for systematic character creation and narrative planning.

  This module provides the external API for character generation, following the standard
  Elixir app pattern with all public functions delegating to internal modules.
  """

  alias AriaFate.CharacterGenerator
  alias AriaFate.SRDParser
  alias AriaFate.PlannerDomain

  @doc """
  Generates a basic Fate Core character sheet with default parameters.

  Returns `{:ok, character}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> AriaFate.generate_character()
      {:ok, %AriaFate.Character{
        name: "Generated Character",
        high_concept: "Mysterious Wanderer",
        trouble: "Can't Stay in One Place",
        # ... other character data
      }}
  """
  defdelegate generate_character(), to: CharacterGenerator

  @doc """
  Generates a Fate Core character sheet with specific constraints.

  ## Parameters

  - `constraints` - A map containing character generation constraints:
    - `:concept` - High concept aspect (string)
    - `:trouble` - Trouble aspect (string)
    - `:refresh` - Starting refresh points (integer, default 3)
    - `:skill_cap` - Maximum skill rating (integer, default 4)
    - `:name` - Character name (string)

  ## Examples

      iex> AriaFate.generate_character(%{
      ...>   concept: "Wizard Detective",
      ...>   trouble: "Magic Always Leaves a Trail",
      ...>   refresh: 3
      ...> })
      {:ok, %AriaFate.Character{
        name: "Elara Vex",
        high_concept: "Wizard Detective",
        trouble: "Magic Always Leaves a Trail",
        # ... other character data
      }}
  """
  defdelegate generate_character(constraints), to: CharacterGenerator

  @doc """
  Plans a character arc using the hybrid temporal planner.

  ## Parameters

  - `character` - The character struct to plan an arc for
  - `options` - Planning options:
    - `:episodes` - Number of episodes to plan (integer, default 3)
    - `:themes` - Story themes to incorporate (list of strings)
    - `:conflicts` - Types of conflicts to include (list of atoms)

  ## Examples

      iex> AriaFate.plan_character_arc(character, episodes: 5)
      {:ok, %AriaFate.CharacterArc{
        episodes: [
          %{title: "The Case Begins", conflicts: [:mystery, :social]},
          # ... more episodes
        ]
      }}
  """
  defdelegate plan_character_arc(character, options \\ []), to: CharacterGenerator

  @doc """
  Parses Fate SRD documents to extract character creation rules and examples.

  ## Parameters

  - `srd_path` - Path to the SRD HTML file
  - `section` - Optional section to extract (atom)

  ## Examples

      iex> AriaFate.parse_srd("thirdparty/CC-BY SRDs/Fate-Core-SRD-CC.html", :skills)
      {:ok, %{skills: [...], skill_descriptions: [...]}}
  """
  defdelegate parse_srd(srd_path, section \\ :all), to: SRDParser

  @doc """
  Creates a hybrid planner domain for character generation tasks.

  This function sets up the planning domain with methods for:
  - Generating character aspects
  - Selecting appropriate skills
  - Creating stunts
  - Planning character development

  ## Examples

      iex> AriaFate.create_planner_domain()
      {:ok, %AriaFate.PlannerDomain{
        methods: [...],
        operators: [...],
        state_schema: %{}
      }}
  """
  defdelegate create_planner_domain(), to: PlannerDomain

  @doc """
  Executes a character generation plan using the hybrid planner.

  ## Parameters

  - `domain` - The planner domain created by `create_planner_domain/0`
  - `initial_state` - Initial planning state with character constraints
  - `goals` - List of goals to achieve (e.g., [:complete_character, :validate_aspects])

  ## Examples

      iex> domain = AriaFate.create_planner_domain()
      iex> state = %{constraints: %{concept: "Space Pilot"}}
      iex> AriaFate.execute_character_plan(domain, state, [:complete_character])
      {:ok, %{character: %AriaFate.Character{...}, plan_trace: [...]}}
  """
  defdelegate execute_character_plan(domain, initial_state, goals), to: PlannerDomain

  @doc """
  Validates a generated character against Fate Core rules.

  ## Parameters

  - `character` - The character struct to validate

  ## Examples

      iex> AriaFate.validate_character(character)
      {:ok, %{valid: true, warnings: []}}

      iex> AriaFate.validate_character(invalid_character)
      {:error, %{valid: false, errors: ["Skill pyramid invalid", ...]}}
  """
  defdelegate validate_character(character), to: CharacterGenerator

  @doc """
  Exports a character to various formats.

  ## Parameters

  - `character` - The character struct to export
  - `format` - Export format (`:json`, `:markdown`, `:html`)

  ## Examples

      iex> AriaFate.export_character(character, :markdown)
      {:ok, "# Character Name\\n\\n**High Concept:** ..."}
  """
  defdelegate export_character(character, format), to: CharacterGenerator
end
