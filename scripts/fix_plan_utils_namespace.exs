#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Script to fix Plan.Utils namespace references throughout the codebase
# This script replaces Plan.Utils with AriaEngine.Plan.Utils

defmodule PlanUtilsNamespaceFixer do
  def run do
    IO.puts("Starting Plan.Utils namespace fix...")
    
    # Find all .ex files in lib directory
    files = Path.wildcard("lib/**/*.ex")
    
    IO.puts("Found #{length(files)} files to process")
    
    Enum.each(files, &fix_file/1)
    
    IO.puts("Plan.Utils namespace fix completed!")
  end
  
  defp fix_file(file_path) do
    content = File.read!(file_path)
    
    # Check if file has Plan.Utils references
    if String.contains?(content, "Plan.Utils") do
      IO.puts("Processing #{file_path}...")
      
      updated_content = content
      |> String.replace("Plan.Utils.", "AriaEngine.Plan.Utils.")
      |> String.replace("Utils.create_initial_solution_tree", "AriaEngine.Plan.Utils.create_initial_solution_tree")
      |> String.replace("Utils.get_primitive_actions_dfs", "AriaEngine.Plan.Utils.get_primitive_actions_dfs")
      |> String.replace("Utils.plan_cost", "AriaEngine.Plan.Utils.plan_cost")
      |> String.replace("Utils.tree_stats", "AriaEngine.Plan.Utils.tree_stats")
      |> String.replace("Utils.validate_plan", "AriaEngine.Plan.Utils.validate_plan")
      |> String.replace("Utils.update_cached_states", "AriaEngine.Plan.Utils.update_cached_states")
      |> String.replace("Utils.get_all_descendants", "AriaEngine.Plan.Utils.get_all_descendants")
      |> String.replace("Utils.generate_node_id", "AriaEngine.Plan.Utils.generate_node_id")
      |> String.replace("Utils.is_primitive_task?", "AriaEngine.Plan.Utils.is_primitive_task?")
      
      # Write back to file
      File.write!(file_path, updated_content)
      IO.puts("Fixed #{file_path}")
    end
  end
end

PlanUtilsNamespaceFixer.run()
