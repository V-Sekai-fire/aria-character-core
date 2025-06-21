#!/usr/bin/env elixir

# Test script for MiniZinc Template Pipeline
Mix.install([
  {:jason, "~> 1.4"},
  {:mustache, "~> 0.5"},
  {:porcelain, "~> 2.0"}
])

defmodule TestMiniZincPipeline do
  @moduledoc """
  Test script to verify MiniZinc template pipeline functionality.
  """

  require Logger

  def run do
    Logger.info("🧪 Testing MiniZinc Template Pipeline")
    
    # Test 1: Check MiniZinc availability
    test_minizinc_availability()
    
    # Test 2: Test template rendering
    test_template_rendering()
    
    # Test 3: Test Porcelain execution (if MiniZinc available)
    test_porcelain_execution()
    
    Logger.info("✅ All tests completed")
  end

  defp test_minizinc_availability do
    Logger.info("🔧 Testing MiniZinc availability...")
    
    case Porcelain.exec("minizinc", ["--version"]) do
      %{status: 0, out: output} ->
        Logger.info("✅ MiniZinc available: #{String.trim(output)}")
        true
        
      %{status: exit_code} ->
        Logger.warn("⚠️ MiniZinc not available (exit code: #{exit_code})")
        false
        
      error ->
        Logger.warn("⚠️ MiniZinc check failed: #{inspect(error)}")
        false
    end
  rescue
    error ->
      Logger.warn("⚠️ MiniZinc check error: #{Exception.message(error)}")
      false
  end

  defp test_template_rendering do
    Logger.info("🔧 Testing Mustache template rendering...")
    
    # Create a simple test template
    template = """
    % Test MiniZinc Template
    int: num_activities = {{num_activities}};
    array[1..num_activities] of int: durations = [{{#durations}}{{.}}{{#has_next}}, {{/has_next}}{{/durations}}];
    
    % Constraints
    {{#constraints}}
    constraint start[{{to_activity}}] >= start[{{from_activity}}] + {{min_distance}};
    {{/constraints}}
    """
    
    # Test data
    template_vars = %{
      num_activities: 3,
      durations: [
        %{value: 10, has_next: true},
        %{value: 20, has_next: true}, 
        %{value: 15, has_next: false}
      ],
      constraints: [
        %{from_activity: 1, to_activity: 2, min_distance: 10},
        %{from_activity: 2, to_activity: 3, min_distance: 20}
      ]
    }
    
    try do
      rendered = :mustache.render(template, template_vars)
      Logger.info("✅ Template rendering successful")
      Logger.debug("Rendered template:\n#{rendered}")
      true
    rescue
      error ->
        Logger.error("❌ Template rendering failed: #{Exception.message(error)}")
        false
    end
  end

  defp test_porcelain_execution do
    Logger.info("🔧 Testing Porcelain execution...")
    
    # Create a simple test MiniZinc model
    test_model = """
    % Simple test model
    var 1..10: x;
    var 1..10: y;
    
    constraint x + y = 10;
    
    solve satisfy;
    
    output ["x = " ++ show(x) ++ ", y = " ++ show(y)];
    """
    
    # Write to temporary file
    temp_file = Path.join(System.tmp_dir!(), "test_model_#{:rand.uniform(1000)}.mzn")
    
    try do
      File.write!(temp_file, test_model)
      Logger.info("📝 Created test model: #{temp_file}")
      
      # Test Porcelain execution
      args = ["--solver", "org.minizinc.mip.coin-bc", temp_file]
      
      case Porcelain.exec("minizinc", args, timeout: 10_000) do
        %{status: 0, out: output} ->
          Logger.info("✅ Porcelain execution successful")
          Logger.info("Output: #{String.trim(output)}")
          true
          
        %{status: exit_code, out: output, err: error} ->
          Logger.warn("⚠️ MiniZinc execution failed (exit code: #{exit_code})")
          Logger.warn("Output: #{output}")
          Logger.warn("Error: #{error}")
          false
          
        %{status: :timeout} ->
          Logger.warn("⚠️ MiniZinc execution timed out")
          false
      end
    rescue
      error ->
        Logger.error("❌ Porcelain execution test failed: #{Exception.message(error)}")
        false
    after
      # Cleanup
      if File.exists?(temp_file) do
        File.rm(temp_file)
        Logger.debug("🧹 Cleaned up test file: #{temp_file}")
      end
    end
  end
end

# Run the tests
TestMiniZincPipeline.run()
