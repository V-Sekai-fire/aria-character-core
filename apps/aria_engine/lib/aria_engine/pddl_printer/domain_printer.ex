defmodule AriaEngine.PddlPrinter.DomainPrinter do
  @moduledoc """
  Provides functions for pretty printing parsed PDDL domain structures.
  """
  alias AriaEngine.Pddl.Domain, as: Domain # Alias Pddl.Domain as Domain
  alias AriaEngine.Pddl.Domain.{Action, Type, Task, Method}
  alias AriaEngine.PddlPrinter.Core

  @doc """
  Formats a PDDL domain struct into a human-readable string.
  """
  @spec format_domain(Domain.t()) :: String.t() # Use Domain.t()
  def format_domain(%Domain{ # Use %Domain{}
        name: name,
        requirements: _requirements,
        types: types,
        predicates: predicates,
        functions: functions,
        actions: actions,
        tasks: tasks,
        methods: methods
      }) do
    """
    (define (domain #{name})
      (:requirements :strips :typing :durative-actions :fluents :adl :derived-predicates :universal-preconditions :conditional-effects :negative-preconditions :disjunctive-preconditions :equality :existential-preconditions :quantified-preconditions :htn)

    #{format_types(types)}

    #{format_predicates(predicates)}

    #{format_functions(functions)}

    #{format_actions(actions)}

    #{format_tasks(tasks)}

    #{format_methods(methods)}
    )
    """
  end

  @spec format_types([Type.t()]) :: String.t()
  defp format_types(types) do
    if Enum.empty?(types), do: "", else: """
      (:types
    #{Enum.map_join(types, "\n", fn %Type{name: name, parent: parent} ->
      parent_str = if parent, do: " - #{Atom.to_string(parent)}", else: ""
      "    #{Atom.to_string(name)}#{parent_str}"
    end)}
      )
    """
  end

  @spec format_predicates([{atom(), [atom()]}]) :: String.t()
  defp format_predicates(predicates) do
    if Enum.empty?(predicates), do: "", else: """
      (:predicates
    #{Enum.map_join(predicates, "\n", fn {name, args} ->
      "    (#{Atom.to_string(name)} #{Enum.map(args, &Atom.to_string/1) |> Enum.join(" ")})"
    end)}
      )
    """
  end

  @spec format_functions([Functions.parsed_function()]) :: String.t()
  defp format_functions(functions) do
    if Enum.empty?(functions), do: "", else: """
      (:functions
    #{Enum.map_join(functions, "\n", fn {name, args} ->
      "    (#{Atom.to_string(name)} #{Enum.map(args, &Atom.to_string/1) |> Enum.join(" ")})"
    end)}
      )
    """
  end

  @spec format_actions([Action.t()]) :: String.t()
  defp format_actions(actions) do
    if Enum.empty?(actions), do: "", else: """
    #{Enum.map_join(actions, "\n", fn %Action{name: name, parameters: parameters, duration: duration, precondition: precondition, effect: effect} ->
      """
      (:durative-action #{Atom.to_string(name)}
        :parameters (#{Core.format_parameters(parameters)})
        :duration (= ?duration #{Core.format_duration(duration)})
        :condition #{Core.format_expression(precondition)}
        :effect #{Core.format_expression(effect)}
      )
      """
    end)}
    """
  end

  @spec format_tasks([Task.t()]) :: String.t()
  defp format_tasks(tasks) do
    if Enum.empty?(tasks), do: "", else: """
    #{Enum.map_join(tasks, "\n", fn %Task{name: name, parameters: parameters} ->
      """
      (:task #{Atom.to_string(name)}
        :parameters (#{Core.format_parameters(parameters)})
      )
      """
    end)}
    """
  end

  @spec format_methods([Method.t()]) :: String.t()
  defp format_methods(methods) do
    if Enum.empty?(methods), do: "", else: """
    #{Enum.map_join(methods, "\n", fn %Method{name: name, parameters: parameters, task: task, subtasks: subtasks, ordering: ordering, constraints: constraints} ->
      """
      (:method #{Atom.to_string(name)}
        :parameters (#{Core.format_parameters(parameters)})
        :task (#{Atom.to_string(task.name)} #{Core.format_parameters(task.parameters)})
        :subtasks (and #{Core.format_subtasks(subtasks)})
        :ordering (and #{Core.format_ordering(ordering)})
        :constraints (and #{Core.format_constraints(constraints)})
      )
      """
    end)}
    """
  end
end
