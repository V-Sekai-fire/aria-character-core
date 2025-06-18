# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Pddl.Problem do
  @moduledoc """
  Represents a PDDL/HDDL problem structure.
  """

  alias AriaEngine.Pddl.Problem.{Object, InitFact, Goal}

  @type t :: %__MODULE__{
          name: atom(),
          domain_name: atom(),
          objects: [Object.t()],
          initial_facts: [InitFact.t()],
          goals: [Goal.t()]
        }

  defstruct [
    :name,
    :domain_name,
    :objects,
    :initial_facts,
    :goals
  ]

  @doc """
  Creates a new PDDL Problem struct.
  """
  @spec new(atom(), atom(), list(), list(), list()) :: t()
  def new(name, domain_name, objects, initial_facts, goals) do
    %__MODULE__{
      name: name,
      domain_name: domain_name,
      objects: objects,
      initial_facts: initial_facts,
      goals: goals
    }
  end
end
