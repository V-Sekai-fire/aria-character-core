# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TrainSchedulingConverter do
  @moduledoc """
  Converts trains05.dzn MiniZinc train scheduling problem into schedule_activities format
  for use with the hybrid coordinator system.

  This module transforms the constraint satisfaction problem from MiniZinc format
  into the activities/entities/resources format expected by AriaEngine.Scheduler.
  """

  require Logger

  @doc """
  Convert trains05.dzn problem data into schedule_activities format.

  Returns a map with:
  - schedule_name: "trains05_scheduling"
  - activities: List of train service activities
  - entities: List of engines with capabilities
  - resources: Map of station platforms with capacity
  - constraints: Scheduling constraints and limits
  """
  def convert_trains05_to_schedule_activities() do
    %{
      "schedule_name" => "trains05_scheduling",
      "activities" => create_train_service_activities(),
      "entities" => create_engine_entities(),
      "resources" => create_station_resources(),
      "constraints" => create_scheduling_constraints(),
      "simulation_options" => %{
        "simulation_mode" => false,
        "verbose" => 2,
        "log_activities" => true
      },
      "resource_management" => %{
        "check_capacity" => true,
        "auto_allocate" => true,
        "conflict_detection" => true
      }
    }
  end

  defp create_train_service_activities() do
    # Route 1: A -> B -> C -> D -> E -> F (services R1a through R1f)
    route1_services = [
      # Start at time 0
      {"R1a", 0},
      # Start at time 30
      {"R1b", 30},
      # Start at time 60
      {"R1c", 60},
      # Start at time 90
      {"R1d", 90},
      # Start at time 120
      {"R1e", 120},
      # Start at time 150
      {"R1f", 150}
    ]

    # Route 2: F -> E -> D -> C -> B -> A (services R2a through R2f)
    route2_services = [
      # Start at time 0
      {"R2a", 0},
      # Start at time 30
      {"R2b", 30},
      # Start at time 60
      {"R2c", 60},
      # Start at time 90
      {"R2d", 90},
      # Start at time 120
      {"R2e", 120},
      # Start at time 150
      {"R2f", 150}
    ]

    # Create activities for route 1 services
    route1_activities =
      Enum.flat_map(route1_services, fn {service_id, start_time} ->
        create_route1_activities(service_id, start_time)
      end)

    # Create activities for route 2 services
    route2_activities =
      Enum.flat_map(route2_services, fn {service_id, start_time} ->
        create_route2_activities(service_id, start_time)
      end)

    route1_activities ++ route2_activities
  end

  defp create_route1_activities(service_id, service_start_time) do
    stations = ["A", "B", "C", "D", "E", "F"]
    travel_times = get_travel_times_route1()

    {activities, _} =
      Enum.reduce(stations, {[], service_start_time}, fn station,
                                                         {acc_activities, current_time} ->
        station_index = Enum.find_index(stations, &(&1 == station))

        # Create station visit activity
        activity = %{
          "id" => "#{service_id}_visit_#{station}",
          "name" => "#{service_id} visits station #{station}",
          "duration" => create_station_visit_duration(current_time, station, service_id),
          "dependencies" => get_station_dependencies(service_id, station, stations),
          "required_capabilities" => ["train_operation", "route1_capable"],
          "required_resources" => ["platform_#{station}"],
          # Will be assigned by scheduler
          "participants" => [],
          "type" => "station_visit",
          "metadata" => %{
            "service_id" => service_id,
            "station" => station,
            "route" => "route1",
            "station_index" => station_index,
            "service_start_time" => service_start_time
          }
        }

        # Calculate next time (current + station wait + travel to next)
        next_time =
          if station_index < length(stations) - 1 do
            travel_time = Enum.at(travel_times, station_index)
            # 2 min station wait + travel time
            current_time + 2 + travel_time
          else
            # Final station, just wait time
            current_time + 2
          end

        {[activity | acc_activities], next_time}
      end)

    Enum.reverse(activities)
  end

  defp create_route2_activities(service_id, service_start_time) do
    stations = ["F", "E", "D", "C", "B", "A"]
    travel_times = get_travel_times_route2()

    {activities, _} =
      Enum.reduce(stations, {[], service_start_time}, fn station,
                                                         {acc_activities, current_time} ->
        station_index = Enum.find_index(stations, &(&1 == station))

        # Create station visit activity
        activity = %{
          "id" => "#{service_id}_visit_#{station}",
          "name" => "#{service_id} visits station #{station}",
          "duration" => create_station_visit_duration(current_time, station, service_id),
          "dependencies" => get_station_dependencies(service_id, station, stations),
          "required_capabilities" => ["train_operation", "route2_capable"],
          "required_resources" => ["platform_#{station}"],
          # Will be assigned by scheduler
          "participants" => [],
          "type" => "station_visit",
          "metadata" => %{
            "service_id" => service_id,
            "station" => station,
            "route" => "route2",
            "station_index" => station_index,
            "service_start_time" => service_start_time
          }
        }

        # Calculate next time (current + station wait + travel to next)
        next_time =
          if station_index < length(stations) - 1 do
            travel_time = Enum.at(travel_times, station_index)
            # 2 min station wait + travel time
            current_time + 2 + travel_time
          else
            # Final station, just wait time
            current_time + 2
          end

        {[activity | acc_activities], next_time}
      end)

    Enum.reverse(activities)
  end

  defp create_station_visit_duration(start_time, _station, _service_id) do
    # Create time interval with start time and 2-minute duration
    start_datetime = DateTime.add(DateTime.utc_now(), start_time * 60, :second)
    # 2 minute station visit
    end_datetime = DateTime.add(start_datetime, 2 * 60, :second)

    %{
      "start" => DateTime.to_iso8601(start_datetime),
      "end" => DateTime.to_iso8601(end_datetime)
    }
  end

  defp get_station_dependencies(service_id, station, stations) do
    station_index = Enum.find_index(stations, &(&1 == station))

    if station_index > 0 do
      previous_station = Enum.at(stations, station_index - 1)
      ["#{service_id}_visit_#{previous_station}"]
    else
      # First station has no dependencies
      []
    end
  end

  defp get_travel_times_route1() do
    # Travel times from trains05.dzn: A->B=7, B->C=8, C->D=5, D->E=7, E->F=6
    [7, 8, 5, 7, 6]
  end

  defp get_travel_times_route2() do
    # Travel times from trains05.dzn: F->E=6, E->D=7, D->C=5, C->B=9, B->A=7
    [6, 7, 5, 9, 7]
  end

  defp create_engine_entities() do
    [
      # Engines E1, E2, E3 start at station A
      %{
        "id" => "E1",
        "type" => "train_engine",
        "capabilities" => ["train_operation", "route1_capable", "route2_capable"],
        "availability" => %{
          "start" => DateTime.to_iso8601(DateTime.utc_now()),
          "end" => DateTime.to_iso8601(DateTime.add(DateTime.utc_now(), 240 * 60, :second))
        },
        "current_activity" => nil,
        "resources_held" => [],
        "metadata" => %{
          "starting_location" => "A",
          "engine_group" => "group_A"
        }
      },
      %{
        "id" => "E2",
        "type" => "train_engine",
        "capabilities" => ["train_operation", "route1_capable", "route2_capable"],
        "availability" => %{
          "start" => DateTime.to_iso8601(DateTime.utc_now()),
          "end" => DateTime.to_iso8601(DateTime.add(DateTime.utc_now(), 240 * 60, :second))
        },
        "current_activity" => nil,
        "resources_held" => [],
        "metadata" => %{
          "starting_location" => "A",
          "engine_group" => "group_A"
        }
      },
      %{
        "id" => "E3",
        "type" => "train_engine",
        "capabilities" => ["train_operation", "route1_capable", "route2_capable"],
        "availability" => %{
          "start" => DateTime.to_iso8601(DateTime.utc_now()),
          "end" => DateTime.to_iso8601(DateTime.add(DateTime.utc_now(), 240 * 60, :second))
        },
        "current_activity" => nil,
        "resources_held" => [],
        "metadata" => %{
          "starting_location" => "A",
          "engine_group" => "group_A"
        }
      },
      # Engines E4, E5, E6 start at station F
      %{
        "id" => "E4",
        "type" => "train_engine",
        "capabilities" => ["train_operation", "route1_capable", "route2_capable"],
        "availability" => %{
          "start" => DateTime.to_iso8601(DateTime.utc_now()),
          "end" => DateTime.to_iso8601(DateTime.add(DateTime.utc_now(), 240 * 60, :second))
        },
        "current_activity" => nil,
        "resources_held" => [],
        "metadata" => %{
          "starting_location" => "F",
          "engine_group" => "group_F"
        }
      },
      %{
        "id" => "E5",
        "type" => "train_engine",
        "capabilities" => ["train_operation", "route1_capable", "route2_capable"],
        "availability" => %{
          "start" => DateTime.to_iso8601(DateTime.utc_now()),
          "end" => DateTime.to_iso8601(DateTime.add(DateTime.utc_now(), 240 * 60, :second))
        },
        "current_activity" => nil,
        "resources_held" => [],
        "metadata" => %{
          "starting_location" => "F",
          "engine_group" => "group_F"
        }
      },
      %{
        "id" => "E6",
        "type" => "train_engine",
        "capabilities" => ["train_operation", "route1_capable", "route2_capable"],
        "availability" => %{
          "start" => DateTime.to_iso8601(DateTime.utc_now()),
          "end" => DateTime.to_iso8601(DateTime.add(DateTime.utc_now(), 240 * 60, :second))
        },
        "current_activity" => nil,
        "resources_held" => [],
        "metadata" => %{
          "starting_location" => "F",
          "engine_group" => "group_F"
        }
      }
    ]
  end

  defp create_station_resources() do
    %{
      "platform_A" => %{
        "type" => "train_platform",
        # Station A has 2 platforms
        "capacity" => 2,
        "current_usage" => 0,
        "constraints" => %{
          # 4 minutes minimum separation
          "min_separation_time" => 4,
          "max_concurrent_trains" => 2
        },
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "A",
          "platform_count" => 2,
          "station_type" => "terminus"
        }
      },
      "platform_B" => %{
        "type" => "train_platform",
        # Station B has 1 platform
        "capacity" => 1,
        "current_usage" => 0,
        "constraints" => %{
          "min_separation_time" => 4,
          "max_concurrent_trains" => 1
        },
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "B",
          "platform_count" => 1,
          "station_type" => "intermediate"
        }
      },
      "platform_C" => %{
        "type" => "train_platform",
        # Station C has 1 platform
        "capacity" => 1,
        "current_usage" => 0,
        "constraints" => %{
          "min_separation_time" => 4,
          "max_concurrent_trains" => 1
        },
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "C",
          "platform_count" => 1,
          "station_type" => "intermediate"
        }
      },
      "platform_D" => %{
        "type" => "train_platform",
        # Station D has 1 platform
        "capacity" => 1,
        "current_usage" => 0,
        "constraints" => %{
          "min_separation_time" => 4,
          "max_concurrent_trains" => 1
        },
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "D",
          "platform_count" => 1,
          "station_type" => "intermediate"
        }
      },
      "platform_E" => %{
        "type" => "train_platform",
        # Station E has 1 platform
        "capacity" => 1,
        "current_usage" => 0,
        "constraints" => %{
          "min_separation_time" => 4,
          "max_concurrent_trains" => 1
        },
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "E",
          "platform_count" => 1,
          "station_type" => "intermediate"
        }
      },
      "platform_F" => %{
        "type" => "train_platform",
        # Station F has 2 platforms
        "capacity" => 2,
        "current_usage" => 0,
        "constraints" => %{
          "min_separation_time" => 4,
          "max_concurrent_trains" => 2
        },
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "F",
          "platform_count" => 2,
          "station_type" => "terminus"
        }
      }
    }
  end

  defp create_scheduling_constraints() do
    %{
      # All 12 services can run concurrently
      "max_concurrent_activities" => 12,
      "require_resources" => true,
      # 240 minutes total time
      "makespan_limit" => 240,
      # 4 minutes minimum separation
      "min_separation_time" => 4,
      "platform_capacity_enforcement" => true,
      "engine_assignment_required" => true,
      "route_sequence_enforcement" => true
    }
  end

  @doc """
  Get the full travel time matrix from trains05.dzn.
  """
  def get_travel_time_matrix() do
    # Travel time matrix from trains05.dzn (in minutes)
    # Rows/Cols: A, B, C, D, E, F
    %{
      {"A", "B"} => 7,
      {"B", "A"} => 7,
      {"B", "C"} => 8,
      {"C", "B"} => 9,
      {"C", "D"} => 5,
      {"D", "C"} => 5,
      {"D", "E"} => 7,
      {"E", "D"} => 7,
      {"E", "F"} => 6,
      {"F", "E"} => 6
    }
  end

  @doc """
  Get platform capacity for a station.
  """
  def get_platform_capacity(station) do
    case station do
      "A" -> 2
      "B" -> 1
      "C" -> 1
      "D" -> 1
      "E" -> 1
      "F" -> 2
      _ -> 0
    end
  end

  @doc """
  Get minimum wait time for a station (from trains05.dzn).
  """
  def get_minimum_wait_time(station) do
    case station do
      "A" -> 2
      "B" -> 2
      "C" -> 2
      "D" -> 2
      "E" -> 2
      "F" -> 2
      _ -> 0
    end
  end
end
