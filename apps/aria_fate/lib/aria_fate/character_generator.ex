# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaFate.CharacterGenerator do
  @moduledoc """
  Main character generation module that coordinates the systematic creation
  of Fate Core characters using the hybrid planner domain.

  This module implements the core functionality for generating consistent,
  rule-compliant characters while addressing LLM limitations around
  task completion and decision consistency.
  """

  alias AriaFate.Character
  alias AriaFate.PlannerDomain

  @doc """
  Generates a basic Fate Core character with default parameters.
  """
  def generate_character do
    generate_character(%{})
  end

  @doc """
  Generates a Fate Core character with specific constraints.

  Uses the hybrid planner to ensure systematic character creation
  that follows Fate Core rules and maintains consistency across
  all character elements.
  """
  def generate_character(constraints) when is_map(constraints) do
    with {:ok, domain} <- PlannerDomain.create_planner_domain(),
         {:ok, result} <- execute_generation_plan(domain, constraints) do
      {:ok, result.character}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Plans a character arc using temporal planning.

  Creates a structured narrative plan that ensures character
  development follows logical progression and creates
  compelling story beats.
  """
  def plan_character_arc(character, options \\ []) do
    episodes = Keyword.get(options, :episodes, 3)
    themes = Keyword.get(options, :themes, [])
    conflicts = Keyword.get(options, :conflicts, [:personal, :external])

    arc = create_character_arc(character, episodes, themes, conflicts)
    {:ok, arc}
  end

  @doc """
  Validates a character against Fate Core rules.
  """
  def validate_character(character) do
    Character.validate(character)
  end

  @doc """
  Exports a character to various formats.
  """
  def export_character(character, format) do
    case format do
      :json -> export_to_json(character)
      :markdown -> export_to_markdown(character)
      :html -> export_to_html(character)
      _ -> {:error, "Unsupported format: #{format}"}
    end
  end

  # Private implementation functions

  defp execute_generation_plan(domain, constraints) do
    initial_state = %{
      constraints: normalize_constraints(constraints),
      character: nil,
      generation_state: %{}
    }

    goals = [:complete_character]

    PlannerDomain.execute_character_plan(domain, initial_state, goals)
  end

  defp normalize_constraints(constraints) do
    %{
      concept: Map.get(constraints, :concept),
      trouble: Map.get(constraints, :trouble),
      name: Map.get(constraints, :name),
      refresh: Map.get(constraints, :refresh, 3),
      skill_cap: Map.get(constraints, :skill_cap, 4)
    }
  end

  defp create_character_arc(character, episodes, themes, conflicts) do
    # Create a structured character arc using the character's aspects
    aspects = Character.all_aspects(character)

    arc_episodes =
      1..episodes
      |> Enum.map(fn episode_num ->
        create_episode(episode_num, character, aspects, themes, conflicts)
      end)

    %{
      character_name: character.name,
      episodes: arc_episodes,
      themes: themes,
      character_growth: plan_character_growth(character, episodes)
    }
  end

  defp create_episode(episode_num, character, aspects, themes, conflicts) do
    # Select aspects and conflicts for this episode
    primary_aspect = Enum.random(aspects)
    conflict_type = Enum.random(conflicts)
    theme = if Enum.empty?(themes), do: nil, else: Enum.random(themes)

    %{
      episode: episode_num,
      title: generate_episode_title(episode_num, primary_aspect),
      primary_aspect: primary_aspect,
      conflict_type: conflict_type,
      theme: theme,
      challenges: generate_challenges(character, conflict_type),
      potential_compels: generate_compels(primary_aspect),
      skill_focus: suggest_skill_focus(character, conflict_type)
    }
  end

  defp generate_episode_title(episode_num, aspect) do
    case episode_num do
      1 -> "The #{extract_key_word(aspect)} Begins"
      n when n <= 3 -> "#{extract_key_word(aspect)} Complications"
      _ -> "#{extract_key_word(aspect)} Resolution"
    end
  end

  defp extract_key_word(aspect) when is_binary(aspect) do
    aspect
    |> String.split()
    |> Enum.find(&(String.length(&1) > 4))
    |> case do
      nil -> "Story"
      word -> word
    end
  end

  defp extract_key_word(_), do: "Story"

  defp generate_challenges(character, conflict_type) do
    case conflict_type do
      :personal -> [
        "Internal struggle with #{character.trouble}",
        "Moral dilemma involving #{character.high_concept}",
        "Past catching up with character"
      ]
      :external -> [
        "Physical obstacle requiring #{get_physical_skill(character)}",
        "Social conflict testing #{get_social_skill(character)}",
        "Environmental hazard"
      ]
      :mystery -> [
        "Clues that don't add up",
        "Missing information",
        "False leads and red herrings"
      ]
      _ -> [
        "Unexpected complication",
        "Resource limitation",
        "Time pressure"
      ]
    end
  end

  defp generate_compels(aspect) do
    [
      "#{aspect} forces you to act against your better judgment",
      "#{aspect} creates an unexpected complication",
      "#{aspect} puts you in conflict with an ally"
    ]
  end

  defp suggest_skill_focus(character, conflict_type) do
    case conflict_type do
      :personal -> get_mental_skill(character)
      :external -> get_physical_skill(character)
      :social -> get_social_skill(character)
      :mystery -> get_investigation_skill(character)
      _ -> get_highest_skill(character)
    end
  end

  defp get_physical_skill(character) do
    physical_skills = [:athletics, :fight, :physique, :drive]
    get_best_skill_from_list(character, physical_skills) || :athletics
  end

  defp get_social_skill(character) do
    social_skills = [:rapport, :deceive, :empathy, :provoke]
    get_best_skill_from_list(character, social_skills) || :rapport
  end

  defp get_mental_skill(character) do
    mental_skills = [:will, :lore, :investigate, :notice]
    get_best_skill_from_list(character, mental_skills) || :will
  end

  defp get_investigation_skill(character) do
    investigation_skills = [:investigate, :notice, :empathy, :contacts]
    get_best_skill_from_list(character, investigation_skills) || :investigate
  end

  defp get_highest_skill(character) do
    character.skills
    |> Enum.max_by(fn {_skill, rating} -> rating end, fn -> {:rapport, 0} end)
    |> elem(0)
  end

  defp get_best_skill_from_list(character, skill_list) do
    character.skills
    |> Enum.filter(fn {skill, _rating} -> skill in skill_list end)
    |> Enum.max_by(fn {_skill, rating} -> rating end, fn -> nil end)
    |> case do
      nil -> nil
      {skill, _rating} -> skill
    end
  end

  defp plan_character_growth(character, episodes) do
    # Plan how the character might grow over the arc
    growth_points = div(episodes, 2) + 1

    %{
      potential_aspect_evolution: suggest_aspect_evolution(character),
      skill_advancement_opportunities: suggest_skill_advancement(character),
      new_stunt_possibilities: suggest_new_stunts(character),
      milestone_suggestions: create_milestone_suggestions(episodes, growth_points)
    }
  end

  defp suggest_aspect_evolution(character) do
    Character.all_aspects(character)
    |> Enum.map(fn aspect ->
      %{
        current: aspect,
        potential_evolution: "#{aspect} (Evolved)",
        trigger: "Major character development or revelation"
      }
    end)
  end

  defp suggest_skill_advancement(character) do
    # Suggest skills that could be improved based on current pyramid
    current_skills = Map.keys(character.skills)
    all_fate_skills = get_all_fate_skills()

    missing_skills = all_fate_skills -- current_skills

    %{
      skills_to_improve: suggest_skills_to_improve(character.skills),
      new_skills_to_learn: Enum.take(missing_skills, 3),
      pyramid_expansion: "Consider adding skills at +1 level"
    }
  end

  defp suggest_skills_to_improve(skills) do
    skills
    |> Enum.filter(fn {_skill, rating} -> rating < 4 end)
    |> Enum.sort_by(fn {_skill, rating} -> -rating end)
    |> Enum.take(3)
    |> Enum.map(fn {skill, rating} -> {skill, rating + 1} end)
  end

  defp suggest_new_stunts(character) do
    # Suggest stunts based on character's highest skills and aspects
    high_skills =
      character.skills
      |> Enum.filter(fn {_skill, rating} -> rating >= 3 end)
      |> Enum.map(fn {skill, _rating} -> skill end)

    Enum.map(high_skills, fn skill ->
      "Advanced #{skill |> Atom.to_string() |> String.capitalize()} technique"
    end)
  end

  defp create_milestone_suggestions(episodes, growth_points) do
    milestone_episodes =
      1..episodes
      |> Enum.take_every(max(1, div(episodes, growth_points)))

    Enum.map(milestone_episodes, fn episode ->
      %{
        episode: episode,
        type: if(episode == episodes, do: :major, else: :significant),
        suggestions: [
          "Rename an aspect to reflect character growth",
          "Swap two adjacent skills on the pyramid",
          "Add a new stunt or modify an existing one"
        ]
      }
    end)
  end

  defp get_all_fate_skills do
    [
      :academics, :athletics, :burglary, :contacts, :crafts, :deceive,
      :drive, :empathy, :fight, :investigate, :lore, :notice,
      :physique, :provoke, :rapport, :resources, :shoot, :stealth,
      :survival, :will
    ]
  end

  # Export functions

  defp export_to_json(character) do
    case Jason.encode(character, pretty: true) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, "JSON encoding failed: #{reason}"}
    end
  end

  defp export_to_markdown(character) do
    markdown = """
    # #{character.name || "Unnamed Character"}

    #{if character.description, do: character.description <> "\n", else: ""}

    ## Aspects

    **High Concept:** #{character.high_concept || "Not set"}

    **Trouble:** #{character.trouble || "Not set"}

    #{format_additional_aspects(character.aspects)}

    ## Skills

    #{format_skills_markdown(character.skills)}

    ## Stunts

    #{format_stunts_markdown(character.stunts)}

    ## Stress & Consequences

    **Refresh:** #{character.refresh}
    **Fate Points:** #{character.fate_points}

    **Physical Stress:** #{character.stress_tracks.physical} boxes
    **Mental Stress:** #{character.stress_tracks.mental} boxes

    **Consequences:**
    - Mild: #{character.consequences.mild || "Empty"}
    - Moderate: #{character.consequences.moderate || "Empty"}
    - Severe: #{character.consequences.severe || "Empty"}

    #{if character.notes != "", do: "\n## Notes\n\n#{character.notes}", else: ""}
    """

    {:ok, markdown}
  end

  defp export_to_html(character) do
    {:ok, markdown} = export_to_markdown(character)

    # Simple markdown to HTML conversion
    html = markdown
    |> String.replace(~r/^# (.+)$/m, "<h1>\\1</h1>")
    |> String.replace(~r/^## (.+)$/m, "<h2>\\1</h2>")
    |> String.replace(~r/^\*\*(.+):\*\* (.+)$/m, "<strong>\\1:</strong> \\2")
    |> String.replace(~r/^- (.+)$/m, "<li>\\1</li>")
    |> String.replace("\n\n", "</p><p>")
    |> (&("<p>" <> &1 <> "</p>")).()
    |> String.replace("<p><h", "<h")
    |> String.replace("</h1></p>", "</h1>")
    |> String.replace("</h2></p>", "</h2>")

    {:ok, html}
  end

  defp format_additional_aspects(aspects) do
    aspects
    |> Enum.with_index(3)
    |> Enum.map(fn {aspect, index} ->
      "**Aspect #{index}:** #{aspect}"
    end)
    |> Enum.join("\n\n")
  end

  defp format_skills_markdown(skills) do
    if Enum.empty?(skills) do
      "No skills assigned."
    else
      skills
      |> Enum.sort_by(fn {_skill, rating} -> -rating end)
      |> Enum.map(fn {skill, rating} ->
        skill_name = skill |> Atom.to_string() |> String.capitalize()
        "- **#{skill_name}:** +#{rating}"
      end)
      |> Enum.join("\n")
    end
  end

  defp format_stunts_markdown(stunts) do
    if Enum.empty?(stunts) do
      "No stunts."
    else
      stunts
      |> Enum.with_index(1)
      |> Enum.map(fn {stunt, index} ->
        "#{index}. #{stunt}"
      end)
      |> Enum.join("\n")
    end
  end
end
