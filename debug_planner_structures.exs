#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Debug script to explore temporal planner data structures and action formats
# Run with: elixir debug_planner_structures.exs

Mix.install([])

IO.puts("=== Temporal Planner Data Structure Debug ===\n")

# Load the project context
Code.eval_file("mix.exs")

defmodule PlannerDebug do
  @moduledoc """
  Debug utility to explore the actual temporal planner data structures.
  """

  def debug_action_formats do
    IO.puts("=== Action Format Examples ===")
    
    # Based on tuple format like {"attack", [...]} or {"at", "john", "home"}
    actions = [
      {"move", ["alex", {"x", 5}, {"y", 3}, {"z", 0}]},
      {"attack", ["alex", "enemy_1"]},
      {"at", "alex", "position_a"},
      {"has", "alex", "weapon"},
      {"use_skill", ["alex", "fireball", "enemy_1"]},
      {"pickup", ["alex", "health_potion"]},
      {"wait", ["alex", 2.5]}
    ]
    
    Enum.each(actions, fn action ->
      IO.puts("  #{inspect(action)}")
    end)
    
    IO.puts("")
  end

  def debug_goal_formats do
    IO.puts("=== Goal Format Examples ===")
    
    # Goals in tuple format
    goals = [
      {"at", "alex", "extraction_point"},
      {"has", "alex", "intel_package"},
      {"alive", "hostage_1", true},
      {"cleared", "room_b", true},
      {"eliminated", "enemy_patrol", true}
    ]
    
    Enum.each(goals, fn goal ->
      IO.puts("  #{inspect(goal)}")
    end)
    
    IO.puts("")
  end

  def debug_plan_structure do
    IO.puts("=== Plan Structure Example ===")
    
    # A plan is a list of actions
    plan = [
      {"move", ["alex", {"x", 2}, {"y", 3}, {"z", 0}]},
      {"pickup", ["alex", "weapon"]},
      {"move", ["alex", {"x", 5}, {"y", 3}, {"z", 0}]},
      {"attack", ["alex", "enemy_1"]},
      {"move", ["alex", {"x", 8}, {"y", 3}, {"z", 0}]}
    ]
    
    IO.puts("Plan (list of actions):")
    Enum.with_index(plan, 1) |> Enum.each(fn {action, idx} ->
      IO.puts("  #{idx}. #{inspect(action)}")
    end)
    
    IO.puts("")
  end

  def debug_multigoal_structure do
    IO.puts("=== Multigoal Structure Example ===")
    
    # Multiple goals to achieve simultaneously
    multigoal = [
      {"at", "alex", "extraction_point"},
      {"has", "alex", "intel_package"},
      {"alive", "hostage_1", true}
    ]
    
    IO.puts("Multigoal (list of goals):")
    Enum.with_index(multigoal, 1) |> Enum.each(fn {goal, idx} ->
      IO.puts("  #{idx}. #{inspect(goal)}")
    end)
    
    IO.puts("")
  end

  def debug_state_structure do
    IO.puts("=== State Structure Example ===")
    
    # State might be represented as nested maps or key-value tuples
    state_examples = [
      # Position tracking
      {{"at", "alex"}, {"x", 2, "y", 3, "z", 0}},
      {{"at", "enemy_1"}, {"x", 6, "y", 3, "z", 0}},
      
      # Inventory tracking  
      {{"has", "alex"}, ["weapon", "health_potion"]},
      
      # Status tracking
      {{"alive", "alex"}, true},
      {{"alive", "hostage_1"}, true},
      
      # Environmental state
      {{"cleared", "room_a"}, true},
      {{"locked", "door_b"}, false}
    ]
    
    IO.puts("State (key-value pairs):")
    Enum.each(state_examples, fn state_entry ->
      IO.puts("  #{inspect(state_entry)}")
    end)
    
    IO.puts("")
  end

  def debug_mcp_tool_schemas do
    IO.puts("=== MCP Tool Schema Examples ===")
    
    # What the MCP tools should actually return/accept
    mcp_examples = %{
      timestrike_create_plan: %{
        input: %{
          "initial_state" => [
            {{"at", "alex"}, {"x", 2, "y", 3, "z", 0}},
            {{"has", "alex"}, ["weapon"]}
          ],
          "goals" => [
            {"at", "alex", "extraction_point"}
          ]
        },
        output: %{
          "success" => true,
          "plan" => [
            {"move", ["alex", {"x", 5}, {"y", 3}, {"z", 0}]},
            {"move", ["alex", {"x", 8}, {"y", 3}, {"z", 0}]}
          ],
          "estimated_duration" => 3.2
        }
      },
      
      timestrike_execute_action: %{
        input: %{
          "action" => {"move", ["alex", {"x", 5}, {"y", 3}, {"z", 0}]},
          "current_state" => [
            {{"at", "alex"}, {"x", 2, "y", 3, "z", 0}}
          ]
        },
        output: %{
          "success" => true,
          "new_state" => [
            {{"at", "alex"}, {"x", 5, "y", 3, "z", 0}}
          ],
          "duration" => 1.8
        }
      }
    }
    
    Enum.each(mcp_examples, fn {tool_name, schema} ->
      IO.puts("#{tool_name}:")
      IO.puts("  Input: #{inspect(schema.input, pretty: true)}")
      IO.puts("  Output: #{inspect(schema.output, pretty: true)}")
      IO.puts("")
    end)
  end

  def debug_temporal_planning_specifics do
    IO.puts("=== Temporal Planning Specifics ===")
    
    # Time-based actions with scheduling
    timed_actions = [
      # Action with start time and duration
      %{
        action: {"move", ["alex", {"x", 5}, {"y", 3}, {"z", 0}]},
        start_time: 0.0,
        duration: 1.8,
        end_time: 1.8
      },
      %{
        action: {"attack", ["alex", "enemy_1"]},
        start_time: 2.0,
        duration: 0.5,
        end_time: 2.5
      }
    ]
    
    IO.puts("Timed Actions:")
    Enum.each(timed_actions, fn timed_action ->
      IO.puts("  #{inspect(timed_action, pretty: true)}")
    end)
    
    IO.puts("")
  end

  def run_debug do
    debug_action_formats()
    debug_goal_formats()
    debug_plan_structure()
    debug_multigoal_structure()
    debug_state_structure()
    debug_mcp_tool_schemas()
    debug_temporal_planning_specifics()
    
    IO.puts("=== Summary ===")
    IO.puts("- Actions: Tuples like {\"move\", [agent, position]}")
    IO.puts("- Goals: Tuples like {\"at\", agent, location}")
    IO.puts("- Plans: Lists of actions")
    IO.puts("- Multigoals: Lists of goals")
    IO.puts("- State: Key-value pairs with tuple keys")
    IO.puts("- Temporal: Actions with timing information")
    IO.puts("")
    IO.puts("This format should be used in ADR-033 MCP tool definitions!")
  end
end

# Run the debug
PlannerDebug.run_debug()
