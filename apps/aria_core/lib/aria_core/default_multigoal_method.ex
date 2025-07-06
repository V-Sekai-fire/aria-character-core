# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.DefaultMultigoalMethod do
  @moduledoc """
  Default multigoal method implementation following IPyHOP pattern.

  This implements the standard IPyHOP multigoal decomposition strategy:
  1. Find the first unachieved goal in the multigoal
  2. Return [goal, multigoal] to work on that goal then continue with multigoal
  3. Return [] when all goals are achieved

  This follows the recursive pattern from IPyHOP's blocks world example:
  ```python
  def mgm_move_blocks(state, multigoal):
      # Find a goal that needs work
      for goal in unachieved_goals:
          return [goal, multigoal]  # Work on goal, then multigoal again
      return []  # All goals achieved
  ```
  """

  require Logger

  @doc """
  Default multigoal method following IPyHOP recursive pattern.

  This method receives the complete multigoal object and returns either:
  - `[]` if all goals are satisfied (completion)
  - `[goal, multigoal]` to work on one goal then continue with multigoal

  ## Parameters

  - `state`: Current planning state
  - `multigoal`: Complete multigoal object with list of goals

  ## Returns

  - `[]` when all goals are achieved
  - `[{predicate, subject, value}, multigoal]` to work on first unachieved goal

  ## Examples

      iex> state = AriaState.new()
      iex> state = AriaState.set_fact(state, "pos", "a", "table")
      iex> multigoal = %{goals: [{"pos", "a", "b"}, {"pos", "b", "table"}]}
      iex> AriaCore.DefaultMultigoalMethod.default_multigoal_method(state, multigoal)
      [{"pos", "a", "b"}, multigoal]
  """
  @spec default_multigoal_method(map(), map()) :: list()
  def default_multigoal_method(state, multigoal) do
    case find_unachieved_goal(state, multigoal.goals) do
      nil ->
        # All goals achieved - return empty list (IPyHOP completion pattern)
        []

      goal ->
        # Found unachieved goal - return [goal, multigoal] (IPyHOP recursive pattern)
        [goal, multigoal]
    end
  end

  @doc """
  Find the first unachieved goal in the list.

  Iterates through goals in order and returns the first one that is not
  satisfied in the current state.

  ## Parameters

  - `state`: Current planning state
  - `goals`: List of goals as {predicate, subject, value} tuples

  ## Returns

  - `nil` if all goals are satisfied
  - `{predicate, subject, value}` for first unachieved goal
  """
  @spec find_unachieved_goal(map(), list()) :: {String.t(), String.t(), String.t()} | nil
  def find_unachieved_goal(state, goals) do
    Enum.find(goals, fn {predicate, subject, value} ->
      not AriaState.matches?(state, predicate, subject, value)
    end)
  end

  @doc """
  Check if all goals in a multigoal are achieved.

  ## Parameters

  - `state`: Current planning state
  - `multigoal`: Multigoal object to check

  ## Returns

  - `true` if all goals are satisfied
  - `false` if any goal is not satisfied
  """
  @spec all_goals_achieved?(map(), map()) :: boolean()
  def all_goals_achieved?(state, multigoal) do
    Enum.all?(multigoal.goals, fn {predicate, subject, value} ->
      AriaState.matches?(state, predicate, subject, value)
    end)
  end

  @doc """
  Get list of unachieved goals from a multigoal.

  ## Parameters

  - `state`: Current planning state
  - `multigoal`: Multigoal object to analyze

  ## Returns

  - List of unachieved goals as {predicate, subject, value} tuples
  """
  @spec get_unachieved_goals(map(), map()) :: list()
  def get_unachieved_goals(state, multigoal) do
    Enum.reject(multigoal.goals, fn {predicate, subject, value} ->
      AriaState.matches?(state, predicate, subject, value)
    end)
  end

  @doc """
  Register the default multigoal method with a domain.

  This adds the default multigoal method to the domain's multigoal methods list.
  The method will be tried when no domain-specific multigoal methods are available.

  ## Parameters

  - `domain`: Domain to register with

  ## Returns

  - Updated domain with default multigoal method registered
  """
  @spec register_with_domain(map()) :: map()
  def register_with_domain(domain) do
    AriaCore.add_multigoal_method_to_domain(domain, "default_multigoal_method", &default_multigoal_method/2)
  end
end
