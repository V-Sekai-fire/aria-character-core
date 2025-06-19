#!/usr/bin/env elixir

# Quick Director Tool Test
# Simple test to verify the director tool works with real MCP calls

defmodule DirectorQuickTest do
  @moduledoc """
  Simple test for the director tool - real MCP calls, narrative extraction, entity checking.
  """

  def run_test do
    IO.puts("\n🎬 Director Tool Quick Test")
    IO.puts("==========================\n")
    
    # Test the director tool with real MCP call
    test_director_call()
  end
  
  def test_director_call do
    IO.puts("📞 Making real director MCP call...")
    
    # Make the actual MCP call
    params = %{
      "template" => "tri_zone_integration",
      "narrative_mode" => true
    }
    
    try do
      # Real call to the MCP tools
      result = AriaEngine.MCPTools.handle_tool_call(:director, params)
      
      case result do
        %{status: "success"} ->
          IO.puts("✅ Director call successful!")
          analyze_result(result)
          
        %{"status" => "success"} ->
          IO.puts("✅ Director call successful!")
          analyze_result(result)
          
        %{status: "error", reason: reason} ->
          IO.puts("❌ Error: #{reason}")
          
        %{"status" => "error", "reason" => reason} ->
          IO.puts("❌ Error: #{reason}")
          
        other ->
          IO.puts("❓ Unexpected result format:")
          IO.inspect(other, limit: :infinity)
      end
      
    rescue
      e ->
        IO.puts("❌ Exception during MCP call: #{Exception.message(e)}")
        IO.puts("   #{Exception.format_stacktrace(System.stacktrace())}")
    end
  end
  
  defp analyze_result(result) do
    IO.puts("\n📊 Result Analysis:")
    IO.puts("------------------")
    
    # Extract and save narrative
    extract_narrative(result)
    
    # Check entity assignments
    check_entity_assignments(result)
    
    # Basic stats
    show_basic_stats(result)
  end
  
  defp extract_narrative(result) do
    narrative = result[:narrative] || result["narrative"]
    
    if narrative do
      File.write!("director_output.md", narrative)
      IO.puts("📝 Narrative saved to director_output.md")
      
      # Show first few lines
      lines = String.split(narrative, "\n") |> Enum.take(3)
      IO.puts("   Preview: #{hd(lines)}")
    else
      IO.puts("❌ No narrative found in result")
    end
  end
  
  defp check_entity_assignments(result) do
    timeline = result[:timeline] || result["timeline"] || []
    
    IO.puts("\n👥 Entity Assignments:")
    IO.puts("--------------------")
    
    if length(timeline) > 0 do
      # Group activities by entity
      entity_assignments = Enum.group_by(timeline, fn activity ->
        activity[:entity] || activity["entity"] || "no_entity"
      end)
      
      Enum.each(entity_assignments, fn {entity, activities} ->
        IO.puts("   #{entity}: #{length(activities)} activities")
        Enum.each(Enum.take(activities, 3), fn activity ->
          activity_id = activity[:activity_id] || activity["activity_id"] || "unknown"
          IO.puts("     - #{activity_id}")
        end)
        if length(activities) > 3 do
          IO.puts("     - ... and #{length(activities) - 3} more")
        end
      end)
    else
      IO.puts("   ❌ No timeline found")
    end
  end
  
  defp show_basic_stats(result) do
    timeline = result[:timeline] || result["timeline"] || []
    activity_log = result[:activity_log] || result["activity_log"] || []
    
    IO.puts("\n📈 Basic Stats:")
    IO.puts("--------------")
    IO.puts("   Activities scheduled: #{length(timeline)}")
    IO.puts("   Activity log entries: #{length(activity_log)}")
    
    # Check if entities are being used
    entities_used = timeline
                   |> Enum.map(fn activity -> 
                     activity[:entity] || activity["entity"] 
                   end)
                   |> Enum.reject(&is_nil/1)
                   |> Enum.uniq()
                   
    IO.puts("   Entities used: #{length(entities_used)}")
    
    if length(entities_used) > 0 do
      IO.puts("   ✅ Entities are being assigned to activities")
    else
      IO.puts("   ⚠️  No entities found in assignments")
    end
  end
end

# Run the test
DirectorQuickTest.run_test()
