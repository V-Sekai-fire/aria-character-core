defmodule AriaEngine.HybridPlanner.Strategies.SatCp do
  @moduledoc """
  SAT-CP Mock Strategy - Simple CP-SAT Interface Mock

  This provides a mock interface for the OptimizerStrategy behavior
  that will eventually integrate with Exhort OR-Tools for solving
  MiniZinc 2024 competition problems using CP-SAT solver.

  This is NOT for schedule activities - it's for constraint programming problems.
  """

  @behaviour AriaEngine.HybridPlanner.OptimizerStrategy

  @impl true
  def solve(problem, _options \\ []) do
    # Mock CP-SAT solver response for MiniZinc-style problems
    {:ok, %{
      status: "OPTIMAL",
      solver: "CP-SAT (Mock)",
      objective_value: 42,
      variables: %{
        "x1" => 1,
        "x2" => 2,
        "x3" => 3
      },
      solve_time_ms: 100
    }}
  end

  @impl true
  def validate_problem(problem) do
    if is_map(problem) do
      :ok
    else
      {:error, "Problem must be a map"}
    end
  end
end
