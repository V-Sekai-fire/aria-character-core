# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZincTest do
  use ExUnit.Case
  doctest AriaMiniZinc

  describe "AriaMiniZinc main API" do
    test "check_availability returns status" do
      result = AriaMiniZinc.check_availability()
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "available_solvers returns list" do
      solvers = AriaMiniZinc.available_solvers()
      assert is_list(solvers)
      assert :fixpoint in solvers
    end

    test "validate_model with valid model" do
      model = "constraint true; solve satisfy;"
      assert AriaMiniZinc.validate_model(model) == :ok
    end

    test "validate_model with invalid model" do
      model = ""
      assert {:error, _reason} = AriaMiniZinc.validate_model(model)
    end
  end

  describe "problem generation and solving" do
    test "generate_problem creates valid problem data" do
      domain = %{name: "test_domain"}
      state = %{entities: ["entity1", "entity2"]}
      goals = [{"entity1", "location", "room1"}, {"entity2", "state", "active"}]

      {:ok, problem_data} = AriaMiniZinc.generate_problem(domain, state, goals)

      assert is_map(problem_data)
      assert Map.has_key?(problem_data, :model)
      assert Map.has_key?(problem_data, :variables)
      assert Map.has_key?(problem_data, :constraints)
      assert Map.has_key?(problem_data, :metadata)
    end

    test "solve with generated problem returns solution" do
      domain = %{name: "test_domain"}
      state = %{entities: ["entity1"]}
      goals = [{"entity1", "location", "room1"}]

      {:ok, problem_data} = AriaMiniZinc.generate_problem(domain, state, goals)
      {:ok, solution} = AriaMiniZinc.solve(problem_data)

      assert is_map(solution)
      assert Map.has_key?(solution, :status)
      assert Map.has_key?(solution, :assignments)
      assert Map.has_key?(solution, :solving_time)
    end

    test "solve with timeout option" do
      domain = %{name: "test_domain"}
      state = %{entities: ["entity1"]}
      goals = [{"entity1", "location", "room1"}]

      {:ok, problem_data} = AriaMiniZinc.generate_problem(domain, state, goals)
      {:ok, solution} = AriaMiniZinc.solve(problem_data, %{timeout: 5000})

      assert solution.status == :optimal
    end
  end

  describe "direct execution" do
    test "exec with invalid template returns error" do
      result = AriaMiniZinc.exec("nonexistent_template")
      assert {:error, _reason} = result
    end
  end
end
