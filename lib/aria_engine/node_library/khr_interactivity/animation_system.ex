defmodule NodeLibrary.KHRInteractivity.AnimationSystem do
  @moduledoc """
  Animation system operations for KHR_interactivity specification.
  Implements animation playback control and timing.
  """

  alias StateV2

  # =============================================================================
  # Animation Control Operations
  # =============================================================================

  @doc """
  Start animation playback.
  
  ## Parameters
  - state: Current state
  - [node_id, animation_id, start_time]: Node ID, animation identifier, and optional start time
  
  ## Returns
  Updated state with animation started
  """
  def start(state, [node_id, animation_id]) do
    start(state, [node_id, animation_id, 0.0])
  end

  def start(state, [node_id, animation_id, start_time]) when is_number(start_time) do
    current_time = :os.system_time(:millisecond) / 1000.0
    
    # Create animation playback state
    animation_state = %{
      animation_id: animation_id,
      start_time: start_time,
      playback_start: current_time,
      is_playing: true,
      is_paused: false,
      current_time: start_time
    }
    
    # Store animation state
    updated_state = StateV2.set_fact(state, "animation_#{animation_id}", "playback_state", animation_state)
    
    # Store result in node
    StateV2.set_fact(updated_state, Integer.to_string(node_id), "animation_started", animation_id)
  end

  def start(state, [node_id, _animation_id, _invalid_time]) do
    StateV2.set_fact(state, Integer.to_string(node_id), "animation_started", nil)
  end

  @doc """
  Stop animation playback.
  
  ## Parameters
  - state: Current state
  - [node_id, animation_id]: Node ID and animation identifier
  
  ## Returns
  Updated state with animation stopped
  """
  def stop(state, [node_id, animation_id]) do
    # Get current animation state
    animation_state = StateV2.get_fact(state, "animation_#{animation_id}", "playback_state")
    
    updated_state = 
      if animation_state do
        # Update animation state to stopped
        stopped_state = %{animation_state | 
          is_playing: false,
          is_paused: false
        }
        
        StateV2.set_fact(state, "animation_#{animation_id}", "playback_state", stopped_state)
      else
        state
      end
    
    StateV2.set_fact(updated_state, Integer.to_string(node_id), "animation_stopped", animation_id)
  end

  @doc """
  Stop animation at specific time.
  
  ## Parameters
  - state: Current state
  - [node_id, animation_id, stop_time]: Node ID, animation identifier, and stop time
  
  ## Returns
  Updated state with animation stopped at specified time
  """
  def stop_at(state, [node_id, animation_id, stop_time]) when is_number(stop_time) do
    # Get current animation state
    animation_state = StateV2.get_fact(state, "animation_#{animation_id}", "playback_state")
    
    updated_state = 
      if animation_state do
        # Update animation state to stopped at specific time
        stopped_state = %{animation_state | 
          is_playing: false,
          is_paused: false,
          current_time: stop_time
        }
        
        StateV2.set_fact(state, "animation_#{animation_id}", "playback_state", stopped_state)
      else
        state
      end
    
    StateV2.set_fact(updated_state, Integer.to_string(node_id), "animation_stopped_at", {animation_id, stop_time})
  end

  def stop_at(state, [node_id, animation_id, _invalid_time]) do
    StateV2.set_fact(state, Integer.to_string(node_id), "animation_stopped_at", {animation_id, nil})
  end

  # =============================================================================
  # Animation State Queries
  # =============================================================================

  @doc """
  Get current animation time.
  
  ## Parameters
  - state: Current state
  - [node_id, animation_id]: Node ID and animation identifier
  
  ## Returns
  Updated state with current animation time
  """
  def get_time(state, [node_id, animation_id]) do
    animation_state = StateV2.get_fact(state, "animation_#{animation_id}", "playback_state")
    
    current_time = 
      if animation_state && animation_state.is_playing do
        system_time = :os.system_time(:millisecond) / 1000.0
        elapsed = system_time - animation_state.playback_start
        animation_state.start_time + elapsed
      else
        animation_state && animation_state.current_time || 0.0
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", current_time)
  end

  @doc """
  Check if animation is playing.
  
  ## Parameters
  - state: Current state
  - [node_id, animation_id]: Node ID and animation identifier
  
  ## Returns
  Updated state with playing status
  """
  def is_playing(state, [node_id, animation_id]) do
    animation_state = StateV2.get_fact(state, "animation_#{animation_id}", "playback_state")
    
    is_playing = animation_state && animation_state.is_playing || false
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", is_playing)
  end

  # =============================================================================
  # Animation Management
  # =============================================================================

  @doc """
  Pause animation playback.
  
  ## Parameters
  - state: Current state
  - [node_id, animation_id]: Node ID and animation identifier
  
  ## Returns
  Updated state with animation paused
  """
  def pause(state, [node_id, animation_id]) do
    animation_state = StateV2.get_fact(state, "animation_#{animation_id}", "playback_state")
    
    updated_state = 
      if animation_state && animation_state.is_playing do
        # Calculate current time and pause
        system_time = :os.system_time(:millisecond) / 1000.0
        elapsed = system_time - animation_state.playback_start
        current_time = animation_state.start_time + elapsed
        
        paused_state = %{animation_state | 
          is_playing: false,
          is_paused: true,
          current_time: current_time
        }
        
        StateV2.set_fact(state, "animation_#{animation_id}", "playback_state", paused_state)
      else
        state
      end
    
    StateV2.set_fact(updated_state, Integer.to_string(node_id), "animation_paused", animation_id)
  end

  @doc """
  Resume animation playback.
  
  ## Parameters
  - state: Current state
  - [node_id, animation_id]: Node ID and animation identifier
  
  ## Returns
  Updated state with animation resumed
  """
  def resume(state, [node_id, animation_id]) do
    animation_state = StateV2.get_fact(state, "animation_#{animation_id}", "playback_state")
    
    updated_state = 
      if animation_state && animation_state.is_paused do
        system_time = :os.system_time(:millisecond) / 1000.0
        
        resumed_state = %{animation_state | 
          is_playing: true,
          is_paused: false,
          playback_start: system_time,
          start_time: animation_state.current_time
        }
        
        StateV2.set_fact(state, "animation_#{animation_id}", "playback_state", resumed_state)
      else
        state
      end
    
    StateV2.set_fact(updated_state, Integer.to_string(node_id), "animation_resumed", animation_id)
  end

  # =============================================================================
  # Task Methods for HTN Planning
  # =============================================================================

  def start_task_method(_state, [node_id, animation_id]) do
    [[:khr_animation_start, node_id, animation_id]]
  end

  def start_task_method(_state, [node_id, animation_id, start_time]) do
    [[:khr_animation_start, node_id, animation_id, start_time]]
  end

  def stop_task_method(_state, [node_id, animation_id]) do
    [[:khr_animation_stop, node_id, animation_id]]
  end

  def stop_at_task_method(_state, [node_id, animation_id, stop_time]) do
    [[:khr_animation_stop_at, node_id, animation_id, stop_time]]
  end

  def get_time_task_method(_state, [node_id, animation_id]) do
    [[:khr_animation_get_time, node_id, animation_id]]
  end

  def is_playing_task_method(_state, [node_id, animation_id]) do
    [[:khr_animation_is_playing, node_id, animation_id]]
  end

  def pause_task_method(_state, [node_id, animation_id]) do
    [[:khr_animation_pause, node_id, animation_id]]
  end

  def resume_task_method(_state, [node_id, animation_id]) do
    [[:khr_animation_resume, node_id, animation_id]]
  end
end
