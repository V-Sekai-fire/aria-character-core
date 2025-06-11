defmodule AriaWorkflow.Multigoal do
  defmodule AriaWorkflow.Multigoal do
  @moduledoc """
  Simple multigoal implementation for SOP planning.
  This is a lightweight version that doesn't depend on external AriaEngine modules.
  """

  defstruct goals: []

  @type t :: %__MODULE__{
    goals: list()
  }

  @doc """
  Create a new empty multigoal.
  """
  @spec new() :: t()
  def new() do
    %__MODULE__{goals: []}
  end

  @doc """
  Add a goal to the multigoal.
  """
  @spec add_goal(t(), term(), term(), term()) :: t()
  def add_goal(%__MODULE__{goals: goals} = multigoal, predicate, subject, object) do
    goal = {predicate, subject, object}
    %{multigoal | goals: [goal | goals]}
  end

  @doc """
  Get all goals from the multigoal.
  """
  @spec get_goals(t()) :: list()
  def get_goals(%__MODULE__{goals: goals}) do
    Enum.reverse(goals)
  end
end
