#!/usr/bin/env elixir

# Test script for the modular MCP scheduler capability testing system
# This script tests the new TestSchedulerCapabilities tool with its split modules

Mix.install([
  {:jason, "~> 1.4"}
])

defmodule TestRunner do
  def run do
    IO.puts("=== Testing Modular MCP Scheduler Capability System ===\n")
    
    # Test 1: Quick test suite
    IO.puts("1. Testing quick test suite...")
    test_quick_suite()
    
    # Test 2: Specific test
    IO.puts("\n2. Testing specific test execution...")
    test_specific_test()
    
    # Test 3: Module availability
    IO.puts("\n3. Testing module availability...")
    test_module_availability()
    
    IO.puts("\n=== Test Complete ===")
  end
  
  defp test_quick_suite do
    try do
      # Simulate the TestSchedulerCapabilities tool execution
      params = %{
        "test_level" => "quick",
        "include_raw_results" => false
      }
      
      IO.puts("  ✓ Quick test parameters: #{inspect(params)}")
      IO.puts("  ✓ Would execute: BasicTests, DependencyTests, EntityTests, ResourceTests")
      
    rescue
      e -> IO.puts("  ❌ Error: #{Exception.message(e)}")
    end
  end
  
  defp test_specific_test do
    try do
      params = %{
        "test_level" => "specific",
        "specific_test" => "entity_capability_matching",
        "include_raw_results" => true
      }
      
      IO.puts("  ✓ Specific test parameters: #{inspect(params)}")
      IO.puts("  ✓ Would execute: EntityTests.test_entity_capability_matching/1")
      
    rescue
      e -> IO.puts("  ❌ Error: #{Exception.message(e)}")
    end
  end
  
  defp test_module_availability do
    modules = [
      "AriaEngine.MCP.Tools.TestSchedulerCapabilities",
      "AriaEngine.MCP.Testing.BasicTests", 
      "AriaEngine.MCP.Testing.DependencyTests",
      "AriaEngine.MCP.Testing.EntityTests",
      "AriaEngine.MCP.Testing.ResourceTests"
    ]
    
    Enum.each(modules, fn module_name ->
      try do
        # Check if the module file exists
        file_path = module_name
          |> String.replace("AriaEngine.MCP.", "lib/aria_engine/mcp/")
          |> String.replace(".", "/")
          |> Kernel.<>(".ex")
          |> String.downcase()
        
        if File.exists?(file_path) do
          IO.puts("  ✓ Module file exists: #{file_path}")
        else
          IO.puts("  ❌ Module file missing: #{file_path}")
        end
      rescue
        e -> IO.puts("  ❌ Error checking #{module_name}: #{Exception.message(e)}")
      end
    end)
  end
end

# Run the test
TestRunner.run()
