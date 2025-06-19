#!/usr/bin/env elixir

# Script to fix StateV2 namespace references throughout the codebase
# This script replaces %StateV2{} with %AriaEngine.StateV2{} and StateV2.t() with AriaEngine.StateV2.t()

defmodule StateV2NamespaceFixer do
  def run do
    IO.puts("Starting StateV2 namespace fix...")
    
    # Find all .ex files in lib directory
    files = Path.wildcard("lib/**/*.ex")
    
    IO.puts("Found #{length(files)} files to process")
    
    Enum.each(files, &fix_file/1)
    
    IO.puts("StateV2 namespace fix completed!")
  end
  
  defp fix_file(file_path) do
    content = File.read!(file_path)
    
    # Skip if already has AriaEngine.StateV2
    unless String.contains?(content, "AriaEngine.StateV2") do
      # Check if file has StateV2 references
      if String.contains?(content, "StateV2") do
        IO.puts("Processing #{file_path}...")
        
        updated_content = content
        |> String.replace("%StateV2{", "%AriaEngine.StateV2{")
        |> String.replace("StateV2.t()", "AriaEngine.StateV2.t()")
        |> String.replace("StateV2.t() |", "AriaEngine.StateV2.t() |")
        |> String.replace("StateV2.t()} |", "AriaEngine.StateV2.t()} |")
        |> String.replace("StateV2.fact_value()", "AriaEngine.StateV2.fact_value()")
        |> String.replace("alias StateV2", "alias AriaEngine.StateV2")
        
        # Write back to file
        File.write!(file_path, updated_content)
        IO.puts("Fixed #{file_path}")
      end
    else
      IO.puts("Skipping #{file_path} - already has AriaEngine.StateV2")
    end
  end
end

StateV2NamespaceFixer.run()
