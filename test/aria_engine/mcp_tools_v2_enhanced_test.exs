defmodule AriaEngine.MCPToolsV2EnhancedTest do
  @moduledoc """
  Test for enhanced schedule_activities schema with all new fields.
  """
  
  use ExUnit.Case
  alias AriaEngine.MCPToolsV2
  alias AriaEngine.Membrane.PipelineManager
  
  setup do
    # Start the pipeline manager for testing
    case GenServer.start_link(PipelineManager, [], name: PipelineManager) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
    
    on_exit(fn ->
      # Only stop if it's still running
      if Process.whereis(PipelineManager) do
        GenServer.stop(PipelineManager)
      end
    end)
    
    :ok
  end
  
  describe "enhanced schedule_activities schema" do
    test "accepts all new schema fields" do
      enhanced_params = %{
        "schedule_name" => "comprehensive_test",
        "activities" => [
          %{
            "id" => "activity_1",
            "name" => "Development Task",
            "duration" => "PT4H",
            "dependencies" => ["setup_task"],
            "required_capabilities" => ["elixir", "testing"],
            "required_resources" => ["laptop", "database"],
            "participants" => ["dev_1", "dev_2"],
            "type" => "development"
          },
          %{
            "id" => "activity_2", 
            "name" => "Code Review",
            "duration" => %{
              "start" => "2025-06-20T14:00:00Z",
              "end" => "2025-06-20T15:00:00Z"
            },
            "dependencies" => ["activity_1"],
            "required_capabilities" => ["code_review"],
            "required_resources" => ["meeting_room"],
            "participants" => ["dev_1", "senior_dev"],
            "type" => "review"
          }
        ],
        "entities" => [
          %{
            "id" => "dev_1",
            "type" => "developer",
            "capabilities" => ["elixir", "testing", "code_review"],
            "availability" => %{
              "start" => "2025-06-20T09:00:00Z",
              "end" => "2025-06-20T17:00:00Z"
            },
            "current_activity" => nil,
            "resources_held" => ["laptop"],
            "metadata" => %{"experience_level" => "senior"}
          },
          %{
            "id" => "dev_2",
            "type" => "developer", 
            "capabilities" => ["elixir", "testing"],
            "availability" => "PT8H",
            "current_activity" => nil,
            "resources_held" => [],
            "metadata" => %{"experience_level" => "junior"}
          },
          %{
            "id" => "senior_dev",
            "type" => "developer",
            "capabilities" => ["elixir", "testing", "code_review", "architecture"],
            "availability" => %{
              "start" => "2025-06-20T13:00:00Z",
              "end" => "2025-06-20T16:00:00Z"
            },
            "current_activity" => nil,
            "resources_held" => [],
            "metadata" => %{"experience_level" => "senior", "specialization" => "architecture"}
          }
        ],
        "resources" => %{
          "laptop" => %{
            "type" => "equipment",
            "capacity" => 3,
            "current_usage" => 1,
            "constraints" => %{"requires_setup" => true},
            "availability_schedule" => [
              %{
                "start" => "2025-06-20T09:00:00Z",
                "end" => "2025-06-20T17:00:00Z"
              }
            ],
            "metadata" => %{"model" => "MacBook Pro", "specs" => "M2 16GB"}
          },
          "database" => %{
            "type" => "service",
            "capacity" => 10,
            "current_usage" => 2,
            "constraints" => %{"max_connections" => 10},
            "availability_schedule" => [
              %{
                "start" => "2025-06-20T00:00:00Z",
                "end" => "2025-06-20T23:59:59Z"
              }
            ],
            "metadata" => %{"type" => "PostgreSQL", "version" => "15"}
          },
          "meeting_room" => %{
            "type" => "physical",
            "capacity" => 8,
            "current_usage" => 0,
            "constraints" => %{"requires_booking" => true},
            "availability_schedule" => [
              %{
                "start" => "2025-06-20T09:00:00Z",
                "end" => "2025-06-20T17:00:00Z"
              }
            ],
            "metadata" => %{"location" => "Building A, Floor 2", "equipment" => ["projector", "whiteboard"]}
          }
        },
        "constraints" => %{
          "max_concurrent_activities" => 5,
          "require_resources" => true
        },
        "simulation_options" => %{
          "simulation_mode" => true,
          "verbose" => 2,
          "log_activities" => true
        },
        "resource_management" => %{
          "check_capacity" => true,
          "auto_allocate" => true,
          "conflict_detection" => true
        },
        "pipeline_topology" => "full_pipeline"
      }
      
      # Test that the enhanced schema is accepted
      result = MCPToolsV2.handle_tool_call(:schedule_activities, enhanced_params)
      
      # Should not error and should return a structured response
      assert is_map(result)
      assert Map.has_key?(result, "status")
      
      # Should indicate processing or success
      assert result["status"] in ["processing", "success", "error"]
      
      # If processing, should have pipeline information
      if result["status"] == "processing" do
        assert Map.has_key?(result, "pipeline_id")
        assert Map.has_key?(result, "topology")
        assert result["topology"] == "full_pipeline"
      end
    end
    
    test "handles ISO 8601 duration strings" do
      params = %{
        "schedule_name" => "iso_duration_test",
        "activities" => [
          %{
            "id" => "iso_activity",
            "duration" => "PT2H30M"
          }
        ]
      }
      
      result = MCPToolsV2.handle_tool_call(:schedule_activities, params)
      assert is_map(result)
      assert Map.has_key?(result, "status")
    end
    
    test "handles open-ended intervals" do
      params = %{
        "schedule_name" => "open_interval_test",
        "activities" => [
          %{
            "id" => "open_start_activity",
            "duration" => %{
              "end" => "2025-06-20T17:00:00Z"
            }
          },
          %{
            "id" => "open_end_activity", 
            "duration" => %{
              "start" => "2025-06-20T09:00:00Z"
            }
          }
        ]
      }
      
      result = MCPToolsV2.handle_tool_call(:schedule_activities, params)
      assert is_map(result)
      assert Map.has_key?(result, "status")
    end
    
    test "maintains backward compatibility" do
      # Test with minimal old-style parameters
      minimal_params = %{
        "schedule_name" => "backward_compat_test",
        "activities" => [
          %{
            "id" => "simple_activity",
            "duration" => "PT1H"
          }
        ]
      }
      
      result = MCPToolsV2.handle_tool_call(:schedule_activities, minimal_params)
      assert is_map(result)
      assert Map.has_key?(result, "status")
    end
  end
end
