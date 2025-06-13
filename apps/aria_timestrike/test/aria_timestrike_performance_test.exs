# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.PerformanceTest do
  use ExUnit.Case, async: false

  alias AriaEngine.{State}

  describe "Timestrike performance and integration tests" do
    test "timestrike action processing performance" do
      action_count = 100

      # Create timestrike actions
      actions = create_timestrike_actions(action_count)
      initial_state = State.new()

      {time_us, results} = :timer.tc(fn ->
        Enum.map(actions, fn {action_type, args} ->
          case action_type do
            :move_to -> AriaTimestrike.move_to(initial_state, args)
            :attack ->
              # attack/2 only takes [agent_id, target_id], so we take first 2 args
              AriaTimestrike.attack(initial_state, Enum.take(args, 2))
            :skill_cast -> AriaTimestrike.skill_cast(initial_state, args)
            :interact -> AriaTimestrike.interact(initial_state, args)
          end
        end)
      end)

      time_ms = time_us / 1000
      actions_per_second = action_count / (time_ms / 1000)

      # All actions should complete (even if they return false placeholders)
      assert length(results) == action_count

      IO.puts("\n🎮 TIMESTRIKE ACTION PERFORMANCE:")
      IO.puts("   Actions: #{action_count}")
      IO.puts("   Time: #{Float.round(time_ms, 2)}ms")
      IO.puts("   Actions/sec: #{Float.round(actions_per_second, 2)}")

      # Should handle at least 1000 actions per second
      assert actions_per_second > 1000
    end

    test "concurrent timestrike action processing" do
      action_count = 200
      worker_count = 4

      actions = create_timestrike_actions(action_count)
      actions_per_worker = div(action_count, worker_count)

      initial_state = State.new()

      {time_us, results} = :timer.tc(fn ->
        actions
        |> Enum.chunk_every(actions_per_worker)
        |> Enum.map(fn action_chunk ->
          Task.async(fn ->
            Enum.map(action_chunk, fn {action_type, args} ->
              case action_type do
                :move_to -> AriaTimestrike.move_to(initial_state, args)
                :attack -> AriaTimestrike.attack(initial_state, args)
                :skill_cast -> AriaTimestrike.skill_cast(initial_state, args)
                :interact -> AriaTimestrike.interact(initial_state, args)
              end
            end)
          end)
        end)
        |> Enum.map(&Task.await/1)
        |> List.flatten()
      end)

      time_ms = time_us / 1000
      actions_per_second = action_count / (time_ms / 1000)

      assert length(results) == action_count

      IO.puts("\n🚀 CONCURRENT TIMESTRIKE PERFORMANCE:")
      IO.puts("   Actions: #{action_count}")
      IO.puts("   Workers: #{worker_count}")
      IO.puts("   Time: #{Float.round(time_ms, 2)}ms")
      IO.puts("   Actions/sec: #{Float.round(actions_per_second, 2)}")

      # Concurrent processing should be faster
      assert actions_per_second > 2000
    end

    test "timestrike game subsystem integration pattern" do
      # This test demonstrates the CORRECT architecture for TimeStrike
      # where results flow to game subsystems instead of test aggregation

      action_count = 50

      # Simulate TimeStrike game subsystems
      ai_engine_pid = spawn(fn -> mock_ai_engine() end)
      physics_engine_pid = spawn(fn -> mock_physics_engine() end)
      game_state_pid = spawn(fn -> mock_game_state_manager() end)

      # Create actions that would trigger different subsystem responses
      actions = create_timestrike_actions(action_count)

      {time_us, :ok} = :timer.tc(fn ->
        test_game_subsystem_integration(actions, %{
          ai_engine: ai_engine_pid,
          physics_engine: physics_engine_pid,
          game_state: game_state_pid
        })
      end)

      time_ms = time_us / 1000
      fps = action_count / (time_ms / 1000)

      IO.puts("\n🎮 GAME SUBSYSTEM INTEGRATION TEST:")
      IO.puts("   Actions: #{action_count}")
      IO.puts("   Time: #{Float.round(time_ms, 2)}ms")
      IO.puts("   Effective FPS: #{Float.round(fps, 2)}")

      # Should maintain reasonable frame rates
      assert fps > 60  # 60 FPS minimum for real-time gaming
    end
  end

  # Helper functions for creating test data
  defp create_timestrike_actions(count) do
    for i <- 1..count do
      agent_id = "agent_#{rem(i, 10)}"

      # Cycle through all 4 action types
      case rem(i, 4) do
        0 -> {:move_to, [agent_id, {rem(i, 100), rem(i * 2, 100), rem(i * 3, 50)}]}
        1 -> {:attack, [agent_id, "target_#{rem(i, 5)}", "skill_#{rem(i, 3)}"]}
        2 -> {:skill_cast, [agent_id, "spell_#{rem(i, 6)}", "area_#{rem(i, 4)}"]}
        3 -> {:interact, [agent_id, "npc_#{rem(i, 8)}", "action_#{rem(i, 5)}"]}
      end
    end
  end

  defp test_game_subsystem_integration(actions, subsystems) do
    initial_state = State.new()

    # Process actions and send results to appropriate subsystems
    Enum.each(actions, fn {action_type, args} ->
      result = case action_type do
        :move_to -> AriaTimestrike.move_to(initial_state, args)
        :attack -> AriaTimestrike.attack(initial_state, args)
        :skill_cast -> AriaTimestrike.skill_cast(initial_state, args)
        :interact -> AriaTimestrike.interact(initial_state, args)
      end

      # Route results to appropriate subsystems
      case action_type do
        :move_to -> send(subsystems.physics_engine, {:movement_update, result})
        :attack -> send(subsystems.ai_engine, {:combat_result, result})
        :skill_cast -> send(subsystems.ai_engine, {:skill_result, result})
        :interact -> send(subsystems.game_state, {:interaction_result, result})
      end
    end)

    # Clean shutdown of mock subsystems
    send(subsystems.ai_engine, :shutdown)
    send(subsystems.physics_engine, :shutdown)
    send(subsystems.game_state, :shutdown)

    :ok
  end

  # Mock game subsystem processes
  defp mock_ai_engine do
    receive do
      {:combat_result, _result} -> mock_ai_engine()
      {:skill_result, _result} -> mock_ai_engine()
      :shutdown -> :ok
    end
  end

  defp mock_physics_engine do
    receive do
      {:movement_update, _result} -> mock_physics_engine()
      :shutdown -> :ok
    end
  end

  defp mock_game_state_manager do
    receive do
      {:interaction_result, _result} -> mock_game_state_manager()
      :shutdown -> :ok
    end
  end
end
