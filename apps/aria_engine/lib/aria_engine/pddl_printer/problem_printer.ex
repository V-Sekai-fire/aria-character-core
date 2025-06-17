defmodule AriaEngine.PddlPrinter.ProblemPrinter do
  @moduledoc """
  Provides functions for pretty printing parsed PDDL problem structures.
  """
  alias AriaEngine.PddlParser.ProblemParser.Objects
  alias AriaEngine.PddlParser.ProblemParser.Init
  alias AriaEngine.PddlParser.ProblemParser.Htn
  alias AriaEngine.PddlPrinter.Core

  @doc """
  Formats a parsed PDDL problem map into a human-readable string.
  """
  @spec format_problem(AriaEngine.PddlParser.parsed_problem_map()) :: String.t()
  def format_problem(%{
        objects: objects,
        initial_facts: initial_facts,
        goals: goals
      }) do
    """
    (define (problem satellite-problem)
      (:domain satellite) ; Assuming domain name is 'satellite' for now

    #{format_objects(objects)}

    #{format_initial_facts(initial_facts)}

    #{format_goals(goals)}
    )
    """
  end

  @spec format_objects([Objects.parsed_object()]) :: String.t()
  defp format_objects(objects) do
    if Enum.empty?(objects), do: "", else: """
      (:objects
    #{Enum.map_join(objects, "\n", fn {name, type} ->
      "    #{Core.to_string_if_atom(name)} - #{Core.to_string_if_atom(type)}"
    end)}
      )
    """
  end

  @spec format_initial_facts([Init.parsed_fact()]) :: String.t()
  defp format_initial_facts(facts) do
    if Enum.empty?(facts), do: "", else: """
      (:init
    #{Enum.map_join(facts, "\n", fn fact ->
      Core.format_initial_fact_item(fact)
    end)}
      )
    """
  end

  @spec format_goals([Htn.parsed_task_item()]) :: String.t()
  defp format_goals(goals) do
    if Enum.empty?(goals), do: "", else: """
      (:htn
        :parameters () ; Assuming no parameters for problem goals
        :subtasks (and
    #{Core.format_subtasks(goals)}
        )
      )
    """
  end
end
