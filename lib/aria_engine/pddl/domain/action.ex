# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Pddl.Domain.Action do
  @moduledoc """
  Represents a PDDL action.
  """

  alias Pddl.Domain.Parameter

  @type t :: %__MODULE__{
          name: atom(),
          parameters: [Parameter.t()],
          duration: any(), # Added duration field
          precondition: any(), # TODO: Define a proper Expression type
          effect: any() # TODO: Define a proper Expression type
        }

  defstruct [:name, :parameters, :duration, :precondition, :effect]

  @doc """
  Creates a new PDDL Action struct.
  """
  @spec new(atom(), list(), any(), any(), any()) :: t()
  def new(name, parameters, duration, precondition, effect) do
    %__MODULE__{
      name: name,
      parameters: parameters,
      duration: duration,
      precondition: precondition,
      effect: effect
    }
  end
end
