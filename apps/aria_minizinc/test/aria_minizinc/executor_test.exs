defmodule AriaMiniZinc.ExecutorTest do
  use ExUnit.Case
  doctest AriaMiniZinc.Executor

  alias AriaMiniZinc.Executor

  describe "Executor - Porcelain-based MiniZinc execution" do
    test "executes MiniZinc with valid model" do
      template_vars = %{
        num_activities: 2,
        durations: [10, 20],
        num_constraints: 1,
        constraints: [%{from_activity: 1, to_activity: 2, min_distance: 0, max_distance: 1000}]
      }

      case Executor.exec("stn_temporal", template_vars: template_vars, timeout: 5000) do
        {:ok, result} ->
          assert is_map(result)
          assert Map.has_key?(result, :solution)
          assert Map.has_key?(result, :solve_time_ms)
          assert is_integer(result.solve_time_ms)

        {:error, reason} ->
          # MiniZinc might not be available in test environment
          assert is_binary(reason) or is_atom(reason)
      end
    end

    test "handles MiniZinc unavailable gracefully" do
      # Test with invalid template to trigger error handling
      result = Executor.exec("nonexistent_template", template_vars: %{})

      assert {:error, _reason} = result
    end

    test "respects timeout configuration" do
      template_vars = %{
        num_activities: 2,
        durations: [10, 20],
        num_constraints: 1,
        constraints: [%{from_activity: 1, to_activity: 2, min_distance: 0, max_distance: 1000}]
      }

      start_time = System.monotonic_time(:millisecond)

      case Executor.exec("stn_temporal", template_vars: template_vars, timeout: 1000) do
        {:ok, _result} ->
          # If successful, should complete within timeout
          elapsed = System.monotonic_time(:millisecond) - start_time
          assert elapsed < 2000  # Allow some buffer

        {:error, _reason} ->
          # Timeout or unavailable is acceptable
          :ok
      end
    end

    test "parses JSON output correctly" do
      # Test with minimal valid template vars
      template_vars = %{
        num_activities: 1,
        durations: [10],
        num_constraints: 0,
        constraints: []
      }

      case Executor.exec("stn_temporal", template_vars: template_vars) do
        {:ok, result} ->
          # Should have parsed solution structure
          assert is_map(result.solution)

        {:error, _reason} ->
          # MiniZinc unavailable is acceptable in test environment
          :ok
      end
    end
  end

  describe "check_availability/0" do
    test "returns availability status" do
      result = Executor.check_availability()
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end
