# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Multigoal do
  @moduledoc """
  Represents a collection of goals in the GTPyhop planner.

  A multigoal is essentially a desired state represented as a collection of
  predicate-subject-object triples that should be true in the world state.

  Example:
  ```elixir
  multigoal = AriaEngine.Multigoal.new()
  |> AriaEngine.Multigoal.add_goal("location", "player", "treasure_room")
  |> AriaEngine.Multigoal.add_goal("has", "player", "treasure")

  # Check if goals are satisfied in current state
  satisfied? = AriaEngine.Multigoal.satisfied?(multigoal, current_state)
  ```
  """

  alias AriaEngine.State

  @type goal :: {State.predicate(), State.subject(), State.object()}
  @type t :: %__MODULE__{
    goals: [goal()]
  }

  defstruct goals: []

  @doc """
  Creates a new empty multigoal.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Creates a multigoal from a list of goals.
  """
  @spec new([goal()]) :: t()
  def new(goals) when is_list(goals) do
    %__MODULE__{goals: goals}
  end

  @doc """
  Creates a multigoal from a State (all triples become goals).
  """
  @spec from_state(State.t()) :: t()
  def from_state(%State{} = state) do
    goals = State.to_triples(state)
    %__MODULE__{goals: goals}
  end

  @doc """
  Adds a single goal to the multigoal.
  """
  @spec add_goal(t(), State.predicate(), State.subject(), State.object()) :: t()
  def add_goal(%__MODULE__{goals: goals} = multigoal, predicate, subject, object) do
    new_goal = {predicate, subject, object}
    %{multigoal | goals: [new_goal | goals]}
  end

  @doc """
  Adds multiple goals to the multigoal.
  """
  @spec add_goals(t(), [goal()]) :: t()
  def add_goals(%__MODULE__{goals: current_goals} = multigoal, new_goals) do
    %{multigoal | goals: new_goals ++ current_goals}
  end

  @doc """
  Removes a goal from the multigoal.
  """
  @spec remove_goal(t(), State.predicate(), State.subject(), State.object()) :: t()
  def remove_goal(%__MODULE__{goals: goals} = multigoal, predicate, subject, object) do
    target_goal = {predicate, subject, object}
    filtered_goals = Enum.reject(goals, fn goal -> goal == target_goal end)
    %{multigoal | goals: filtered_goals}
  end

  @doc """
  Checks if all goals in the multigoal are satisfied by the given state.
  """
  @spec satisfied?(t(), State.t()) :: boolean()
  def satisfied?(%__MODULE__{goals: goals}, %State{} = state) do
    Enum.all?(goals, fn {predicate, subject, object} ->
      State.get_object(state, predicate, subject) == object
    end)
  end

  @doc """
  Returns goals that are not yet satisfied in the given state.
  """
  @spec unsatisfied_goals(t(), State.t()) :: [goal()]
  def unsatisfied_goals(%__MODULE__{goals: goals}, %State{} = state) do
    Enum.reject(goals, fn {predicate, subject, object} ->
      State.get_object(state, predicate, subject) == object
    end)
  end

  @doc """
  Returns goals that are satisfied in the given state.
  """
  @spec satisfied_goals(t(), State.t()) :: [goal()]
  def satisfied_goals(%__MODULE__{goals: goals}, %State{} = state) do
    Enum.filter(goals, fn {predicate, subject, object} ->
      State.get_object(state, predicate, subject) == object
    end)
  end

  @doc """
  Checks if the multigoal is empty (has no goals).
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{goals: goals}) do
    Enum.empty?(goals)
  end

  @doc """
  Returns the number of goals in the multigoal.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{goals: goals}) do
    length(goals)
  end

  @doc """
  Converts the multigoal to a State.
  """
  @spec to_state(t()) :: State.t()
  def to_state(%__MODULE__{goals: goals}) do
    State.from_triples(goals)
  end

  @doc """
  Gets all goals as a list.
  """
  @spec to_list(t()) :: [goal()]
  def to_list(%__MODULE__{goals: goals}) do
    goals
  end

  @doc """
  Gets all goals as a list (alias for to_list for compatibility).
  """
  @spec get_goals(t()) :: [goal()]
  def get_goals(%__MODULE__{goals: goals}) do
    goals
  end

  @doc """
  Merges two multigoals, combining their goals.
  """
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{goals: goals1}, %__MODULE__{goals: goals2}) do
    # Remove duplicates when merging
    combined_goals = (goals1 ++ goals2) |> Enum.uniq()
    %__MODULE__{goals: combined_goals}
  end

  @doc """
  Creates a copy of the multigoal.
  """
  @spec copy(t()) :: t()
  def copy(%__MODULE__{goals: goals}) do
    %__MODULE__{goals: List.duplicate(goals, 1) |> List.flatten()}
  end

  @doc """
  Filters goals based on a predicate function.
  """
  @spec filter(t(), (goal() -> boolean())) :: t()
  def filter(%__MODULE__{goals: goals}, predicate_fn) do
    filtered_goals = Enum.filter(goals, predicate_fn)
    %__MODULE__{goals: filtered_goals}
  end

  @doc """
  Maps over goals, transforming each one.
  """
  @spec map(t(), (goal() -> goal())) :: t()
  def map(%__MODULE__{goals: goals}, transform_fn) do
    transformed_goals = Enum.map(goals, transform_fn)
    %__MODULE__{goals: transformed_goals}
  end

  @doc """
  Built-in method to split a multigoal into individual unigoals.

  This method takes a list of goals and returns them as individual
  unigoals to be achieved sequentially. This is useful when no
  domain-specific multigoal method is available.

  ## Parameters
  - state: The current planning state
  - goals: A list of goal specifications

  ## Returns
  - A list of individual goals to be achieved in order
  - `false` if the goals cannot be split or are invalid

  ## Examples

      iex> state = AriaEngine.create_state()
      iex> goals = [["on", "a", "b"], ["on", "b", "table"]]
      iex> AriaEngine.Multigoal.split_multigoal(state, goals)
      [["on", "a", "b"], ["on", "b", "table"]]
  """
  def split_multigoal(%State{} = _state, goals) when is_list(goals) do
    # Filter out any nil or invalid goals
    valid_goals = Enum.filter(goals, &valid_goal?/1)

    case valid_goals do
      [] -> []
      _ -> valid_goals
    end
  end

  def split_multigoal(%State{} = _state, _goals), do: false

  @doc """
  Check if a goal specification is valid.

  A valid goal should be a list with at least one element.
  """
  def valid_goal?(goal) when is_list(goal) and length(goal) > 0, do: true
  def valid_goal?(_), do: false
end
