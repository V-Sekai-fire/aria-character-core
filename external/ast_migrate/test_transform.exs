# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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

Logger.debug("=== Original content ===")
Logger.debug(test_content)

case MembraneNamespaceCleanup.transform_file_content(test_content, "test.ex") do
  {:ok, transformed} ->
    Logger.debug("\n=== Transformed content ===")
    Logger.debug(transformed)

    Logger.debug("\n=== Comparison ===")
    if test_content == transformed do
      Logger.debug("❌ NO CHANGES MADE")
    else
      Logger.debug("✅ TRANSFORMATION APPLIED")
    end

  {:error, reason} ->
    Logger.debug("❌ Error: #{reason}")
end
