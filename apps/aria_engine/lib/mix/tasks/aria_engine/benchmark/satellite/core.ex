# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.AriaEngine.Benchmark.Satellite.Core do
  @moduledoc "Core logic for benchmarking the Satellite HDDL SAT problem."
  # Removed use Mix.Task

  alias AriaEngine.Domains.SatelliteDomain
  alias AriaEngine.Problems.SatelliteProblem
  alias AriaEngine.PddlParser
  alias AriaEngine.Planner
  alias Mix.Tasks.AriaEngine.Benchmark.Satellite.DomainBuilder
  alias Mix.Tasks.AriaEngine.Benchmark.Satellite.StateBuilder
  alias AriaEngine.PddlPrinter # Added alias for PddlPrinter

  @type parsed_domain_map :: AriaEngine.PddlParser.parsed_domain_map()
  @type parsed_problem_map :: AriaEngine.PddlParser.parsed_problem_map()

  @spec run() :: :ok | {:error, String.t()}
  def run() do # Changed def run(_) to def run()
    Mix.shell().info("Loading Satellite Domain and Problem PDDL...")

    domain_pddl = SatelliteDomain.domain_pddl()
    problem_pddl = SatelliteProblem.problem_pddl()

    Mix.shell().info("Parsing PDDL...")
    {:ok, parsed_domain} = PddlParser.parse_domain(domain_pddl)
    {:ok, parsed_problem} = PddlParser.parse_problem(problem_pddl)

    Mix.shell().info("Parsed Domain:\n#{PddlPrinter.format_domain(parsed_domain)}")
    Mix.shell().info("Parsed Problem:\n#{PddlPrinter.format_problem(parsed_problem)}")

    Mix.shell().info("Constructing AriaEngine Domain and State...")
    initial_state = StateBuilder.build_aria_state(parsed_problem)
    domain = DomainBuilder.build_aria_domain(parsed_domain, initial_state) # Pass initial_state to build domain
    goals = parsed_problem.goals

    Mix.shell().info("Starting planning...")
    start_time = System.monotonic_time()

    # The Planner.plan/5 function expects:
    # domain_interface, initial_state, goals, opts, current_time
    case Planner.plan(domain, initial_state, goals, [], 0) do
      {:ok, plan} ->
        end_time = System.monotonic_time()
        duration = System.convert_time_unit(end_time - start_time, :native, :millisecond)
        Mix.shell().info("Planning successful in #{duration} ms!")
        Mix.shell().info("Plan: #{inspect(plan)}") # Reverted to inspect
      {:error, reason} ->
        end_time = System.monotonic_time()
        duration = System.convert_time_unit(end_time - start_time, :native, :millisecond)
        Mix.shell().error("Planning failed after #{duration} ms: #{inspect(reason)}")
    end
  end
end
