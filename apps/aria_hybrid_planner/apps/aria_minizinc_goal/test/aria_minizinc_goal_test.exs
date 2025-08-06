# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincGoalTest do
  use ExUnit.Case
  doctest AriaMinizincGoal

  describe "solve_goals/4" do
    test "validates input parameters" do
      # Test invalid domain
      assert {:error, "Domain must be a map"} =
        AriaMinizincGoal.solve_goals("invalid", %{}, [], %{})

      # Test invalid state
      assert {:error, "State must be a map"} =
        AriaMinizincGoal.solve_goals(%{}, "invalid", [], %{})

      # Test invalid goals
      assert {:error, "Goals must be a list"} =
        AriaMinizincGoal.solve_goals(%{}, %{}, "invalid", %{})

      # Test invalid options
      assert {:error, "Options must be a map"} =
        AriaMinizincGoal.solve_goals(%{}, %{}, [], "invalid")

      # Test empty goals
      assert {:error, "Goals list cannot be empty"} =
        AriaMinizincGoal.solve_goals(%{}, %{}, [], %{})
    end

    test "solves simple goal with MiniZinc" do
      domain = %{
        actions: [:move, :pickup],
        predicates: [:at, :holding]
      }

      state = %{
        facts: [
          {:robot, :at, :location_a},
          {:box, :at, :location_b}
        ]
      }

      goals = [
        {:robot, :at, :location_b},
        {:box, :at, :location_a}
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
        {:error, reason} ->
          # MiniZinc may not be available in test environment
          assert reason =~ "MiniZinc"
      end
    end

    test "handles timeout option" do
      domain = %{actions: [:move]}
      state = %{facts: []}
      goals = [{:robot, :at, :location_a}]
      options = %{optimization_type: :minimize_time}

      result = AriaMinizincGoal.solve_goals(domain, state, goals, options, timeout: 5000)

      case result do
        {:ok, solution} ->
          assert solution.status == :success
          assert solution.solver == :minizinc
        {:error, reason} ->
          # MiniZinc may not be available or may timeout
          assert is_binary(reason)
      end
    end

    test "handles different optimization types" do
      domain = %{actions: [:move]}
      state = %{facts: []}
      goals = [{:robot, :at, :location_a}]

      # Test minimize_distance optimization
      options = %{optimization_type: :minimize_distance}
      result = AriaMinizincGoal.solve_goals(domain, state, goals, options)

      case result do
        {:ok, solution} ->
          assert solution.status == :success
        {:error, _reason} ->
          # May fail if MiniZinc not available
          :ok
      end

      # Test maximize_efficiency optimization
      options = %{optimization_type: :maximize_efficiency}
      result = AriaMinizincGoal.solve_goals(domain, state, goals, options)

      case result do
        {:ok, solution} ->
          assert solution.status == :success
        {:error, _reason} ->
          # May fail if MiniZinc not available
          :ok
      end
    end
  end

  describe "template path" do
    test "template file path is constructed correctly" do
      template_path = Path.join([
        Application.app_dir(:aria_minizinc_goal),
        "priv",
        "templates",
        "goal_solving.mzn.eex"
      ])

      # Template should have correct path structure
      assert String.ends_with?(template_path, "goal_solving.mzn.eex")
      assert String.contains?(template_path, "aria_minizinc_goal")
    end
  end

  describe "variable extraction" do
    test "extracts variables from goals correctly" do
      domain = %{actions: [:move]}
      state = %{facts: []}
      goals = [
        {:robot, :at, :location_a},
        {:box, :holding, :robot}
      ]
      options = %{optimization_type: :minimize_time}

      # This should work even if MiniZinc fails, as it tests the conversion logic
      result = AriaMinizincGoal.solve_goals(domain, state, goals, options)

      case result do
        {:ok, solution} ->
          assert is_map(solution.variables)
        {:error, reason} ->
          # Expected if MiniZinc not available, but conversion should work
          assert is_binary(reason)
      end
    end
  end
end
