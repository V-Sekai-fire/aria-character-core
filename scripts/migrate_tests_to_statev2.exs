#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Comprehensive script to migrate all test files from State to StateV2

defmodule TestMigrator do
  def migrate_all_tests() do
    test_files = [
      "apps/aria_engine/test/run_lazy_refineahead_test.exs",
      "apps/aria_engine/test/planning_test.exs", 
      "apps/aria_engine/test/goal_test.exs",
      "apps/aria_engine/test/aria_engine/state_quantifiers_test.exs",
      "apps/aria_engine/test/debug_temporal_puzzle.exs",
      "apps/aria_engine/test/debug_temporal_planner_stn_bridge.exs",
      "apps/aria_engine/test/test_simple_hgn.exs"
    ]
    
    Enum.each(test_files, &migrate_test_file/1)
    IO.puts("✅ Migrated #{length(test_files)} test files to StateV2")
  end
  
  def migrate_test_file(file_path) do
    IO.puts("Migrating #{file_path}...")
    
    if File.exists?(file_path) do
      content = File.read!(file_path)
      
      # Basic migrations
      fixed_content = content
      # Replace imports and aliases
      |> String.replace("alias State", "alias AriaEngine.StateV2")
      |> String.replace("alias {State,", "alias {StateV2,")
      
      # Replace AriaEngine.StateV2.new() with StateV2.new()
      |> String.replace("AriaEngine.StateV2.new()", "StateV2.new()")
      
      # Replace State.set_fact calls - need to handle parameter order
      # AriaEngine.StateV2.set_fact(state, predicate, subject, value) -> StateV2.set_fact(state, subject, predicate, value)
      |> fix_state_set_fact_calls()
      
      # Replace State.get_fact calls - need to handle parameter order  
      # AriaEngine.StateV2.get_fact(state, predicate, subject) -> StateV2.get_fact(state, subject, predicate)
      |> fix_state_get_fact_calls()
      
      # Replace other State method calls
      |> String.replace(~r/State\.([a-zA-Z_]+)/, "StateV2.\\1")
      
      # Fix pattern matching on State structs
      |> String.replace("%AriaEngine.StateV2{", "%StateV2{")
      
      File.write!(file_path, fixed_content)
      IO.puts("  ✅ Migrated #{file_path}")
    else
      IO.puts("  ⚠️  File not found: #{file_path}")
    end
  end
  
  defp fix_state_set_fact_calls(content) do
    # Handle AriaEngine.StateV2.set_fact(state, predicate, subject, value) -> StateV2.set_fact(state, subject, predicate, value)
    content
    |> String.replace(
      ~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)",\s*"?([^")]+)"?\)/,
      "StateV2.set_fact(\\1, \"\\3\", \"\\2\", \"\\4\")"
    )
    |> String.replace(
      ~r/StateV2\.set_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)",\s*([^)]+)\)/,
      "StateV2.set_fact(\\1, \"\\3\", \"\\2\", \\4)"
    )
  end
  
  defp fix_state_get_fact_calls(content) do
    # Handle AriaEngine.StateV2.get_fact(state, predicate, subject) -> StateV2.get_fact(state, subject, predicate) 
    content
    |> String.replace(
      ~r/State\.get_fact\(([^,]+),\s*"([^"]+)",\s*"([^"]+)"\)/,
      "StateV2.get_fact(\\1, \"\\3\", \"\\2\")"
    )
  end
end

TestMigrator.migrate_all_tests()
