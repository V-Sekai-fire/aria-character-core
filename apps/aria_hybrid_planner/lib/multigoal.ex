# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Multigoal do
  @moduledoc """
  Local Multigoal module for aria_hybrid_planner to replace AriaEngine.Multigoal dependency.
  """

  defstruct [
    :goals,
    :strategy,
    :metadata
  ]

  @type t :: %__MODULE__{
          goals: [term()],
          strategy: atom(),
          metadata: map()
        }

  @doc """
  Create a new multigoal with the given goals.
  """
  @spec new([term()]) :: t()
  def new(goals) when is_list(goals) do
    %__MODULE__{
      goals: goals,
      strategy: :all,
      metadata: %{}
    }
  end

  @doc """
  Check if all goals in the multigoal are satisfied in the given state.
  """
  @spec satisfied?(t(), State.t()) :: boolean()
  def satisfied?(multigoal, state) do
    Enum.all?(multigoal.goals, fn goal ->
      goal_satisfied?(goal, state)
    end)
  end

  @doc """
  Get the list of unsatisfied goals from the multigoal.
  """
  @spec unsatisfied_goals(t(), State.t()) :: [term()]
  def unsatisfied_goals(multigoal, state) do
    Enum.reject(multigoal.goals, fn goal ->
      goal_satisfied?(goal, state)
    end)
  end

  # Private helper functions

  defp goal_satisfied?({predicate, subject, value}, state) when is_binary(predicate) and is_binary(subject) do
    case State.get_fact(state, subject, predicate) do
      ^value -> true
      _ -> false
    end
  end

  defp goal_satisfied?(goal, _state) do
    # For other goal types, assume not satisfied for now
    # This can be extended based on actual goal formats used
    false
  end
end
