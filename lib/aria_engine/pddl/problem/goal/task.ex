# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Pddl.Problem.Goal.Task do
  @moduledoc """
  Represents a task goal in a PDDL problem.
  """

  @type t :: %__MODULE__{
          name: atom(),
          args: [atom()]
        }

  defstruct [:name, :args]

  @doc """
  Creates a new PDDL Task Goal struct.
  """
  @spec new(atom(), list()) :: t()
  def new(name, args) do
    %__MODULE__{name: name, args: args}
  end
end
