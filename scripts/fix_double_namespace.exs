#!/usr/bin/env elixir

# Script to fix double namespace prefixes like AriaEngine.Plan.AriaEngine.Plan.Utils
# This script fixes the double prefixing issue

defmodule DoubleNamespaceFixer do
  def run do
    IO.puts("Starting double namespace fix...")
    
    # Find all .ex files in lib directory
    files = Path.wildcard("lib/**/*.ex")
    
    IO.puts("Found #{length(files)} files to process")
    
    Enum.each(files, &fix_file/1)
    
    IO.puts("Double namespace fix completed!")
  end
  
  defp fix_file(file_path) do
    content = File.read!(file_path)
    
    # Check if file has double namespace issues
    if String.contains?(content, "AriaEngine.Plan.AriaEngine.Plan.Utils") or
       String.contains?(content, "AriaEngine.AriaEngine.Plan.AriaEngine.Plan.Utils") do
      IO.puts("Processing #{file_path}...")
      
      updated_content = content
      |> String.replace("AriaEngine.AriaEngine.Plan.AriaEngine.Plan.Utils", "AriaEngine.Plan.Utils")
      |> String.replace("AriaEngine.Plan.AriaEngine.Plan.Utils", "AriaEngine.Plan.Utils")
      
      # Write back to file
      File.write!(file_path, updated_content)
      IO.puts("Fixed #{file_path}")
    end
  end
end

DoubleNamespaceFixer.run()
