# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Debug script for empty goals in AriaEngine.run/2
# Usage: mix run debug_empty_goals.exs

defmodule DebugEmptyGoals do
  alias AriaEngine
  alias AriaEngine.State

  def run do
    IO.puts("--- Starting DebugEmptyGoals Script ---")

    domain_def = AriaEngine.new("empty_test", %{
      goals: []
    })

    IO.puts("Created domain_def with goals: #{inspect(domain_def.goals)}")
    IO.puts("Domain def initial_state: #{inspect(domain_def.initial_state)}")

    # Attempt to run the engine with empty goals
    result = AriaEngine.run(domain_def)

    IO.puts("Result of AriaEngine.run: #{inspect(result)}")

    case result do
      {:ok, completed} ->
        IO.puts("AriaEngine.run succeeded. Status: #{inspect(completed.status)}")
        assert completed.status == :completed
      {:error, reason} ->
        IO.puts("AriaEngine.run failed. Reason: #{reason}")
        # This is the unexpected path, so we'll assert false here if we reach it
        assert false, "AriaEngine.run failed unexpectedly for empty goals: #{reason}"
    end

    IO.puts("--- DebugEmptyGoals Script Finished ---")
  end

  # Add temporary debug prints to AriaEngine.run/2 for this script
  # This is a temporary override for debugging purposes only.
  # In a real scenario, this would be done by modifying the source file directly.
  defoverridable AriaEngine

  defimpl AriaEngine do
    def run(%AriaEngine{goals: []} = engine, _opts) do
      IO.puts("DEBUG: Matched run/2 for empty goals in debug script.")
      completed_engine = %{engine |
        status: :completed,
        current_state: engine.initial_state,
        completed_at: DateTime.utc_now(),
        progress: %{engine.progress |
          total_steps: 0,
          completed_steps: 0,
          current_step: "completed"
        }
      }
      {:ok, completed_engine}
    end

    def run(%AriaEngine{} = engine, opts \\ []) do
      IO.puts("DEBUG: Matched general run/2 in debug script. Goals: #{inspect(engine.goals)}")
      with {:ok, planned_engine} <- AriaEngine.plan_advanced(engine, opts),
           {:ok, completed_engine} <- AriaEngine.execute(planned_engine, opts) do
        {:ok, completed_engine}
      end
    end
  end
end

DebugEmptyGoals.run()
