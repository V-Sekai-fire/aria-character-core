# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Domain.Core do
  @moduledoc """
  Local Domain.Core module for aria_hybrid_planner to replace AriaEngine.Domain.Core dependency.
  """

  defstruct [
    :name,
    :actions,
    :task_methods,
    :unigoal_methods,
    :multigoal_methods
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          actions: map(),
          task_methods: map(),
          unigoal_methods: map(),
          multigoal_methods: map()
        }
end
