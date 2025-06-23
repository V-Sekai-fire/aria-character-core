# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TrainSchedulingConverter do
  @moduledoc "Converts trains05.dzn MiniZinc train scheduling problem into schedule_activities format\nfor use with the hybrid coordinator system.\n\nThis module transforms the constraint satisfaction problem from MiniZinc format\ninto the activities/entities/resources format expected by AriaEngine.Scheduler.\n"
  require Logger

  @doc "Convert trains05.dzn problem data into schedule_activities format.\n\nReturns a map with:\n- schedule_name: \"trains05_scheduling\"\n- activities: List of train service activities\n- entities: List of engines with capabilities\n- resources: Map of station platforms with capacity\n- constraints: Scheduling constraints and limits\n"
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
    route1_services = [
      {"R1a", 0},
      {"R1b", 30},
      {"R1c", 60},
      {"R1d", 90},
      {"R1e", 120},
      {"R1f", 150}
    ]

    route2_services = [
      {"R2a", 0},
      {"R2b", 30},
      {"R2c", 60},
      {"R2d", 90},
      {"R2e", 120},
      {"R2f", 150}
    ]

    route1_activities =
      Enum.flat_map(route1_services, fn {service_id, start_time} ->
        create_route1_activities(service_id, start_time)
      end)

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

        activity = %{
          "id" => "#{service_id}_visit_#{station}",
          "name" => "#{service_id} visits station #{station}",
          "duration" => create_station_visit_duration(current_time, station, service_id),
          "dependencies" => get_station_dependencies(service_id, station, stations),
          "required_capabilities" => ["train_operation", "route1_capable"],
          "required_resources" => ["platform_#{station}"],
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

        next_time =
          if station_index < length(stations) - 1 do
            travel_time = Enum.at(travel_times, station_index)
            current_time + 2 + travel_time
          else
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

        activity = %{
          "id" => "#{service_id}_visit_#{station}",
          "name" => "#{service_id} visits station #{station}",
          "duration" => create_station_visit_duration(current_time, station, service_id),
          "dependencies" => get_station_dependencies(service_id, station, stations),
          "required_capabilities" => ["train_operation", "route2_capable"],
          "required_resources" => ["platform_#{station}"],
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

        next_time =
          if station_index < length(stations) - 1 do
            travel_time = Enum.at(travel_times, station_index)
            current_time + 2 + travel_time
          else
            current_time + 2
          end

        {[activity | acc_activities], next_time}
      end)

    Enum.reverse(activities)
  end

  defp create_station_visit_duration(start_time, _station, _service_id) do
    start_datetime = DateTime.add(DateTime.utc_now(), start_time * 60, :second)
    end_datetime = DateTime.add(start_datetime, 2 * 60, :second)
    %{"start" => DateTime.to_iso8601(start_datetime), "end" => DateTime.to_iso8601(end_datetime)}
  end

  defp get_station_dependencies(service_id, station, stations) do
    station_index = Enum.find_index(stations, &(&1 == station))

    if station_index > 0 do
      previous_station = Enum.at(stations, station_index - 1)
      ["#{service_id}_visit_#{previous_station}"]
    else
      []
    end
  end

  defp get_travel_times_route1() do
    [7, 8, 5, 7, 6]
  end

  defp get_travel_times_route2() do
    [6, 7, 5, 9, 7]
  end

  defp create_engine_entities() do
    [
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
        "metadata" => %{"starting_location" => "A", "engine_group" => "group_A"}
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
        "metadata" => %{"starting_location" => "A", "engine_group" => "group_A"}
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
        "metadata" => %{"starting_location" => "A", "engine_group" => "group_A"}
      },
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
        "metadata" => %{"starting_location" => "F", "engine_group" => "group_F"}
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
        "metadata" => %{"starting_location" => "F", "engine_group" => "group_F"}
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
        "metadata" => %{"starting_location" => "F", "engine_group" => "group_F"}
      }
    ]
  end

  defp create_station_resources() do
    %{
      "platform_A" => %{
        "type" => "train_platform",
        "capacity" => 2,
        "current_usage" => 0,
        "constraints" => %{"min_separation_time" => 4, "max_concurrent_trains" => 2},
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "A",
          "platform_count" => 2,
          "station_type" => "terminus"
        }
      },
      "platform_B" => %{
        "type" => "train_platform",
        "capacity" => 1,
        "current_usage" => 0,
        "constraints" => %{"min_separation_time" => 4, "max_concurrent_trains" => 1},
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "B",
          "platform_count" => 1,
          "station_type" => "intermediate"
        }
      },
      "platform_C" => %{
        "type" => "train_platform",
        "capacity" => 1,
        "current_usage" => 0,
        "constraints" => %{"min_separation_time" => 4, "max_concurrent_trains" => 1},
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "C",
          "platform_count" => 1,
          "station_type" => "intermediate"
        }
      },
      "platform_D" => %{
        "type" => "train_platform",
        "capacity" => 1,
        "current_usage" => 0,
        "constraints" => %{"min_separation_time" => 4, "max_concurrent_trains" => 1},
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "D",
          "platform_count" => 1,
          "station_type" => "intermediate"
        }
      },
      "platform_E" => %{
        "type" => "train_platform",
        "capacity" => 1,
        "current_usage" => 0,
        "constraints" => %{"min_separation_time" => 4, "max_concurrent_trains" => 1},
        "availability_schedule" => [],
        "metadata" => %{
          "station_name" => "E",
          "platform_count" => 1,
          "station_type" => "intermediate"
        }
      },
      "platform_F" => %{
        "type" => "train_platform",
        "capacity" => 2,
        "current_usage" => 0,
        "constraints" => %{"min_separation_time" => 4, "max_concurrent_trains" => 2},
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
      "max_concurrent_activities" => 12,
      "require_resources" => true,
      "makespan_limit" => 240,
      "min_separation_time" => 4,
      "platform_capacity_enforcement" => true,
      "engine_assignment_required" => true,
      "route_sequence_enforcement" => true
    }
  end

  @doc "Get the full travel time matrix from trains05.dzn.\n"
  def get_travel_time_matrix() do
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

  @doc "Get platform capacity for a station.\n"
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

  @doc "Get minimum wait time for a station (from trains05.dzn).\n"
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