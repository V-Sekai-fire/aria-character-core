#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Script to fix StateV2 namespace issues in scheduler modules

defmodule StateV2Fixer do
  def fix_file(file_path) do
    content = File.read!(file_path)
    
    # Replace unqualified StateV2 calls with AriaEngine.StateV2
    # But preserve already qualified ones
    fixed_content = content
    |> String.replace(~r/(?<!AriaEngine\.)StateV2\./, "AriaEngine.StateV2.")
    
    if content != fixed_content do
      File.write!(file_path, fixed_content)
      IO.puts("Fixed: #{file_path}")
    else
      IO.puts("No changes needed: #{file_path}")
    end
  end
  
  def run do
    scheduler_files = [
      "lib/aria_engine/scheduler/entity_manager.ex",
      "lib/aria_engine/scheduler/resource_manager.ex",
      "lib/aria_engine/scheduler/state_manager.ex",
      "lib/aria_engine/scheduler/domain_converter.ex",
      "lib/aria_engine/scheduler/core.ex"
    ]
    
    Enum.each(scheduler_files, &fix_file/1)
    IO.puts("StateV2 namespace fixing complete!")
  end
end

StateV2Fixer.run()
