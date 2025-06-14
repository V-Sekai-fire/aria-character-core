# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.TuiContentProvider do
  @moduledoc """
  TimeStrike-specific content provider for the TUI display system.

  Implements the AriaTui.ContentProvider behaviour to provide
  temporal planner game-specific content formatting.
  """

  @behaviour AriaTui.ContentProvider

  alias AriaTui.Display.Colors

  @impl AriaTui.ContentProvider
  def get_main_content(state, width, height) do
    # Generate TimeStrike temporal planner display
    content = get_timestrike_content(state)

    # Pad content to fit available space
    content
    |> Enum.take(height)
    |> pad_content_lines(width, height)
  end

  @impl AriaTui.ContentProvider
  def get_left_panel_content(state, width, height) do
    game_time = format_game_time(state)
    goal = Map.get(state, :current_goal, "survive_encounter")

    content = [
      " #{Colors.colorize("Mission Status", :bright_white)}",
      "",
      " Time: #{game_time}",
      " Goal: #{goal}",
      " Status: #{get_mission_status_display(state)}",
      "",
      " #{Colors.colorize("Temporal Planner", :bright_cyan)}",
      " Planning Time: #{Map.get(state, :last_plan_time, "N/A")}ms",
      " Actions Queued: #{get_queued_actions_count(state)}",
      " Re-plans: #{Map.get(state, :replan_count, 0)}",
      "",
      " #{Colors.colorize("Performance", :bright_green)}",
      " Tick Rate: #{Map.get(state, :tick_rate, "1000")} FPS",
      " Latency: #{Map.get(state, :latency, "< 1")}ms"
    ]

    pad_content_lines(content, width, height)
  end

  @impl AriaTui.ContentProvider
  def get_right_panel_content(state, width, height) do
    content = [
      " #{Colors.colorize("Tactical Situation", :bright_yellow)}",
      "",
      " Hostage Timer: #{get_hostage_timer(state)}",
      " Reinforcements: #{get_reinforcement_timer(state)}",
      " Team Status: #{get_team_status(state)}",
      "",
      " #{Colors.colorize("Player Input", :bright_magenta)}",
      " Last Input: #{Map.get(state, :last_input, "None")}",
      " Input Lag: #{Map.get(state, :input_lag, "< 1")}ms",
      " Interrupts: #{Map.get(state, :interrupt_count, 0)}",
      "",
      " #{Colors.colorize("Controls", :gray)}",
      " SPACE: Interrupt/Pause",
      " C: Change Conviction",
      " Q: Quit Game"
    ]

    pad_content_lines(content, width, height)
  end

  @impl AriaTui.ContentProvider
  def get_header_content(state, _layout) do
    game_time = format_game_time(state)
    goal = Map.get(state, :current_goal, "survive_encounter")
    plan_status = Map.get(state, :plan_status, "Executing")

    [
      "#{Colors.colorize("=== TimeStrike - Temporal Planner Test ===", :bright_white)}",
      "#{Colors.colorize("Time: #{game_time} | Goal: #{goal} | Plan Status: #{plan_status}", :bright_cyan)}"
    ]
  end

  @impl AriaTui.ContentProvider
  def get_footer_content(_state, _layout) do
    [
      Colors.colorize("[Press SPACE to pause | Q to quit | C to change conviction]", :gray)
    ]
  end

  # Private helper functions

  defp get_timestrike_content(state) do
    content = [
      " #{Colors.colorize("Current State:", :bright_yellow)}",
    ]

    # Add agent states
    agent_content = get_agent_states(state)
    content = content ++ agent_content

    content = content ++ [
      "",
      " #{Colors.colorize("Enemies:", :bright_red)}",
    ]

    # Add enemy states
    enemy_content = get_enemy_states(state)
    content = content ++ enemy_content

    content = content ++ [
      "",
      " #{Colors.colorize("Scheduled Actions:", :bright_magenta)}",
    ]

    # Add scheduled actions
    scheduled_content = get_scheduled_actions(state)
    content ++ scheduled_content
  end

  defp get_agent_states(state) do
    agents = Map.get(state, :agents, %{})

    if map_size(agents) == 0 do
      [" - No agents available"]
    else
      Enum.map(agents, fn {agent_id, agent_data} ->
        position = format_position(Map.get(agent_data, :position, {0, 0, 0}))
        hp = Map.get(agent_data, :hp, 100)
        max_hp = Map.get(agent_data, :max_hp, 100)
        action_status = get_agent_action_status(agent_data, state)

        color = get_agent_color(agent_id)
        " - #{Colors.colorize(agent_id, color)}: #{position} HP:#{hp}/#{max_hp} [#{action_status}]"
      end)
    end
  end

  defp get_enemy_states(state) do
    enemies = Map.get(state, :enemies, %{})

    if map_size(enemies) == 0 do
      [" - No enemies detected"]
    else
      Enum.map(enemies, fn {enemy_id, enemy_data} ->
        position = format_position(Map.get(enemy_data, :position, {0, 0, 0}))
        hp = Map.get(enemy_data, :hp, 70)
        max_hp = Map.get(enemy_data, :max_hp, 70)
        status = get_enemy_status(enemy_data)

        base_line = " - #{enemy_id}: #{position} HP:#{hp}/#{max_hp}"
        if status != "" do
          "#{base_line} [#{status}]"
        else
          base_line
        end
      end)
    end
  end

  defp get_scheduled_actions(state) do
    actions = Map.get(state, :scheduled_actions, [])
    current_time = Map.get(state, :game_time, 0)

    if length(actions) == 0 do
      [" No pending actions"]
    else
      actions
      |> Enum.filter(fn action -> Map.get(action, :scheduled_time, 0) > current_time end)
      |> Enum.take(4)  # Show next 4 actions
      |> Enum.map(fn action ->
        time_str = format_game_time(%{game_time: Map.get(action, :scheduled_time, 0)})
        description = Map.get(action, :description, "Unknown action")
        " #{time_str} - #{description}"
      end)
    end
  end

  defp format_game_time(state) do
    time_ms = Map.get(state, :game_time, 0)
    seconds = time_ms / 1000.0
    minutes = trunc(seconds / 60)
    remaining_seconds = seconds - (minutes * 60)

    if minutes > 0 do
      "#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{:io_lib.format("~4.1f", [remaining_seconds])}", 5, "0")}s"
    else
      "#{String.pad_leading("#{:io_lib.format("~4.1f", [remaining_seconds])}", 5, "0")}s"
    end
  end

  defp format_position({x, y, z}) when is_number(x) and is_number(y) and is_number(z) do
    "(#{trunc(x)},#{trunc(y)},#{trunc(z)})"
  end

  defp format_position(_), do: "(0,0,0)"

  defp get_agent_action_status(agent_data, _state) do
    current_action = Map.get(agent_data, :current_action)

    case current_action do
      %{action: :move_to, target: target, eta: eta} ->
        target_str = format_position(target)
        eta_str = format_game_time(%{game_time: eta})
        "Moving to #{target_str}, ETA: #{eta_str}"

      %{action: :skill_cast, skill: skill, target: target, eta: eta} ->
        target_str = format_position(target)
        eta_str = format_game_time(%{game_time: eta})
        "Casting #{skill} at #{target_str}, ETA: #{eta_str}"

      %{action: :attack, target: target, eta: eta} ->
        eta_str = format_game_time(%{game_time: eta})
        "Attacking #{target}, ETA: #{eta_str}"

      _ ->
        "Ready"
    end
  end

  defp get_enemy_status(enemy_data) do
    predicted_damage = Map.get(enemy_data, :predicted_damage)

    if predicted_damage && predicted_damage > 0 do
      "Will take #{predicted_damage} damage from Scorch"
    else
      ""
    end
  end

  defp get_agent_color(agent_id) do
    case String.downcase("#{agent_id}") do
      "alex" -> :bright_green
      "maya" -> :bright_blue
      "jordan" -> :bright_yellow
      _ -> :white
    end
  end

  defp get_mission_status_display(state) do
    case Map.get(state, :mission_status, :active) do
      :active -> Colors.colorize("Active", :bright_green)
      :paused -> Colors.colorize("Paused", :bright_yellow)
      :complete -> Colors.colorize("Complete", :bright_cyan)
      :failed -> Colors.colorize("Failed", :bright_red)
      _ -> Colors.colorize("Unknown", :gray)
    end
  end

  defp get_queued_actions_count(state) do
    actions = Map.get(state, :scheduled_actions, [])
    current_time = Map.get(state, :game_time, 0)

    actions
    |> Enum.count(fn action -> Map.get(action, :scheduled_time, 0) > current_time end)
  end

  defp get_hostage_timer(state) do
    current_time = Map.get(state, :game_time, 0) / 1000.0
    hostage_deadline = 30.0
    remaining = hostage_deadline - current_time

    if remaining > 0 do
      Colors.colorize("#{:io_lib.format("~.1f", [remaining])}s", :bright_red)
    else
      Colors.colorize("EXPIRED", :red)
    end
  end

  defp get_reinforcement_timer(state) do
    current_time = Map.get(state, :game_time, 0) / 1000.0
    reinforcement_time = 45.0
    remaining = reinforcement_time - current_time

    if remaining > 0 do
      Colors.colorize("#{:io_lib.format("~.1f", [remaining])}s", :yellow)
    else
      Colors.colorize("ARRIVED", :bright_red)
    end
  end

  defp get_team_status(state) do
    agents = Map.get(state, :agents, %{})
    alive_count = Enum.count(agents, fn {_id, agent} -> Map.get(agent, :hp, 0) > 0 end)
    total_count = map_size(agents)

    if alive_count == total_count do
      Colors.colorize("All Alive (#{alive_count}/#{total_count})", :bright_green)
    else
      Colors.colorize("#{alive_count}/#{total_count} Alive", :yellow)
    end
  end

  defp pad_content_lines(content, width, target_height) do
    padded_lines = Enum.map(content, fn line ->
      visual_len = Colors.visual_length(line)
      padding = width - visual_len
      line <> String.duplicate(" ", max(0, padding))
    end)

    # Ensure we have exactly target_height lines
    current_length = length(padded_lines)
    empty_line = String.duplicate(" ", width)

    cond do
      current_length < target_height ->
        padded_lines ++ List.duplicate(empty_line, target_height - current_length)
      current_length > target_height ->
        Enum.take(padded_lines, target_height)
      true ->
        padded_lines
    end
  end
end
