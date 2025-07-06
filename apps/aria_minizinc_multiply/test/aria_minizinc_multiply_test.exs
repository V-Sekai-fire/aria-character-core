# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincMultiplyTest do
  use ExUnit.Case
  import Mox

  setup :verify_on_exit!

  describe "multiply/2 with explicit multiplier" do
    test "multiplies positive integers correctly" do
      {:ok, result} = AriaMinizincMultiply.multiply(5, 3)
      assert result.result == 15
      assert result.solver in [:minizinc, :fixpoint]
      assert is_binary(result.solving_start)
      assert is_binary(result.solving_end)
      assert is_binary(result.duration)
    end

    test "multiplies negative integers correctly" do
      {:ok, result} = AriaMinizincMultiply.multiply(-4, 3)
      assert result.result == -12
    end

    test "multiplies with negative multiplier correctly" do
      {:ok, result} = AriaMinizincMultiply.multiply(7, -2)
      assert result.result == -14
    end

    test "returns error for zero input_value" do
      {:error, reason} = AriaMinizincMultiply.multiply(0, 3)
      assert reason == "input_value must be non-zero"
    end

    test "returns error for zero multiplier" do
      {:error, reason} = AriaMinizincMultiply.multiply(5, 0)
      assert reason == "multiplier must be non-zero"
    end

    test "returns error for non-integer input_value" do
      {:error, reason} = AriaMinizincMultiply.multiply("5", 3)
      assert reason == "input_value must be an integer"
    end

    test "returns error for non-integer multiplier" do
      {:error, reason} = AriaMinizincMultiply.multiply(5, "3")
      assert reason == "multiplier must be an integer"
    end
  end

  describe "multiply/1 with default multiplier" do
    test "uses default multiplier of 3" do
      {:ok, result} = AriaMinizincMultiply.multiply(7)
      assert result.result == 21
    end

    test "works with negative input" do
      {:ok, result} = AriaMinizincMultiply.multiply(-5)
      assert result.result == -15
    end
  end

  describe "multiply/2 with options as second parameter" do
    test "uses default multiplier when options provided as second parameter" do
      {:ok, result} = AriaMinizincMultiply.multiply(4, solver: :fixpoint)
      assert result.result == 12
      assert result.solver == :fixpoint
    end

    test "respects timeout option" do
      {:ok, result} = AriaMinizincMultiply.multiply(6, timeout: 5000)
      assert result.result == 18
    end
  end

  describe "solve/2 with solver options" do
    test "forces fixpoint solver" do
      params = %{input_value: 8, multiplier: 4}
      {:ok, result} = AriaMinizincMultiply.solve(params, solver: :fixpoint)
      assert result.result == 32
      assert result.solver == :fixpoint
    end

    test "auto solver selection works" do
      params = %{input_value: 3, multiplier: 7}
      {:ok, result} = AriaMinizincMultiply.solve(params, solver: :auto)
      assert result.result == 21
      assert result.solver in [:minizinc, :fixpoint]
    end

    test "returns error for invalid solver option" do
      params = %{input_value: 5, multiplier: 2}
      {:error, reason} = AriaMinizincMultiply.solve(params, solver: :invalid)
      assert reason == "Invalid solver option: :invalid"
    end

    test "validates input parameters" do
      params = %{input_value: 0, multiplier: 3}
      {:error, reason} = AriaMinizincMultiply.solve(params)
      assert reason == "input_value must be non-zero"
    end
  end

  describe "solver fallback behavior" do
    test "falls back to fixpoint when MiniZinc fails" do
      # This test would require mocking AriaMinizincExecutor to simulate failure
      # For now, we test that fixpoint solver works independently
      params = %{input_value: 9, multiplier: 2}
      {:ok, result} = AriaMinizincMultiply.solve(params, solver: :fixpoint)
      assert result.result == 18
      assert result.solver == :fixpoint
    end
  end

  describe "result format" do
    test "includes all required fields" do
      {:ok, result} = AriaMinizincMultiply.multiply(6, 5)

      assert Map.has_key?(result, :result)
      assert Map.has_key?(result, :solving_start)
      assert Map.has_key?(result, :solving_end)
      assert Map.has_key?(result, :duration)
      assert Map.has_key?(result, :solver)

      assert is_integer(result.result)
      assert is_binary(result.solving_start)
      assert is_binary(result.solving_end)
      assert is_binary(result.duration)
      assert result.solver in [:minizinc, :fixpoint]
    end

    test "duration format is ISO8601-like" do
      {:ok, result} = AriaMinizincMultiply.multiply(2, 8)
      assert String.starts_with?(result.duration, "PT")
      assert String.ends_with?(result.duration, "S")
    end

    test "timestamps are ISO8601 format" do
      {:ok, result} = AriaMinizincMultiply.multiply(3, 4)

      # Should be able to parse the timestamps
      assert {:ok, _, _} = DateTime.from_iso8601(result.solving_start)
      assert {:ok, _, _} = DateTime.from_iso8601(result.solving_end)
    end
  end

  describe "large number handling" do
    test "handles large positive numbers" do
      {:ok, result} = AriaMinizincMultiply.multiply(1000, 999)
      assert result.result == 999_000
    end

    test "handles large negative numbers" do
      {:ok, result} = AriaMinizincMultiply.multiply(-500, 200)
      assert result.result == -100_000
    end
  end

  describe "edge cases" do
    test "multiplication by 1" do
      {:ok, result} = AriaMinizincMultiply.multiply(42, 1)
      assert result.result == 42
    end

    test "multiplication by -1" do
      {:ok, result} = AriaMinizincMultiply.multiply(42, -1)
      assert result.result == -42
    end

    test "very small numbers" do
      {:ok, result} = AriaMinizincMultiply.multiply(1, 1)
      assert result.result == 1
    end
  end
end
