defmodule Multigoal do
  @moduledoc "Represents a collection of goals in the GTPyhop planner.\n\nA multigoal is essentially a desired state represented as a collection of\npredicate-subject-fact triples that should be true in the world state.\n\nExample:\n```elixir\nmultigoal = Multigoal.new()\n|> Multigoal.add_goal(\"player\", \"location\", \"treasure_room\")\n|> Multigoal.add_goal(\"player\", \"has\", \"treasure\")\n\n# Check if goals are satisfied in current state\nsatisfied? = Multigoal.satisfied?(multigoal, current_state)\n```\n"
  alias AriaEngine.State
  @type goal :: {State.subject(), State.predicate(), AriaEngine.State.fact_value()}
  @type t :: %__MODULE__{goals: [goal()]}
  defstruct goals: []
  @doc "Creates a new empty multigoal.\n"
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc "Creates a multigoal from a list of goals.\n"
  @spec new([goal()]) :: t()
  def new(goals) when is_list(goals) do
    %__MODULE__{goals: goals}
  end

  @doc "Creates a multigoal from a StateV2 (all triples become goals).\n"
  @spec from_state(AriaEngine.State.t()) :: t()
  def from_state(%AriaEngine.State{} = state) do
    goals = State.to_triples(state)
    %__MODULE__{goals: goals}
  end

  @doc "Adds a single goal to the multigoal.\n"
  @spec add_goal(t(), State.subject(), State.predicate(), AriaEngine.State.fact_value()) :: t()
  def add_goal(%__MODULE__{goals: goals} = multigoal, subject, predicate, fact_value) do
    new_goal = {subject, predicate, fact_value}
    %{multigoal | goals: [new_goal | goals]}
  end

  @doc "Adds multiple goals to the multigoal.\n"
  @spec add_goals(t(), [goal()]) :: t()
  def add_goals(%__MODULE__{goals: current_goals} = multigoal, new_goals) do
    %{multigoal | goals: new_goals ++ current_goals}
  end

  @doc "Removes a goal from the multigoal.\n"
  @spec remove_goal(t(), State.subject(), State.predicate(), AriaEngine.State.fact_value()) :: t()
  def remove_goal(%__MODULE__{goals: goals} = multigoal, subject, predicate, fact_value) do
    target_goal = {subject, predicate, fact_value}
    filtered_goals = Enum.reject(goals, fn goal -> goal == target_goal end)
    %{multigoal | goals: filtered_goals}
  end

  @doc "Checks if all goals in the multigoal are satisfied by the given state.\n"
  @spec satisfied?(t(), AriaEngine.State.t()) :: boolean()
  def satisfied?(%__MODULE__{goals: goals}, %AriaEngine.State{} = state) do
    Enum.all?(goals, fn {subject, predicate, fact_value} ->
      AriaEngine.State.get_fact(state, subject, predicate) == fact_value
    end)
  end

  @doc "Returns goals that are not yet satisfied in the given state.\n"
  @spec unsatisfied_goals(t(), AriaEngine.State.t()) :: [goal()]
  def unsatisfied_goals(%__MODULE__{goals: goals}, %AriaEngine.State{} = state) do
    Enum.reject(goals, fn {subject, predicate, fact_value} ->
      AriaEngine.State.get_fact(state, subject, predicate) == fact_value
    end)
  end

  @doc "Returns goals that are satisfied in the given state.\n"
  @spec satisfied_goals(t(), AriaEngine.State.t()) :: [goal()]
  def satisfied_goals(%__MODULE__{goals: goals}, %AriaEngine.State{} = state) do
    Enum.filter(goals, fn {subject, predicate, fact_value} ->
      AriaEngine.State.get_fact(state, subject, predicate) == fact_value
    end)
  end

  @doc "Checks if the multigoal is empty (has no goals).\n"
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{goals: goals}) do
    Enum.empty?(goals)
  end

  @doc "Returns the number of goals in the multigoal.\n"
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{goals: goals}) do
    length(goals)
  end

  @doc "Converts the multigoal to a State.\n"
  @spec to_state(t()) :: AriaEngine.State.t()
  def to_state(%__MODULE__{goals: goals}) do
    State.from_triples(goals)
  end

  @doc "Gets all goals as a list.\n"
  @spec to_list(t()) :: [goal()]
  def to_list(%__MODULE__{goals: goals}) do
    goals
  end

  @doc "Gets all goals as a list (alias for to_list for compatibility).\n"
  @spec get_goals(t()) :: [goal()]
  def get_goals(%__MODULE__{goals: goals}) do
    goals
  end

  @doc "Gets all goals as a list (alias for to_list for compatibility).\n"
  @spec to_goals(t()) :: [goal()]
  def to_goals(%__MODULE__{goals: goals}) do
    goals
  end

  @doc "Merges two multigoals, combining their goals.\n"
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{goals: goals1}, %__MODULE__{goals: goals2}) do
    combined_goals = (goals1 ++ goals2) |> Enum.uniq()
    %__MODULE__{goals: combined_goals}
  end

  @doc "Creates a copy of the multigoal.\n"
  @spec copy(t()) :: t()
  def copy(%__MODULE__{goals: goals}) do
    %__MODULE__{goals: List.duplicate(goals, 1) |> List.flatten()}
  end

  @doc "Filters goals based on a predicate function.\n"
  @spec filter(t(), (goal() -> boolean())) :: t()
  def filter(%__MODULE__{goals: goals}, predicate_fn) do
    filtered_goals = Enum.filter(goals, predicate_fn)
    %__MODULE__{goals: filtered_goals}
  end

  @doc "Maps over goals, transforming each one.\n"
  @spec map(t(), (goal() -> goal())) :: t()
  def map(%__MODULE__{goals: goals}, transform_fn) do
    transformed_goals = Enum.map(goals, transform_fn)
    %__MODULE__{goals: transformed_goals}
  end

  @doc "Built-in method to split a multigoal into individual unigoals.\n\nThis method takes a list of goals and returns them as individual\nunigoals to be achieved sequentially. This is useful when no\ndomain-specific multigoal method is available.\n\n## Parameters\n- state: The current planning state\n- goals: A list of goal specifications\n\n## Returns\n- A list of individual goals to be achieved in order\n- `false` if the goals cannot be split or are invalid\n\n## Examples\n\n    iex> state = create_state()\n    iex> goals = [[\"on\", \"a\", \"b\"], [\"on\", \"b\", \"table\"]]\n    iex> Multigoal.split_multigoal(state, goals)\n    [[\"on\", \"a\", \"b\"], [\"on\", \"b\", \"table\"]]\n"
  @spec split_multigoal(AriaEngine.State.t(), list()) :: list() | false
  def split_multigoal(%AriaEngine.State{} = _state, goals) when is_list(goals) do
    valid_goals = Enum.filter(goals, &valid_goal?/1)

    case valid_goals do
      [] -> []
      _ -> valid_goals
    end
  end

  def split_multigoal(%AriaEngine.State{} = _state, _goals) do
    false
  end

  @doc "Check if a goal specification is valid.\n\nA valid goal should be a list with at least one element.\n"
  @spec valid_goal?(term()) :: boolean()
  def valid_goal?(goal) when is_list(goal) and length(goal) > 0 do
    true
  end

  def valid_goal?(_) do
    false
  end
end