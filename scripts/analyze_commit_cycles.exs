#!/usr/bin/env elixir

# Coding Workflow Cycle Time Analysis Script
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule CommitCycleAnalyzer do
  @moduledoc """
  Analyzes git commit history to calculate coding workflow cycle times.

  This script examines the timing patterns between commits to understand
  development velocity, identify bottlenecks, and measure iteration speed.
  """

  @doc """
  Parse git log output and calculate cycle times between commits.
  """
  def analyze_commits(git_log_output) do
    commits = parse_git_log(git_log_output)

    cycle_times = calculate_cycle_times(commits)
    stats = calculate_statistics(cycle_times)
    patterns = identify_patterns(cycle_times)

    %{
      total_commits: length(commits),
      cycle_times: cycle_times,
      statistics: stats,
      patterns: patterns,
      analysis_timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Parse git log output into structured commit data.
  """
  defp parse_git_log(output) do
    output
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_commit_line/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_commit_line(line) do
    case String.split(line, " ", parts: 3) do
      [hash, timestamp_str, message] ->
        case parse_timestamp(timestamp_str) do
          {:ok, datetime} -> {hash, datetime, message}
          {:error, _} ->
            IO.puts("Failed to parse timestamp: #{timestamp_str}")
            nil
        end
      parts ->
        IO.puts("Failed to parse line: #{line} -> #{inspect(parts)}")
        nil
    end
  end

  defp parse_timestamp(timestamp_str) do
    # Handle ISO 8601 format: "2025-06-11T08:13:34-07:00"
    case DateTime.from_iso8601(timestamp_str) do
      {:ok, datetime, _offset} -> {:ok, datetime}
      {:error, _} ->
        # Try alternative format if needed
        {:error, :invalid_format}
    end
  end

  @doc """
  Calculate time intervals between consecutive commits.
  """
  defp calculate_cycle_times(commits) do
    commits
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [{current_hash, current_time, current_msg}, {_prev_hash, prev_time, _prev_msg}] ->
      diff_seconds = DateTime.diff(current_time, prev_time, :second)
      diff_minutes = diff_seconds / 60.0

      %{
        commit_hash: current_hash,
        message: current_msg,
        cycle_time_minutes: diff_minutes,
        cycle_time_hours: diff_minutes / 60.0,
        timestamp: current_time
      }
    end)
  end

  @doc """
  Calculate statistical measures of cycle times.
  """
  defp calculate_statistics(cycle_times) do
    if length(cycle_times) == 0 do
      %{average: 0, median: 0, min: 0, max: 0, total: 0}
    else
      times = Enum.map(cycle_times, & &1.cycle_time_minutes)
      sorted_times = Enum.sort(times)

      %{
        average: Enum.sum(times) / length(times),
        median: median(sorted_times),
        min: Enum.min(times),
        max: Enum.max(times),
        total: Enum.sum(times),
        count: length(times)
      }
    end
  end

  defp median([]), do: 0
  defp median(list) do
    len = length(list)
    sorted = Enum.sort(list)

    if rem(len, 2) == 0 do
      # Even number of elements
      mid1 = Enum.at(sorted, div(len, 2) - 1)
      mid2 = Enum.at(sorted, div(len, 2))
      (mid1 + mid2) / 2
    else
      # Odd number of elements
      Enum.at(sorted, div(len, 2))
    end
  end

  @doc """
  Identify development patterns based on cycle times.
  """
  defp identify_patterns(cycle_times) do
    rapid_cycles = Enum.filter(cycle_times, & &1.cycle_time_minutes < 60)
    moderate_cycles = Enum.filter(cycle_times, & &1.cycle_time_minutes >= 60 and &1.cycle_time_minutes < 300)
    extended_cycles = Enum.filter(cycle_times, & &1.cycle_time_minutes >= 300)

    %{
      rapid_development: %{
        count: length(rapid_cycles),
        description: "Quick iterations and fixes (< 1 hour)",
        examples: Enum.take(rapid_cycles, 3)
      },
      moderate_development: %{
        count: length(moderate_cycles),
        description: "Standard development cycles (1-5 hours)",
        examples: Enum.take(moderate_cycles, 3)
      },
      extended_development: %{
        count: length(extended_cycles),
        description: "Major features or complex refactors (> 5 hours)",
        examples: Enum.take(extended_cycles, 3)
      }
    }
  end

  @doc """
  Format analysis results for commit message inclusion.
  """
  def format_for_commit_message(analysis) do
    stats = analysis.statistics
    patterns = analysis.patterns

    """
    📊 Coding Workflow Cycle Times:
    • Avg: #{Float.round(stats.average, 1)}m | Med: #{Float.round(stats.median, 1)}m
    • Range: #{Float.round(stats.min, 1)}m - #{Float.round(stats.max / 60, 1)}h
    • Rapid cycles: #{patterns.rapid_development.count}/#{stats.count}
    • Extended cycles: #{patterns.extended_development.count}/#{stats.count}
    """
  end

  @doc """
  Generate comprehensive development velocity report.
  """
  def generate_report(analysis) do
    stats = analysis.statistics
    patterns = analysis.patterns

    IO.puts("=== CODING WORKFLOW CYCLE TIME ANALYSIS ===")
    IO.puts("Analysis Date: #{DateTime.to_string(analysis.analysis_timestamp)}")
    IO.puts("Total Commits Analyzed: #{analysis.total_commits}")
    IO.puts("")

    IO.puts("=== CYCLE TIME STATISTICS ===")
    IO.puts("Average Cycle Time: #{Float.round(stats.average, 1)} minutes")
    IO.puts("Median Cycle Time: #{Float.round(stats.median, 1)} minutes")
    IO.puts("Fastest Cycle: #{Float.round(stats.min, 1)} minutes")
    IO.puts("Longest Cycle: #{Float.round(stats.max / 60, 1)} hours")
    IO.puts("Total Development Time: #{Float.round(stats.total / 60, 1)} hours")
    IO.puts("")

    IO.puts("=== DEVELOPMENT PATTERNS ===")
    for {pattern_name, pattern_data} <- patterns do
      IO.puts("#{String.capitalize(to_string(pattern_name))}: #{pattern_data.count} cycles")
      IO.puts("  #{pattern_data.description}")
      if length(pattern_data.examples) > 0 do
        IO.puts("  Examples:")
        for example <- pattern_data.examples do
          time_display = if example.cycle_time_hours >= 1 do
            "#{Float.round(example.cycle_time_hours, 1)}h"
          else
            "#{Float.round(example.cycle_time_minutes, 0)}m"
          end
          IO.puts("    • #{time_display}: #{String.slice(example.message, 0, 50)}...")
        end
      end
      IO.puts("")
    end

    analysis
  end
end

# Main execution
case System.argv() do
  [] ->
    # Get git log data
    {git_output, 0} = System.cmd("git", [
      "log", "--oneline", "--pretty=format:%h %cI %s", "-10"
    ], cd: System.cwd())

    git_output
    |> CommitCycleAnalyzer.analyze_commits()
    |> CommitCycleAnalyzer.generate_report()

  ["--format-commit"] ->
    {git_output, 0} = System.cmd("git", [
      "log", "--oneline", "--pretty=format:%h %cI %s", "-10"
    ], cd: System.cwd())

    analysis = CommitCycleAnalyzer.analyze_commits(git_output)
    formatted = CommitCycleAnalyzer.format_for_commit_message(analysis)
    IO.puts(formatted)

  ["-h"] ->
    IO.puts("""
    Coding Workflow Cycle Time Analyzer

    Usage:
      elixir analyze_commit_cycles.exs          # Full analysis report
      elixir analyze_commit_cycles.exs --format-commit  # Compact format for commit messages
      elixir analyze_commit_cycles.exs -h       # Show this help
    """)

  _ ->
    IO.puts("Invalid arguments. Use -h for help.")
    System.halt(1)
end
