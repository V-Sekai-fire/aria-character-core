#!/usr/bin/env elixir

# Working Director Tool Test
# Properly loads the project and tests the director tool

# Change to project directory and load dependencies
System.cmd("mix", ["deps.get"], cd: ".")

# Use Mix.install to properly set up the environment
Mix.install([])

# Compile the project
{output, exit_code} = System.cmd("mix", ["compile"], cd: ".")

if exit_code != 0 do
  IO.puts("❌ Compilation failed:")
  IO.puts(output)
  System.halt(1)
end

# Load all compiled modules
Code.append_path("_build/dev/lib/aria_character_core/ebin")

defmodule DirectorWorkingTest do
  @moduledoc """
  Proper test for the director tool with correct module loading.
  """

  def run_test do
    IO.puts("\n🎬 Director Tool Working Test")
    IO.puts("============================\n")
    
    # Test the director tool with real MCP call
    test_director_call()
  end
  
  def test_director_call do
    IO.puts("📞 Making director MCP call...")
    
    # Test parameters
    params = %{
      "template" => "tri_zone_integration",
      "narrative_mode" => true
    }
    
    try do
      # Call the MCP tools directly
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
        IO.puts("Stack trace:")
        IO.puts(Exception.format_stacktrace(__STACKTRACE__))
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
    
    # Check mission duration formatting
    check_duration_formatting(result)
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
  
  defp check_duration_formatting(result) do
    activity_log = result[:activity_log] || result["activity_log"] || []
    
    IO.puts("\n⏰ Duration Formatting Check:")
    IO.puts("-----------------------------")
    
    if length(activity_log) > 0 do
      Enum.take(activity_log, 5)
      |> Enum.each(fn activity ->
        timestamp = activity[:timestamp] || activity["timestamp"]
        mission_duration = activity[:mission_duration] || activity["mission_duration"]
        relative_minutes = activity[:relative_minutes] || activity["relative_minutes"]
        activity_id = activity[:activity_id] || activity["activity_id"] || "unknown"
        
        cond do
          is_binary(timestamp) ->
            IO.puts("   📅 Absolute timestamp: #{timestamp} (#{activity_id})")
          is_binary(mission_duration) ->
            IO.puts("   ✅ Mission duration: #{mission_duration} (#{activity_id})")
          is_integer(relative_minutes) ->
            IO.puts("   ⏱️ Relative time: #{relative_minutes} minutes (#{activity_id})")
          true ->
            IO.puts("   ❓ Unknown format for #{activity_id}: #{inspect(activity)}")
        end
      end)
    else
      IO.puts("   ❌ No activity log found to check formatting")
    end
  end
end

# Run the test
DirectorWorkingTest.run_test()
