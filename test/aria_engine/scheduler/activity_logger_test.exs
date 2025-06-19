# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.ActivityLoggerTest do
  use ExUnit.Case, async: true
  
  alias AriaEngine.Scheduler.ActivityLogger
  alias AriaEngine.Scheduler.ActivityLogEntry
  
  describe "generate_activity_log/3" do
    test "generates duration-based formatting when mission_start is nil" do
      schedule = [
        %{
          id: "activity_1",
          start_time: 0,
          end_time: 30,
          duration: 30,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 1
        },
        %{
          id: "activity_2", 
          start_time: 150,
          end_time: 180,
          duration: 30,
          assigned_entity: %{id: "entity_2"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 2
        },
        %{
          id: "activity_3",
          start_time: 1500,
          end_time: 1530,
          duration: 30,
          assigned_entity: %{id: "entity_3"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 3
        }
      ]
      
      result = ActivityLogger.generate_activity_log(schedule, [], mission_start: nil)
      
      assert length(result) == 3
      
      # First activity - Mission Minute format
      first_log = Enum.at(result, 0)
      assert %ActivityLogEntry{
        timestamp: nil,
        mission_duration: "Mission Minute 0",
        relative_minutes: 0,
        activity_id: "activity_1",
        event_type: :started
      } = first_log
      
      # Second activity - Mission Hour format
      second_log = Enum.at(result, 1)
      assert %ActivityLogEntry{
        timestamp: nil,
        mission_duration: "Mission Hour 2:30",
        relative_minutes: 150,
        activity_id: "activity_2",
        event_type: :started
      } = second_log
      
      # Third activity - Mission Day format
      third_log = Enum.at(result, 2)
      assert %ActivityLogEntry{
        timestamp: nil,
        mission_duration: "Mission Day 1, 01:00",
        relative_minutes: 1500,
        activity_id: "activity_3",
        event_type: :started
      } = third_log
    end
    
    test "generates absolute timestamps when mission_start is provided" do
      mission_start = ~U[2025-06-20 08:00:00Z]
      
      schedule = [
        %{
          id: "activity_1",
          start_time: 0,
          end_time: 30,
          duration: 30,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 1
        },
        %{
          id: "activity_2",
          start_time: 120,
          end_time: 150,
          duration: 30,
          assigned_entity: %{id: "entity_2"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 2
        }
      ]
      
      result = ActivityLogger.generate_activity_log(schedule, [], mission_start: mission_start)
      
      assert length(result) == 2
      
      # First activity - starts at mission start
      first_log = Enum.at(result, 0)
      assert %ActivityLogEntry{
        timestamp: ~U[2025-06-20 08:00:00Z],
        mission_duration: nil,
        relative_minutes: 0,
        activity_id: "activity_1"
      } = first_log
      
      # Second activity - starts 2 hours later
      second_log = Enum.at(result, 1)
      assert %ActivityLogEntry{
        timestamp: ~U[2025-06-20 10:00:00Z],
        mission_duration: nil,
        relative_minutes: 120,
        activity_id: "activity_2"
      } = second_log
    end
    
    test "handles activities without start_time using fallback spacing" do
      schedule = [
        %{
          id: "activity_1",
          # No start_time provided
          duration: 30,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 1
        },
        %{
          id: "activity_2",
          # No start_time provided
          duration: 45,
          assigned_entity: %{id: "entity_2"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 2
        }
      ]
      
      result = ActivityLogger.generate_activity_log(schedule, [], mission_start: nil)
      
      assert length(result) == 2
      
      # First activity uses index 0 * 30 = 0 minutes
      first_log = Enum.at(result, 0)
      assert %ActivityLogEntry{
        mission_duration: "Mission Minute 0",
        relative_minutes: 0,
        activity_id: "activity_1"
      } = first_log
      
      # Second activity uses index 1 * 30 = 30 minutes
      second_log = Enum.at(result, 1)
      assert %ActivityLogEntry{
        mission_duration: "Mission Minute 30",
        relative_minutes: 30,
        activity_id: "activity_2"
      } = second_log
    end
    
    test "includes all required metadata fields" do
      schedule = [
        %{
          id: "activity_1",
          start_time: 60,
          end_time: 90,
          duration: 30,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [%{id: "resource_1"}],
          resource_requirements: %{cpu: 2},
          execution_order: 1
        }
      ]
      
      result = ActivityLogger.generate_activity_log(schedule, [], mission_start: nil)
      
      assert length(result) == 1
      log_entry = Enum.at(result, 0)
      
      assert %ActivityLogEntry{
        activity_id: "activity_1",
        entity_id: "entity_1",
        event_type: :started,
        resource_snapshot: %{
          assigned_resources: [%{id: "resource_1"}],
          resource_requirements: %{cpu: 2}
        },
        state_changes: [],
        metadata: %{
          execution_order: 1,
          start_time: 60,
          end_time: 90,
          duration_minutes: 30
        }
      } = log_entry
    end
  end
  
  describe "generate_simulation_activity_log/4" do
    test "generates duration-based formatting for simulation completion" do
      schedule = [
        %{
          id: "activity_1",
          start_time: 0,
          end_time: 30,
          duration: 30,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 1,
          simulation_state: %{completed: true}
        }
      ]
      
      # Mock final state
      final_state = %AriaEngine.StateV2{data: %{}}
      
      result = ActivityLogger.generate_simulation_activity_log(schedule, [], final_state, mission_start: nil)
      
      assert length(result) == 1
      log_entry = Enum.at(result, 0)
      
      assert %ActivityLogEntry{
        timestamp: nil,
        mission_duration: "Mission Minute 30",
        relative_minutes: 30,
        activity_id: "activity_1",
        event_type: :completed
      } = log_entry
      
      assert log_entry.metadata.simulation_executed == true
    end
    
    test "generates absolute timestamps when mission_start is provided" do
      mission_start = ~U[2025-06-20 14:00:00Z]
      
      schedule = [
        %{
          id: "activity_1",
          start_time: 0,
          end_time: 90,
          duration: 90,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 1,
          simulation_state: %{completed: true}
        }
      ]
      
      final_state = %AriaEngine.StateV2{data: %{}}
      
      result = ActivityLogger.generate_simulation_activity_log(schedule, [], final_state, mission_start: mission_start)
      
      assert length(result) == 1
      log_entry = Enum.at(result, 0)
      
      assert %ActivityLogEntry{
        timestamp: ~U[2025-06-20 15:30:00Z],  # 90 minutes after mission start
        mission_duration: nil,
        relative_minutes: 90,
        activity_id: "activity_1",
        event_type: :completed
      } = log_entry
    end
  end
  
  describe "duration formatting edge cases" do
    test "handles zero minutes" do
      schedule = [
        %{
          id: "activity_1",
          start_time: 0,
          end_time: 0,
          duration: 0,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 1
        }
      ]
      
      result = ActivityLogger.generate_activity_log(schedule, [], mission_start: nil)
      
      log_entry = Enum.at(result, 0)
      assert log_entry.mission_duration == "Mission Minute 0"
    end
    
    test "handles exact hour boundaries" do
      schedule = [
        %{
          id: "activity_1",
          start_time: 60,
          end_time: 120,
          duration: 60,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 1
        }
      ]
      
      result = ActivityLogger.generate_activity_log(schedule, [], mission_start: nil)
      
      log_entry = Enum.at(result, 0)
      assert log_entry.mission_duration == "Mission Hour 1:00"
    end
    
    test "handles exact day boundaries" do
      schedule = [
        %{
          id: "activity_1",
          start_time: 1440,  # Exactly 1 day
          end_time: 1470,
          duration: 30,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 1
        }
      ]
      
      result = ActivityLogger.generate_activity_log(schedule, [], mission_start: nil)
      
      log_entry = Enum.at(result, 0)
      assert log_entry.mission_duration == "Mission Day 1, 00:00"
    end
    
    test "handles large time values" do
      schedule = [
        %{
          id: "activity_1",
          start_time: 10080,  # 7 days
          end_time: 10110,
          duration: 30,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [],
          resource_requirements: %{},
          execution_order: 1
        }
      ]
      
      result = ActivityLogger.generate_activity_log(schedule, [], mission_start: nil)
      
      log_entry = Enum.at(result, 0)
      assert log_entry.mission_duration == "Mission Day 7, 00:00"
    end
  end
  
  describe "generate_timeline/3" do
    test "generates timeline with relative time values" do
      schedule = [
        %{
          id: "activity_1",
          start_time: 0,
          end_time: 30,
          assigned_entity: %{id: "entity_1"},
          assigned_resources: [%{id: "resource_1"}]
        },
        %{
          id: "activity_2",
          start_time: 30,
          end_time: 90,
          assigned_entity: %{id: "entity_2"},
          assigned_resources: []
        }
      ]
      
      result = ActivityLogger.generate_timeline(schedule, [], [])
      
      assert length(result) == 2
      
      first_timeline = Enum.at(result, 0)
      assert %{
        activity_id: "activity_1",
        start_time: 0,
        end_time: 30,
        duration: 30,
        entity: "entity_1",
        resources: ["resource_1"],
        status: "scheduled"
      } = first_timeline
      
      second_timeline = Enum.at(result, 1)
      assert %{
        activity_id: "activity_2",
        start_time: 30,
        end_time: 90,
        duration: 60,
        entity: "entity_2",
        resources: [],
        status: "scheduled"
      } = second_timeline
    end
  end
end
