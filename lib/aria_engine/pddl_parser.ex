# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser do
  @moduledoc """
  A basic PDDL parser for converting PDDL domain and problem strings
  into Elixir data structures suitable for AriaEngine.
  """

  alias AriaEngine.Pddl.Domain
  alias AriaEngine.Pddl.Problem
  alias AriaEngine.PddlParser.Core
  alias AriaEngine.PddlParser.DomainParser
  alias AriaEngine.PddlParser.ProblemParser

  @type parsed_domain_map :: AriaEngine.Domain.Core.t()
  @type parsed_problem_map :: Problem.t()

  @doc """
  Parses a PDDL string based on its type (:domain or :problem).
  """
  @spec parse(:domain, String.t()) :: {:ok, AriaEngine.Domain.Core.t()} | {:error, String.t()}
  @spec parse(:problem, String.t()) :: {:ok, Problem.t()} | {:error, String.t()}
  def parse(:domain, pddl_string), do: parse_domain(pddl_string)
  def parse(:problem, pddl_string), do: parse_problem(pddl_string)
  def parse(type, _pddl_string), do: {:error, "Unknown PDDL type: #{type}"}

  @doc """
  Parses a PDDL domain string into an Elixir map.
  """
  @spec parse_domain(String.t()) :: {:ok, AriaEngine.Domain.Core.t()} | {:error, String.t()}
  def parse_domain(pddl_string) do
    domain_name =
      case Core.parse_pddl_block(pddl_string, "define") do
        {:ok, define_content} ->
          case Core.parse_pddl_block(define_content, "domain") do
            {:ok, name} -> String.trim(name)
            _ -> "unknown_domain"
          end
        _ -> "unknown_domain"
      end

    domain_sections = DomainParser.parse_domain_sections(pddl_string)

    {:ok, Domain.new(
      String.to_atom(domain_name),
      types: domain_sections.types,
      predicates: domain_sections.predicates,
      functions: domain_sections.functions,
      actions: domain_sections.actions,
      tasks: domain_sections.tasks,
      methods: domain_sections.methods
    )}
  end

  @doc """
  Parses a PDDL problem string into an Elixir map containing initial state and goals.
  """
  @spec parse_problem(String.t()) :: {:ok, Problem.t()} | {:error, String.t()}
  def parse_problem(pddl_string) do
    problem_sections = ProblemParser.parse_problem_sections(pddl_string)

    {:ok, Problem.new(
      String.to_atom(problem_sections.name), # Assuming problem_sections has a name
      String.to_atom(problem_sections.domain_name), # Assuming problem_sections has a domain_name
      problem_sections.objects,
      problem_sections.initial_facts,
      problem_sections.goals
    )}
  end
end
