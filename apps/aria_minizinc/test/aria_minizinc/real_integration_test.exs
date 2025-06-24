# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.RealIntegrationTest do
  use ExUnit.Case, async: false

  alias AriaMiniZinc.{Solver, ProblemGenerator, Executor}

  @moduletag :external_dependency

  setup_all do
    # Check if MiniZinc is available before running tests
    case Executor.check_availability() do
      {:ok, version} ->
        IO.puts("MiniZinc available: #{version}")
        :ok
      {:error, reason} ->
        IO.puts("MiniZinc not available: #{reason}")
        {:skip, "MiniZinc not available: #{reason}"}
    end
  end

  describe "End-to-End Real MiniZinc Integration" do
    @tag timeout: 30_000
    test "solves simple STN problem with real MiniZinc" do
      # Create a simple temporal scheduling problem
      domain = %{
        name: "simple_scheduling",
        actions: ["start_task", "complete_task"]
      }

      state = %{
        entities: ["task_a", "task_b"],
        resources: ["worker"]
      }

      goals = [
        {"task_a", "state", "completed"},
        {"task_b", "state", "completed"}
      ]

      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        default_duration: 30
      }

      # Generate the problem
      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Solve with real MiniZinc
      result = Solver.solve(problem_data, %{
        solver_type: :production,
        timeout: 10_000  # 10 second timeout
      })

      # Verify real solution
      assert {:ok, solution} = result
      assert solution.status == :success

      # Verify timing format (real timestamps)
      assert is_binary(solution.solving_start)
      assert is_binary(solution.solving_end)
      assert is_binary(solution.duration)

      # Parse timestamps to verify they're valid ISO8601
      {:ok, start_time, _} = DateTime.from_iso8601(solution.solving_start)
      {:ok, end_time, _} = DateTime.from_iso8601(solution.solving_end)
      assert DateTime.compare(end_time, start_time) in [:gt, :eq]

      # Verify solution structure
      assert is_map(solution.solution)
      assert Map.has_key?(solution.solution, :makespan) or Map.has_key?(solution.solution, :objective)

      # Verify raw output contains actual MiniZinc output
      assert is_binary(solution.raw_output)
      assert String.length(solution.raw_output) > 0
    end

    @tag timeout: 30_000
    test "solves goal-solving problem with real MiniZinc" do
      # Create a simple goal-solving problem
      domain = %{name: "robot_navigation"}
      state = %{entities: ["robot", "package"]}
      goals = [
        {"robot", "location", "warehouse"},
        {"package", "state", "delivered"}
      ]

      # Use default options (goal_solving template)
      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, %{})

      # Solve with real MiniZinc
      result = Solver.solve(problem_data, %{
        solver_type: :production,
        timeout: 10_000
      })

      # Verify real solution
      assert {:ok, solution} = result
      assert solution.status == :success

      # Verify timing measurements are real
      assert is_binary(solution.solving_start)
      assert is_binary(solution.solving_end)
      assert is_binary(solution.duration)

      # Verify solution contains expected structure
      assert is_map(solution.solution)
      assert is_binary(solution.raw_output)
    end

    @tag timeout: 30_000
    test "handles complex STN with multiple constraints" do
      domain = %{
        name: "complex_scheduling",
        constraints: ["precedence", "resource_limits"]
      }

      state = %{
        entities: ["prep", "cook", "serve"],
        resources: ["chef", "kitchen"]
      }

      goals = [
        {"prep", "state", "completed"},
        {"cook", "state", "completed"},
        {"serve", "state", "completed"}
      ]

      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        default_duration: 20,
        max_makespan: 100
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Solve with real MiniZinc
      result = Solver.solve(problem_data, %{
        solver_type: :production,
        timeout: 15_000
      })

      assert {:ok, solution} = result
      assert solution.status == :success

      # Verify the solution respects temporal constraints
      if Map.has_key?(solution.solution, :start_times) and Map.has_key?(solution.solution, :end_times) do
        start_times = solution.solution.start_times
        end_times = solution.solution.end_times

        # Verify start times are before end times
        Enum.zip(start_times, end_times)
        |> Enum.each(fn {start, finish} ->
          assert start <= finish, "Start time #{start} should be <= end time #{finish}"
        end)
      end

      # Verify makespan is reasonable
      if Map.has_key?(solution.solution, :makespan) do
        assert solution.solution.makespan <= 100, "Makespan should respect max_makespan constraint"
      end
    end

    @tag timeout: 15_000
    test "handles timeout scenarios gracefully" do
      # Create a potentially complex problem
      domain = %{name: "timeout_test"}
      state = %{entities: ["task1", "task2", "task3", "task4", "task5"]}
      goals = [
        {"task1", "state", "done"},
        {"task2", "state", "done"},
        {"task3", "state", "done"},
        {"task4", "state", "done"},
        {"task5", "state", "done"}
      ]

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, %{problem_type: :stn})

      # Use very short timeout to test timeout handling
      result = Solver.solve(problem_data, %{
        solver_type: :production,
        timeout: 100  # 100ms - very short
      })

      # Should either succeed quickly or timeout gracefully
      case result do
        {:ok, solution} ->
          # If it succeeds, verify it's a valid solution
          assert solution.status == :success
          assert is_binary(solution.solving_start)
          assert is_binary(solution.solving_end)
        {:error, reason} ->
          # If it times out, should get a meaningful error
          assert is_binary(reason)
          assert String.contains?(reason, "timeout") or String.contains?(reason, "killed")
      end
    end

    @tag timeout: 20_000
    test "parses real MiniZinc JSON output correctly" do
      domain = %{name: "json_parsing_test"}
      state = %{entities: ["entity1", "entity2"]}
      goals = [
        {"entity1", "location", "target1"},
        {"entity2", "location", "target2"}
      ]

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, %{problem_type: :stn})

      result = Solver.solve(problem_data, %{
        solver_type: :production,
        timeout: 10_000
      })

      assert {:ok, solution} = result

      # Verify raw output contains valid JSON
      assert is_binary(solution.raw_output)

      # Try to extract JSON from raw output
      json_lines = solution.raw_output
                  |> String.split("\n")
                  |> Enum.filter(&String.starts_with?(&1, "{"))

      if length(json_lines) > 0 do
        json_line = hd(json_lines)
        assert {:ok, parsed} = Jason.decode(json_line)
        assert is_map(parsed)

        # Verify parsed JSON matches solution data
        if Map.has_key?(parsed, "makespan") and Map.has_key?(solution.solution, :makespan) do
          assert parsed["makespan"] == solution.solution.makespan
        end
      end
    end

    @tag timeout: 20_000
    test "measures real solving time accurately" do
      domain = %{name: "timing_test"}
      state = %{entities: ["quick_task"]}
      goals = [{"quick_task", "state", "done"}]

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, %{})

      # Record test start time
      test_start = DateTime.utc_now()

      result = Solver.solve(problem_data, %{
        solver_type: :production,
        timeout: 10_000
      })

      test_end = DateTime.utc_now()

      assert {:ok, solution} = result

      # Parse solving timestamps
      {:ok, solving_start, _} = DateTime.from_iso8601(solution.solving_start)
      {:ok, solving_end, _} = DateTime.from_iso8601(solution.solving_end)

      # Verify solving times are within test timeframe
      assert DateTime.compare(solving_start, test_start) in [:gt, :eq]
      assert DateTime.compare(test_end, solving_end) in [:gt, :eq]

      # Verify solving duration is reasonable
      solving_duration_ms = DateTime.diff(solving_end, solving_start, :millisecond)
      assert solving_duration_ms >= 0
      assert solving_duration_ms < 10_000  # Should solve quickly

      # Verify duration string format
      assert String.starts_with?(solution.duration, "PT")
      assert String.ends_with?(solution.duration, "S")
    end
  end

  describe "Real MiniZinc Error Handling" do
    @tag timeout: 15_000
    test "handles MiniZinc solver errors gracefully" do
      # Create a potentially problematic model by using invalid template variables
      domain = %{name: "error_test"}
      state = %{entities: []}  # Empty entities might cause issues
      goals = []  # Empty goals might cause issues

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, %{problem_type: :stn})

      result = Solver.solve(problem_data, %{
        solver_type: :production,
        timeout: 5_000
      })

      # Should handle gracefully - either succeed with empty solution or fail with clear error
      case result do
        {:ok, solution} ->
          # If it succeeds, should be a valid empty solution
          assert solution.status == :success
          assert is_binary(solution.solving_start)
          assert is_binary(solution.solving_end)
        {:error, reason} ->
          # If it fails, should provide meaningful error message
          assert is_binary(reason)
          assert String.length(reason) > 0
      end
    end

    @tag timeout: 10_000
    test "validates MiniZinc availability before solving" do
      # This test verifies the availability check works
      case Executor.check_availability() do
        {:ok, version} ->
          assert is_binary(version)
          assert String.contains?(version, "MiniZinc") or String.contains?(version, "minizinc")
        {:error, reason} ->
          # If MiniZinc is not available, this test should be skipped
          flunk("MiniZinc should be available for real integration tests: #{reason}")
      end
    end
  end

  describe "Template Comparison with Real Solver" do
    @tag timeout: 30_000
    test "compares STN vs goal_solving templates with real solving" do
      domain = %{name: "template_comparison"}
      state = %{entities: ["task1", "task2"]}
      goals = [
        {"task1", "location", "room1"},
        {"task2", "location", "room2"}
      ]

      # Generate with goal_solving template
      {:ok, goal_data} = ProblemGenerator.generate_problem(domain, state, goals, %{})

      # Generate with STN template
      {:ok, stn_data} = ProblemGenerator.generate_problem(domain, state, goals, %{problem_type: :stn})

      # Solve both with real MiniZinc
      goal_result = Solver.solve(goal_data, %{solver_type: :production, timeout: 10_000})
      stn_result = Solver.solve(stn_data, %{solver_type: :production, timeout: 10_000})

      # Both should succeed
      assert {:ok, goal_solution} = goal_result
      assert {:ok, stn_solution} = stn_result

      # Both should have valid timing
      assert is_binary(goal_solution.solving_start)
      assert is_binary(stn_solution.solving_start)

      # Both should have valid solutions
      assert goal_solution.status == :success
      assert stn_solution.status == :success

      # Solutions may differ but both should be valid
      assert is_map(goal_solution.solution)
      assert is_map(stn_solution.solution)
    end
  end
end
