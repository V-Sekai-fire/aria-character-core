defmodule AriaEngine.PddlParser.RoundTripTest do
  use ExUnit.Case, async: true

  alias AriaEngine.PddlParser
  alias AriaEngine.PddlPrinter
  alias AriaEngine.Domains.SatelliteDomain
  alias AriaEngine.Problems.SatelliteProblem

  describe "PDDL Round-Trip Testing" do
    test "parses and prints a simple domain without loss" do
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

      {:ok, parsed_domain} = PddlParser.parse_domain(domain_pddl)
      reprinted_pddl = PddlPrinter.format_domain(parsed_domain)
      {:ok, re_parsed_domain} = PddlParser.parse_domain(reprinted_pddl)

      # Compare the parsed structures for equivalence
      assert parsed_domain == re_parsed_domain
    end

    test "parses and prints a simple problem without loss" do
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

      {:ok, parsed_problem} = PddlParser.parse_problem(problem_pddl)
      reprinted_pddl = PddlPrinter.format_problem(parsed_problem)
      {:ok, re_parsed_problem} = PddlParser.parse_problem(reprinted_pddl)

      # Compare the parsed structures for equivalence
      assert parsed_problem == re_parsed_problem
    end

    test "parses and prints Satellite domain without loss" do
      domain_pddl = SatelliteDomain.domain_pddl()
      {:ok, parsed_domain} = PddlParser.parse_domain(domain_pddl)
      reprinted_pddl = PddlPrinter.format_domain(parsed_domain)
      {:ok, re_parsed_domain} = PddlParser.parse_domain(reprinted_pddl)
      assert parsed_domain == re_parsed_domain
    end

    test "parses and prints Satellite problem without loss" do
      problem_pddl = SatelliteProblem.problem_pddl()
      {:ok, parsed_problem} = PddlParser.parse_problem(problem_pddl)
      reprinted_pddl = PddlPrinter.format_problem(parsed_problem)
      {:ok, re_parsed_problem} = PddlParser.parse_problem(reprinted_pddl)
      assert parsed_problem == re_parsed_problem
    end
  end
end
