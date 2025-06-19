#!/usr/bin/env elixir

# JSON Solution Tree Generator - Main Entry Point
# Modular agent-entity-capability scenario that outputs JSON solution trees and markdown logs

Code.require_file("json_solution/test_data.exs", __DIR__)
Code.require_file("json_solution/scheduler_runner.exs", __DIR__)
Code.require_file("json_solution/activity_logger.exs", __DIR__)
Code.require_file("json_solution/json_generators.exs", __DIR__)
Code.require_file("json_solution/markdown_generators.exs", __DIR__)
Code.require_file("json_solution/file_writer.exs", __DIR__)

defmodule JsonSolutionTest do
  @moduledoc """
  JSON Solution Tree Test - Main Entry Point
  
  A minimal scenario with 3 workers, 3 tasks, and 3 tools that generates
  comprehensive JSON solution trees and markdown logs showing 
  agent-entity-capability planning results.
  """
  
  require Logger
  
  alias JsonSolution.{TestData, SchedulerRunner, ActivityLogger, 
                      JsonGenerators, MarkdownGenerators, FileWriter}
  
  def run_test do
    print_test_header()
    Logger.info("Generating JSON solution trees and markdown logs")
    Logger.info("3 workers, 3 tasks, 3 tools - Simple work assignment")
    Logger.info("")
    
    # Create test scenario
    {workers, tools, tasks} = TestData.create_simple_scenario()
    
    Logger.info("Workers: #{length(workers)}")
    Logger.info("Tools: #{length(tools)}")
    Logger.info("Tasks: #{length(tasks)}")
    Logger.info("")
    
    # Initialize activity logger
    ActivityLogger.start_logging()
    
    # Run scheduling with detailed logging
    {execution_time_ms, result} = SchedulerRunner.run_with_logging(workers, tools, tasks)
    
    case result do
      {:ok, simulation_result} ->
        Logger.info("✅ SUCCESS: #{execution_time_ms}ms")
        Logger.info("Schedule: #{length(simulation_result.schedule)} activities scheduled")
        
        # Generate all output files
        generate_all_outputs(execution_time_ms, simulation_result, workers, tools, tasks)
        
        Logger.info("")
        Logger.info("=== JSON SOLUTION GENERATION COMPLETE ===")
        
      {:error, reason} ->
        Logger.error("❌ FAILED: #{reason} (#{execution_time_ms}ms)")
    end
  end
  
  defp generate_all_outputs(execution_time_ms, simulation_result, workers, tools, tasks) do
    Logger.info("Generating output files...")
    
    # Generate JSON files
    JsonGenerators.generate_all(execution_time_ms, simulation_result, workers, tools, tasks)
    
    # Generate markdown files
    MarkdownGenerators.generate_all(execution_time_ms, simulation_result, workers, tools, tasks)
    
    Logger.info("📊 Generated complete solution package:")
    Logger.info("  JSON Files:")
    Logger.info("    - solution_tree.json")
    Logger.info("    - agent_assignments.json") 
    Logger.info("    - resource_timeline.json")
    Logger.info("    - complexity_analysis.json")
    Logger.info("  Markdown Files:")
    Logger.info("    - scheduling_test_log.md")
    Logger.info("    - activity_log.md")
  end
  
  defp print_test_header do
    IO.puts """
    
    JSON SOLUTION TREE TEST
    Agent-Entity-Capability Planning
    
    Test: Simple task assignment with 3 workers, 3 tasks, 3 tools
    Output: JSON solution trees and markdown logs
    Focus: Agent-capability matching and resource allocation
    
    """
  end
end

# Run the test
Logger.configure(level: :info)
JsonSolutionTest.run_test()
