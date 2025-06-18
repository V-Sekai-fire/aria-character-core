# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Pddl.Domain.Task do
  @moduledoc """
  Represents a PDDL task.
  """

  alias Pddl.Domain.Parameter

  @type t :: %__MODULE__{
          name: atom(),
          parameters: [Parameter.t()]
        }

  defstruct [:name, :parameters]

  @doc """
  Creates a new PDDL Task struct.
  """
  @spec new(atom(), list()) :: t()
  def new(name, parameters) do
    %__MODULE__{name: name, parameters: parameters}
  end
end
