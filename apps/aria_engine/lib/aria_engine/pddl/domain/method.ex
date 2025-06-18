# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Pddl.Domain.Method do
  @moduledoc """
  Represents a PDDL method.
  """

  alias AriaEngine.Pddl.Domain.{Parameter, Task}

  @type t :: %__MODULE__{
          name: atom(),
          task: Task.t(),
          parameters: [Parameter.t()],
          constraints: any(), # TODO: Define a proper Expression type
          ordering: list(),
          subtasks: [Task.t()]
        }

  defstruct [:name, :task, :parameters, :constraints, :ordering, :subtasks]

  @doc """
  Creates a new PDDL Method struct.
  """
  @spec new(atom(), Task.t(), list(), any(), list(), list()) :: t()
  def new(name, task, parameters, constraints, ordering, subtasks) do
    %__MODULE__{
      name: name,
      task: task,
      parameters: parameters,
      constraints: constraints,
      ordering: ordering,
      subtasks: subtasks
    }
  end
end
