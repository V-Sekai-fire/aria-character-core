# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.SolverBehaviour do
  @moduledoc """
  Behaviour for MiniZinc solver implementations.

  This behaviour defines the interface for solving MiniZinc problems,
  allowing for different implementations (real solver, mock solver, etc.)
  following the reverse routing pattern from ADR-176.
  """

  @type problem_data :: %{
    model: String.t(),
    variables: map(),
    constraints: [map()],
    objective: String.t(),
    metadata: map()
  }

  @type options :: %{
    solver_type: :production | :test,
    timeout: non_neg_integer(),
    solver: String.t(),
    variable_count: non_neg_integer()
  }

  @type result :: %{
    status: :success | :error | :timeout,
    solution: map(),
    solve_time_ms: non_neg_integer(),
    raw_output: String.t()
  }

  @callback solve(problem_data(), options()) :: {:ok, result()} | {:error, String.t()}
end
