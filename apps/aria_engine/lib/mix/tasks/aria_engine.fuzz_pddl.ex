# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.AriaEngine.FuzzPddl do
  @moduledoc """
  Performs fuzzing for the PDDL parser and printer by generating random PDDL structures.
  """
  use Mix.Task

  alias AriaEngine.PddlFuzzer
  alias AriaEngine.PddlParser
  alias AriaEngine.PddlPrinter
  alias MapSet

  @shortdoc "Fuzzes PDDL parser/printer with random inputs"
  def run(args) do
    num_iterations = parse_iterations(args)
    Mix.shell().info("Starting PDDL Fuzzing with #{num_iterations} iterations...")

    Enum.each(1..num_iterations, fn i ->
      Mix.shell().info("\n--- Fuzzing Iteration #{i}/#{num_iterations} ---")
      fuzz_domain_round_trip(i)
      fuzz_problem_round_trip(i)
    end)

    Mix.shell().info("\nPDDL Fuzzing Finished.")
  end

  defp parse_iterations(args) do
    case OptionParser.parse(args, switches: [iterations: :integer]) do
      {[iterations: n], _, _} when is_integer(n) and n > 0 -> n
      _ -> 10 # Default to 10 iterations
    end
  end

  defp fuzz_domain_round_trip(iteration) do
    Mix.shell().info("Fuzzing Domain (Iteration #{iteration})...")
    original_struct = PddlFuzzer.generate_random_domain()

    case PddlPrinter.format(:domain, original_struct) do
      reprinted_pddl when is_binary(reprinted_pddl) ->
        case PddlParser.parse(:domain, reprinted_pddl) do
          {:ok, re_parsed_struct} ->
            if compare_structures(:domain, original_struct, re_parsed_struct) do
              Mix.shell().info("  Domain Fuzz Test: PASSED")
            else
              Mix.shell().error("  Domain Fuzz Test: FAILED - Structures do not match.")
              Mix.shell().info("    Original Struct: #{inspect(original_struct, pretty: true)}")
              Mix.shell().info("    Re-Parsed Struct: #{inspect(re_parsed_struct, pretty: true)}")
              Mix.shell().info("    Reprinted PDDL:\n#{reprinted_pddl}")
            end
          {:error, reason} ->
            Mix.shell().error("  Domain Fuzz Test: FAILED - Re-parsing error: #{inspect(reason)}")
            Mix.shell().info("    Reprinted PDDL:\n#{reprinted_pddl}")
        end
      {:error, reason} ->
        Mix.shell().error("  Domain Fuzz Test: FAILED - Printing error: #{inspect(reason)}")
        Mix.shell().info("    Original Struct: #{inspect(original_struct, pretty: true)}")
    end
  end

  defp fuzz_problem_round_trip(iteration) do
    Mix.shell().info("Fuzzing Problem (Iteration #{iteration})...")
    original_struct = PddlFuzzer.generate_random_problem()

    case PddlPrinter.format(:problem, original_struct) do
      reprinted_pddl when is_binary(reprinted_pddl) ->
        case PddlParser.parse(:problem, reprinted_pddl) do
          {:ok, re_parsed_struct} ->
            if compare_structures(:problem, original_struct, re_parsed_struct) do
              Mix.shell().info("  Problem Fuzz Test: PASSED")
            else
              Mix.shell().error("  Problem Fuzz Test: FAILED - Structures do not match.")
              Mix.shell().info("    Original Struct: #{inspect(original_struct, pretty: true)}")
              Mix.shell().info("    Re-Parsed Struct: #{inspect(re_parsed_struct, pretty: true)}")
              Mix.shell().info("    Reprinted PDDL:\n#{reprinted_pddl}")
            end
          {:error, reason} ->
            Mix.shell().error("  Problem Fuzz Test: FAILED - Re-parsing error: #{inspect(reason)}")
            Mix.shell().info("    Reprinted PDDL:\n#{reprinted_pddl}")
        end
      {:error, reason} ->
        Mix.shell().error("  Problem Fuzz Test: FAILED - Printing error: #{inspect(reason)}")
        Mix.shell().info("    Original Struct: #{inspect(original_struct, pretty: true)}")
    end
  end

  # This is a simplified comparison. For robust fuzzing, this needs to be
  # a deep, order-independent comparison of all relevant fields.
  # For now, we'll rely on the existing PddlParser.Domain and Problem structs
  # having proper equality checks, or we'll need to implement a more
  # sophisticated comparison here.
  defp compare_structures(_type, s1, s2) do
    # This is a placeholder. A proper comparison needs to handle
    # potential reordering of elements (e.g., predicates, actions, objects)
    # that are semantically equivalent but structurally different after
    # printing and re-parsing.
    # For now, we'll assume the structs themselves have comparable fields
    # or that the printer/parser maintain a consistent order.
    # If fuzzing reveals issues here, this function will need to be expanded
    # to perform deep, normalized comparisons similar to what's in
    # Mix.Tasks.AriaEngine.PddlRoundTripTest.
    s1 == s2
  end
end
