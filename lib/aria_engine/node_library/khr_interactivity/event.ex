# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Event do
  @moduledoc """
  KHR_interactivity Event Nodes

  Implements event operations from the glTF KHR_interactivity specification:
  - khr_event_on_start: Triggered when the system starts
  - khr_event_on_stop: Triggered when the system stops
  - khr_event_on_tick: Triggered on each frame/tick
  - khr_event_on_click: Triggered on mouse/pointer click
  - khr_event_on_key: Triggered on keyboard input
  - khr_event_on_hover: Triggered when hovering over elements
  - khr_event_on_custom: Triggered by custom events

  Events form the foundation of reactive behavior in KHR_interactivity systems.
  """

  alias StateV2
  alias Domain.Actions

  @doc "Register all event actions with a domain"
  @spec register_actions(Domain.Core.t()) :: Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_event_on_start, &event_on_start/2, %{
      domain: "khr_interactivity",
      category: "event",
      khr_node_type: "event/onStart",
      description: "System start event"
    })
    |> Actions.add_action(:khr_event_on_stop, &event_on_stop/2, %{
      domain: "khr_interactivity",
      category: "event",
      khr_node_type: "event/onStop",
      description: "System stop event"
    })
    |> Actions.add_action(:khr_event_on_tick, &event_on_tick/2, %{
      domain: "khr_interactivity",
      category: "event",
      khr_node_type: "event/onTick",
      description: "Frame/tick event"
    })
    |> Actions.add_action(:khr_event_on_click, &event_on_click/2, %{
      domain: "khr_interactivity",
      category: "event",
      khr_node_type: "event/onClick",
      description: "Click event"
    })
    |> Actions.add_action(:khr_event_on_key, &event_on_key/2, %{
      domain: "khr_interactivity",
      category: "event",
      khr_node_type: "event/onKey",
      description: "Keyboard input event"
    })
    |> Actions.add_action(:khr_event_on_hover, &event_on_hover/2, %{
      domain: "khr_interactivity",
      category: "event",
      khr_node_type: "event/onHover",
      description: "Hover event"
    })
    |> Actions.add_action(:khr_event_on_custom, &event_on_custom/2, %{
      domain: "khr_interactivity",
      category: "event",
      khr_node_type: "event/onCustom",
      description: "Custom event"
    })
  end

  @doc """
  System start event.
  
  Triggered when the KHR_interactivity system begins execution.
  Provides initial timestamp and system state.
  """
  def event_on_start(state, [node_index]) do
    timestamp = System.system_time(:millisecond)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "triggered", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "timestamp", timestamp)
    |> StateV2.set_fact(Integer.to_string(node_index), "event_type", "start")
  end

  @doc """
  System stop event.
  
  Triggered when the KHR_interactivity system stops execution.
  Provides final timestamp and cleanup signals.
  """
  def event_on_stop(state, [node_index]) do
    timestamp = System.system_time(:millisecond)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "triggered", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "timestamp", timestamp)
    |> StateV2.set_fact(Integer.to_string(node_index), "event_type", "stop")
  end

  @doc """
  Frame/tick event.
  
  Triggered on each frame or update cycle.
  Provides delta time and frame number.
  """
  def event_on_tick(state, [node_index, delta_time \\ 0.016]) do
    timestamp = System.system_time(:millisecond)
    
    # Get current frame number or initialize to 0
    current_frame = StateV2.get_fact(state, Integer.to_string(node_index), "frame_number") || 0
    new_frame = current_frame + 1
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "triggered", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "timestamp", timestamp)
    |> StateV2.set_fact(Integer.to_string(node_index), "event_type", "tick")
    |> StateV2.set_fact(Integer.to_string(node_index), "delta_time", delta_time)
    |> StateV2.set_fact(Integer.to_string(node_index), "frame_number", new_frame)
  end

  @doc """
  Click event.
  
  Triggered when user clicks on interactive elements.
  Provides click position, button, and target information.
  """
  def event_on_click(state, [node_index, x \\ 0, y \\ 0, button \\ "left"]) do
    timestamp = System.system_time(:millisecond)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "triggered", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "timestamp", timestamp)
    |> StateV2.set_fact(Integer.to_string(node_index), "event_type", "click")
    |> StateV2.set_fact(Integer.to_string(node_index), "position_x", x)
    |> StateV2.set_fact(Integer.to_string(node_index), "position_y", y)
    |> StateV2.set_fact(Integer.to_string(node_index), "button", button)
  end

  @doc """
  Keyboard input event.
  
  Triggered when user presses or releases keys.
  Provides key code, action type, and modifier states.
  """
  def event_on_key(state, [node_index, key_code \\ "", action \\ "press"]) do
    timestamp = System.system_time(:millisecond)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "triggered", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "timestamp", timestamp)
    |> StateV2.set_fact(Integer.to_string(node_index), "event_type", "key")
    |> StateV2.set_fact(Integer.to_string(node_index), "key_code", key_code)
    |> StateV2.set_fact(Integer.to_string(node_index), "action", action)
  end

  @doc """
  Hover event.
  
  Triggered when user hovers over interactive elements.
  Provides hover state and position information.
  """
  def event_on_hover(state, [node_index, x \\ 0, y \\ 0, is_entering \\ true]) do
    timestamp = System.system_time(:millisecond)
    hover_state = if is_entering, do: "enter", else: "exit"
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "triggered", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "timestamp", timestamp)
    |> StateV2.set_fact(Integer.to_string(node_index), "event_type", "hover")
    |> StateV2.set_fact(Integer.to_string(node_index), "position_x", x)
    |> StateV2.set_fact(Integer.to_string(node_index), "position_y", y)
    |> StateV2.set_fact(Integer.to_string(node_index), "hover_state", hover_state)
  end

  @doc """
  Custom event.
  
  Triggered by application-specific events.
  Provides flexible event data and custom payload.
  """
  def event_on_custom(state, [node_index, event_name \\ "", event_data \\ %{}]) do
    timestamp = System.system_time(:millisecond)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "triggered", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "timestamp", timestamp)
    |> StateV2.set_fact(Integer.to_string(node_index), "event_type", "custom")
    |> StateV2.set_fact(Integer.to_string(node_index), "event_name", event_name)
    |> StateV2.set_fact(Integer.to_string(node_index), "event_data", event_data)
  end

  @doc """
  Check if an event node was triggered.
  
  Helper function to query event trigger state.
  """
  def is_triggered?(state, node_index) do
    case StateV2.get_fact(state, Integer.to_string(node_index), "triggered") do
      true -> true
      _ -> false
    end
  end

  @doc """
  Clear event trigger state.
  
  Helper function to reset event state after processing.
  """
  def clear_trigger(state, node_index) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "triggered", false)
  end

  @doc """
  Get event data for a triggered event.
  
  Helper function to retrieve all event-related data.
  """
  def get_event_data(state, node_index) do
    node_id = Integer.to_string(node_index)
    
    %{
      triggered: StateV2.get_fact(state, node_id, "triggered"),
      timestamp: StateV2.get_fact(state, node_id, "timestamp"),
      event_type: StateV2.get_fact(state, node_id, "event_type"),
      # Additional data depends on event type
      position_x: StateV2.get_fact(state, node_id, "position_x"),
      position_y: StateV2.get_fact(state, node_id, "position_y"),
      button: StateV2.get_fact(state, node_id, "button"),
      key_code: StateV2.get_fact(state, node_id, "key_code"),
      action: StateV2.get_fact(state, node_id, "action"),
      hover_state: StateV2.get_fact(state, node_id, "hover_state"),
      event_name: StateV2.get_fact(state, node_id, "event_name"),
      event_data: StateV2.get_fact(state, node_id, "event_data"),
      delta_time: StateV2.get_fact(state, node_id, "delta_time"),
      frame_number: StateV2.get_fact(state, node_id, "frame_number")
    }
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Map.new()
  end
end
