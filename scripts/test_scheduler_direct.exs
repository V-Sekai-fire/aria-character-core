#!/usr/bin/env elixir

# Simple test to debug the scheduler call chain
Mix.install([])

# Add the lib directory to the code path
Code.prepend_path("_build/dev/lib/aria_character_core/ebin")

# Load the application
Application.ensure_all_started(:logger)

require Logger

Logger.configure(level: :info)

Logger.info("🔧 Starting direct scheduler test...")

# Test data
activities = [
  %{
    "duration" => %{
      "end" => "2025-06-20T10:00:00Z",
      "start" => "2025-06-20T09:00:00Z"
    },
    "id" => "activity_1",
    "name" => "Test Meeting",
    "participants" => ["alice", "bob"],
    "resources" => ["conference_room_a"]
  }
]

Logger.info("🔧 Calling AriaEngine.Scheduler.schedule_activities()...")

try do
  result = AriaEngine.Scheduler.schedule_activities("test_schedule", activities, [
    entities: [],
    resources: [],
    constraints: %{},
    simulation_mode: false,
    verbose: 2
  ])
  
  Logger.info("🔧 Scheduler result: #{inspect(result)}")
rescue
  e ->
    Logger.error("🔧 Scheduler failed with exception: #{inspect(e)}")
    Logger.error("🔧 Stacktrace: #{inspect(__STACKTRACE__)}")
end

Logger.info("🔧 Direct scheduler test complete")
