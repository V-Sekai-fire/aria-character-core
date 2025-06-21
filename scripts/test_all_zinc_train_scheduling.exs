#!/usr/bin/env elixir

# Comprehensive test script for all MiniZinc 2024 train scheduling problems
# Tests trains05, trains09, trains12, trains15, and trains18 instances

Mix.install([
  {:jason, "~> 1.4"}
])

# Load the AriaEngine modules
Code.require_file("../lib/aria_engine.ex", __DIR__)
Code.require_file("../lib/aria_engine/mcp_tools_v2.ex", __DIR__)

defmodule AllZincTrainSchedulingTest do
  @moduledoc """
  Tests all MiniZinc 2024 train scheduling instances to verify our planner
  can handle increasing complexity and different problem configurations.
  
  Instances tested:
  - trains05.dzn: 6 stops, 2 routes, 12 services, 6 engines (baseline)
  - trains09.dzn: 9 stops, 8 routes, 16 services, 4 engines (complex routing)
  - trains12.dzn: 9 stops, 4 routes, 8 services, 4 engines (hub-based)
  - trains15.dzn: 11 stops, 5 routes, 5 services, 5 engines (large network)
  - trains18.dzn: 9 stops, 8 routes, 16 services, 2 engines (high density)
  """

  require Logger

  alias AriaEngine.MCPToolsV2

  @instances [
    %{
      name: "trains05",
      file: "trains05.dzn",
      description: "6 stops, 2 routes, 12 services, 6 engines (baseline)",
      complexity: :simple
    },
    %{
      name: "trains09", 
      file: "trains09.dzn",
      description: "9 stops, 8 routes, 16 services, 4 engines (complex routing)",
      complexity: :medium
    },
    %{
      name: "trains12",
      file: "trains12.dzn", 
      description: "9 stops, 4 routes, 8 services, 4 engines (hub-based)",
      complexity: :medium
    },
    %{
      name: "trains15",
      file: "trains15.dzn",
      description: "11 stops, 5 routes, 5 services, 5 engines (large network)",
      complexity: :complex
    },
    %{
      name: "trains18",
      file: "trains18.dzn",
      description: "9 stops, 8 routes, 16 services, 2 engines (high density)",
      complexity: :complex
    }
  ]

  def run_all_tests do
    Logger.info("=== MiniZinc 2024 Train Scheduling - All Instances Test ===")
    Logger.info("Testing #{length(@instances)} train scheduling instances")
    Logger.info("Using direct MCP tool calls for testing")
    
    results = Enum.map(@instances, &test_instance/1)
    
    # Summary report
    print_summary_report(results)
    
    Logger.info("=== All Train Scheduling Tests Complete ===")
  end

  defp test_instance(instance) do
    Logger.info("\n" <> String.duplicate("=", 60))
    Logger.info("Testing #{instance.name}: #{instance.description}")
    Logger.info("Complexity: #{instance.complexity}")
    Logger.info(String.duplicate("=", 60))
    
    start_time = System.monotonic_time(:millisecond)
    
    try do
      # Load and parse the instance data
      instance_data = load_instance_data(instance.name)
      
      # Convert to our format and test
      request = build_request_from_instance(instance.name, instance_data)
      
      Logger.info("Sending #{instance.name} scheduling request...")
      Logger.info("Network: #{length(instance_data.stops)} stops, #{length(instance_data.routes)} routes")
      Logger.info("Services: #{length(instance_data.services)}, Engines: #{length(instance_data.engines)}")
      
      case MCPToolsV2.handle_tool_call(:schedule_activities, request["params"]["arguments"]) do
        %{"status" => "processing"} = response ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time
          
          Logger.info("✅ #{instance.name} completed (mock pipeline) in #{duration}ms")
          verification_result = verify_schedule(instance.name, instance_data, response)
          
          %{
            instance: instance.name,
            status: :success,
            duration_ms: duration,
            verification: verification_result,
            complexity: instance.complexity
          }
          
        %{"status" => "error"} = response ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time
          
          Logger.error("❌ #{instance.name} failed: #{response["error"]}")
          
          %{
            instance: instance.name,
            status: :error,
            duration_ms: duration,
            error: response["error"],
            complexity: instance.complexity
          }
          
        response ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time
          
          Logger.info("✅ #{instance.name} completed in #{duration}ms")
          verification_result = verify_schedule(instance.name, instance_data, response)
          
          %{
            instance: instance.name,
            status: :success,
            duration_ms: duration,
            verification: verification_result,
            complexity: instance.complexity
          }
      end
      
    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        
        Logger.error("❌ #{instance.name} crashed: #{inspect(error)}")
        
        %{
          instance: instance.name,
          status: :crashed,
          duration_ms: duration,
          error: inspect(error),
          complexity: instance.complexity
        }
    end
  end

  defp load_instance_data("trains05") do
    %{
      stops: ["A", "B", "C", "D", "E", "F"],
      routes: [
        ["A", "B", "C", "D", "E", "F"],
        ["F", "E", "D", "C", "B", "A"]
      ],
      services: [
        %{id: "R1a", route: 1, start: 0, end: 60},
        %{id: "R1b", route: 1, start: 30, end: 90},
        %{id: "R1c", route: 1, start: 60, end: 120},
        %{id: "R1d", route: 1, start: 90, end: 150},
        %{id: "R1e", route: 1, start: 120, end: 180},
        %{id: "R1f", route: 1, start: 150, end: 210},
        %{id: "R2a", route: 2, start: 0, end: 60},
        %{id: "R2b", route: 2, start: 30, end: 90},
        %{id: "R2c", route: 2, start: 60, end: 120},
        %{id: "R2d", route: 2, start: 90, end: 150},
        %{id: "R2e", route: 2, start: 120, end: 180},
        %{id: "R2f", route: 2, start: 150, end: 210}
      ],
      engines: ["E1", "E2", "E3", "E4", "E5", "E6"],
      engine_starts: %{"E1" => "A", "E2" => "A", "E3" => "A", "E4" => "F", "E5" => "F", "E6" => "F"},
      travel_times: %{
        {"A", "B"} => 7, {"B", "A"} => 7,
        {"B", "C"} => 8, {"C", "B"} => 9,
        {"C", "D"} => 10, {"D", "C"} => 10,
        {"D", "E"} => 8, {"E", "D"} => 8,
        {"E", "F"} => 15, {"F", "E"} => 15
      },
      platforms: %{"A" => 2, "B" => 1, "C" => 1, "D" => 1, "E" => 1, "F" => 2},
      min_wait: %{"A" => 10, "B" => 4, "C" => 4, "D" => 4, "E" => 4, "F" => 10},
      makespan: 240,
      min_sep: 4
    }
  end

  defp load_instance_data("trains09") do
    %{
      stops: ["A", "B", "C", "D", "E", "F", "G", "H", "I"],
      routes: [
        ["A", "B", "C", "D", "E"],
        ["E", "D", "C", "H", "I"],
        ["I", "H", "C", "G", "F"],
        ["F", "G", "C", "B", "A"],
        ["C", "D", "E"],
        ["E", "D", "C"],
        ["C", "H", "I"],
        ["I", "H", "C"]
      ],
      services: [
        %{id: "R01", route: 1, start: 0, end: 360},
        %{id: "R02", route: 2, start: 0, end: 360},
        %{id: "R03", route: 3, start: 0, end: 360},
        %{id: "R04", route: 4, start: 0, end: 360},
        %{id: "R05", route: 5, start: 0, end: 150},
        %{id: "R06", route: 6, start: 90, end: 210},
        %{id: "R07", route: 7, start: 0, end: 150},
        %{id: "R08", route: 8, start: 90, end: 210},
        %{id: "R09", route: 1, start: 120, end: 360},
        %{id: "R10", route: 2, start: 120, end: 360},
        %{id: "R11", route: 3, start: 120, end: 360},
        %{id: "R12", route: 4, start: 120, end: 360},
        %{id: "R13", route: 5, start: 120, end: 180},
        %{id: "R14", route: 6, start: 210, end: 360},
        %{id: "R15", route: 7, start: 120, end: 180},
        %{id: "R16", route: 8, start: 210, end: 360}
      ],
      engines: ["E1", "E2", "E3", "E4"],
      engine_starts: %{"E1" => "A", "E2" => "E", "E3" => "C", "E4" => "C"},
      travel_times: %{
        {"A", "B"} => 9, {"B", "A"} => 7,
        {"B", "C"} => 12, {"C", "B"} => 9,
        {"C", "D"} => 10, {"D", "C"} => 10,
        {"D", "E"} => 8, {"E", "D"} => 9,
        {"C", "G"} => 11, {"G", "C"} => 12,
        {"C", "H"} => 6, {"H", "C"} => 4,
        {"F", "G"} => 8, {"G", "F"} => 9,
        {"H", "I"} => 9, {"I", "H"} => 12
      },
      platforms: %{"A" => 1, "B" => 1, "C" => 2, "D" => 1, "E" => 1, "F" => 1, "G" => 1, "H" => 1, "I" => 1},
      min_wait: %{"A" => 10, "B" => 10, "C" => 20, "D" => 10, "E" => 10, "F" => 10, "G" => 10, "H" => 10, "I" => 10},
      makespan: 360,
      min_sep: 8
    }
  end

  defp load_instance_data("trains12") do
    %{
      stops: ["A", "B", "C", "D", "E", "F", "G", "H", "I"],
      routes: [
        ["A", "B", "C", "D", "E", "F"],
        ["G", "B", "C", "H", "I"],
        ["F", "E", "D", "C", "B", "A"],
        ["I", "H", "C", "B", "G"]
      ],
      services: [
        %{id: "R1a", route: 1, start: 0, end: 60},
        %{id: "R1b", route: 1, start: 0, end: 70},
        %{id: "R1c", route: 1, start: 0, end: 80},
        %{id: "R2a", route: 2, start: 0, end: 90},
        %{id: "R2b", route: 2, start: 0, end: 180},
        %{id: "R3a", route: 3, start: 0, end: 190},
        %{id: "R4a", route: 4, start: 0, end: 200},
        %{id: "R4b", route: 4, start: 0, end: 210}
      ],
      engines: ["E1", "E2", "E3", "E4"],
      engine_starts: %{"E1" => "A", "E2" => "A", "E3" => "A", "E4" => "G"},
      travel_times: %{
        {"A", "B"} => 7, {"B", "A"} => 7,
        {"B", "C"} => 8, {"C", "B"} => 9,
        {"C", "D"} => 10, {"D", "C"} => 10,
        {"D", "E"} => 8, {"E", "D"} => 8,
        {"E", "F"} => 15, {"F", "E"} => 15,
        {"B", "G"} => 12, {"G", "B"} => 12,
        {"C", "H"} => 4, {"H", "C"} => 4,
        {"H", "I"} => 6, {"I", "H"} => 6
      },
      platforms: %{"A" => 2, "B" => 1, "C" => 1, "D" => 1, "E" => 1, "F" => 2, "G" => 2, "H" => 1, "I" => 2},
      min_wait: %{"A" => 10, "B" => 4, "C" => 8, "D" => 8, "E" => 4, "F" => 10, "G" => 10, "H" => 8, "I" => 10},
      makespan: 300,
      min_sep: 20
    }
  end

  defp load_instance_data("trains15") do
    %{
      stops: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K"],
      routes: [
        ["A", "B", "C", "D", "E", "F"],
        ["G", "B", "C", "J", "K"],
        ["F", "E", "D", "C", "B", "A"],
        ["K", "J", "C", "D", "H", "I"],
        ["I", "H", "D", "E", "F"]
      ],
      services: [
        %{id: "R1a", route: 1, start: 0, end: 120},
        %{id: "R2a", route: 2, start: 0, end: 120},
        %{id: "R3a", route: 3, start: 0, end: 120},
        %{id: "R4a", route: 4, start: 0, end: 120},
        %{id: "R5a", route: 5, start: 0, end: 120}
      ],
      engines: ["E1", "E2", "E3", "E4", "E5"],
      engine_starts: %{"E1" => "A", "E2" => "G", "E3" => "F", "E4" => "K", "E5" => "I"},
      travel_times: %{
        {"A", "B"} => 7, {"B", "A"} => 7,
        {"B", "C"} => 8, {"C", "B"} => 9,
        {"C", "D"} => 10, {"D", "C"} => 10,
        {"D", "E"} => 8, {"E", "D"} => 8,
        {"E", "F"} => 15, {"F", "E"} => 15,
        {"B", "G"} => 12, {"G", "B"} => 12,
        {"C", "J"} => 5, {"J", "C"} => 6,
        {"J", "K"} => 10, {"K", "J"} => 10,
        {"D", "H"} => 4, {"H", "D"} => 4,
        {"H", "I"} => 6, {"I", "H"} => 6
      },
      platforms: %{"A" => 2, "B" => 1, "C" => 2, "D" => 1, "E" => 1, "F" => 1, "G" => 2, "H" => 1, "I" => 1, "J" => 1, "K" => 2},
      min_wait: %{"A" => 10, "B" => 4, "C" => 8, "D" => 8, "E" => 4, "F" => 10, "G" => 10, "H" => 8, "I" => 10, "J" => 6, "K" => 10},
      makespan: 240,
      min_sep: 4
    }
  end

  defp load_instance_data("trains18") do
    %{
      stops: ["A", "B", "C", "D", "E", "F", "G", "H", "I"],
      routes: [
        ["A", "B", "C", "D", "E"],
        ["E", "D", "C", "H", "I"],
        ["I", "H", "C", "G", "F"],
        ["F", "G", "C", "B", "A"],
        ["C", "D", "E"],
        ["E", "D", "C"],
        ["C", "H", "I"],
        ["I", "H", "C"]
      ],
      services: [
        %{id: "R01", route: 1, start: 0, end: 60},
        %{id: "R02", route: 2, start: 0, end: 60},
        %{id: "R03", route: 3, start: 0, end: 60},
        %{id: "R04", route: 4, start: 0, end: 60},
        %{id: "R05", route: 5, start: 0, end: 60},
        %{id: "R06", route: 6, start: 0, end: 60},
        %{id: "R07", route: 7, start: 0, end: 60},
        %{id: "R08", route: 8, start: 0, end: 60},
        %{id: "R09", route: 1, start: 12, end: 60},
        %{id: "R10", route: 2, start: 12, end: 60},
        %{id: "R11", route: 3, start: 12, end: 60},
        %{id: "R12", route: 4, start: 12, end: 60},
        %{id: "R13", route: 5, start: 12, end: 60},
        %{id: "R14", route: 6, start: 12, end: 60},
        %{id: "R15", route: 7, start: 12, end: 60},
        %{id: "R16", route: 8, start: 12, end: 60}
      ],
      engines: ["E1", "E2"],
      engine_starts: %{"E1" => "A", "E2" => "C"},
      travel_times: %{
        {"A", "B"} => 1, {"B", "A"} => 1,
        {"B", "C"} => 1, {"C", "B"} => 1,
        {"C", "D"} => 1, {"D", "C"} => 1,
        {"D", "E"} => 1, {"E", "D"} => 1,
        {"C", "G"} => 1, {"G", "C"} => 1,
        {"C", "H"} => 1, {"H", "C"} => 1,
        {"F", "G"} => 1, {"G", "F"} => 1,
        {"H", "I"} => 1, {"I", "H"} => 1
      },
      platforms: %{"A" => 1, "B" => 1, "C" => 2, "D" => 1, "E" => 1, "F" => 1, "G" => 1, "H" => 1, "I" => 1},
      min_wait: %{"A" => 1, "B" => 1, "C" => 2, "D" => 1, "E" => 1, "F" => 1, "G" => 1, "H" => 1, "I" => 1},
      makespan: 60,
      min_sep: 1
    }
  end

  defp build_request_from_instance(instance_name, data) do
    # Generate activities for all services
    activities = generate_activities_from_data(data)
    
    # Define entities (engines and stops)
    entities = generate_entities_from_data(data)
    
    # Define resources (platforms)
    resources = generate_resources_from_data(data)
    
    # Define constraints
    constraints = %{
      "require_resources" => true,
      "enforce_dependencies" => true,
      "min_separation_time" => data.min_sep,
      "respect_travel_times" => true,
      "platform_capacity" => true,
      "makespan" => data.makespan
    }
    
    %{
      "id" => "zinc_train_test_#{instance_name}",
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
          "schedule_name" => "zinc_train_#{instance_name}",
          "activities" => activities,
          "entities" => entities,
          "resources" => resources,
          "constraints" => constraints,
          "travel_times" => data.travel_times
        }
      }
    }
  end

  defp generate_activities_from_data(data) do
    Enum.flat_map(data.services, fn service ->
      route = Enum.at(data.routes, service.route - 1)
      generate_service_activities(service, route, data)
    end)
  end

  defp generate_service_activities(service, route, data) do
    Enum.with_index(route)
    |> Enum.map(fn {stop, index} ->
      {start_offset, duration} = calculate_timing(route, index, data.travel_times, data.min_wait)
      
      %{
        "id" => "#{service.id}_#{stop}",
        "name" => "#{service.id} at #{stop}",
        "duration" => %{
          "start" => format_time(service.start + start_offset),
          "end" => format_time(service.start + start_offset + duration)
        },
        "participants" => ["engine_#{service.id}"],
        "resources" => ["platform_#{stop}"],
        "location" => stop,
        "service_id" => service.id,
        "stop_sequence" => index + 1,
        "dependencies" => (if index > 0, do: ["#{service.id}_#{Enum.at(route, index - 1)}"], else: [])
      }
    end)
  end

  defp calculate_timing(route, index, travel_times, min_wait) do
    if index == 0 do
      {0, Map.get(min_wait, Enum.at(route, index), 5)}
    else
      # Calculate cumulative travel time
      total_time = Enum.take(route, index + 1)
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.reduce(0, fn [from, to], acc ->
        travel_time = Map.get(travel_times, {from, to}, 5)
        wait_time = Map.get(min_wait, to, 5)
        acc + travel_time + wait_time
      end)
      
      current_stop = Enum.at(route, index)
      wait_time = Map.get(min_wait, current_stop, 5)
      
      {total_time - wait_time, wait_time}
    end
  end

  defp generate_entities_from_data(data) do
    # Engines
    engines = Enum.map(data.engines, fn engine_id ->
      start_location = Map.get(data.engine_starts, engine_id, "A")
      %{
        "id" => engine_id,
        "type" => "engine",
        "availability" => "full_time",
        "start_location" => start_location
      }
    end)
    
    # Stops
    stops = Enum.map(data.stops, fn stop ->
      platforms = Map.get(data.platforms, stop, 1)
      min_wait = Map.get(data.min_wait, stop, 5)
      
      stop_type = cond do
        platforms >= 2 -> "terminus"
        true -> "ordinary"
      end
      
      %{
        "id" => stop,
        "type" => stop_type,
        "platforms" => platforms,
        "min_wait" => min_wait
      }
    end)
    
    engines ++ stops
  end

  defp generate_resources_from_data(data) do
    Enum.reduce(data.stops, %{}, fn stop, acc ->
      capacity = Map.get(data.platforms, stop, 1)
      Map.put(acc, "platform_#{stop}", %{
        "capacity" => capacity,
        "type" => "platform",
        "location" => stop
      })
    end)
  end

  defp format_time(minutes) do
    base = ~U[2025-06-20T06:00:00Z]
    DateTime.add(base, minutes * 60, :second)
    |> DateTime.to_iso8601()
  end

  defp verify_schedule(instance_name, data, response) do
    Logger.info("Verifying #{instance_name} schedule...")
    
    case extract_schedule_from_response(response) do
      {:ok, schedule} ->
        checks = [
          verify_basic_structure(schedule),
          verify_timing_constraints(schedule, data),
          verify_resource_constraints(schedule, data)
        ]
        
        passed = Enum.count(checks, & &1)
        total = length(checks)
        
        if passed == total do
          Logger.info("✅ VERIFIED: #{instance_name} meets all #{total} constraints")
          %{status: :verified, passed: passed, total: total}
        else
          Logger.warning("❌ PARTIAL: #{instance_name} passed #{passed}/#{total} constraints")
          %{status: :partial, passed: passed, total: total}
        end
        
      {:error, reason} ->
        Logger.warning("❌ Could not verify #{instance_name}: #{reason}")
        %{status: :unverifiable, reason: reason}
    end
  end

  defp extract_schedule_from_response(response) do
    cond do
      Map.has_key?(response, "schedule") and is_list(response["schedule"]) ->
        {:ok, response["schedule"]}
        
      Map.has_key?(response, "result") and Map.has_key?(response["result"], "schedule") ->
        {:ok, response["result"]["schedule"]}
        
      Map.has_key?(response, "timeline") and is_list(response["timeline"]) ->
        {:ok, response["timeline"]}
        
      true ->
        {:error, "No recognizable schedule structure"}
    end
  end

  defp verify_basic_structure(schedule) do
    is_list(schedule) and length(schedule) > 0 and
    Enum.all?(schedule, fn activity ->
      Map.has_key?(activity, "id") and
      Map.has_key?(activity, "duration") and
      Map.has_key?(activity, "location")
    end)
  end

  defp verify_timing_constraints(schedule, data) do
    # Check if all activities are within makespan
    Enum.all?(schedule, fn activity ->
      try do
        {:ok, start_time, _} = DateTime.from_iso8601(activity["duration"]["start"])
        {:ok, end_time, _} = DateTime.from_iso8601(activity["duration"]["end"])
        base_time = ~U[2025-06-20T06:00:00Z]
        
        start_minutes = div(DateTime.diff(start_time, base_time, :second), 60)
        end_minutes = div(DateTime.diff(end_time, base_time, :second), 60)
        
        start_minutes >= 0 and end_minutes <= data.makespan
      rescue
        _ -> false
      end
    end)
  end

  defp verify_resource_constraints(schedule, data) do
    # Check basic resource assignment
    Enum.all?(schedule, fn activity ->
      location = Map.get(activity, "location")
      resources = Map.get(activity, "resources", [])
      
      location in data.stops and length(resources) > 0
    end)
  end

  defp print_summary_report(results) do
    Logger.info("\n" <> String.duplicate("=", 80))
    Logger.info("SUMMARY REPORT - All Train Scheduling Instances")
    Logger.info(String.duplicate("=", 80))
    
    successful = Enum.count(results, fn r -> r.status == :success end)
    total = length(results)
    
    Logger.info("Overall Success Rate: #{successful}/#{total} (#{Float.round(successful/total*100, 1)}%)")
    Logger.info("")
    
    # Performance by complexity
    by_complexity = Enum.group_by(results, & &1.complexity)
    
    Enum.each([:simple, :medium, :complex], fn complexity ->
      instances = Map.get(by_complexity, complexity, [])
      if length(instances) > 0 do
        success_count = Enum.count(instances, fn r -> r.status == :success end)
        avg_time = instances
        |> Enum.filter(fn r -> Map.has_key?(r, :duration_ms) end)
        |> Enum.map(& &1.duration_ms)
        |> case do
          [] -> 0
          times -> Enum.sum(times) / length(times)
        end
        
        Logger.info("#{String.upcase(to_string(complexity))} Complexity: #{success_count}/#{length(instances)} success, avg #{Float.round(avg_time, 1)}ms")
      end
    end)
    
    Logger.info("")
    Logger.info("Individual Results:")
    
    # Detailed results
    Enum.each(results, fn result ->
      status_icon = case result.status do
        :success -> "✅"
        :error -> "❌"
        :crashed -> "💥"
      end
      
      duration_str = if Map.has_key?(result, :duration_ms) do
        " (#{result.duration_ms}ms)"
      else
        ""
      end
      
      verification_str = case Map.get(result, :verification) do
        %{status: :verified, passed: p, total: t} -> " - VERIFIED #{p}/#{t}"
        %{status: :partial, passed: p, total: t} -> " - PARTIAL #{p}/#{t}"
        %{status: :unverifiable} -> " - UNVERIFIABLE"
        _ -> ""
      end
      
      Logger.info("  #{status_icon} #{result.instance}#{duration_str}#{verification_str}")
      
      if Map.has_key?(result, :error) do
        Logger.info("    Error: #{result.error}")
      end
    end)
    
    Logger.info("")
    Logger.info("Legend:")
    Logger.info("  ✅ Success - Test completed successfully")
    Logger.info("  ❌ Error - Test failed with error")
    Logger.info("  💥 Crashed - Test crashed with exception")
    Logger.info("  VERIFIED - Schedule meets all constraints")
    Logger.info("  PARTIAL - Schedule meets some constraints")
    Logger.info("  UNVERIFIABLE - Could not verify schedule")
  end
end

# Run all tests
AllZincTrainSchedulingTest.run_all_tests()
