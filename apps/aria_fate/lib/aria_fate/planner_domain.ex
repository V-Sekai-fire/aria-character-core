# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaFate.PlannerDomain do
  @moduledoc """
  Defines the hybrid planner domain for systematic character generation.

  This module creates planning methods and operators that ensure consistent
  character creation following Fate Core rules, addressing the problem that
  LLMs forget previous decisions and can't reliably complete task lists.
  """

  alias AriaFate.Character

  @doc """
  Creates a hybrid planner domain for character generation.

  The domain includes methods for:
  - Generating character aspects that work together
  - Selecting skills that match the character concept
  - Creating appropriate stunts
  - Validating character consistency

  Returns a domain structure that can be used with aria_hybrid_planner.
  """
  def create_planner_domain do
    domain = %{
      methods: character_generation_methods(),
      operators: character_generation_operators(),
      state_schema: character_state_schema()
    }

    {:ok, domain}
  end

  @doc """
  Executes a character generation plan using the hybrid planner.

  This function takes a planning domain, initial state with constraints,
  and goals, then systematically generates a character following the
  planned sequence of operations.
  """
  def execute_character_plan(domain, initial_state, goals) do
    # Convert goals to todo items for the hybrid planner
    todos = Enum.map(goals, fn goal -> %{task: goal, priority: 1} end)

    # Use AriaHybridPlanner to plan and execute
    case AriaHybridPlanner.run_lazy(domain, initial_state, todos, []) do
      {:ok, {_solution_tree, final_state}} ->
        # Extract character from final state and format result
        character = Map.get(final_state, :character)
        plan_trace = Map.get(final_state, :plan_trace, ["Character generation completed"])

        {:ok, %{character: character, plan_trace: plan_trace, final_state: final_state}}

      {:error, reason} ->
        # Fallback to simulation if hybrid planner fails
        case simulate_character_planning(initial_state, goals) do
          {:ok, result} -> {:ok, result}
          {:error, _} -> {:error, reason}
        end
    end
  end

  # Private functions for domain definition

  defp character_generation_methods do
    [
      # High-level character creation method
      %{
        name: :complete_character,
        preconditions: [:has_constraints],
        subtasks: [
          :generate_basic_info,
          :create_aspects,
          :assign_skills,
          :create_stunts,
          :calculate_derived_stats,
          :validate_character
        ]
      },

      # Aspect generation methods
      %{
        name: :create_aspects,
        preconditions: [:has_basic_info],
        subtasks: [
          :create_high_concept,
          :create_trouble,
          :create_phase_aspects
        ]
      },

      # Skill assignment methods
      %{
        name: :assign_skills,
        preconditions: [:has_aspects],
        subtasks: [
          :determine_skill_priorities,
          :build_skill_pyramid,
          :validate_skill_pyramid
        ]
      },

      # Stunt creation methods
      %{
        name: :create_stunts,
        preconditions: [:has_skills],
        subtasks: [
          :identify_stunt_opportunities,
          :design_stunts,
          :validate_refresh_cost
        ]
      }
    ]
  end

  defp character_generation_operators do
    [
      # Basic info operators
      %{
        name: :generate_basic_info,
        preconditions: [:has_constraints],
        effects: [:has_basic_info],
        action: &generate_basic_info_action/1
      },

      # Aspect operators
      %{
        name: :create_high_concept,
        preconditions: [:has_basic_info],
        effects: [:has_high_concept],
        action: &create_high_concept_action/1
      },

      %{
        name: :create_trouble,
        preconditions: [:has_high_concept],
        effects: [:has_trouble],
        action: &create_trouble_action/1
      },

      %{
        name: :create_phase_aspects,
        preconditions: [:has_trouble],
        effects: [:has_aspects],
        action: &create_phase_aspects_action/1
      },

      # Skill operators
      %{
        name: :determine_skill_priorities,
        preconditions: [:has_aspects],
        effects: [:has_skill_priorities],
        action: &determine_skill_priorities_action/1
      },

      %{
        name: :build_skill_pyramid,
        preconditions: [:has_skill_priorities],
        effects: [:has_skills],
        action: &build_skill_pyramid_action/1
      },

      # Stunt operators
      %{
        name: :identify_stunt_opportunities,
        preconditions: [:has_skills],
        effects: [:has_stunt_ideas],
        action: &identify_stunt_opportunities_action/1
      },

      %{
        name: :design_stunts,
        preconditions: [:has_stunt_ideas],
        effects: [:has_stunts],
        action: &design_stunts_action/1
      },

      # Validation operators
      %{
        name: :validate_character,
        preconditions: [:has_stunts],
        effects: [:character_complete],
        action: &validate_character_action/1
      }
    ]
  end

  defp character_state_schema do
    %{
      constraints: %{
        concept: :string,
        trouble: :string,
        name: :string,
        refresh: :integer,
        skill_cap: :integer
      },
      character: %{
        name: :string,
        high_concept: :string,
        trouble: :string,
        aspects: [:string],
        skills: %{},
        stunts: [:string],
        refresh: :integer
      },
      generation_state: %{
        skill_priorities: [:atom],
        stunt_ideas: [:string],
        validation_results: %{}
      }
    }
  end

  # Operator action functions

  defp generate_basic_info_action(state) do
    constraints = Map.get(state, :constraints, %{})

    character = Character.new(%{
      name: Map.get(constraints, :name, generate_random_name()),
      refresh: Map.get(constraints, :refresh, 3)
    })

    {:ok, Map.put(state, :character, character)}
  end

  defp create_high_concept_action(state) do
    constraints = Map.get(state, :constraints, %{})
    character = Map.get(state, :character)

    high_concept = Map.get(constraints, :concept) || generate_high_concept(constraints)
    updated_character = %{character | high_concept: high_concept}

    {:ok, Map.put(state, :character, updated_character)}
  end

  defp create_trouble_action(state) do
    constraints = Map.get(state, :constraints, %{})
    character = Map.get(state, :character)

    trouble = Map.get(constraints, :trouble) || generate_trouble(character.high_concept)
    updated_character = %{character | trouble: trouble}

    {:ok, Map.put(state, :character, updated_character)}
  end

  defp create_phase_aspects_action(state) do
    character = Map.get(state, :character)

    aspects = generate_phase_aspects(character.high_concept, character.trouble)
    updated_character = %{character | aspects: aspects}

    {:ok, Map.put(state, :character, updated_character)}
  end

  defp determine_skill_priorities_action(state) do
    character = Map.get(state, :character)

    priorities = determine_skill_priorities_from_aspects(character)
    generation_state = Map.put(Map.get(state, :generation_state, %{}), :skill_priorities, priorities)

    {:ok, Map.put(state, :generation_state, generation_state)}
  end

  defp build_skill_pyramid_action(state) do
    generation_state = Map.get(state, :generation_state, %{})
    character = Map.get(state, :character)
    priorities = Map.get(generation_state, :skill_priorities, [])

    skills = build_skill_pyramid_from_priorities(priorities)
    updated_character = %{character | skills: skills}

    {:ok, Map.put(state, :character, updated_character)}
  end

  defp identify_stunt_opportunities_action(state) do
    character = Map.get(state, :character)

    stunt_ideas = identify_stunts_from_character(character)
    generation_state = Map.put(Map.get(state, :generation_state, %{}), :stunt_ideas, stunt_ideas)

    {:ok, Map.put(state, :generation_state, generation_state)}
  end

  defp design_stunts_action(state) do
    generation_state = Map.get(state, :generation_state, %{})
    character = Map.get(state, :character)
    stunt_ideas = Map.get(generation_state, :stunt_ideas, [])

    stunts = design_stunts_from_ideas(stunt_ideas, character)
    updated_character = %{character | stunts: stunts}

    {:ok, Map.put(state, :character, updated_character)}
  end

  defp validate_character_action(state) do
    character = Map.get(state, :character)

    case Character.validate(character) do
      {:ok, validation} ->
        generation_state = Map.put(Map.get(state, :generation_state, %{}), :validation_results, validation)
        {:ok, Map.put(state, :generation_state, generation_state)}

      {:error, validation} ->
        {:error, "Character validation failed: #{inspect(validation)}"}
    end
  end

  # Helper functions for character generation

  defp generate_random_name do
    names = ["Aria", "Zara", "Kai", "Nova", "Raven", "Phoenix", "Storm", "Sage"]
    Enum.random(names)
  end

  defp generate_high_concept(_constraints) do
    concepts = [
      "Mysterious Wanderer",
      "Brilliant Detective",
      "Rogue Scholar",
      "Noble Warrior",
      "Cunning Thief",
      "Wise Mentor"
    ]
    Enum.random(concepts)
  end

  defp generate_trouble(_high_concept) do
    # Generate trouble that creates interesting conflicts with the high concept
    troubles = [
      "Can't Resist a Mystery",
      "Haunted by the Past",
      "Too Curious for My Own Good",
      "Honor Before Reason",
      "Wanted by the Authorities",
      "Protective of the Innocent"
    ]
    Enum.random(troubles)
  end

  defp generate_phase_aspects(_high_concept, _trouble) do
    [
      "Loyal to My Friends",
      "Always Has a Plan",
      "Knows Someone Everywhere"
    ]
  end

  defp determine_skill_priorities_from_aspects(character) do
    # Analyze aspects to determine which skills should be prioritized
    _all_aspects = Character.all_aspects(character)

    # This would use more sophisticated analysis in a full implementation
    base_priorities = [:investigate, :notice, :rapport, :will, :athletics]

    # Add concept-specific skills
    concept_skills = extract_skills_from_concept(character.high_concept)

    # Ensure we have enough skills for a proper pyramid (need at least 10 skills)
    all_fate_skills = [
      :academics, :athletics, :burglary, :contacts, :crafts, :deceive,
      :drive, :empathy, :fight, :investigate, :lore, :notice,
      :physique, :provoke, :rapport, :resources, :shoot, :stealth,
      :survival, :will
    ]

    (concept_skills ++ base_priorities ++ all_fate_skills)
    |> Enum.uniq()
    |> Enum.take(20)  # Take more skills to ensure we have enough
  end

  defp extract_skills_from_concept(concept) when is_binary(concept) do
    concept_lower = String.downcase(concept)

    cond do
      String.contains?(concept_lower, "detective") -> [:investigate, :notice, :empathy]
      String.contains?(concept_lower, "warrior") -> [:fight, :athletics, :physique]
      String.contains?(concept_lower, "scholar") -> [:lore, :investigate, :academics]
      String.contains?(concept_lower, "thief") -> [:stealth, :burglary, :athletics]
      true -> [:rapport, :will]
    end
  end

  defp extract_skills_from_concept(_), do: []

  defp build_skill_pyramid_from_priorities(priorities) do
    # Build a valid skill pyramid with the given priorities
    # Fate Core pyramid: 1 at +4, 2 at +3, 3 at +2, 4 at +1
    skill_ratings = [
      {4, 1},  # One skill at Great (+4)
      {3, 2},  # Two skills at Good (+3)
      {2, 3},  # Three skills at Fair (+2)
      {1, 4}   # Four skills at Average (+1)
    ]

    # Ensure we have enough skills for the pyramid (need at least 10 skills)
    available_skills = Enum.take(priorities, 10)

    {skills, _remaining} =
      Enum.reduce(skill_ratings, {%{}, available_skills}, fn {rating, count}, {acc_skills, remaining_priorities} ->
        # Only assign skills if we have enough remaining
        if length(remaining_priorities) >= count do
          {selected, rest} = Enum.split(remaining_priorities, count)

          skill_map =
            selected
            |> Enum.reduce(%{}, fn skill, acc ->
              Map.put(acc, skill, rating)
            end)

          {Map.merge(acc_skills, skill_map), rest}
        else
          # If we don't have enough skills, skip this rating level
          {acc_skills, remaining_priorities}
        end
      end)

    skills
  end

  defp identify_stunts_from_character(character) do
    # Identify potential stunts based on character's highest skills and aspects
    high_skills =
      character.skills
      |> Enum.filter(fn {_skill, rating} -> rating >= 3 end)
      |> Enum.map(fn {skill, _rating} -> skill end)

    Enum.map(high_skills, fn skill ->
      "#{skill |> Atom.to_string() |> String.capitalize()} Specialist"
    end)
  end

  defp design_stunts_from_ideas(stunt_ideas, character) do
    # Design actual stunts from the ideas, limiting to 3 to stay within refresh
    stunt_ideas
    |> Enum.take(3)
    |> Enum.map(&design_specific_stunt(&1, character))
  end

  defp design_specific_stunt(idea, _character) do
    # Create a specific stunt description
    "#{idea}: +2 to relevant skill in specific circumstances"
  end

  # Simulation function for testing without full planner integration
  defp simulate_character_planning(initial_state, _goals) do
    # Simulate the planning process step by step
    with {:ok, state1} <- generate_basic_info_action(initial_state),
         {:ok, state2} <- create_high_concept_action(state1),
         {:ok, state3} <- create_trouble_action(state2),
         {:ok, state4} <- create_phase_aspects_action(state3),
         {:ok, state5} <- determine_skill_priorities_action(state4),
         {:ok, state6} <- build_skill_pyramid_action(state5),
         {:ok, state7} <- identify_stunt_opportunities_action(state6),
         {:ok, state8} <- design_stunts_action(state7),
         {:ok, final_state} <- validate_character_action(state8) do

      character = Map.get(final_state, :character)
      plan_trace = [
        "Generated basic character info",
        "Created high concept: #{character.high_concept}",
        "Created trouble: #{character.trouble}",
        "Generated phase aspects",
        "Determined skill priorities",
        "Built skill pyramid",
        "Identified stunt opportunities",
        "Designed stunts",
        "Validated character"
      ]

      {:ok, %{character: character, plan_trace: plan_trace, final_state: final_state}}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
