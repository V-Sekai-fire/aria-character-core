# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Client do
  @moduledoc """
  Enhanced Terminal User Interface (TUI) client providing a rich, interactive terminal interface.

  This module provides a responsive terminal interface that displays
  application state in real-time with a beautiful layout, colors, and responsive controls.
  Uses ANSI escape codes for cross-platform terminal enhancement.
  
  Integrates with AriaEngine for state management and planning capabilities.
  """

  alias AriaTui.Display
  alias AriaEngine.{State, Planner}
  alias AriaTui.SystemDomain

  @tick_interval 100  # 100ms ticks

  def start(initial_state \\ nil) do
    state = initial_state || create_default_state()
    {:ok, state_pid} = start_link(initial_state: state)

    # Setup terminal
    setup_terminal()

    # Start the TUI loop
    spawn(fn -> enhanced_tui_loop(state_pid) end)

    # Handle user input
    enhanced_input_loop(state_pid)
  end

  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :initial_state)
    state = initial_state || create_default_state()
    Agent.start_link(fn ->
      %{
        application_state: state,
        tick_count: 0,
        paused: false,
        test_mode: "overview",
        content_provider: AriaTui.DefaultContentProvider,
        start_time: :os.system_time(:second),
        last_message: "🎯 TUI Component Test Suite started! Press 1-4 for tests, Q to quit.",
        last_update: DateTime.utc_now(),
        # Plan display state
        last_plan: nil,
        plan_display_until: nil,
        plan_scroll_offset: 0,
        plan_debounce_ref: nil,
        show_plan_overlay: false
      }
    end)
  end

  def get_state(pid) do
    Agent.get(pid, fn state -> state end)
  end

  def update_state(pid, fun) do
    Agent.update(pid, fun)
  end

  def handle_key(pid, key) do
    Agent.update(pid, fn state ->
      case key do
        " " -> %{state | last_message: "🔔 Interrupted by user"}
        "p" -> %{state | paused: !state.paused}
        "q" -> %{state | last_message: "👋 Goodbye!"}
        "r" -> %{state | last_message: "🔄 Display refreshed"}
        "1" -> %{state | test_mode: "colors", last_message: "🎨 Color test mode"}
        "2" -> %{state | test_mode: "layout", last_message: "📐 Layout test mode"}
        "3" -> %{state | test_mode: "responsive", last_message: "📱 Responsive test mode"}
        "4" -> %{state | test_mode: "components", last_message: "🧩 Component test mode"}
        "0" -> %{state | test_mode: "overview", last_message: "🎯 Overview mode"}
        _ -> state
      end
    end)
  end

  def tick(pid) do
    Agent.update(pid, fn state ->
      if state.paused do
        state
      else
        %{state | tick_count: state.tick_count + 1}
      end
    end)
  end

  def handle_message(pid, message) do
    case message do
      {:state_update, new_state} ->
        Agent.update(pid, fn state ->
          %{state | application_state: new_state}
        end)
      _ ->
        :ok
    end
  end

  defp create_default_state do
    # Create an AriaEngine state for demonstration/testing
    engine_state = State.new()
                  |> State.set_object("system_status", "tui", "operational")
                  |> State.set_object("system_metric", "uptime", 0)
                  |> State.set_object("system_metric", "components_active", 3)
                  |> State.set_object("tui_state", "test_mode", "overview")
                  |> State.set_object("system_metric", "memory_usage", 42.5)
                  |> State.set_object("system_metric", "cpu_usage", 23.1)
    
    %{
      status: "active",
      engine_state: engine_state,
      planning_status: :idle,
      last_plan: nil,
      components: %{
        "component_1" => %{value: 42, status: :operational},
        "component_2" => %{value: 73, status: :operational},
        "component_3" => %{value: 91, status: :operational}
      }
    }
  end

  # Terminal handling
  defp setup_terminal do
    # Hide cursor and enable alternative screen buffer
    IO.write("\e[?25l\e[?1049h")

    # Clear screen once at startup
    IO.write("\e[2J\e[H")

    # Set up signal handling for clean exit and resize
    Process.flag(:trap_exit, true)

    # Try to set up terminal resize handling (Unix-specific)
    try do
      :os.set_signal(:sigwinch, :handle)
    rescue
      _ -> :ok  # Ignore if not supported
    end

    # Try to set up interrupt handling (Unix-specific)
    try do
      :os.set_signal(:sigint, :handle)
      :os.set_signal(:sigterm, :handle)
    rescue
      _ -> :ok  # Ignore if not supported
    end
  end

  defp cleanup_terminal do
    # Show cursor and restore normal screen buffer
    IO.write("\e[?25h\e[?1049l")
  end

  defp enhanced_tui_loop(state_pid) do
    state = Agent.get(state_pid, & &1)

    # Display current state using the display module (it handles screen clearing)
    Display.display_state(state)

    # Update state if not paused
    unless state.paused do
      # Perform world observations (may fail)
      observation_type = case rem(state.tick_count, 30) do
        0 -> :system_metrics
        10 -> :network_status
        20 -> :environment
        _ -> nil
      end
      
      updated_state = if observation_type do
        # Attempt world observation intent
        observed_state = %{state.application_state | 
          engine_state: observe_world_state(state.application_state.engine_state, observation_type)
        }
        update_test_state(observed_state, state.tick_count)
      else
        update_test_state(state.application_state, state.tick_count)
      end
      
      Agent.update(state_pid, fn s ->
        %{s |
          application_state: updated_state,
          tick_count: s.tick_count + 1
        }
      end)
    end

    # Continue the loop
    Process.sleep(@tick_interval)
    enhanced_tui_loop(state_pid)
  end

  defp enhanced_input_loop(game_pid) do
    case IO.gets("") do
      " \n" ->  # Spacebar pressed
        Agent.update(game_pid, fn state ->
          paused = not state.paused
          message = if paused, do: "⏸️ TUI paused", else: "▶️ TUI resumed"
          %{state | paused: paused, last_message: message}
        end)
        enhanced_input_loop(game_pid)

      "1\n" ->  # Color test
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "colors", last_message: "🎨 Color test mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "2\n" ->  # Layout test
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "layout", last_message: "📐 Layout test mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "3\n" ->  # Responsive test
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "responsive", last_message: "📱 Responsive test mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "4\n" ->  # Component test
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "components", last_message: "🧩 Component test mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "0\n" ->  # Overview
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "overview", last_message: "🏠 Overview mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "r\n" ->  # Refresh
        Agent.update(game_pid, fn state ->
          %{state | last_message: "🔄 Display refreshed", last_update: DateTime.utc_now()}
        end)
        enhanced_input_loop(game_pid)

      "p\n" ->  # P key pressed (legacy pause)
        Agent.update(game_pid, fn state ->
          paused = not state.paused
          message = if paused, do: "⏸️ TUI paused", else: "▶️ TUI resumed"
          %{state | paused: paused, last_message: message}
        end)
        enhanced_input_loop(game_pid)

      "q\n" ->  # Quit
        cleanup_terminal()
        IO.puts("\n\e[92m👋 TUI test suite ended. Thanks for testing!\e[0m")
        System.halt(0)

      input when input in ["\e", "\e[", <<3>>, <<4>>] ->  # Escape sequences or Ctrl+C/D
        cleanup_terminal()
        IO.puts("\n\e[92m👋 TUI test suite ended. Thanks for testing!\e[0m")
        System.halt(0)

      _ ->
        enhanced_input_loop(game_pid)
    end
  rescue
    # Handle any unexpected errors during input processing
    _ ->
      cleanup_terminal()
      IO.puts("\n\e[91m⚠️ TUI ended unexpectedly. Terminal cleaned up.\e[0m")
      System.halt(1)
  end

  # Update components based on tick count for simulation
  defp update_components(components, tick_count) do
    Map.new(components, fn {name, component} ->
      # Simulate component updates
      new_value = case rem(tick_count, 100) do
        n when n < 10 -> component.value + 1
        n when n < 20 -> component.value - 1
        _ -> component.value
      end
      
      {name, %{component | value: new_value}}
    end)
  end

  def update_test_state(state, tick_count) do
    # Use AriaEngine to update state through planning
    updated_engine_state = update_engine_state_with_planner(state.engine_state, tick_count)
    
    %{state |
      engine_state: updated_engine_state,
      components: update_components(state.components, tick_count)
    }
  end

  defp update_engine_state_with_planner(engine_state, tick_count) do
    # Update facts in the engine state to simulate system changes
    engine_state
    |> State.set_object("system_metric", "uptime", tick_count)
    |> State.set_object("system_metric", "memory_usage", 40.0 + :math.sin(tick_count / 10.0) * 10.0)
    |> State.set_object("system_metric", "cpu_usage", 20.0 + :math.cos(tick_count / 15.0) * 15.0)
    |> maybe_trigger_planning(tick_count)
    |> observe_world_state(:system_metrics)
  end

  defp maybe_trigger_planning(engine_state, tick_count) do
    # Every 50 ticks, simulate a planning operation
    if rem(tick_count, 50) == 0 do
      # Add a planning event to the state
      updated_state = 
        engine_state
        |> State.set_object("system_event", "last_planning", tick_count)
        |> State.set_object("system_status", "tui", "planning")

      # Use the planner to achieve a goal
      domain = SystemDomain.create_domain()
      goal = {"observation_completed", ["cpu_usage"]}
      case Planner.plan(domain, updated_state, [goal]) do
        {:ok, plan, _} ->
          Agent.update(self(), fn state ->
            %{state | last_plan: plan, plan_display_until: DateTime.utc_now() |> DateTime.add(5, :second)}
          end)
          updated_state
        {:error, _reason} ->
          updated_state
      end
    else
      engine_state
      |> State.set_object("system_status", "tui", "operational")
    end
  end

  # World observation updates as intents (may fail)
  defp observe_world_state(engine_state, observation_type) do
    case attempt_observation(observation_type) do
      {:ok, observed_facts} ->
        # Observation succeeded - update our memory of the world
        Enum.reduce(observed_facts, engine_state, fn {fact, value}, acc_state ->
          State.set_object(acc_state, "system_observation", fact, value)
        end)
        
      {:error, :sensor_failure} ->
        # Sensor failed - mark uncertainty in our state
        State.set_object(engine_state, "system_observation", "status", :sensor_failure)
        
      {:error, :partial_observation} ->
        # Only partial data available - update what we can
        State.set_object(engine_state, "system_observation", "status", :partial_data)
        
      {:error, :world_changed_too_fast} ->
        # World changed faster than we can observe - mark staleness
        State.set_object(engine_state, "system_observation", "status", :stale_data)
        
      {:error, reason} ->
        # Other observation failures
        State.set_object(engine_state, "system_observation", "status", {:failed, reason})
    end
  end

  defp attempt_observation(observation_type) do
    # Simulate observation attempts with realistic failure rates
    case observation_type do
      :system_metrics ->
        if :rand.uniform() > 0.1 do  # 90% success rate for system metrics
          {:ok, [
            {:cpu_usage, 20.0 + :rand.uniform() * 60.0},
            {:memory_usage, 30.0 + :rand.uniform() * 50.0},
            {:disk_usage, 40.0 + :rand.uniform() * 40.0}
          ]}
        else
          {:error, :sensor_failure}
        end
        
      :network_status ->
        if :rand.uniform() > 0.15 do  # 85% success rate for network
          {:ok, [
            {:network_latency, 10.0 + :rand.uniform() * 100.0},
            {:bandwidth_usage, :rand.uniform() * 100.0}
          ]}
        else
          {:error, :partial_observation}
        end
        
      :environment ->
        if :rand.uniform() > 0.2 do  # 80% success rate for environment
          {:ok, [
            {:temperature, 20.0 + :rand.uniform() * 15.0},
            {:humidity, 40.0 + :rand.uniform() * 40.0}
          ]}
        else
          {:error, :world_changed_too_fast}
        end
        
      _ ->
        {:error, :unknown_observation_type}
    end
  end

  # Handle terminal resize signals (if supported)
  def handle_info({:signal, :sigwinch}, state) do
    # Terminal was resized - the next display update will handle it
    {:noreply, state}
  end

  # Handle interrupt signals for clean exit
  def handle_info({:signal, :sigint}, _state) do
    cleanup_terminal()
    IO.puts("\n\e[92m👋 TUI interrupted. Terminal cleaned up.\e[0m")
    System.halt(0)
  end

  def handle_info({:signal, :sigterm}, _state) do
    cleanup_terminal()
    IO.puts("\n\e[92m👋 TUI terminated. Terminal cleaned up.\e[0m")
    System.halt(0)
  end

  def handle_info(_, state), do: {:noreply, state}
end
