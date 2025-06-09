#!/usr/bin/env elixir

# Simplified test without dependencies
defmodule SimpleTest do
  def run do
    IO.puts("Starting simple test...")
    
    # Check if we can load the modules
    try do
      Code.prepend_path("apps/aria_engine/lib")
      Code.compile_file("apps/aria_engine/lib/aria_engine/state.ex")
      IO.puts("✓ State module compiled")
    rescue
      e -> IO.puts("✗ Failed to compile State: #{inspect(e)}")
    end
    
    try do
      Code.compile_file("apps/aria_engine/lib/aria_engine/domain.ex")
      IO.puts("✓ Domain module compiled")
    rescue
      e -> IO.puts("✗ Failed to compile Domain: #{inspect(e)}")
    end
    
    try do
      Code.compile_file("apps/aria_engine/lib/aria_engine/multigoal.ex")
      IO.puts("✓ Multigoal module compiled")
    rescue
      e -> IO.puts("✗ Failed to compile Multigoal: #{inspect(e)}")
    end
    
    try do
      Code.compile_file("apps/aria_engine/lib/aria_engine/plan.ex")
      IO.puts("✓ Plan module compiled")
    rescue
      e -> IO.puts("✗ Failed to compile Plan: #{inspect(e)}")
    end
    
    try do
      Code.compile_file("apps/aria_engine/lib/aria_engine/logistics_actions.ex")
      IO.puts("✓ LogisticsActions module compiled")
    rescue
      e -> IO.puts("✗ Failed to compile LogisticsActions: #{inspect(e)}")
    end
    
    try do
      Code.compile_file("apps/aria_engine/lib/aria_engine/logistics_methods.ex")
      IO.puts("✓ LogisticsMethods module compiled")
    rescue
      e -> IO.puts("✗ Failed to compile LogisticsMethods: #{inspect(e)}")
    end
    
    try do
      Code.compile_file("apps/aria_engine/lib/aria_engine.ex")
      IO.puts("✓ AriaEngine main module compiled")
    rescue
      e -> IO.puts("✗ Failed to compile AriaEngine: #{inspect(e)}")
    end
    
    IO.puts("\nTest completed.")
  end
end

SimpleTest.run()
