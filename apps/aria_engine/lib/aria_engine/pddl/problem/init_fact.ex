# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Pddl.Problem.InitFact do
  @moduledoc """
  Container module for PDDL initial facts (predicates and functions).
  """

  alias AriaEngine.Pddl.Problem.InitFact.{Predicate, Function}

  @type t :: Predicate.t() | Function.t()
end
