#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Script to fix double namespace issues with AriaEngine.AriaEngine.StateV2
# This fixes Dialyzer errors and runtime function clause mismatches

defmodule DoubleNamespaceFixer do
  def run do
    IO.puts("Fixing double namespace issues: AriaEngine.AriaEngine.StateV2 -> AriaEngine.StateV2")
    
    files_to_fix = [
      "lib/aria_engine/domain/durative_action.ex",
      "lib/aria_engine/plan.ex", 
      "lib/aria_engine/plan/backtracking.ex",
      "lib/aria_engine/plan/node_expansion.ex",
      "lib/aria_engine/planning/core_interface.ex",
      "lib/aria_engine/hybrid_planner/strategy_coordinator.ex",
      "lib/aria_engine/hybrid_planner/hybrid_coordinator_v2.ex",
      "lib/aria_engine/hybrid_planner/strategy_registry.ex",
      "lib/aria_engine/hybrid_planner/strategies.ex"
    ]
    
    Enum.each(files_to_fix, &fix_file/1)
    
    IO.puts("Double namespace fixes completed!")
  end
  
  defp fix_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        fixed_content = String.replace(content, "AriaEngine.AriaEngine.StateV2", "AriaEngine.StateV2")
        
        if fixed_content != content do
          File.write!(file_path, fixed_content)
          IO.puts("Fixed: #{file_path}")
        else
          IO.puts("No changes needed: #{file_path}")
        end
        
      {:error, reason} ->
        IO.puts("Error reading #{file_path}: #{reason}")
    end
  end
end

DoubleNamespaceFixer.run()
