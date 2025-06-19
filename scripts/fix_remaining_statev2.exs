#!/usr/bin/env elixir

# Script to fix remaining StateV2 namespace references
# This script replaces StateV2 with AriaEngine.StateV2 in specific contexts

defmodule RemainingStateV2Fixer do
  def run do
    IO.puts("Starting remaining StateV2 namespace fix...")
    
    # Find all .ex files in lib directory
    files = Path.wildcard("lib/**/*.ex")
    
    IO.puts("Found #{length(files)} files to process")
    
    Enum.each(files, &fix_file/1)
    
    IO.puts("Remaining StateV2 namespace fix completed!")
  end
  
  defp fix_file(file_path) do
    content = File.read!(file_path)
    
    # Check if file has StateV2 references that aren't already AriaEngine.StateV2
    if String.contains?(content, "StateV2") and not String.contains?(content, "AriaEngine.StateV2") do
      IO.puts("Processing #{file_path}...")
      
      updated_content = content
      |> String.replace("StateV2.add_fact", "AriaEngine.StateV2.add_fact")
      |> String.replace("StateV2.get_fact", "AriaEngine.StateV2.get_fact")
      |> String.replace("StateV2.set_fact", "AriaEngine.StateV2.set_fact")
      |> String.replace("StateV2.matches?", "AriaEngine.StateV2.matches?")
      |> String.replace("StateV2.new", "AriaEngine.StateV2.new")
      
      # Write back to file
      File.write!(file_path, updated_content)
      IO.puts("Fixed #{file_path}")
    end
  end
end

RemainingStateV2Fixer.run()
