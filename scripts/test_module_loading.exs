#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Test module loading and function availability

Mix.install([])

# Add the lib directory to the code path
Code.prepend_path("lib")

# Require the modules
Code.require_file("lib/aria_engine/convergence_flow.ex")
Code.require_file("lib/aria_engine/convergence_flow_optimized.ex")

defmodule ModuleTest do
  def test_modules do
    IO.puts "=== Module Loading Test ==="
    
    # Test if modules are loaded
    IO.puts "AriaEngine.ConvergenceFlow loaded: #{Code.ensure_loaded?(AriaEngine.ConvergenceFlow)}"
    IO.puts "AriaEngine.ConvergenceFlowOptimized loaded: #{Code.ensure_loaded?(AriaEngine.ConvergenceFlowOptimized)}"
    
    # Test function availability
    IO.puts "\n=== Function Availability ==="
    
    # Check ConvergenceFlow functions
    flow_functions = AriaEngine.ConvergenceFlow.__info__(:functions)
    IO.puts "ConvergenceFlow functions: #{inspect(flow_functions)}"
    
    # Check ConvergenceFlowOptimized functions  
    optimized_functions = AriaEngine.ConvergenceFlowOptimized.__info__(:functions)
    IO.puts "ConvergenceFlowOptimized functions: #{inspect(optimized_functions)}"
    
    # Test a simple call
    IO.puts "\n=== Simple Function Test ==="
    test_activities = [
      %{id: "test1", duration: 5, resources: [:cpu], dependencies: [], priority: 1}
    ]
    
    try do
      result = AriaEngine.ConvergenceFlow.solve_activities_with_convergence(test_activities, stages: 2)
      IO.puts "ConvergenceFlow test: SUCCESS - #{inspect(result)}"
    rescue
      e -> IO.puts "ConvergenceFlow test: FAILED - #{inspect(e)}"
    end
    
    try do
      result = AriaEngine.ConvergenceFlowOptimized.solve_activities_streaming(test_activities, stages: 2)
      IO.puts "ConvergenceFlowOptimized test: SUCCESS - #{inspect(result)}"
    rescue
      e -> IO.puts "ConvergenceFlowOptimized test: FAILED - #{inspect(e)}"
    end
  end
end

ModuleTest.test_modules()
