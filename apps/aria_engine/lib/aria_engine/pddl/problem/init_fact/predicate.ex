defmodule AriaEngine.Pddl.Problem.InitFact.Predicate do
  @moduledoc """
  Represents a predicate initial fact in a PDDL problem.
  """

  @type t :: %__MODULE__{
          name: atom(),
          args: [atom()]
        }

  defstruct [:name, :args]

  @doc """
  Creates a new PDDL Predicate InitFact struct.
  """
  @spec new(atom(), list()) :: t()
  def new(name, args) do
    %__MODULE__{name: name, args: args}
  end
end
