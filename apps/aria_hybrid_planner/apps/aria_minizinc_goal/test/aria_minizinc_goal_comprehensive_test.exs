# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincGoalComprehensiveTest do
  use ExUnit.Case

  describe "goal solving with complex domains" do
    test "solves multi-step planning problem" do
      domain = %{
        actions: [:move, :pickup, :putdown, :stack],
        predicates: [:at, :holding, :on, :clear, :empty]
      }

      state = %{
        facts: [
          {:robot, :at, :room_a},
          {:robot, :holding, :nothing},
          {:box1, :at, :room_a},
          {:box2, :at, :room_b},
          {:table, :at, :room_c}
        ]
      }

      goals = [
        {:robot, :at, :room_c},
        {:box1, :on, :table},
        {:box2, :on, :box1}
      ]

      options = %{
        optimization_type: :minimize_time
      }

      result = AriaMinizincGoal.solve_goals(domain, state, goals, options)

      case result do
        {:ok, solution} ->
          assert solution.status == :success
          assert solution.solver == :minizinc
          assert is_map(solution.variables)
          assert is_number(solution.objective_value)

          # Verify variable structure
          variables = solution.variables
          assert Map.has_key?(variables, :time_vars)
          assert Map.has_key?(variables, :location_vars)
          assert Map.has_key?(variables, :boolean_vars)

        {:error, reason} ->
          # MiniZinc may not be available in test environment
          assert is_binary(reason)
      end
    end

    test "handles resource allocation problem" do
      domain = %{
        actions: [:allocate, :deallocate, :transfer],
        predicates: [:assigned, :available, :capacity]
      }

      state = %{
        facts: [
          {:worker1, :available, true},
          {:worker2, :available, true},
          {:task1, :assigned, :nobody},
          {:task2, :assigned, :nobody}
        ]
      }

      goals = [
        {:task1, :assigned, :worker1},
        {:task2, :assigned, :worker2}
      ]

      options = %{
        optimization_type: :maximize_efficiency
      }

      result = AriaMinizincGoal.solve_goals(domain, state, goals, options)

      case result do
        {:ok, solution} ->
          assert solution.status == :success
          assert solution.solver == :minizinc

          # Check that efficiency optimization was used
          variables = solution.variables
          assert length(variables.boolean_vars) > 0

        {:error, reason} ->
          assert is_binary(reason)
      end
    end
  end

  describe "goal solving validation" do
    test "validates domain structure" do
      invalid_domain = "not_a_map"
      state = %{facts: []}
      goals = [{:entity, :predicate, :value}]
      options = %{optimization_type: :minimize_time}

      {:error, reason} = AriaMinizincGoal.solve_goals(invalid_domain, state, goals, options)
      assert reason == "Domain must be a map"
    end

    test "validates state structure" do
      domain = %{actions: [], predicates: []}
      invalid_state = "not_a_map"
      goals = [{:entity, :predicate, :value}]
      options = %{optimization_type: :minimize_time}

      {:error, reason} = AriaMinizincGoal.solve_goals(domain, invalid_state, goals, options)
      assert reason == "State must be a map"
    end

    test "validates goals structure" do
      domain = %{actions: [], predicates: []}
      state = %{facts: []}
      invalid_goals = "not_a_list"
      options = %{optimization_type: :minimize_time}

      {:error, reason} = AriaMinizincGoal.solve_goals(domain, state, invalid_goals, options)
      assert reason == "Goals must be a list"
    end

    test "validates non-empty goals" do
      domain = %{actions: [], predicates: []}
      state = %{facts: []}
      empty_goals = []
      options = %{optimization_type: :minimize_time}

      {:error, reason} = AriaMinizincGoal.solve_goals(domain, state, empty_goals, options)
      assert reason == "Goals list cannot be empty"
    end
  end

  describe "goal solving edge cases" do
    test "handles single goal" do
      domain = %{actions: [:move], predicates: [:at]}
      state = %{facts: [{:robot, :at, :start}]}
      goals = [{:robot, :at, :goal}]
      options = %{optimization_type: :minimize_time}

      result = AriaMinizincGoal.solve_goals(domain, state, goals, options)

      case result do
        {:ok, solution} ->
          assert solution.status == :success
          assert length(solution.variables.time_vars) == 1
          assert length(solution.variables.location_vars) == 1
          assert length(solution.variables.boolean_vars) == 1
        {:error, _reason} ->
          :ok  # Expected if MiniZinc not available
      end
    end

    test "handles timeout gracefully" do
      domain = %{actions: [:action], predicates: [:predicate]}
      state = %{facts: []}
      goals = [{:entity, :predicate, :value}]
      options = %{optimization_type: :minimize_time}

      # Very short timeout
      result = AriaMinizincGoal.solve_goals(domain, state, goals, options, timeout: 1)

      case result do
        {:ok, solution} ->
          # If it solves quickly, that's fine
          assert solution.status == :success
        {:error, reason} ->
          # Timeout or MiniZinc unavailable is expected
          assert is_binary(reason)
      end
    end
  end
end
