# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Verification.AnimationVerificationTest do
  @moduledoc """
  KHR_interactivity Animation System Specification Verification Tests
  
  Verifies animation operations against KHR specification requirements:
  - Timeline mapping and synchronization
  - Animation state management
  - glTF animation integration
  - Proper start/stop semantics
  """

  use ExUnit.Case
  alias StateV2
  alias NodeLibrary.KHRInteractivity.AnimationSystem
  alias NodeLibrary.KHRInteractivity.Support.GLTFSceneMock

  describe "animation/start specification compliance" do
    test "basic animation start with glTF timeline mapping" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Get animation info from mock scene
      animation_info = GLTFSceneMock.get_animation_info(state, "head_nod")
      
      # Start animation with default start time
      result_state = AnimationSystem.start(state, [5000, "head_nod"])
      
      # Verify animation started
      assert StateV2.get_fact(result_state, "5000", "animation_started") == "head_nod"
      
      # Verify animation playback state created
      playback_state = StateV2.get_fact(result_state, "animation_head_nod", "playback_state")
      assert playback_state != nil
      assert playback_state.animation_id == "head_nod"
      assert playback_state.start_time == 0.0
      assert playback_state.is_playing == true
      assert playback_state.is_paused == false
    end

    test "animation start with custom start time" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      custom_start_time = 1.5
      result_state = AnimationSystem.start(state, [5001, "arm_wave", custom_start_time])
      
      # Verify custom start time
      playback_state = StateV2.get_fact(result_state, "animation_arm_wave", "playback_state")
      assert playback_state.start_time == custom_start_time
      assert playback_state.current_time == custom_start_time
      assert playback_state.is_playing == true
    end

    test "animation start with invalid parameters" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Invalid start time
      result_state = AnimationSystem.start(state, [5002, "head_nod", "invalid_time"])
      
      # Should handle gracefully
      assert StateV2.get_fact(result_state, "5002", "animation_started") == nil
    end

    test "multiple animations can be started independently" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start multiple animations
      state_1 = AnimationSystem.start(state, [5010, "head_nod"])
      state_2 = AnimationSystem.start(state_1, [5011, "arm_wave", 0.5])
      
      # Both should be playing
      head_state = StateV2.get_fact(state_2, "animation_head_nod", "playback_state")
      arm_state = StateV2.get_fact(state_2, "animation_arm_wave", "playback_state")
      
      assert head_state.is_playing == true
      assert arm_state.is_playing == true
      assert arm_state.start_time == 0.5
    end
  end

  describe "animation/stop specification compliance" do
    test "immediate animation stop" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start then stop animation
      state_started = AnimationSystem.start(state, [5100, "head_nod"])
      state_stopped = AnimationSystem.stop(state_started, [5101, "head_nod"])
      
      # Verify stop result
      assert StateV2.get_fact(state_stopped, "5101", "animation_stopped") == "head_nod"
      
      # Verify animation state updated
      playback_state = StateV2.get_fact(state_stopped, "animation_head_nod", "playback_state")
      assert playback_state.is_playing == false
      assert playback_state.is_paused == false
    end

    test "stop non-existent animation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Stop animation that was never started
      result_state = AnimationSystem.stop(state, [5200, "non_existent"])
      
      # Should handle gracefully
      assert StateV2.get_fact(result_state, "5200", "animation_stopped") == "non_existent"
    end

    test "stop already stopped animation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start, stop, then stop again
      state_started = AnimationSystem.start(state, [5300, "head_nod"])
      state_stopped_1 = AnimationSystem.stop(state_started, [5301, "head_nod"])
      state_stopped_2 = AnimationSystem.stop(state_stopped_1, [5302, "head_nod"])
      
      # Should handle gracefully
      assert StateV2.get_fact(state_stopped_2, "5302", "animation_stopped") == "head_nod"
      
      playback_state = StateV2.get_fact(state_stopped_2, "animation_head_nod", "playback_state")
      assert playback_state.is_playing == false
    end
  end

  describe "animation/stopAt specification compliance" do
    test "scheduled stop at specific time" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start animation and schedule stop
      state_started = AnimationSystem.start(state, [5400, "arm_wave"])
      stop_time = 1.2
      state_stopped = AnimationSystem.stop_at(state_started, [5401, "arm_wave", stop_time])
      
      # Verify scheduled stop
      assert StateV2.get_fact(state_stopped, "5401", "animation_stopped_at") == {"arm_wave", stop_time}
      
      # Verify animation state shows correct stop time
      playback_state = StateV2.get_fact(state_stopped, "animation_arm_wave", "playback_state")
      assert playback_state.is_playing == false
      assert playback_state.current_time == stop_time
    end

    test "stopAt with invalid time parameter" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      state_started = AnimationSystem.start(state, [5500, "head_nod"])
      result_state = AnimationSystem.stop_at(state_started, [5501, "head_nod", "invalid_time"])
      
      # Should handle invalid time gracefully
      assert StateV2.get_fact(result_state, "5501", "animation_stopped_at") == {"head_nod", nil}
    end

    test "stopAt non-existent animation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      result_state = AnimationSystem.stop_at(state, [5600, "non_existent", 1.0])
      
      # Should handle gracefully
      assert StateV2.get_fact(result_state, "5600", "animation_stopped_at") == {"non_existent", 1.0}
    end

    test "stopAt time beyond animation duration" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Get animation duration from mock
      animation_info = GLTFSceneMock.get_animation_info(state, "head_nod")
      duration = animation_info.duration  # Should be 2.0 from mock data
      
      state_started = AnimationSystem.start(state, [5700, "head_nod"])
      beyond_duration = duration + 1.0
      result_state = AnimationSystem.stop_at(state_started, [5701, "head_nod", beyond_duration])
      
      # Should accept the time even if beyond duration
      playback_state = StateV2.get_fact(result_state, "animation_head_nod", "playback_state")
      assert playback_state.current_time == beyond_duration
    end
  end

  describe "animation state queries" do
    test "get_time returns current animation time" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start animation
      state_started = AnimationSystem.start(state, [5800, "head_nod"])
      
      # Get current time immediately after start
      result_state = AnimationSystem.get_time(state_started, [5801, "head_nod"])
      
      # Should return a time value (exact value depends on timing)
      current_time = StateV2.get_fact(result_state, "5801", "value")
      assert is_number(current_time)
      assert current_time >= 0.0
    end

    test "get_time for stopped animation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start, stop at specific time, then query
      state_started = AnimationSystem.start(state, [5900, "arm_wave"])
      state_stopped = AnimationSystem.stop_at(state_started, [5901, "arm_wave", 0.75])
      result_state = AnimationSystem.get_time(state_stopped, [5902, "arm_wave"])
      
      # Should return the stopped time
      current_time = StateV2.get_fact(result_state, "5902", "value")
      assert current_time == 0.75
    end

    test "is_playing returns correct status" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Check non-existent animation
      result_state_none = AnimationSystem.is_playing(state, [6000, "non_existent"])
      assert StateV2.get_fact(result_state_none, "6000", "value") == false
      
      # Start animation and check
      state_started = AnimationSystem.start(state, [6001, "head_nod"])
      result_state_playing = AnimationSystem.is_playing(state_started, [6002, "head_nod"])
      assert StateV2.get_fact(result_state_playing, "6002", "value") == true
      
      # Stop animation and check
      state_stopped = AnimationSystem.stop(state_started, [6003, "head_nod"])
      result_state_stopped = AnimationSystem.is_playing(state_stopped, [6004, "head_nod"])
      assert StateV2.get_fact(result_state_stopped, "6004", "value") == false
    end
  end

  describe "animation management operations" do
    test "pause and resume animation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start, pause, then resume
      state_started = AnimationSystem.start(state, [6100, "arm_wave"])
      state_paused = AnimationSystem.pause(state_started, [6101, "arm_wave"])
      state_resumed = AnimationSystem.resume(state_paused, [6102, "arm_wave"])
      
      # Verify pause state
      assert StateV2.get_fact(state_paused, "6101", "animation_paused") == "arm_wave"
      paused_playback = StateV2.get_fact(state_paused, "animation_arm_wave", "playback_state")
      assert paused_playback.is_playing == false
      assert paused_playback.is_paused == true
      
      # Verify resume state
      assert StateV2.get_fact(state_resumed, "6102", "animation_resumed") == "arm_wave"
      resumed_playback = StateV2.get_fact(state_resumed, "animation_arm_wave", "playback_state")
      assert resumed_playback.is_playing == true
      assert resumed_playback.is_paused == false
    end

    test "pause non-playing animation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Pause animation that's not playing
      result_state = AnimationSystem.pause(state, [6200, "head_nod"])
      
      # Should handle gracefully
      assert StateV2.get_fact(result_state, "6200", "animation_paused") == "head_nod"
    end

    test "resume non-paused animation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start animation (not paused) and try to resume
      state_started = AnimationSystem.start(state, [6300, "head_nod"])
      result_state = AnimationSystem.resume(state_started, [6301, "head_nod"])
      
      # Should handle gracefully
      assert StateV2.get_fact(result_state, "6301", "animation_resumed") == "head_nod"
    end
  end

  describe "glTF animation integration" do
    test "animation timeline mapping with scene nodes" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start head_nod animation which targets node 2 (head)
      result_state = AnimationSystem.start(state, [7000, "head_nod"])
      
      # Verify animation targets the correct node
      animation_info = GLTFSceneMock.get_animation_info(state, "head_nod")
      head_channel = Enum.at(animation_info.channels, 0)
      assert head_channel.target.node == 2  # Head node index
      assert head_channel.target.path == "rotation"
      
      # Animation should be playing
      playback_state = StateV2.get_fact(result_state, "animation_head_nod", "playback_state")
      assert playback_state.is_playing == true
    end

    test "multiple animation channels coordination" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start arm_wave animation which targets node 4 (left_arm)
      result_state = AnimationSystem.start(state, [7100, "arm_wave"])
      
      animation_info = GLTFSceneMock.get_animation_info(state, "arm_wave")
      arm_channel = Enum.at(animation_info.channels, 0)
      assert arm_channel.target.node == 4  # Left arm node index
      assert arm_channel.target.path == "rotation"
      
      # Verify animation duration matches keyframe data
      assert animation_info.duration == 1.5  # From mock accessor data
    end

    test "animation state persistence across operations" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Complex animation lifecycle
      state_1 = AnimationSystem.start(state, [7200, "head_nod", 0.5])
      state_2 = AnimationSystem.pause(state_1, [7201, "head_nod"])
      state_3 = AnimationSystem.resume(state_2, [7202, "head_nod"])
      final_state = AnimationSystem.stop_at(state_3, [7203, "head_nod", 1.8])
      
      # Final state should reflect complete lifecycle
      playback_state = StateV2.get_fact(final_state, "animation_head_nod", "playback_state")
      assert playback_state.is_playing == false
      assert playback_state.is_paused == false
      assert playback_state.current_time == 1.8
      
      # All operation results should be recorded
      assert StateV2.get_fact(final_state, "7200", "animation_started") == "head_nod"
      assert StateV2.get_fact(final_state, "7201", "animation_paused") == "head_nod"
      assert StateV2.get_fact(final_state, "7202", "animation_resumed") == "head_nod"
      assert StateV2.get_fact(final_state, "7203", "animation_stopped_at") == {"head_nod", 1.8}
    end
  end

  describe "animation timing and synchronization" do
    test "animation timing accuracy" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      start_time = 0.3
      state_started = AnimationSystem.start(state, [7300, "arm_wave", start_time])
      
      # Small delay to simulate time passage (in real implementation)
      # Process.sleep(10)  # Commented out for test reliability
      
      result_state = AnimationSystem.get_time(state_started, [7301, "arm_wave"])
      current_time = StateV2.get_fact(result_state, "7301", "value")
      
      # Time should be at least the start time
      assert current_time >= start_time
    end

    test "simultaneous animation management" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Start multiple animations
      state_1 = AnimationSystem.start(state, [7400, "head_nod"])
      state_2 = AnimationSystem.start(state_1, [7401, "arm_wave", 0.2])
      
      # Check both are playing
      head_playing = AnimationSystem.is_playing(state_2, [7402, "head_nod"])
      arm_playing = AnimationSystem.is_playing(head_playing, [7403, "arm_wave"])
      
      assert StateV2.get_fact(head_playing, "7402", "value") == true
      assert StateV2.get_fact(arm_playing, "7403", "value") == true
      
      # Stop one animation
      state_head_stopped = AnimationSystem.stop(arm_playing, [7404, "head_nod"])
      
      # Verify individual animation states
      head_final = AnimationSystem.is_playing(state_head_stopped, [7405, "head_nod"])
      arm_final = AnimationSystem.is_playing(head_final, [7406, "arm_wave"])
      
      assert StateV2.get_fact(head_final, "7405", "value") == false  # Head stopped
      assert StateV2.get_fact(arm_final, "7406", "value") == true    # Arm still playing
    end
  end
end
