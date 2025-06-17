defmodule AriaEngine.Pddl.Domain.Type do
  @moduledoc """
  Represents a PDDL type.
  """

  @type t :: %__MODULE__{
          name: atom(),
          parent: atom() | nil
        }

  defstruct [:name, :parent]

  @doc """
  Creates a new PDDL Type struct.
  """
  @spec new(atom(), atom() | nil) :: t()
  def new(name, parent \\ nil) do
    %__MODULE__{name: name, parent: parent}
  end
end
