defmodule AriaEngine.Membrane.ValidationPipelineFilterTest do
  use ExUnit.Case, async: true
  alias AriaEngine.Membrane.ValidationPipelineFilter
  alias Timeline.Internal.STN

  describe("ValidationPipelineFilter with failing STN cases") do
    test "detects inconsistent STN through validation pipeline" do
      _stn =
        STN.new()
        |> STN.add_time_point("task_a")
        |> STN.add_time_point("task_b")
        |> STN.add_constraint("task_a", "task_b", {20, 30})
        |> STN.add_constraint("task_b", "task_a", {20, 30})

      mcp_request = %{
        "id" => "test_inconsistent_stn",
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "params" => %{
          "name" => "schedule_activities",
          "arguments" => %{
            "schedule_name" => "inconsistent_test",
            "activities" => [
              %{
                "id" => "task_a",
                "name" => "Task A",
                "duration" => %{
                  "start" => "2025-06-20T09:00:00Z",
                  "end" => "2025-06-20T09:30:00Z"
                }
              },
              %{
                "id" => "task_b",
                "name" => "Task B",
                "duration" => %{
                  "start" => "2025-06-20T10:00:00Z",
                  "end" => "2025-06-20T10:30:00Z"
                }
              }
            ],
            "constraints" => %{
              "temporal_constraints" => [
                %{
                  "from" => "task_a",
                  "to" => "task_b",
                  "min_distance" => 20,
                  "max_distance" => 30
                },
                %{
                  "from" => "task_b",
                  "to" => "task_a",
                  "min_distance" => 20,
                  "max_distance" => 30
                }
              ]
            },
            "entities" => [],
            "resources" => %{}
          }
        }
      }

      buffer = %Membrane.Buffer{payload: Jason.encode!(mcp_request), metadata: %{}}
      {[], state} = ValidationPipelineFilter.handle_init(nil, %{timeout: 30000})
      {actions, _new_state} = ValidationPipelineFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, response_buffer}] = actions
      response = Jason.decode!(response_buffer.payload)
      assert response["result"]["status"] in ["inconsistent", "infeasible"]
    end

    test "detects over-constrained temporal windows" do
      mcp_request = %{
        "id" => "test_over_constrained",
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "params" => %{
          "name" => "schedule_activities",
          "arguments" => %{
            "schedule_name" => "over_constrained_test",
            "activities" => [
              %{
                "id" => "start",
                "name" => "Start Task",
                "duration" => %{
                  "start" => "2025-06-20T09:00:00Z",
                  "end" => "2025-06-20T09:00:00Z"
                }
              },
              %{
                "id" => "middle",
                "name" => "Middle Task",
                "duration" => %{
                  "start" => "2025-06-20T09:05:00Z",
                  "end" => "2025-06-20T09:05:00Z"
                }
              },
              %{
                "id" => "end",
                "name" => "End Task",
                "duration" => %{
                  "start" => "2025-06-20T09:15:00Z",
                  "end" => "2025-06-20T09:15:00Z"
                }
              }
            ],
            "constraints" => %{
              "temporal_constraints" => [
                %{"from" => "start", "to" => "middle", "min_distance" => 5, "max_distance" => 5},
                %{"from" => "middle", "to" => "end", "min_distance" => 5, "max_distance" => 5},
                %{"from" => "start", "to" => "end", "min_distance" => 15, "max_distance" => 15}
              ]
            },
            "entities" => [],
            "resources" => %{}
          }
        }
      }

      buffer = %Membrane.Buffer{payload: Jason.encode!(mcp_request), metadata: %{}}
      {[], state} = ValidationPipelineFilter.handle_init(nil, %{timeout: 30000})
      {actions, _new_state} = ValidationPipelineFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, response_buffer}] = actions
      response = Jason.decode!(response_buffer.payload)
      assert response["result"]["status"] in ["inconsistent", "infeasible"]
    end

    test "handles boundary conditions gracefully" do
      mcp_request = %{
        "id" => "test_boundary",
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "params" => %{
          "name" => "schedule_activities",
          "arguments" => %{
            "schedule_name" => "boundary_test",
            "activities" => [
              %{
                "id" => "a",
                "name" => "Task A",
                "duration" => %{
                  "start" => "2025-06-20T09:00:00Z",
                  "end" => "2025-06-20T09:00:00Z"
                }
              },
              %{
                "id" => "b",
                "name" => "Task B",
                "duration" => %{
                  "start" => "2025-06-20T10:00:00Z",
                  "end" => "2025-06-20T10:00:00Z"
                }
              }
            ],
            "constraints" => %{
              "temporal_constraints" => [
                %{
                  "from" => "a",
                  "to" => "b",
                  "min_distance" => 999_999,
                  "max_distance" => 1_000_000
                }
              ]
            },
            "entities" => [],
            "resources" => %{}
          }
        }
      }

      buffer = %Membrane.Buffer{payload: Jason.encode!(mcp_request), metadata: %{}}
      {[], state} = ValidationPipelineFilter.handle_init(nil, %{timeout: 30000})
      {actions, _new_state} = ValidationPipelineFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, response_buffer}] = actions
      response = Jason.decode!(response_buffer.payload)
      assert Map.has_key?(response, "result")
      assert is_binary(response["result"]["status"])
    end

    test "compares hybrid vs minizinc solver results" do
      mcp_request = %{
        "id" => "test_comparison",
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "params" => %{
          "name" => "schedule_activities",
          "arguments" => %{
            "schedule_name" => "comparison_test",
            "activities" => [
              %{
                "id" => "task1",
                "name" => "Simple Task",
                "duration" => %{
                  "start" => "2025-06-20T09:00:00Z",
                  "end" => "2025-06-20T10:00:00Z"
                }
              }
            ],
            "constraints" => %{},
            "entities" => [],
            "resources" => %{}
          }
        }
      }

      buffer = %Membrane.Buffer{payload: Jason.encode!(mcp_request), metadata: %{}}
      {[], state} = ValidationPipelineFilter.handle_init(nil, %{timeout: 30000})
      {actions, _new_state} = ValidationPipelineFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, response_buffer}] = actions
      response = Jason.decode!(response_buffer.payload)
      assert Map.has_key?(response["result"], "validation_type")
      assert Map.has_key?(response["result"], "hybrid_result")

      if state.minizinc_available do
        assert Map.has_key?(response["result"], "minizinc_result")
      end
    end
  end
end