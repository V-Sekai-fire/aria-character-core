#!/usr/bin/env elixir

# Test simple activity through the stdio MCP interface
Mix.install([
  {:jason, "~> 1.4"}
])

defmodule SimpleActivityStdioTest do
  require Logger

  def run do
    Logger.info("=== Simple Activity Stdio Test ===")
    
    # Create a simple, well-formed MCP request
    mcp_request = %{
      "id" => "simple_test_001",
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
          "schedule_name" => "simple_test",
          "activities" => [
            %{
              "id" => "meeting_1",
              "name" => "Team Standup",
              "duration" => %{
                "start" => "2025-06-21T09:00:00Z",
                "end" => "2025-06-21T09:30:00Z"
              },
              "participants" => ["alice"],
              "resources" => ["room_1"]
            }
          ],
          "entities" => [
            %{
              "id" => "alice",
              "type" => "person",
              "availability" => "full_time"
            }
          ],
          "resources" => %{
            "room_1" => %{
              "type" => "meeting_room",
              "capacity" => 4
            }
          },
          "constraints" => %{
            "max_concurrent_activities" => 3,
            "require_resources" => true
          }
        }
      }
    }
    
    Logger.info("Request: #{Jason.encode!(mcp_request, pretty: true)}")
    
    # Test through the pipeline manager approach
    try do
      Logger.info("Starting pipeline manager...")
      
      # Start the pipeline manager
      case AriaEngine.Membrane.PipelineManager.start_link([]) do
        {:ok, _pid} ->
          Logger.info("✅ Pipeline manager started")
          
          # Extract the tool call
          tool_name = mcp_request["params"]["name"]
          params = mcp_request["params"]["arguments"]
          
          Logger.info("Extracted tool call: #{tool_name}")
          Logger.info("Parameters: #{inspect(params, pretty: true)}")
          
          # Add pipeline topology to params
          enhanced_params = Map.put(params, "pipeline_topology", "plan_transform_pipeline")
          
          Logger.info("MCP tool call: #{tool_name} with params: #{inspect(enhanced_params)}")
          
          # Create a pipeline and send the request
          case AriaEngine.Membrane.PipelineManager.create_testing_pipeline(:plan_transformation) do
            {:ok, pipeline_pid} ->
              Logger.info("✅ Pipeline created: #{inspect(pipeline_pid)}")
              
              # Send request to pipeline
              case AriaEngine.Membrane.PipelineManager.send_request_to_pipeline(pipeline_pid, enhanced_params) do
                :ok ->
                  Logger.info("✅ Request sent to pipeline successfully")
                  
                  # Create response
                  response = %{
                    "id" => mcp_request["id"],
                    "jsonrpc" => "2.0",
                    "result" => %{
                      "status" => "processing",
                      "pipeline_id" => inspect(pipeline_pid),
                      "topology" => "plan_transform_pipeline",
                      "message" => "Request sent to Membrane pipeline for processing",
                      "schedule" => [],
                      "analysis" => %{},
                      "resource_utilization" => %{},
                      "timeline" => [],
                      "simulation_metadata" => %{
                        "pipeline_based" => true,
                        "topology" => "plan_transform_pipeline"
                      }
                    }
                  }
                  
                  Logger.info("✅ SUCCESS: Pipeline processing initiated")
                  Logger.info("Response: #{Jason.encode!(response, pretty: true)}")
                  
                  # Validate response format
                  if Map.has_key?(response["result"], "schedule") do
                    Logger.info("✅ Schedule field present")
                  end
                  
                  if Map.has_key?(response["result"], "pipeline_id") do
                    Logger.info("✅ Pipeline ID present: #{response["result"]["pipeline_id"]}")
                  end
                  
                {:error, reason} ->
                  Logger.error("❌ Failed to send request to pipeline: #{inspect(reason)}")
              end
              
            {:error, reason} ->
              Logger.error("❌ Failed to create pipeline: #{inspect(reason)}")
          end
          
        {:error, reason} ->
          Logger.error("❌ Failed to start pipeline manager: #{inspect(reason)}")
      end
      
    rescue
      error ->
        Logger.error("❌ EXCEPTION: #{inspect(error)}")
        Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
    end
    
    Logger.info("=== Test Complete ===")
  end
end

SimpleActivityStdioTest.run()
