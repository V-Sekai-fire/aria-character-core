# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.MultiplyTest do
  use ExUnit.Case, async: true
  import Mox

  alias AriaMiniZinc.Executor

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "AriaMiniZinc.multiply/3 with mock executor" do
    test "multiplies integers using mock executor" do
      # Setup mock executor expectations
      expect(AriaMiniZinc.MockExecutor, :exec, fn template_name, opts ->
        # Verify template and options
        assert template_name == "multiply"
        assert Keyword.has_key?(opts, :template_vars)

        template_vars = Keyword.get(opts, :template_vars)
        assert Map.has_key?(template_vars, :input_value)
        assert Map.has_key?(template_vars, :multiplier)

        input_value = template_vars.input_value
        multiplier = template_vars.multiplier
        result = input_value * multiplier

        # Return mock solution with proper timing format
        solving_start = "2025-06-24T21:39:14.638527+00:00"
        solving_end = "2025-06-24T21:39:14.653527+00:00"

        {:ok, %{
          status: :success,
          solution: %{result: result},
          solving_start: solving_start,
          solving_end: solving_end,
          duration: "PT0.015S",
          raw_output: "{\"result\": #{result}}"
        }}
      end)

      # Test multiplication with mock executor
      result = AriaMiniZinc.multiply(5, 3, executor: AriaMiniZinc.MockExecutor)

      # Verify result structure
      assert {:ok, solution} = result
      assert solution.result == 15
      assert solution.solving_start == "2025-06-24T21:39:14.638527+00:00"
      assert solution.solving_end == "2025-06-24T21:39:14.653527+00:00"
      assert solution.duration == "PT0.015S"
    end

    test "handles different multiplication values with mock" do
      expect(AriaMiniZinc.MockExecutor, :exec, fn _template_name, opts ->
        template_vars = Keyword.get(opts, :template_vars)
        input_value = template_vars.input_value
        multiplier = template_vars.multiplier
        result = input_value * multiplier

        {:ok, %{
          status: :success,
          solution: %{result: result},
          solving_start: "2025-06-24T21:39:14.638527+00:00",
          solving_end: "2025-06-24T21:39:14.653527+00:00",
          duration: "PT0.010S",
          raw_output: "{\"result\": #{result}}"
        }}
      end)

      result = AriaMiniZinc.multiply(7, 4, executor: AriaMiniZinc.MockExecutor)

      assert {:ok, solution} = result
      assert solution.result == 28
    end

    test "uses default multiplier with mock" do
      expect(AriaMiniZinc.MockExecutor, :exec, fn _template_name, opts ->
        template_vars = Keyword.get(opts, :template_vars)
        input_value = template_vars.input_value
        multiplier = template_vars.multiplier

        # Should use default multiplier of 3
        assert multiplier == 3
        result = input_value * multiplier

        {:ok, %{
          status: :success,
          solution: %{result: result},
          solving_start: "2025-06-24T21:39:14.638527+00:00",
          solving_end: "2025-06-24T21:39:14.653527+00:00",
          duration: "PT0.005S",
          raw_output: "{\"result\": #{result}}"
        }}
      end)

      result = AriaMiniZinc.multiply(6, executor: AriaMiniZinc.MockExecutor)

      assert {:ok, solution} = result
      assert solution.result == 18
    end

    test "handles mock executor errors" do
      expect(AriaMiniZinc.MockExecutor, :exec, fn _template_name, _opts ->
        {:error, "Mock execution failed"}
      end)

      result = AriaMiniZinc.multiply(5, 3, executor: AriaMiniZinc.MockExecutor)

      assert {:error, error_msg} = result
      assert String.contains?(error_msg, "Executor failed")
    end
  end

  describe "AriaMiniZinc.multiply/3 input validation" do
    test "validates input_value is non-zero integer" do
      result = AriaMiniZinc.multiply(0, 3)
      assert {:error, "input_value must be non-zero"} = result

      result = AriaMiniZinc.multiply("5", 3)
      assert {:error, "input_value must be an integer"} = result

      result = AriaMiniZinc.multiply(5.5, 3)
      assert {:error, "input_value must be an integer"} = result
    end

    test "validates multiplier is non-zero integer" do
      result = AriaMiniZinc.multiply(5, 0)
      assert {:error, "multiplier must be non-zero"} = result

      result = AriaMiniZinc.multiply(5, "3")
      assert {:error, "multiplier must be an integer"} = result

      result = AriaMiniZinc.multiply(5, 3.5)
      assert {:error, "multiplier must be an integer"} = result
    end

    test "accepts negative integers" do
      expect(AriaMiniZinc.MockExecutor, :exec, fn _template_name, opts ->
        template_vars = Keyword.get(opts, :template_vars)
        input_value = template_vars.input_value
        multiplier = template_vars.multiplier
        result = input_value * multiplier

        {:ok, %{
          status: :success,
          solution: %{result: result},
          solving_start: "2025-06-24T21:39:14.638527+00:00",
          solving_end: "2025-06-24T21:39:14.653527+00:00",
          duration: "PT0.005S",
          raw_output: "{\"result\": #{result}}"
        }}
      end)

      result = AriaMiniZinc.multiply(-5, 3, executor: AriaMiniZinc.MockExecutor)

      assert {:ok, solution} = result
      assert solution.result == -15
    end
  end

  describe "Mock integration with real MiniZinc simulation" do
    test "mock simulates real MiniZinc behavior" do
      # Mock that simulates calling real MiniZinc
      expect(AriaMiniZinc.MockExecutor, :exec, fn template_name, opts ->
        # Simulate real MiniZinc template processing
        assert template_name == "multiply"
        template_vars = Keyword.get(opts, :template_vars)

        # Simulate MiniZinc constraint solving
        input_value = template_vars.input_value
        multiplier = template_vars.multiplier
        result = input_value * multiplier

        # Simulate real MiniZinc output format
        raw_output = """
        {"result": #{result}}
        ----------
        ==========
        """

        {:ok, %{
          status: :success,
          solution: %{result: result},
          solving_start: DateTime.utc_now() |> DateTime.to_iso8601(),
          solving_end: DateTime.utc_now() |> DateTime.add(15, :millisecond) |> DateTime.to_iso8601(),
          duration: "PT0.015S",
          raw_output: raw_output
        }}
      end)

      result = AriaMiniZinc.multiply(8, 2, executor: AriaMiniZinc.MockExecutor)

      assert {:ok, solution} = result
      assert solution.result == 16
      assert is_binary(solution.solving_start)
      assert is_binary(solution.solving_end)
      assert solution.duration == "PT0.015S"
    end
  end
end
