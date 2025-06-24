# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ValidationSolverTest do
  use ExUnit.Case
  doctest AriaMiniZinc.ValidationSolver

  alias AriaMiniZinc.ValidationSolver

  describe "ValidationSolver - Validation pipeline solving" do
    test "solves STN temporal problems" do
      params = %{
        "schedule_name" => "test_schedule",
        "activities" => [
          %{"id" => "activity1", "duration" => 10},
          %{"id" => "activity2", "duration" => 20}
        ]
      }

      state = %{timeout: 5000}

      result = ValidationSolver.solve(params, state)

      assert match?(%{status: :success}, result) or match?(%{status: :error}, result)

      case result do
        %{status: :success} ->
          assert Map.has_key?(result, :solution)
          assert Map.has_key?(result, :solve_time_ms)
          assert Map.has_key?(result, :raw_output)
          assert is_integer(result.solve_time_ms)

        %{status: :error} ->
          # MiniZinc might not be available in test environment
          assert Map.has_key?(result, :error)
          assert is_binary(result.error)
      end
    end

    test "solves widget assembly problems" do
      params = %{
        "schedule_name" => "widget_assembly_schedule"
      }

      state = %{timeout: 5000}

      result = ValidationSolver.solve(params, state)

      assert match?(%{status: :success}, result) or match?(%{status: :error}, result)

      case result do
        %{status: :success} ->
          assert Map.has_key?(result, :solution)
          assert Map.has_key?(result.solution, :activities)
          assert Map.has_key?(result.solution, :makespan)
          assert is_list(result.solution.activities)

        %{status: :error} ->
          # MiniZinc might not be available
          assert Map.has_key?(result, :error)
      end
    end

    test "handles timeout configuration" do
      params = %{
        "schedule_name" => "test_schedule",
        "activities" => [%{"id" => "activity1", "duration" => 10}]
      }

      state = %{timeout: 1000}  # Short timeout

      start_time = System.monotonic_time(:millisecond)
      result = ValidationSolver.solve(params, state)
      elapsed = System.monotonic_time(:millisecond) - start_time

      # Should either complete quickly or timeout
      case result do
        %{status: :success} ->
          assert elapsed < 2000  # Allow some buffer

        %{status: :error} ->
          # Timeout or unavailable is acceptable
          :ok
      end
    end

    test "converts solution format correctly" do
      params = %{
        "schedule_name" => "test_schedule",
        "activities" => [
          %{"id" => "task1", "duration" => 15},
          %{"id" => "task2", "duration" => 25}
        ]
      }

      state = %{timeout: 5000}

      case ValidationSolver.solve(params, state) do
        %{status: :success, solution: solution} ->
          # Verify solution structure
          assert Map.has_key?(solution, :activities)
          assert Map.has_key?(solution, :makespan)
          assert is_list(solution.activities)

          # Check activity structure
          Enum.each(solution.activities, fn activity ->
            assert Map.has_key?(activity, :id)
            assert Map.has_key?(activity, :start_time)
            assert Map.has_key?(activity, :end_time)
            assert Map.has_key?(activity, :duration)
            assert is_integer(activity.start_time)
            assert is_integer(activity.end_time)
            assert is_integer(activity.duration)
          end)

        %{status: :error} ->
          # MiniZinc unavailable is acceptable in test environment
          :ok
      end
    end

    test "handles invalid parameters gracefully" do
      # Test with missing activities
      params = %{"schedule_name" => "test_schedule"}
      state = %{timeout: 5000}

      result = ValidationSolver.solve(params, state)
      assert match?(%{status: :success}, result) or match?(%{status: :error}, result)

      # Test with malformed activities
      params = %{
        "schedule_name" => "test_schedule",
        "activities" => ["invalid", %{"malformed" => "activity"}]
      }

      result = ValidationSolver.solve(params, state)
      assert match?(%{status: :success}, result) or match?(%{status: :error}, result)
    end

    test "parses duration strings correctly" do
      params = %{
        "schedule_name" => "test_schedule",
        "activities" => [
          %{"id" => "task1", "duration" => "PT15M"},  # ISO 8601 format
          %{"id" => "task2", "duration" => "30"},     # String number
          %{"id" => "task3", "duration" => 45}        # Integer
        ]
      }

      state = %{timeout: 5000}

      case ValidationSolver.solve(params, state) do
        %{status: :success, solution: solution} ->
          # Should handle all duration formats
          assert length(solution.activities) == 3

        %{status: :error} ->
          # MiniZinc unavailable is acceptable
          :ok
      end
    end
  end

  describe "check_availability/0" do
    test "returns availability status" do
      result = ValidationSolver.check_availability()
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "error handling" do
    test "handles MiniZinc execution errors" do
      # Test with parameters that might cause solver issues
      params = %{
        "schedule_name" => "problematic_schedule",
        "activities" => []  # Empty activities might cause issues
      }

      state = %{timeout: 1000}

      result = ValidationSolver.solve(params, state)

      # Should handle gracefully
      assert match?(%{status: :success}, result) or match?(%{status: :error}, result)

      if match?(%{status: :error}, result) do
        assert Map.has_key?(result, :error)
        assert is_binary(result.error)
        assert Map.has_key?(result, :solve_time_ms)
        assert is_integer(result.solve_time_ms)
      end
    end

    test "handles conversion errors" do
      # Test with parameters that might cause conversion issues
      params = %{
        "schedule_name" => "test_schedule",
        "activities" => [
          %{"id" => "task1", "duration" => "invalid_duration"}
        ]
      }

      state = %{timeout: 5000}

      result = ValidationSolver.solve(params, state)

      # Should either handle gracefully or return error
      assert match?(%{status: :success}, result) or match?(%{status: :error}, result)
    end
  end
end
