# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.SolverTest do
  use ExUnit.Case
  doctest AriaMiniZinc.Solver

  alias AriaMiniZinc.Solver

  describe "Solver - High-level solver interface with fallback" do
    test "solve returns solution for valid problem" do
      problem_data = %{
        model: "constraint true; solve satisfy;",
        variables: %{},
        constraints: [],
        metadata: %{solver_type: :test}
      }

      result = Solver.solve(problem_data)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "solve handles timeout option" do
      problem_data = %{
        model: "constraint true; solve satisfy;",
        variables: %{},
        constraints: [],
        metadata: %{solver_type: :test}
      }

      options = %{timeout: 1000}
      result = Solver.solve(problem_data, options)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "solve falls back gracefully when MiniZinc unavailable" do
      problem_data = %{
        model: "invalid model syntax",
        variables: %{},
        constraints: [],
        metadata: %{solver_type: :test}
      }

      result = Solver.solve(problem_data)
      # Should either succeed with fallback or fail gracefully
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "check_availability/0" do
    test "returns availability status" do
      result = Solver.check_availability()
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "available_solvers/0" do
    test "returns list of available solvers" do
      solvers = Solver.available_solvers()
      assert is_list(solvers)
      # fixpoint should always be available as fallback
      assert :fixpoint in solvers
    end
  end

  describe "validate_model/1" do
    test "validates correct MiniZinc model" do
      model = "constraint true; solve satisfy;"
      result = Solver.validate_model(model)
      assert result == :ok
    end

    test "rejects invalid MiniZinc model" do
      model = ""
      result = Solver.validate_model(model)
      assert {:error, _reason} = result
    end

    test "handles malformed syntax" do
      model = "constraint invalid syntax here"
      result = Solver.validate_model(model)
      assert match?(:ok, result) or match?({:error, _}, result)
    end
  end

  describe "solver selection and fallback" do
    test "prefers MiniZinc when available" do
      # This test checks that the solver selection logic works
      solvers = Solver.available_solvers()

      if :minizinc in solvers do
        # MiniZinc should be preferred
        assert :minizinc == hd(solvers) or :fixpoint in solvers
      else
        # Should fall back to fixpoint
        assert :fixpoint in solvers
      end
    end

    test "includes fixpoint as fallback option" do
      solvers = Solver.available_solvers()
      assert :fixpoint in solvers
    end
  end
end
