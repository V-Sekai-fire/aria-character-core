defmodule AriaNeonFrontlines.BlockCompetitorTest do
  use ExUnit.Case, async: true

  alias AriaNeonFrontlines.BlockCompetitor

  describe "register_block_competitor/1" do
    test "returns valid state structure" do
      state = AriaState.RelationalState.new()
      {:ok, result} = BlockCompetitor.register_block_competitor(state, ["operative_1"])

      # Check that the registration function returns a valid state
      assert is_map(result)
      assert Map.has_key?(result, :data)
      assert {:ok, _} = BlockCompetitor.register_block_competitor(state, ["operative_1"])
    end
  end

  describe "actions/1" do
    test "returns all available actions" do
      actions = BlockCompetitor.actions(%{})

      assert is_list(actions)
      assert length(actions) == 4
      action_names = Enum.map(actions, &elem(&1, 0))
      assert :coordinate_firefight in action_names
      assert :gain_tactical_advantage in action_names
      assert :disrupt_enemy_supplies in action_names
      assert :secure_position in action_names
    end
  end

  describe "init_state/1" do
    test "initializes state with required fields" do
      state = BlockCompetitor.init_state("operative_1")

      assert is_map(state)
      assert Map.has_key?(state, :combat_readiness)
      assert Map.has_key?(state, :tactical_advantage)
      assert Map.has_key?(state, :firefight_coordination)
      assert Map.has_key?(state, :enemy_positions)
      assert Map.has_key?(state, :current_location)
      assert Map.has_key?(state, :neon_level)
      assert state.combat_readiness == 0.9
      assert state.current_location == "combat_post"
    end
  end

  describe "coordinate_firefight/2" do
    test "successfully coordinates firefight with sufficient readiness" do
      state = AriaState.RelationalState.new()
      # Set up combat readiness
      state = AriaState.RelationalState.set_fact(state, "combat_readiness", "current", 0.8)

      {:ok, result} = BlockCompetitor.coordinate_firefight(state, ["firefight_1"])

      coordination = AriaState.RelationalState.get_fact(result, "firefight_coordination", "firefight_1")
      assert is_map(coordination)
      assert coordination.firefight_id == "firefight_1"
      assert Map.has_key?(coordination, :timestamp)
      assert coordination.readiness == 0.8
    end

    test "fails with insufficient combat readiness" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "combat_readiness", "current", 0.5)

      {:error, :combat_readiness_insufficient} = BlockCompetitor.coordinate_firefight(state, ["firefight_1"])
    end
  end

  describe "gain_tactical_advantage/2" do
    test "successfully gains advantage in favorable position" do
      state = AriaState.RelationalState.new()
      # Set up favorable conditions
      state = AriaState.RelationalState.set_fact(state, "enemy_nearby", "hilltop", false)
      state = AriaState.RelationalState.set_fact(state, "cover_available", "hilltop", true)
      state = AriaState.RelationalState.set_fact(state, "high_ground", "hilltop", true)

      {:ok, result} = BlockCompetitor.gain_tactical_advantage(state, ["hilltop"])

      advantage = AriaState.RelationalState.get_fact(result, "tactical_advantage", "hilltop")
      assert is_float(advantage)
      assert advantage > 0.5
      assert AriaState.RelationalState.get_fact(result, "position_secured", "hilltop") == true
    end

    test "fails in disadvantageous position" do
      state = AriaState.RelationalState.new()
      # Set up unfavorable conditions
      state = AriaState.RelationalState.set_fact(state, "enemy_nearby", "alley", true)
      state = AriaState.RelationalState.set_fact(state, "cover_available", "alley", false)
      state = AriaState.RelationalState.set_fact(state, "high_ground", "alley", false)

      {:error, :position_not_advantageous} = BlockCompetitor.gain_tactical_advantage(state, ["alley"])
    end
  end

  describe "disrupt_enemy_supplies/2" do
    test "successfully disrupts active supply line" do
      state = AriaState.RelationalState.new()
      # Set up active supply line
      state = AriaState.RelationalState.set_fact(state, "enemy_supply_line", "supply_route_1", true)

      # Mock random for success
      :rand.seed(:exsplus, {1, 2, 3})

      {:ok, result} = BlockCompetitor.disrupt_enemy_supplies(state, ["supply_route_1"])

      assert AriaState.RelationalState.get_fact(result, "supply_line_disrupted", "supply_route_1") == true
      assert AriaState.RelationalState.get_fact(result, "disruption_timestamp", "supply_route_1") != nil
    end

    test "fails with non-existent supply line" do
      state = AriaState.RelationalState.new()

      {:error, :supply_line_not_found} = BlockCompetitor.disrupt_enemy_supplies(state, ["nonexistent"])
    end

    test "can fail due to interception" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "enemy_supply_line", "supply_route_1", true)

      # Test that the function can return either success or failure
      result = BlockCompetitor.disrupt_enemy_supplies(state, ["supply_route_1"])

      case result do
        {:ok, _} -> assert true  # Success is acceptable
        {:error, :disruption_failed} -> assert true  # Failure is also acceptable
      end
    end
  end

  describe "secure_position/2" do
    test "successfully secures position with sufficient security" do
      state = AriaState.RelationalState.new()
      # Set up secure position
      state = AriaState.RelationalState.set_fact(state, "position_controlled", "bunker", false)
      state = AriaState.RelationalState.set_fact(state, "reinforcements_available", "bunker", true)
      state = AriaState.RelationalState.set_fact(state, "defensive_position", "bunker", true)

      {:ok, result} = BlockCompetitor.secure_position(state, ["bunker"])

      assert AriaState.RelationalState.get_fact(result, "position_controlled", "bunker") == true
      security = AriaState.RelationalState.get_fact(result, "position_security", "bunker")
      assert is_float(security)
      assert security >= 0.6
    end

    test "fails in insecure position" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "position_controlled", "alley", false)
      state = AriaState.RelationalState.set_fact(state, "reinforcements_available", "alley", false)
      state = AriaState.RelationalState.set_fact(state, "defensive_position", "alley", false)

      {:error, :position_not_secure} = BlockCompetitor.secure_position(state, ["alley"])
    end

    test "fails if position already controlled" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "position_controlled", "bunker", true)

      {:error, :position_already_controlled} = BlockCompetitor.secure_position(state, ["bunker"])
    end
  end

  describe "coordinate_firefight_command/2" do
    test "succeeds with acceptable risk level" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "combat_readiness", "current", 0.8)
      # Set up low risk conditions
      state = AriaState.RelationalState.set_fact(state, "enemy_strength", "firefight_1", 0.3)
      state = AriaState.RelationalState.set_fact(state, "friendly_support", "firefight_1", 0.9)

      {:ok, result} = BlockCompetitor.coordinate_firefight_command(state, ["firefight_1"])

      coordination = AriaState.RelationalState.get_fact(result, "firefight_coordination", "firefight_1")
      assert is_map(coordination)
    end

    test "fails with high risk level" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "combat_readiness", "current", 0.8)
      # Set up high risk conditions
      state = AriaState.RelationalState.set_fact(state, "enemy_strength", "firefight_1", 0.9)
      state = AriaState.RelationalState.set_fact(state, "friendly_support", "firefight_1", 0.2)

      {:error, {:risk_too_high, risk_level}} = BlockCompetitor.coordinate_firefight_command(state, ["firefight_1"])

      assert is_float(risk_level)
      assert risk_level > 0.7
    end
  end

  describe "execute_tactical_operation/2" do
    test "returns complete tactical operation task list" do
      {:ok, tasks} = BlockCompetitor.execute_tactical_operation(AriaState.RelationalState.new(), ["operation_1"])

      assert is_list(tasks)
      assert length(tasks) == 5

      task_names = Enum.map(tasks, &elem(&1, 0))
      assert :secure_position in task_names
      assert :gain_tactical_advantage in task_names
      assert :coordinate_firefight in task_names
      assert :disrupt_enemy_supplies in task_names

      # Check goal task
      goal_task = List.last(tasks)
      assert elem(goal_task, 0) == "position_controlled"
      assert elem(goal_task, 1) == "operation_1"
      assert elem(goal_task, 2) == true
    end
  end

  describe "achieve_tactical_control/2" do
    test "returns empty list when control already achieved" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "position_controlled", "bunker", true)

      {:ok, tasks} = BlockCompetitor.achieve_tactical_control(state, {"bunker", true})

      assert tasks == []
    end

    test "returns control tasks when needed" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "position_controlled", "bunker", false)

      {:ok, tasks} = BlockCompetitor.achieve_tactical_control(state, {"bunker", true})

      assert length(tasks) == 3
      task_names = Enum.map(tasks, &elem(&1, 0))
      assert :secure_position in task_names
      assert :gain_tactical_advantage in task_names

      # Check goal task
      goal_task = List.last(tasks)
      assert goal_task == {"position_controlled", "bunker", true}
    end
  end

  describe "calculate_tactical_advantage/2" do
    test "calculates advantage with favorable conditions" do
      state = AriaState.RelationalState.new()
      # Set up favorable conditions
      state = AriaState.RelationalState.set_fact(state, "enemy_nearby", "hilltop", false)
      state = AriaState.RelationalState.set_fact(state, "cover_available", "hilltop", true)
      state = AriaState.RelationalState.set_fact(state, "high_ground", "hilltop", true)
      state = AriaState.RelationalState.set_fact(state, "neon_level", "hilltop", 0.8)

      advantage = BlockCompetitor.calculate_tactical_advantage(state, "hilltop")

      assert is_float(advantage)
      assert advantage > 0.5  # Base + bonuses
      assert advantage <= 1.0
    end

    test "calculates disadvantage with unfavorable conditions" do
      state = AriaState.RelationalState.new()
      # Set up unfavorable conditions
      state = AriaState.RelationalState.set_fact(state, "enemy_nearby", "alley", true)
      state = AriaState.RelationalState.set_fact(state, "cover_available", "alley", false)
      state = AriaState.RelationalState.set_fact(state, "high_ground", "alley", false)

      advantage = BlockCompetitor.calculate_tactical_advantage(state, "alley")

      assert is_float(advantage)
      assert advantage < 0.5  # Base - penalties
    end
  end

  describe "calculate_position_security/2" do
    test "calculates security with defensive advantages" do
      state = AriaState.RelationalState.new()
      # Set up secure conditions
      state = AriaState.RelationalState.set_fact(state, "reinforcements_available", "bunker", true)
      state = AriaState.RelationalState.set_fact(state, "enemy_pressure", "bunker", 0.2)
      state = AriaState.RelationalState.set_fact(state, "defensive_position", "bunker", true)

      security = BlockCompetitor.calculate_position_security(state, "bunker")

      assert is_float(security)
      assert security > 0.5  # Base + bonuses
      assert security <= 1.0
    end

    test "calculates insecurity with threats" do
      state = AriaState.RelationalState.new()
      # Set up insecure conditions
      state = AriaState.RelationalState.set_fact(state, "reinforcements_available", "alley", false)
      state = AriaState.RelationalState.set_fact(state, "enemy_pressure", "alley", 0.8)
      state = AriaState.RelationalState.set_fact(state, "defensive_position", "alley", false)

      security = BlockCompetitor.calculate_position_security(state, "alley")

      assert is_float(security)
      assert security < 0.5  # Base - penalties
    end
  end

  describe "assess_firefight_risk/2" do
    test "calculates low risk with favorable conditions" do
      state = AriaState.RelationalState.new()
      # Set up low risk conditions
      state = AriaState.RelationalState.set_fact(state, "enemy_strength", "firefight_1", 0.3)
      state = AriaState.RelationalState.set_fact(state, "friendly_support", "firefight_1", 0.9)
      state = AriaState.RelationalState.set_fact(state, "terrain_advantage", "firefight_1", 0.8)

      risk = BlockCompetitor.assess_firefight_risk(state, "firefight_1")

      assert is_float(risk)
      assert risk < 0.5  # Low risk
    end

    test "calculates high risk with unfavorable conditions" do
      state = AriaState.RelationalState.new()
      # Set up high risk conditions
      state = AriaState.RelationalState.set_fact(state, "enemy_strength", "firefight_1", 0.9)
      state = AriaState.RelationalState.set_fact(state, "friendly_support", "firefight_1", 0.2)
      state = AriaState.RelationalState.set_fact(state, "terrain_advantage", "firefight_1", 0.3)

      risk = BlockCompetitor.assess_firefight_risk(state, "firefight_1")

      assert is_float(risk)
      assert risk > 0.7  # High risk
    end
  end
end
