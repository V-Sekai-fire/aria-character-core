# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples do
  @moduledoc """
  Demonstrates AriaEngine.Scheduler capabilities with various scheduling samples.
  
  Usage: mix schedule.samples
  """
  
  use Mix.Task
  require Logger
  
  alias AriaEngine.Scheduler
  alias AriaEngine.Scheduler.{Entity, Resource}

  @shortdoc "Run scheduling samples to demonstrate AriaEngine.Scheduler capabilities"

  def run(_args) do
    # Start the application to ensure all dependencies are loaded
    Mix.Task.run("app.start")
    
    IO.puts("\n" <> IO.ANSI.cyan() <> "🚀 AriaEngine.Scheduler Samples" <> IO.ANSI.reset())
    IO.puts(String.duplicate("=", 50))
    
    samples = [
      &sample_1_simple_sequential/0,
      &sample_2_resource_constraints/0,
      &sample_3_complex_dependencies/0,
      &sample_4_entity_capabilities/0,
      &sample_5_simulation_mode/0
    ]
    
    Enum.with_index(samples, 1)
    |> Enum.each(fn {sample_fn, index} ->
      try do
        sample_fn.()
      rescue
        e ->
          IO.puts(IO.ANSI.red() <> "❌ Sample #{index} failed: #{Exception.message(e)}" <> IO.ANSI.reset())
          IO.puts(Exception.format_stacktrace(__STACKTRACE__))
      end
      
      if index < length(samples) do
        IO.puts("\n" <> String.duplicate("-", 50))
      end
    end)
    
    IO.puts("\n" <> IO.ANSI.green() <> "✅ All samples completed!" <> IO.ANSI.reset())
  end

  defp sample_1_simple_sequential do
    IO.puts("\n" <> IO.ANSI.yellow() <> "📋 Sample 1: Simple Sequential Activities" <> IO.ANSI.reset())
    IO.puts("Demonstrates basic dependency handling and timing calculations")
    
    activities = [
      %{
        "id" => "design",
        "duration" => "PT30M",  # 30 minutes
        "dependencies" => []
      },
      %{
        "id" => "develop", 
        "duration" => "PT2H",   # 2 hours
        "dependencies" => ["design"]
      },
      %{
        "id" => "test",
        "duration" => "PT45M",  # 45 minutes
        "dependencies" => ["develop"]
      },
      %{
        "id" => "deploy",
        "duration" => "PT15M",  # 15 minutes
        "dependencies" => ["test"]
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities("Website Launch", activities, base_datetime: base_datetime) do
      {:ok, result} ->
        print_schedule_result(result, "Sequential project workflow")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp sample_2_resource_constraints do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🔧 Sample 2: Resource-Constrained Scheduling" <> IO.ANSI.reset())
    IO.puts("Demonstrates resource allocation and capacity management")
    
    activities = [
      %{
        "id" => "frontend_task",
        "duration" => "PT1H",
        "dependencies" => [],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "backend_task",
        "duration" => "PT1H30M",
        "dependencies" => [],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "database_task",
        "duration" => "PT45M",
        "dependencies" => [],
        "required_resources" => ["developer"]
      }
    ]
    
    resources = [
      %Resource{
        id: "developer",
        type: :human,
        capacity: 1,  # Only one developer available
        current_usage: 0
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities(
      "Resource Constrained Project",
      activities,
      base_datetime: base_datetime,
      resources: resources
    ) do
      {:ok, result} ->
        print_schedule_result(result, "Tasks competing for limited developer resource")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp sample_3_complex_dependencies do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🔗 Sample 3: Complex Dependencies" <> IO.ANSI.reset())
    IO.puts("Demonstrates parallel execution and critical path analysis")
    
    activities = [
      %{
        "id" => "requirements",
        "duration" => "PT1H",
        "dependencies" => []
      },
      %{
        "id" => "ui_design",
        "duration" => "PT2H",
        "dependencies" => ["requirements"]
      },
      %{
        "id" => "api_design",
        "duration" => "PT1H30M",
        "dependencies" => ["requirements"]
      },
      %{
        "id" => "frontend_dev",
        "duration" => "PT3H",
        "dependencies" => ["ui_design"]
      },
      %{
        "id" => "backend_dev",
        "duration" => "PT4H",
        "dependencies" => ["api_design"]
      },
      %{
        "id" => "integration",
        "duration" => "PT1H",
        "dependencies" => ["frontend_dev", "backend_dev"]
      },
      %{
        "id" => "testing",
        "duration" => "PT2H",
        "dependencies" => ["integration"]
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities(
      "Complex Project",
      activities,
      base_datetime: base_datetime
    ) do
      {:ok, result} ->
        print_schedule_result(result, "Project with parallel tracks and convergence")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp sample_4_entity_capabilities do
    IO.puts("\n" <> IO.ANSI.yellow() <> "👥 Sample 4: Entity and Capability Management" <> IO.ANSI.reset())
    IO.puts("Demonstrates capability-based task assignment")
    
    activities = [
      %{
        "id" => "design_mockups",
        "duration" => "PT2H",
        "dependencies" => [],
        "required_capabilities" => [:design]
      },
      %{
        "id" => "implement_ui",
        "duration" => "PT3H",
        "dependencies" => ["design_mockups"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "write_tests",
        "duration" => "PT1H30M",
        "dependencies" => ["implement_ui"],
        "required_capabilities" => [:testing]
      }
    ]
    
    entities = [
      %Entity{
        id: "alice",
        type: :agent,
        capabilities: [:design, :frontend_coding],
        availability: nil
      },
      %Entity{
        id: "bob",
        type: :agent,
        capabilities: [:frontend_coding, :testing],
        availability: nil
      },
      %Entity{
        id: "charlie",
        type: :agent,
        capabilities: [:testing, :backend_coding],
        availability: nil
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities(
      "Team Project",
      activities,
      base_datetime: base_datetime,
      entities: entities
    ) do
      {:ok, result} ->
        print_schedule_result(result, "Tasks assigned based on team member capabilities")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp sample_5_simulation_mode do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🎯 Sample 5: Simulation Mode" <> IO.ANSI.reset())
    IO.puts("Demonstrates predictive scheduling without execution")
    
    activities = [
      %{
        "id" => "research",
        "duration" => "PT4H",
        "dependencies" => []
      },
      %{
        "id" => "prototype",
        "duration" => "PT6H",
        "dependencies" => ["research"]
      },
      %{
        "id" => "evaluate",
        "duration" => "PT2H",
        "dependencies" => ["prototype"]
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.simulate_schedule(
      "Research Project",
      activities,
      base_datetime: base_datetime,
      verbose: 1
    ) do
      {:ok, result} ->
        print_schedule_result(result, "Simulation run - no actual execution")
        IO.puts(IO.ANSI.blue() <> "💡 This was a simulation - no actual work was performed" <> IO.ANSI.reset())
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Simulation failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp print_schedule_result(result, description) do
    IO.puts("\n" <> IO.ANSI.green() <> "✅ #{description}" <> IO.ANSI.reset())
    IO.puts("Status: #{result.status}")
    IO.puts("Reason: #{result.reason}")
    
    if result.analysis do
      IO.puts("\n📊 Analysis:")
      IO.puts("  • Activities analyzed: #{result.analysis.activities_analyzed}")
      IO.puts("  • Dependencies found: #{result.analysis.dependencies_found}")
      IO.puts("  • Resource conflicts: #{result.analysis.resource_conflicts}")
      IO.puts("  • Critical path length: #{result.analysis.critical_path_length}")
      IO.puts("  • Method: #{result.analysis.method}")
    end
    
    if result.schedule && length(result.schedule) > 0 do
      IO.puts("\n📅 Schedule:")
      
      result.schedule
      |> Enum.sort_by(fn activity -> 
        case activity do
          %{start_time: start_time} when is_binary(start_time) -> start_time
          %{"start_time" => start_time} when is_binary(start_time) -> start_time
          _ -> "1970-01-01T00:00:00Z"
        end
      end)
      |> Enum.each(fn activity ->
        id = get_activity_field(activity, "id")
        start_time = get_activity_field(activity, "start_time")
        end_time = get_activity_field(activity, "end_time")
        duration = get_activity_field(activity, "duration")
        
        start_formatted = format_time(start_time)
        end_formatted = format_time(end_time)
        
        IO.puts("  • #{id}: #{start_formatted} → #{end_formatted} (#{duration})")
      end)
    else
      IO.puts("\n📅 Schedule: Empty (no activities to schedule)")
    end
    
    if result.simulation_metadata do
      IO.puts("\n🔍 Simulation Metadata:")
      IO.puts("  • Generated at: #{format_time(result.simulation_metadata.generated_at)}")
      IO.puts("  • Entities count: #{result.simulation_metadata.entities_count}")
      IO.puts("  • Resources count: #{result.simulation_metadata.resources_count}")
    end
  end

  defp get_activity_field(activity, field) when is_map(activity) do
    # Handle both atom and string keys
    atom_field = if is_atom(field), do: field, else: String.to_atom(field)
    string_field = to_string(field)
    
    case activity do
      %{^atom_field => value} -> value
      %{^string_field => value} -> value
      _ -> 
        # Try accessing with both atom and string keys
        Map.get(activity, atom_field, Map.get(activity, string_field, "N/A"))
    end
  end

  defp format_time(nil), do: "N/A"
  defp format_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%H:%M:%S")
  defp format_time(time_string) when is_binary(time_string) do
    case DateTime.from_iso8601(time_string) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%H:%M:%S")
      _ -> time_string
    end
  end
  defp format_time(_), do: "N/A"
end
