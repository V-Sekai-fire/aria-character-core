# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Test the transformation directly
alias AstMigrate.Rules.MembraneNamespaceCleanup

test_content = """
defmodule AriaEngine.Membrane.Format.TestModule do
  alias AriaEngine.Membrane.Format.PlanningResult

  def test_function do
    AriaEngine.Membrane.Format.PlanningResult.success(%{}, "test", %{}, %{})
  end
end
"""

IO.puts("=== Original content ===")
IO.puts(test_content)

case MembraneNamespaceCleanup.transform_file_content(test_content, "test.ex") do
  {:ok, transformed} ->
    IO.puts("\n=== Transformed content ===")
    IO.puts(transformed)

    IO.puts("\n=== Comparison ===")
    if test_content == transformed do
      IO.puts("❌ NO CHANGES MADE")
    else
      IO.puts("✅ TRANSFORMATION APPLIED")
    end

  {:error, reason} ->
    IO.puts("❌ Error: #{reason}")
end
