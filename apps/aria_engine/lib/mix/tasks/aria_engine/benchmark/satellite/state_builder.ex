# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.AriaEngine.Benchmark.Satellite.StateBuilder do
  @moduledoc "Builds the AriaEngine State for the Satellite benchmark."

  alias AriaEngine.State
  # Removed alias AriaEngine.PddlParser

  @type parsed_problem_map :: AriaEngine.PddlParser.parsed_problem_map()

  @spec build_aria_state(parsed_problem_map()) :: State.t()
  def build_aria_state(parsed_problem) do
    state = State.new()

    # Add initial facts
    state = Enum.reduce(parsed_problem.initial_facts, state, fn fact, acc_state ->
      case fact do
        {:assign, {func_name, func_args}, value} ->
          # Handle numeric fluents, e.g., (= (calibration-time instrument0) 20)
          # Store as a fact for now, e.g., {"calibration-time", "instrument0"} -> 20
          subject = Enum.map_join(func_args, "_", &Atom.to_string/1)
          State.set_fact(acc_state, Atom.to_string(func_name), subject, value)
        {predicate, args} ->
          # Handle boolean predicates, e.g., (on_board instrument0 satellite0)
          # Store as {"on_board", "instrument0_satellite0"} -> true
          subject = Enum.map_join(args, "_", &Atom.to_string/1)
          State.set_fact(acc_state, Atom.to_string(predicate), subject, true)
      end
    end)

    state
  end
end
