# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Pddl.Problem.InitFact do
  @moduledoc """
  Container module for PDDL initial facts (predicates and functions).
  """

  alias Pddl.Problem.InitFact.{Predicate, Function}

  @type t :: Predicate.t() | Function.t()
end
