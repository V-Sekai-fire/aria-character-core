# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.MockIntegrationTest do
  use ExUnit.Case, async: true
  import Mox

  alias AriaMiniZinc.{Solver, ProblemGenerator}

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "Mock executor integration" do
    test "uses mock executor to avoid external MiniZinc dependency" do
      # Setup mock executor expectations
      expect(AriaMiniZinc.MockExecutor, :exec, fn template_name, opts ->
        # Verify template and options
        assert template_name == "stn_temporal"
        assert Keyword.has_key?(opts, :template_vars)

        template_vars = Keyword.get(opts, :template_vars)
        assert Map.has_key?(template_vars, :num_time_points)
        assert Map.has_key?(template_vars, :distance_matrix)

        # Return mock solution
        {:ok, %{
          status: :success,
          solution: %{
            start_times: [0, 30, 60],
            end_times: [25, 55, 85],
            makespan: 85,
            objective: 85,
            status: "SATISFIED"
          },
          solve_time_ms: 15,
          raw_output: """
          {
            "start_times": [0, 30, 60],
            "end_times": [25, 55, 85],
            "makespan": 85,
            "_objective": 85,
            "status": "SATISFIED"
          }
          ----------
          ==========
          """
        }}
      end)

      # Generate STN problem using the correct function
      domain = %{name: "test_domain"}
      state = %{entities: ["start", "middle", "end"]}
      goals = [
        {"start", "location", "room1"},
        {"middle", "location", "room2"},
        {"end", "location", "room3"}
      ]
      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, %{problem_type: :stn})

      # Solve with mock executor injected
      result = Solver.solve(problem_data, %{
        solver_type: :production,
        executor: AriaMiniZinc.MockExecutor
      })

      # Verify result structure
      assert {:ok, solution} = result
      assert solution.status == :success
      assert solution.solution.start_times == [0, 30, 60]
      assert solution.solution.end_times == [25, 55, 85]
      assert solution.solution.makespan == 85
      assert solution.solve_time_ms == 15
    end

    test "mock executor handles check_availability" do
      expect(AriaMiniZinc.MockExecutor, :check_availability, fn ->
        {:ok, "MiniZinc 2.8.0 (mock)"}
      end)

      result = AriaMiniZinc.MockExecutor.check_availability()
      assert {:ok, version} = result
      assert String.contains?(version, "mock")
    end

    test "mock executor handles spawn operations" do
      expect(AriaMiniZinc.MockExecutor, :spawn, fn template_name, opts ->
        assert template_name == "goal_solving"
        assert Keyword.has_key?(opts, :template_vars)

        # Return mock process reference
        {:ok, %{pid: self(), status: :running}}
      end)

      result = AriaMiniZinc.MockExecutor.spawn("goal_solving", template_vars: %{})
      assert {:ok, proc} = result
      assert Map.has_key?(proc, :pid)
      assert Map.has_key?(proc, :status)
    end

    test "solver uses test mode without external dependencies" do
      # Generate test problem using correct function
      domain = %{name: "test_domain"}
      state = %{entities: ["start", "end"]}
      goals = [{"start", "location", "room1"}, {"end", "location", "room2"}]
      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, %{problem_type: :stn})

      # Solve using test mode (uses internal mock, no Mox expectations needed)
      result = Solver.solve(problem_data, %{solver_type: :test, variable_count: 2})

      # Verify mock result structure
      assert {:ok, solution} = result
      assert solution.status == :success
      assert is_list(solution.solution.start_times)
      assert is_list(solution.solution.end_times)
      assert is_integer(solution.solution.makespan)
      assert solution.solve_time_ms == 10  # Mock solve time
    end

    test "handles error cases in mock executor" do
      expect(AriaMiniZinc.MockExecutor, :exec, fn _template_name, _opts ->
        {:error, "Mock execution failed"}
      end)

      # Generate problem using correct function
      domain = %{name: "test_domain"}
      state = %{entities: ["single"]}
      goals = [{"single", "location", "room1"}]
      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, %{problem_type: :stn})

      result = Solver.solve(problem_data, %{
        solver_type: :production,
        executor: AriaMiniZinc.MockExecutor
      })

      assert {:error, error_msg} = result
      assert String.contains?(error_msg, "Mock execution failed")
    end
  end

  describe "Mock system validation" do
    test "validates mock executor behaviour compliance" do
      # Test that mock implements all required callbacks
      behaviours = AriaMiniZinc.MockExecutor.__info__(:attributes)[:behaviour] || []
      assert AriaMiniZinc.ExecutorBehaviour in behaviours
    end

    test "mock solver behaviour compliance" do
      # Test that mock implements all required callbacks
      behaviours = AriaMiniZinc.MockSolver.__info__(:attributes)[:behaviour] || []
      assert AriaMiniZinc.SolverBehaviour in behaviours
    end

    test "dependency injection works correctly" do
      # Generate problem using correct function
      domain = %{name: "test_domain"}
      state = %{entities: ["test"]}
      goals = [{"test", "location", "room1"}]
      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, %{problem_type: :stn})

      # Test with real executor (should work in production)
      result_real = Solver.solve(problem_data, %{
        solver_type: :test,  # Use test mode to avoid external dependency
        variable_count: 1
      })
      assert {:ok, _} = result_real

      # Test with mock executor injection
      expect(AriaMiniZinc.MockExecutor, :exec, fn _, _ ->
        {:ok, %{
          status: :success,
          solution: %{makespan: 42},
          solve_time_ms: 5,
          raw_output: "mock"
        }}
      end)

      result_mock = Solver.solve(problem_data, %{
        solver_type: :production,
        executor: AriaMiniZinc.MockExecutor
      })
      assert {:ok, solution} = result_mock
      assert solution.solution.makespan == 42
    end
  end
end
