# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Multigoal do
  @moduledoc """
  Local Multigoal module for aria_hybrid_planner to replace AriaEngine.Multigoal dependency.
  """

  defstruct [
    :goals,
    :strategy,
    :metadata
  ]

  @type t :: %__MODULE__{
          goals: [term()],
          strategy: atom(),
          metadata: map()
        }
end
