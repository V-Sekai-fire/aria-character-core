defmodule Mix.Tasks.AriaEngine.PddlRoundTripTest do
  @moduledoc "Performs round-trip testing for the PDDL parser and printer."
  use Mix.Task

  alias AriaEngine.PddlParser
  alias AriaEngine.PddlPrinter
  alias AriaEngine.Domains.SatelliteDomain
  alias AriaEngine.Problems.SatelliteProblem

  @shortdoc "Performs PDDL parser/printer round-trip tests"
  def run(_) do
    Mix.shell().info("Starting PDDL Round-Trip Tests...")

    # Test Case 1: Simple Domain
    test_case_simple_domain()

    # Test Case 2: Simple Problem
    test_case_simple_problem()

    # Test Case 3: Satellite Domain
    test_case_satellite_domain()

    # Test Case 4: Satellite Problem
    test_case_satellite_problem()

    Mix.shell().info("PDDL Round-Trip Tests Finished.")
  end

  defp test_case_simple_domain() do
    Mix.shell().info("\n--- Test Case: Simple Domain ---")
    domain_pddl = """
    (define (domain simple-domain)
      (:requirements :strips :typing)
      (:types
        object
        agent - object
      )
      (:predicates
        (at ?x - object ?l - location)
        (has ?a - agent ?o - object)
      )
      (:functions
        (fuel ?r - rocket)
      )
      (:durative-action move
        :parameters (?r - rocket ?from ?to - location)
        :duration (= ?duration 10)
        :condition (and (at ?r ?from))
        :effect (and (at ?r ?to) (not (at ?r ?from)))
      )
    )
    """
    run_round_trip_test(:domain, domain_pddl, "Simple Domain")
  end

  defp test_case_simple_problem() do
    Mix.shell().info("\n--- Test Case: Simple Problem ---")
    problem_pddl = """
    (define (problem simple-problem)
      (:domain simple-domain)
      (:objects
        rocket1 - rocket
        locA locB - location
      )
      (:init
        (at rocket1 locA)
        (= (fuel rocket1) 100)
      )
      (:htn
        :parameters ()
        :subtasks (and
          (move rocket1 locA locB)
        )
      )
    )
    """
    run_round_trip_test(:problem, problem_pddl, "Simple Problem")
  end

  defp test_case_satellite_domain() do
    Mix.shell().info("\n--- Test Case: Satellite Domain ---")
    domain_pddl = SatelliteDomain.domain_pddl()
    run_round_trip_test(:domain, domain_pddl, "Satellite Domain")
  end

  defp test_case_satellite_problem() do
    Mix.shell().info("\n--- Test Case: Satellite Domain ---")
    problem_pddl = SatelliteProblem.problem_pddl()
    run_round_trip_test(:problem, problem_pddl, "Satellite Problem")
  end

  defp run_round_trip_test(type, original_pddl, test_name) do
    Mix.shell().info("Running round-trip test for #{test_name}...")
    case PddlParser.parse(type, original_pddl) do
      {:ok, parsed_structure} ->
        reprinted_pddl = PddlPrinter.format(type, parsed_structure)
        case PddlParser.parse(type, reprinted_pddl) do
          {:ok, re_parsed_structure} ->
            if compare_structures(type, parsed_structure, re_parsed_structure) do
              Mix.shell().info("  #{test_name} Round-Trip Test: PASSED")
            else
              Mix.shell().error("  #{test_name} Round-Trip Test: FAILED - Structures do not match.")
              Mix.shell().info("    Original Parsed: #{inspect(parsed_structure, pretty: true)}")
              Mix.shell().info("    Re-Parsed: #{inspect(re_parsed_structure, pretty: true)}")
              Mix.shell().info("    Reprinted PDDL:\n#{reprinted_pddl}")
            end
          {:error, reason} ->
            Mix.shell().error("  #{test_name} Round-Trip Test: FAILED - Re-parsing error: #{reason}")
            Mix.shell().info("    Reprinted PDDL:\n#{reprinted_pddl}")
        end
      {:error, reason} ->
        Mix.shell().error("  #{test_name} Round-Trip Test: FAILED - Initial parsing error: #{reason}")
    end
  end

  defp compare_structures(:domain, s1, s2) do
    # For domains, a direct comparison should mostly work if parsing/printing is consistent
    # Order of actions, types, predicates, functions might vary, so a deeper comparison is needed
    # For now, let's do a basic comparison and refine if needed.
    s1.name == s2.name &&
    normalize_domain_elements(s1.types) == normalize_domain_elements(s2.types) &&
    normalize_domain_elements(s1.predicates) == normalize_domain_elements(s2.predicates) &&
    normalize_domain_elements(s1.functions) == normalize_domain_elements(s2.functions) &&
    normalize_domain_elements(s1.durative_actions) == normalize_domain_elements(s2.durative_actions) &&
    normalize_domain_elements(s1.tasks) == normalize_domain_elements(s2.tasks) &&
    normalize_domain_elements(s1.methods) == normalize_domain_elements(s2.methods)
  end

  defp compare_structures(:problem, s1, s2) do
    # For problems, especially initial facts and goals, order might not matter
    s1.objects == s2.objects && # Objects usually maintain order or are small enough
    normalize_facts(s1.initial_facts) == normalize_facts(s2.initial_facts) &&
    normalize_goals(s1.goals) == normalize_goals(s2.goals)
  end

  # Normalizes a list of facts for order-independent comparison
  defp normalize_facts(facts) do
    facts
    |> Enum.map(fn
      {:assign, {func_name, func_args}, value} ->
        {:assign, func_name, Enum.sort(func_args), value}
      {predicate, args} ->
        {predicate, Enum.sort(args)}
      other -> other # Pass through errors or other unexpected formats
    end)
    |> MapSet.new()
  end

  # Normalizes a list of goals for order-independent comparison
  defp normalize_goals(goals) do
    goals
    |> Enum.map(fn {task_name, args} ->
      {task_name, Enum.sort(args)}
    end)
    |> MapSet.new()
  end

  # Generic normalization for domain elements that might vary in order
  defp normalize_domain_elements(elements) when is_list(elements) do
    elements
    |> Enum.map(fn
      {name, args} when is_list(args) -> {name, Enum.sort(args)}
      %{} = map -> Map.new(map, fn {k, v} -> {k, normalize_domain_elements(v)} end)
      other -> other
    end)
    |> MapSet.new()
  end

  defp normalize_domain_elements(element) do
    element
  end
end
