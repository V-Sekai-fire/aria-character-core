#!/usr/bin/env elixir

defmodule FinalTestFixer do
  def run do
    IO.puts("🔧 Final test fixes...")

    # Fix remaining AriaEngine.State references in multigoal test
    fix_multigoal_test_completely()

    # Fix State API parameter ordering issues in quantifier tests
    fix_state_quantifier_tests()

    IO.puts("✅ Final fixes completed!")
  end

  defp fix_multigoal_test_completely do
    IO.puts("📝 Fixing multigoal test completely...")

    file = "test/aria_engine/multigoal_optimization_test.exs"
    if File.exists?(file) do
      content = File.read!(file)

      # Fix the parameter ordering issue - the regex didn't work properly
      # Current wrong: State.set_fact(state, "robot", "location", "dock")
      # Should be: State.set_fact(state, "location", "robot", "dock")

      updated_content = content
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"robot",\s*"location",\s*([^)]+)\)/, "State.set_fact(\\1, \"location\", \"robot\", \\2)")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"package_([^"]+)",\s*"location",\s*([^)]+)\)/, "State.set_fact(\\1, \"location\", \"package_\\2\", \\3)")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"package_([^"]+)",\s*"weight",\s*([^)]+)\)/, "State.set_fact(\\1, \"weight\", \"package_\\2\", \\3)")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"agent_([^"]+)",\s*"location",\s*([^)]+)\)/, "State.set_fact(\\1, \"location\", \"agent_\\2\", \\3)")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"agent_([^"]+)",\s*"capacity",\s*([^)]+)\)/, "State.set_fact(\\1, \"capacity\", \"agent_\\2\", \\3)")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"task_([^"]+)",\s*"status",\s*([^)]+)\)/, "State.set_fact(\\1, \"status\", \"task_\\2\", \\3)")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"task_([^"]+)",\s*"depends_on",\s*([^)]+)\)/, "State.set_fact(\\1, \"depends_on\", \"task_\\2\", \\3)")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"resource_([^"]+)",\s*"available",\s*([^)]+)\)/, "State.set_fact(\\1, \"available\", \"resource_\\2\", \\3)")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"resource_([^"]+)",\s*"capacity",\s*([^)]+)\)/, "State.set_fact(\\1, \"capacity\", \"resource_\\2\", \\3)")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"goal_([^"]+)",\s*"impossible",\s*([^)]+)\)/, "State.set_fact(\\1, \"impossible\", \"goal_\\2\", \\3)")

      File.write!(file, updated_content)
      IO.puts("  ✅ Fixed multigoal test parameter ordering")
    end
  end

  defp fix_state_quantifier_tests do
    IO.puts("📝 Fixing state quantifier test setup...")

    file = "test/aria_engine/test/aria_engine/state_quantifiers_test.exs"
    if File.exists?(file) do
      content = File.read!(file)

      # Fix the test setup - the State.set_fact calls need proper parameter ordering
      # Current wrong: State.set_fact(state, "chair1", "status", "available")
      # Should be: State.set_fact(state, "status", "chair1", "available")

      updated_content = content
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"status",\s*"([^"]+)"\)/, "State.set_fact(\\1, \"status\", \"\\2\", \"\\3\")")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"type",\s*"([^"]+)"\)/, "State.set_fact(\\1, \"type\", \"\\2\", \"\\3\")")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"location",\s*"([^"]+)"\)/, "State.set_fact(\\1, \"location\", \"\\2\", \"\\3\")")
      |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"available",\s*([^)]+)\)/, "State.set_fact(\\1, \"available\", \"\\2\", \\3)")

      File.write!(file, updated_content)
      IO.puts("  ✅ Fixed state quantifier test setup")
    end
  end
end

FinalTestFixer.run()
