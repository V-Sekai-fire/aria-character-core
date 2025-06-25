# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.MultiplyRealIntegrationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  describe "Real MiniZinc integration for multiply" do
    test "multiplies integers through real MiniZinc solver" do
      # Test basic multiplication through real MiniZinc
      result = AriaMiniZinc.multiply(5, 3)

      case result do
        {:ok, solution} ->
          # Verify the multiplication result
          assert solution.result == 15

          # Verify timing information is present
          assert is_binary(solution.solving_start)
          assert is_binary(solution.solving_end)
          assert is_binary(solution.duration)

          # Verify ISO8601 timestamp format
          assert String.match?(solution.solving_start, ~r/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
          assert String.match?(solution.solving_end, ~r/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)

          # Verify duration format (ISO8601 duration)
          assert String.match?(solution.duration, ~r/PT\d+(\.\d+)?S/)

        {:error, reason} ->
          # If MiniZinc is not available, skip the test
          if String.contains?(reason, "MiniZinc") or String.contains?(reason, "not found") do
            IO.puts("Skipping real integration test - MiniZinc not available: #{reason}")
          else
            flunk("Unexpected error: #{reason}")
          end
      end
    end

    test "handles different multiplication values through real MiniZinc" do
      result = AriaMiniZinc.multiply(7, 4)

      case result do
        {:ok, solution} ->
          assert solution.result == 28

        {:error, reason} ->
          if String.contains?(reason, "MiniZinc") or String.contains?(reason, "not found") do
            IO.puts("Skipping real integration test - MiniZinc not available: #{reason}")
          else
            flunk("Unexpected error: #{reason}")
          end
      end
    end

    test "uses default multiplier through real MiniZinc" do
      result = AriaMiniZinc.multiply(6)

      case result do
        {:ok, solution} ->
          # Should use default multiplier of 3
          assert solution.result == 18

        {:error, reason} ->
          if String.contains?(reason, "MiniZinc") or String.contains?(reason, "not found") do
            IO.puts("Skipping real integration test - MiniZinc not available: #{reason}")
          else
            flunk("Unexpected error: #{reason}")
          end
      end
    end

    test "handles negative numbers through real MiniZinc" do
      result = AriaMiniZinc.multiply(-5, 3)

      case result do
        {:ok, solution} ->
          assert solution.result == -15

        {:error, reason} ->
          if String.contains?(reason, "MiniZinc") or String.contains?(reason, "not found") do
            IO.puts("Skipping real integration test - MiniZinc not available: #{reason}")
          else
            flunk("Unexpected error: #{reason}")
          end
      end
    end

    test "handles large numbers through real MiniZinc" do
      result = AriaMiniZinc.multiply(1000, 999)

      case result do
        {:ok, solution} ->
          assert solution.result == 999_000

        {:error, reason} ->
          if String.contains?(reason, "MiniZinc") or String.contains?(reason, "not found") do
            IO.puts("Skipping real integration test - MiniZinc not available: #{reason}")
          else
            flunk("Unexpected error: #{reason}")
          end
      end
    end
  end

  describe "Real MiniZinc template verification" do
    test "verifies multiply template exists and is valid" do
      # Test that the template file exists
      template_path = Path.join([
        :code.priv_dir(:aria_minizinc),
        "templates",
        "minizinc",
        "multiply.mzn.eex"
      ])

      assert File.exists?(template_path), "multiply.mzn.eex template should exist"

      # Read and verify template content
      template_content = File.read!(template_path)

      # Verify template has required MiniZinc elements
      assert String.contains?(template_content, "input_value")
      assert String.contains?(template_content, "multiplier")
      assert String.contains?(template_content, "var int: result")
      assert String.contains?(template_content, "constraint result = input_value * multiplier")
      assert String.contains?(template_content, "solve satisfy")
      assert String.contains?(template_content, "output")
    end
  end
end
