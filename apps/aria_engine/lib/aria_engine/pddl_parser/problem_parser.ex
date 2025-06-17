defmodule AriaEngine.PddlParser.ProblemParser do
  @moduledoc """
  Parses the problem section of a PDDL string.
  """
  alias AriaEngine.Pddl.Problem
  alias AriaEngine.PddlParser.Core
  alias AriaEngine.PddlParser.ProblemParser.Objects
  alias AriaEngine.PddlParser.ProblemParser.Init
  alias AriaEngine.PddlParser.ProblemParser.Htn

  @type parsed_problem :: Problem.t()

  @spec parse_problem_sections(String.t()) :: Problem.t()
  def parse_problem_sections(pddl_string) do
    problem_name =
      case Core.parse_pddl_block(pddl_string, "define") do
        {:ok, define_content} ->
          case Core.parse_pddl_block(define_content, "problem") do
            {:ok, name} -> String.trim(name)
            _ -> "unknown_problem"
          end
        _ -> "unknown_problem"
      end

    domain_name =
      case Core.parse_pddl_block(pddl_string, ":domain") do
        {:ok, domain_content} -> String.trim(domain_content)
        _ -> "unknown_domain"
      end

    objects_str = Core.parse_pddl_block(pddl_string, ":objects")
    init_str = Core.parse_pddl_block(pddl_string, ":init")
    htn_str = Core.parse_pddl_block(pddl_string, ":htn")

    objects = if elem(objects_str, 0) == :ok, do: Objects.parse_objects(elem(objects_str, 1)), else: []
    initial_facts = if elem(init_str, 0) == :ok, do: Init.parse_init(elem(init_str, 1)), else: []
    goals = if elem(htn_str, 0) == :ok, do: Htn.parse_htn_subtasks(elem(htn_str, 1)), else: []

    Problem.new(
      String.to_atom(problem_name),
      String.to_atom(domain_name),
      objects,
      initial_facts,
      goals
    )
  end
end
