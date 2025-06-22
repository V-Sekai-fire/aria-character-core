# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples.Helpers do
  @moduledoc """
  Shared helper functions for scheduler samples.
  """

  def print_schedule_result_with_timing(result, description, planning_time_ms) do
    IO.puts("\n" <> IO.ANSI.green() <> "✅ #{description}" <> IO.ANSI.reset())
    IO.puts("Status: #{result.status}")
    IO.puts("Reason: #{result.reason}")
    IO.puts(IO.ANSI.cyan() <> "⏱️  Planning Time: #{planning_time_ms}ms" <> IO.ANSI.reset())

    if result.analysis do
      IO.puts("\n📊 Analysis:")
      IO.puts("  • Activities analyzed: #{result.analysis.activities_analyzed}")
      IO.puts("  • Dependencies found: #{result.analysis.dependencies_found}")
      IO.puts("  • Resource conflicts: #{result.analysis.resource_conflicts}")
      IO.puts("  • Critical path length: #{result.analysis.critical_path_length}")
      IO.puts("  • Method: #{result.analysis.method}")
    end

    if result.schedule && length(result.schedule) > 0 do
      IO.puts("\n📅 Schedule (First 10 activities):")

      result.schedule
      |> Enum.sort_by(fn activity ->
        case activity do
          %{start_time: start_time} when is_binary(start_time) -> start_time
          %{"start_time" => start_time} when is_binary(start_time) -> start_time
          _ -> "1970-01-01T00:00:00Z"
        end
      end)
      |> Enum.take(10)
      |> Enum.each(fn activity ->
        id = get_activity_field(activity, "id")
        start_time = get_activity_field(activity, "start_time")
        end_time = get_activity_field(activity, "end_time")
        duration = get_activity_field(activity, "duration")

        start_formatted = format_time(start_time)
        end_formatted = format_time(end_time)

        IO.puts("  • #{id}: #{start_formatted} → #{end_formatted} (#{duration})")
      end)

      if length(result.schedule) > 10 do
        IO.puts("  • ... and #{length(result.schedule) - 10} more activities")
      end
    end

    if result.simulation_metadata do
      IO.puts("\n🔍 Simulation Metadata:")
      IO.puts("  • Generated at: #{format_time(result.simulation_metadata.generated_at)}")
      IO.puts("  • Entities count: #{result.simulation_metadata.entities_count}")
      IO.puts("  • Resources count: #{result.simulation_metadata.resources_count}")
    end
  end

  def print_schedule_result(result, description) do
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

  def get_activity_field(activity, field) when is_map(activity) do
    # Handle both atom and string keys
    atom_field = if is_atom(field), do: field, else: String.to_atom(field)
    string_field = to_string(field)

    case activity do
      %{^atom_field => value} ->
        value

      %{^string_field => value} ->
        value

      _ ->
        # Try accessing with both atom and string keys
        Map.get(activity, atom_field, Map.get(activity, string_field, "N/A"))
    end
  end

  def format_time(nil), do: "N/A"
  def format_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%H:%M:%S")

  def format_time(time_string) when is_binary(time_string) do
    case DateTime.from_iso8601(time_string) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%H:%M:%S")
      _ -> time_string
    end
  end

  def format_time(_), do: "N/A"
end
