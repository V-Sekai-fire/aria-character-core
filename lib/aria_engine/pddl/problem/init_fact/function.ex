# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Pddl.Problem.InitFact.Function do
  @moduledoc """
  Represents a function initial fact in a PDDL problem.
  """

  @type t :: %__MODULE__{
          name: atom(),
          args: [atom()],
          value: integer()
        }

  defstruct [:name, :args, :value]

  @doc """
  Creates a new PDDL Function InitFact struct.
  """
  @spec new(atom(), list(), integer()) :: t()
  def new(name, args, value) do
    %__MODULE__{name: name, args: args, value: value}
  end
end
