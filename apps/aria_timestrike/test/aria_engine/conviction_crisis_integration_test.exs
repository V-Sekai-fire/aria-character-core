# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ConvictionCrisisIntegrationTest do
  @moduledoc """
  MVP acceptance test for the temporal planner - drives out all required components
  through a complete integration test of the conviction crisis demo scenario.

  This test implements Resolution 22: Start with tests - write MVP acceptance test first.
  The failing test will drive out exactly what components need to be implemented.
  """

  use ExUnit.Case, async: false

  alias AriaEngine.{TemporalState, GameActionJob}
  alias AriaTimestrike.{WebInterface, GameEngine}

  @moduletag :integration
  @moduletag timeout: 60_000  # 1 minute timeout for real-time demo

  describe "MVP Demo: Conviction Crisis Scenario" do
    test "Alex moves from {2,3} to {8,3} with real-time display and SPACEBAR interruption" do
      # This is the core MVP acceptance test from Resolution 18
      # Test scenario: "Alex moves from {2,3} to {8,3} with real-time terminal display and SPACEBAR interruption"

      # Step 1: Start game and initialize temporal state
      {:ok, game_state} = GameEngine.start_game()

      # Step 2: Verify Alex starts at initial position {2,3,0}
      alex_position = TemporalState.get_agent_position(game_state, "Alex")
      assert alex_position == {2, 3, 0}, "Alex should start at position {2,3,0}"

      # Step 3: Verify auto-plan to {8,3,0} is generated
      {:ok, planned_actions} = GameEngine.plan_to_goal(game_state, "Alex", {8, 3, 0})
      assert length(planned_actions) > 0, "Should generate movement plan to {8,3,0}"

      # Step 4: Start real-time movement execution
      {:ok, execution_pid} = WebInterface.start_real_time_display(game_state)

      # Calculate expected movement time: distance = 6 units, Alex speed = 4.0 u/s = 1.5 seconds
      expected_duration_ms = trunc(6.0 / 4.0 * 1000)  # 1500ms

      # Step 5: Execute movement and watch real-time progress
      {:ok, movement_job} = GameActionJob.schedule_action(game_state, "Alex", {:move_to, {8, 3}})

      # Step 6: Interrupt movement at midpoint {5,3} (simulate SPACEBAR after ~750ms)
      :timer.sleep(750)  # Wait for Alex to reach approximately {5,3}

      # Simulate SPACEBAR interruption
      WebInterface.handle_user_input(execution_pid, :spacebar)

      # Step 7: Verify replanning occurs after interruption
      current_position = TemporalState.get_agent_position(game_state, "Alex")
      assert elem(current_position, 0) >= 4 and elem(current_position, 0) <= 6,
             "Alex should be interrupted around midpoint, got #{inspect(current_position)}"

      # Verify new plan is generated to continue to {8,3}
      {:ok, replan_actions} = GameEngine.replan_after_interruption(game_state, "Alex", {8, 3})
      assert length(replan_actions) > 0, "Should generate new plan after interruption"

      # Step 8: Complete movement to {8,3}
      {:ok, completion_job} = GameActionJob.schedule_remaining_movement(game_state, "Alex", {8, 3})

      # Wait for completion
      :timer.sleep(1000)  # Allow time for remaining movement

      # Step 9: Verify final position and "Mission Complete!" message
      final_position = TemporalState.get_agent_position(game_state, "Alex")
      assert final_position == {8, 3}, "Alex should reach final destination {8,3}"

      # Verify mission complete status
      mission_status = TemporalState.get_mission_status(game_state)
      assert mission_status == :complete, "Mission should be marked as complete"

      # Verify success message is displayed
      last_message = WebInterface.get_last_displayed_message(execution_pid)
      assert last_message =~ "Mission Complete!", "Should display Mission Complete message"

      # Cleanup
      WebInterface.stop_real_time_display(execution_pid)
      GameEngine.stop_game(game_state)
    end

    test "movement timing is deterministic and accurate" do
      # This test verifies Resolution 23: deterministic timing calculations

      {:ok, game_state} = GameEngine.start_game()

      # Test Alex movement: {2,3} to {8,3} = 6 units at 4.0 u/s = 1.5 seconds
      start_time = System.monotonic_time(:millisecond)
      {:ok, _job} = GameActionJob.schedule_action(game_state, "Alex", {:move_to, {8, 3}})

      # Wait for completion
      :timer.sleep(1600)  # Slightly more than expected 1500ms

      end_time = System.monotonic_time(:millisecond)
      actual_duration = end_time - start_time

      # Should be very close to 1500ms (allowing 100ms tolerance for execution overhead)
      assert abs(actual_duration - 1500) <= 100,
             "Movement should take ~1500ms, took #{actual_duration}ms"

      # Verify final position is exact
      final_position = TemporalState.get_agent_position(game_state, "Alex")
      assert final_position == {8, 3}, "Final position should be exactly {8,3}"

      GameEngine.stop_game(game_state)
    end

    test "real-time web interface updates during movement" do
      # This test verifies Resolution 8: LiveView with real-time updates

      {:ok, game_state} = GameEngine.start_game()
      {:ok, web_pid} = WebInterface.start_real_time_display(game_state)

      # Start movement
      {:ok, _job} = GameActionJob.schedule_action(game_state, "Alex", {:move_to, {8, 3}})

      # Collect position updates during movement
      position_updates = Enum.reduce(1..8, [], fn _i, acc ->
        :timer.sleep(200)
        current_pos = TemporalState.get_agent_position(game_state, "Alex")
        [current_pos | acc]
      end)

      position_updates = Enum.reverse(position_updates)

      # Verify we got position updates
      assert length(position_updates) > 0, "Should collect position updates"

      # Verify smooth progression from {2,3,0} toward {8,3,0}
      [first_pos | _] = position_updates
      [last_pos | _] = Enum.reverse(position_updates)

      assert elem(first_pos, 0) <= 3, "Should start near {2,3,0}"
      assert elem(last_pos, 0) >= 7, "Should end near {8,3,0}"

      # Verify monotonic X progression (no backwards movement)
      x_positions = Enum.map(position_updates, &elem(&1, 0))
      assert x_positions == Enum.sort(x_positions), "X coordinate should increase monotonically"

      WebInterface.stop_real_time_display(web_pid)
      GameEngine.stop_game(game_state)
    end

    test "Oban job scheduling and execution integration" do
      # This test verifies Resolution 2: Oban queues working correctly

      {:ok, game_state} = GameEngine.start_game()

      # Schedule action through Oban
      action_params = %{
        agent_id: "Alex",
        action_type: :move_to,
        target_position: {8, 3},
        game_state_id: game_state.id
      }

      # Verify job is enqueued
      {:ok, job} = GameActionJob.new(action_params)
                   |> AriaQueue.Oban.insert()

      assert job.id, "Job should be assigned an ID after insertion"
      assert job.queue == "sequential_actions", "Movement should use sequential queue"

      # Wait for job execution
      :timer.sleep(2000)

      # Verify job completed successfully
      completed_job = AriaQueue.Oban.Repo.get(AriaQueue.Oban.Job, job.id)
      assert completed_job.state == "completed", "Job should complete successfully"

      # Verify game state was updated
      final_position = TemporalState.get_agent_position(game_state, "Alex")
      assert final_position == {8, 3, 0}, "Alex should be at target position after job completion"

      GameEngine.stop_game(game_state)
    end
  end

  describe "Component Integration Verification" do
    test "all required modules are available and working together" do
      # This test ensures all the components driven out by the main test actually exist
      # and can work together - serves as a development checkpoint

      # Verify TemporalState module exists and functions
      assert Code.ensure_loaded?(AriaEngine.TemporalState), "TemporalState module should exist"

      # Verify GameActionJob module exists
      assert Code.ensure_loaded?(AriaEngine.GameActionJob), "GameActionJob module should exist"

      # Verify WebInterface module exists
      assert Code.ensure_loaded?(AriaTimestrike.WebInterface), "WebInterface module should exist"

      # Verify GameEngine module exists
      assert Code.ensure_loaded?(AriaTimestrike.GameEngine), "GameEngine module should exist"

      # Test basic integration without full scenario
      {:ok, state} = AriaTimestrike.GameEngine.start_game()
      assert state, "GameEngine should be able to start game"

      # Verify we can get agent position
      position = AriaEngine.TemporalState.get_agent_position(state, "Alex")
      assert is_tuple(position) and tuple_size(position) == 3, "Should return valid 3D position"

      AriaTimestrike.GameEngine.stop_game(state)
    end
  end
end
