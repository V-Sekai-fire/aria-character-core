defmodule AriaEngine.Pddl.Domain do
  @moduledoc """
  Represents a PDDL/HDDL domain structure.
  """

  # Alias for nested structs used within Domain
  alias AriaEngine.Pddl.Domain.{Action, Type, Task, Method}

  @type t :: %__MODULE__{
          name: atom(),
          requirements: [atom()],
          types: [Type.t()],
          predicates: [{atom(), [atom()]}],
          functions: [{atom(), [atom()]}],
          actions: [Action.t()],
          tasks: [Task.t()],
          methods: [Method.t()]
        }

  defstruct [
    :name,
    :requirements,
    :types,
    :predicates,
    :functions,
    :actions,
    :tasks,
    :methods
  ]

  @doc """
  Creates a new PDDL Domain struct.
  """
  @spec new(atom(), keyword()) :: t()
  def new(name, opts \\ []) do
    %__MODULE__{
      name: name,
      requirements: Keyword.get(opts, :requirements, []),
      types: Keyword.get(opts, :types, []),
      predicates: Keyword.get(opts, :predicates, []),
      functions: Keyword.get(opts, :functions, []),
      actions: Keyword.get(opts, :actions, []),
      tasks: Keyword.get(opts, :tasks, []),
      methods: Keyword.get(opts, :methods, [])
    }
  end
end
