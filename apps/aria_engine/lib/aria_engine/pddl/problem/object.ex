# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Pddl.Problem.Object do
  @moduledoc """
  Represents an object in a PDDL problem.
  """

  @type t :: %__MODULE__{
          name: atom(),
          type: atom()
        }

  defstruct [:name, :type]

  @doc """
  Creates a new PDDL Object struct.
  """
  @spec new(atom(), atom()) :: t()
  def new(name, type) do
    %__MODULE__{name: name, type: type}
  end
end
