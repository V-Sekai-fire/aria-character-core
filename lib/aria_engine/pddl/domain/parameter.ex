# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Pddl.Domain.Parameter do
  @moduledoc """
  Represents a parameter in a PDDL action, task, or method.
  """

  @type t :: %__MODULE__{
          name: atom(),
          type: atom()
        }

  defstruct [:name, :type]

  @doc """
  Creates a new PDDL Parameter struct.
  """
  @spec new(atom(), atom()) :: t()
  def new(name, type) do
    %__MODULE__{name: name, type: type}
  end
end
