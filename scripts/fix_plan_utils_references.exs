#!/usr/bin/env elixir

# Script to fix remaining Plan.Utils references that need AriaEngine prefix
# This script fixes unqualified Plan.Utils calls

defmodule PlanUtilsReferenceFixer do
  def run do
    IO.puts("Starting Plan.Utils reference fix...")
    
    # Find all .ex files in lib directory
    files = Path.wildcard("lib/**/*.ex")
    
    IO.puts("Found #{length(files)} files to process")
    
    Enum.each(files, &fix_file/1)
    
    IO.puts("Plan.Utils reference fix completed!")
  end
  
  defp fix_file(file_path) do
    content = File.read!(file_path)
    
    # Check if file has unqualified Plan.Utils references
    if String.contains?(content, "Plan.Utils.") and not String.contains?(content, "AriaEngine.Plan.Utils.") do
      IO.puts("Processing #{file_path}...")
      
      updated_content = content
      |> String.replace("Plan.Utils.create_initial_solution_tree", "AriaEngine.Plan.Utils.create_initial_solution_tree")
      |> String.replace("Plan.Utils.get_primitive_actions_dfs", "AriaEngine.Plan.Utils.get_primitive_actions_dfs")
      |> String.replace("Plan.Utils.plan_cost", "AriaEngine.Plan.Utils.plan_cost")
      |> String.replace("Plan.Utils.tree_stats", "AriaEngine.Plan.Utils.tree_stats")
      |> String.replace("Plan.Utils.validate_plan", "AriaEngine.Plan.Utils.validate_plan")
      |> String.replace("Plan.Utils.update_cached_states", "AriaEngine.Plan.Utils.update_cached_states")
      |> String.replace("Plan.Utils.get_all_descendants", "AriaEngine.Plan.Utils.get_all_descendants")
      |> String.replace("Plan.Utils.generate_node_id", "AriaEngine.Plan.Utils.generate_node_id")
      |> String.replace("Plan.Utils.is_primitive_task?", "AriaEngine.Plan.Utils.is_primitive_task?")
      
      # Write back to file
      File.write!(file_path, updated_content)
      IO.puts("Fixed #{file_path}")
    end
  end
end

PlanUtilsReferenceFixer.run()
