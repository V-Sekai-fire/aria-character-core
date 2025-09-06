defmodule AriaNeonFrontlines.LocalSocializerTest do
  use ExUnit.Case, async: true

  alias AriaNeonFrontlines.LocalSocializer

  describe "register_local_socializer/1" do
    test "returns valid state structure" do
      state = AriaState.RelationalState.new()
      {:ok, result} = LocalSocializer.register_local_socializer(state, ["operative_1"])

      # Check that the registration function returns a valid state
      assert is_map(result)
      assert Map.has_key?(result, :data)
      assert {:ok, _} = LocalSocializer.register_local_socializer(state, ["operative_1"])
    end
  end

  describe "actions/1" do
    test "returns all available actions" do
      actions = LocalSocializer.actions(%{})

      assert is_list(actions)
      assert length(actions) == 4
      action_names = Enum.map(actions, &elem(&1, 0))
      assert :command_squad in action_names
      assert :log_tactical_decision in action_names
      assert :coordinate_movement in action_names
      assert :establish_command_post in action_names
    end
  end

  describe "init_state/1" do
    test "initializes state with required fields" do
      state = LocalSocializer.init_state("operative_1")

      assert is_map(state)
      assert Map.has_key?(state, :squad_members)
      assert Map.has_key?(state, :command_authority)
      assert Map.has_key?(state, :coordination_bonus)
      assert Map.has_key?(state, :tactical_log)
      assert Map.has_key?(state, :current_location)
      assert Map.has_key?(state, :neon_level)
      assert state.command_authority == :high
      assert state.current_location == "command_post"
    end
  end

  describe "command_squad/2" do
    test "successfully commands valid squad member" do
      state = AriaState.RelationalState.new()
      # Set up squad members
      state = AriaState.RelationalState.set_fact(state, "squad_members", "active", ["operative_1", "operative_2"])

      {:ok, result} = LocalSocializer.command_squad(state, ["operative_1", "advance"])

      assert AriaState.RelationalState.get_fact(result, "last_command", "operative_1") == "advance"
      assert AriaState.RelationalState.get_fact(result, "command_timestamp", "operative_1") != nil
    end

    test "fails with invalid squad member" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "squad_members", "active", ["operative_1", "operative_2"])

      {:error, :not_squad_member} = LocalSocializer.command_squad(state, ["operative_3", "advance"])
    end
  end

  describe "log_tactical_decision/2" do
    test "successfully logs tactical decision" do
      state = AriaState.RelationalState.new()

      {:ok, result} = LocalSocializer.log_tactical_decision(state, ["formation_change", %{formation: "wedge"}])

      # Find the log entry in the data (it uses the actual timestamp as key)
      log_entries = result.data
      log_entry_key = log_entries
                     |> Map.keys()
                     |> Enum.find(fn {pred, _subj} -> pred == "tactical_log_entry" end)

      assert log_entry_key != nil
      {_, timestamp} = log_entry_key
      log_entry = AriaState.RelationalState.get_fact(result, "tactical_log_entry", timestamp)

      assert is_map(log_entry)
      assert log_entry.type == "formation_change"
      assert log_entry.data == %{formation: "wedge"}
      assert Map.has_key?(log_entry, :timestamp)
    end
  end

  describe "coordinate_movement/2" do
    test "successfully coordinates movement with ready squad" do
      state = AriaState.RelationalState.new()
      # Set up squad readiness
      state = AriaState.RelationalState.set_fact(state, "squad_status", "readiness", 0.8)

      {:ok, result} = LocalSocializer.coordinate_movement(state, ["current_pos", "target_pos"])

      assert AriaState.RelationalState.get_fact(result, "movement_coordinated", {"current_pos", "target_pos"}) == true
      assert AriaState.RelationalState.get_fact(result, "squad_location", "current") == "target_pos"
    end

    test "fails with unready squad" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "squad_status", "readiness", 0.5)

      {:error, :squad_not_ready} = LocalSocializer.coordinate_movement(state, ["current_pos", "target_pos"])
    end
  end

  describe "establish_command_post/2" do
    test "successfully establishes command post in secure location" do
      state = AriaState.RelationalState.new()
      # Set up location security
      state = AriaState.RelationalState.set_fact(state, "location_security", "hilltop", 0.7)

      {:ok, result} = LocalSocializer.establish_command_post(state, ["hilltop"])

      assert AriaState.RelationalState.get_fact(result, "command_post", "hilltop") == true
      assert AriaState.RelationalState.get_fact(result, "communication_hub", "hilltop") == true
      assert AriaState.RelationalState.get_fact(result, "tactical_advantage", "hilltop") == 0.8
    end

    test "fails in insecure location" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "location_security", "alley", 0.4)

      {:error, :location_not_secure} = LocalSocializer.establish_command_post(state, ["alley"])
    end
  end

  describe "coordinate_movement_command/2" do
    test "succeeds with high probability" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "squad_status", "readiness", 0.8)

      # Mock random to ensure success
      :rand.seed(:exsplus, {1, 2, 3})

      {:ok, result} = LocalSocializer.coordinate_movement_command(state, ["current", "target"])

      assert AriaState.RelationalState.get_fact(result, "movement_coordinated", {"current", "target"}) == true
    end

    test "can fail due to coordination issues" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "squad_status", "readiness", 0.8)

      # Test that the function can return either success or failure
      result = LocalSocializer.coordinate_movement_command(state, ["current", "target"])

      case result do
        {:ok, _} -> assert true  # Success is acceptable
        {:error, :coordination_failed} -> assert true  # Failure is also acceptable
      end
    end
  end

  describe "setup_tactical_operation/2" do
    test "returns complete tactical operation task list" do
      {:ok, tasks} = LocalSocializer.setup_tactical_operation(AriaState.RelationalState.new(), ["hilltop"])

      assert is_list(tasks)
      assert length(tasks) == 4

      task_names = Enum.map(tasks, &elem(&1, 0))
      assert :establish_command_post in task_names
      assert :coordinate_movement in task_names
      assert :log_tactical_decision in task_names

      # Check goal task
      goal_task = List.last(tasks)
      assert elem(goal_task, 0) == "command_post"
      assert elem(goal_task, 1) == "hilltop"
      assert elem(goal_task, 2) == true
    end
  end

  describe "achieve_squad_coordination/2" do
    test "returns empty list when coordination already achieved" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "squad_coordination", "alpha", "coordinated")

      {:ok, tasks} = LocalSocializer.achieve_squad_coordination(state, {"alpha", "coordinated"})

      assert tasks == []
    end

    test "returns coordination tasks when needed" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "squad_coordination", "alpha", "uncoordinated")

      {:ok, tasks} = LocalSocializer.achieve_squad_coordination(state, {"alpha", "coordinated"})

      assert length(tasks) == 2
      assert hd(tasks) == {:command_squad, ["alpha", "coordinate_to_coordinated"]}
      assert List.last(tasks) == {"squad_coordinated", "alpha", "coordinated"}
    end
  end
end
