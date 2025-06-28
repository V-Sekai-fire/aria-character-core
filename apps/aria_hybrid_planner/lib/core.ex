# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Core do
  @moduledoc """
  Local Core module for aria_hybrid_planner to replace AriaEngine.Core dependency.
  """

  defstruct [
    :actions,
    :task_methods,
    :unigoal_methods,
    :multigoal_methods,
    :solution_tree
  ]

  @type t :: %__MODULE__{
          actions: map(),
          task_methods: map(),
          unigoal_methods: map(),
          multigoal_methods: map(),
          solution_tree: map() | nil
        }
end
