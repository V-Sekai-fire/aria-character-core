#!/usr/bin/env elixir

# Simple MCP Test to show obvious failures

defmodule SimpleMCPTest do
  def run do
    IO.puts("=== Simple MCP Test ===")
    
    # Test 1: Single Activity
    request = %{
      "schedule_name" => "Single",
      "activities" => [
        %{"id" => "A", "duration" => 1}
      ]
    }
    
    IO.puts("Testing single activity scheduling...")
    result = call_mcp_tool(request)
    
    case result do
      %{"status" => "success", "schedule" => schedule} ->
        if length(schedule) == 0 do
          IO.puts("❌ FAILURE: Expected schedule with 1 activity, got empty schedule")
          IO.puts("  EXPECTED: [A(0-1)]")
          IO.puts("  ACTUAL:   [] (empty)")
          IO.puts("  PROBLEM:  MCP tool is in analysis-only mode!")
        else
          IO.puts("✅ SUCCESS: Generated schedule with #{length(schedule)} activities")
        end
      
      %{"status" => "error"} = error ->
        IO.puts("💥 ERROR: #{inspect(error)}")
      
      other ->
        IO.puts("💥 UNEXPECTED: #{inspect(other)}")
    end
  end

  defp call_mcp_tool(request) do
    alias AriaEngine.MCP.Tools.ScheduleActivities
    
    case ScheduleActivities.execute(request, %{}) do
      {:reply, response, _frame} ->
        case response do
          %{content: [%{"text" => text}]} -> Jason.decode!(text)
          %{content: [%{text: text}]} -> Jason.decode!(text)
          %{text: text} -> Jason.decode!(text)
          text when is_binary(text) -> Jason.decode!(text)
          _ -> %{"status" => "error", "reason" => "Invalid response format"}
        end
      
      other ->
        %{"status" => "error", "reason" => "Unexpected response: #{inspect(other)}"}
    end
  end
end

SimpleMCPTest.run()
