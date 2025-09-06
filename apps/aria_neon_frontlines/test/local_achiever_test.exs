defmodule AriaNeonFrontlines.LocalAchieverTest do
  use ExUnit.Case, async: true

  alias AriaNeonFrontlines.LocalAchiever

  describe "register_local_achiever/1" do
    test "returns valid state structure" do
      state = AriaState.RelationalState.new()
      {:ok, result} = LocalAchiever.register_local_achiever(state, ["operative_1"])

      # Check that the registration function returns a valid state
      assert is_map(result)
      assert Map.has_key?(result, :data)
      assert {:ok, _} = LocalAchiever.register_local_achiever(state, ["operative_1"])
    end
  end

  describe "actions/1" do
    test "returns all available actions" do
      actions = LocalAchiever.actions(%{})

      assert is_list(actions)
      assert length(actions) == 4
      action_names = Enum.map(actions, &elem(&1, 0))
      assert :allocate_resources in action_names
      assert :optimize_supply_chain in action_names
      assert :calculate_efficiency in action_names
      assert :refine_allocation in action_names
    end
  end

  describe "init_state/1" do
    test "initializes state with required fields" do
      state = LocalAchiever.init_state("operative_1")

      assert is_map(state)
      assert Map.has_key?(state, :resource_allocation)
      assert Map.has_key?(state, :optimization_score)
      assert Map.has_key?(state, :efficiency_metrics)
      assert Map.has_key?(state, :allocation_history)
      assert Map.has_key?(state, :current_location)
      assert Map.has_key?(state, :neon_level)
      assert state.current_location == "resource_center"
    end
  end

  describe "allocate_resources/2" do
    test "successfully allocates resources within limits" do
      state = AriaState.RelationalState.new()
      # Set up available resources
      state = AriaState.RelationalState.set_fact(state, "available_resources", "total", 100)

      allocation = %{weapons: 30, ammo: 40}
      {:ok, result} = LocalAchiever.allocate_resources(state, [allocation])

      assert AriaState.RelationalState.get_fact(result, "resource_allocation", "current") == allocation
      assert AriaState.RelationalState.get_fact(result, "allocation_timestamp", "current") != nil
    end

    test "fails with insufficient resources" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "available_resources", "total", 50)

      allocation = %{weapons: 30, ammo: 40}
      {:error, :insufficient_resources} = LocalAchiever.allocate_resources(state, [allocation])
    end
  end

  describe "optimize_supply_chain/2" do
    test "optimizes supply chain efficiency" do
      state = AriaState.RelationalState.new()
      # Set up initial efficiency
      state = AriaState.RelationalState.set_fact(state, "supply_chain_efficiency", "logistics", 0.7)

      {:ok, result} = LocalAchiever.optimize_supply_chain(state, ["logistics"])

      efficiency = AriaState.RelationalState.get_fact(result, "supply_chain_efficiency", "logistics")
      assert efficiency > 0.7
      assert efficiency <= 1.0
      assert AriaState.RelationalState.get_fact(result, "optimization_applied", "logistics") == true
    end
  end

  describe "calculate_efficiency/2" do
    test "calculates comprehensive efficiency metrics" do
      state = AriaState.RelationalState.new()
      # Set up allocation data
      state = AriaState.RelationalState.set_fact(state, "resource_allocation", "current", %{weapons: 10, ammo: 20})
      state = AriaState.RelationalState.set_fact(state, "allocation_history", "all", [%{weapons: 5}])

      {:ok, result} = LocalAchiever.calculate_efficiency(state, [])

      efficiency_score = AriaState.RelationalState.get_fact(result, "efficiency_score", "current")
      metrics = AriaState.RelationalState.get_fact(result, "efficiency_metrics", "current")

      assert is_float(efficiency_score)
      assert is_map(metrics)
      assert Map.has_key?(metrics, :resource_utilization)
      assert Map.has_key?(metrics, :allocation_effectiveness)
      assert Map.has_key?(metrics, :overall_efficiency)
    end
  end

  describe "refine_allocation/2" do
    test "refines allocation based on current metrics" do
      state = AriaState.RelationalState.new()
      # Set up metrics
      state = AriaState.RelationalState.set_fact(state, "efficiency_metrics", "current", %{overall_efficiency: 0.6})

      {:ok, result} = LocalAchiever.refine_allocation(state, ["optimization_1"])

      refinement = AriaState.RelationalState.get_fact(result, "allocation_refinement", "optimization_1")
      assert is_float(refinement)
      assert refinement > 0.0
    end
  end

  describe "allocate_resources_command/2" do
    test "succeeds with valid allocation" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "available_resources", "total", 100)

      allocation = %{weapons: 30, ammo: 40}
      {:ok, result} = LocalAchiever.allocate_resources_command(state, [allocation])

      assert AriaState.RelationalState.get_fact(result, "resource_allocation", "current") == allocation
    end

    test "fails with allocation conflicts" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "available_resources", "total", 100)
      # Set up conflicting allocation
      state = AriaState.RelationalState.set_fact(state, "resource_allocation", "current", %{weapons: 80})

      allocation = %{weapons: 30, ammo: 40}
      {:error, {:allocation_conflicts, conflicts}} = LocalAchiever.allocate_resources_command(state, [allocation])

      assert is_list(conflicts)
      assert :weapons in conflicts
    end
  end

  describe "optimize_resource_cycle/2" do
    test "returns complete resource optimization task list" do
      {:ok, tasks} = LocalAchiever.optimize_resource_cycle(AriaState.RelationalState.new(), ["cycle_1"])

      assert is_list(tasks)
      assert length(tasks) == 5

      task_names = Enum.map(tasks, &elem(&1, 0))
      assert :calculate_efficiency in task_names
      assert :allocate_resources in task_names
      assert :optimize_supply_chain in task_names
      assert :refine_allocation in task_names

      # Check goal task
      goal_task = List.last(tasks)
      assert elem(goal_task, 0) == "efficiency_score"
      assert elem(goal_task, 1) == "current"
      assert elem(goal_task, 2) == {:>=, 0.8}
    end
  end

  describe "achieve_efficiency_target/2" do
    test "returns empty list when target already achieved" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "efficiency_score", "current", 0.9)

      {:ok, tasks} = LocalAchiever.achieve_efficiency_target(state, {"optimization", 0.8})

      assert tasks == []
    end

    test "returns optimization tasks when target not met" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "efficiency_score", "current", 0.5)

      {:ok, tasks} = LocalAchiever.achieve_efficiency_target(state, {"optimization", 0.8})

      assert length(tasks) == 3
      task_names = Enum.map(tasks, &elem(&1, 0))
      assert :optimize_supply_chain in task_names
      assert :refine_allocation in task_names

      # Check goal task
      goal_task = List.last(tasks)
      assert goal_task == {"efficiency_score", "current", {:>=, 0.8}}
    end
  end

  describe "calculate_overall_efficiency/1" do
    test "calculates combined utilization and effectiveness" do
      state = AriaState.RelationalState.new()
      # Set up test data
      state = AriaState.RelationalState.set_fact(state, "resource_allocation", "current", %{weapons: 50})
      state = AriaState.RelationalState.set_fact(state, "available_resources", "total", 100)
      state = AriaState.RelationalState.set_fact(state, "allocation_history", "all", [%{weapons: 25}])

      efficiency = LocalAchiever.calculate_overall_efficiency(state)

      assert is_float(efficiency)
      assert efficiency >= 0.0
      assert efficiency <= 1.0
    end
  end

  describe "calculate_resource_utilization/1" do
    test "calculates utilization ratio" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "resource_allocation", "current", %{weapons: 30, ammo: 20})
      state = AriaState.RelationalState.set_fact(state, "available_resources", "total", 100)

      utilization = LocalAchiever.calculate_resource_utilization(state)

      assert utilization == 0.5  # 50/100
    end

    test "handles zero available resources" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "available_resources", "total", 0)

      utilization = LocalAchiever.calculate_resource_utilization(state)

      assert utilization == 0.0
    end
  end

  describe "calculate_allocation_effectiveness/1" do
    test "calculates effectiveness based on history" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "allocation_history", "all", [%{weapons: 10}, %{ammo: 20}, %{supplies: 30}])

      effectiveness = LocalAchiever.calculate_allocation_effectiveness(state)

      assert is_float(effectiveness)
      assert effectiveness >= 0.5  # Base + history bonus
    end
  end

  describe "calculate_chain_efficiency/2" do
    test "returns optimized efficiency when optimization applied" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "optimization_applied", "logistics", true)

      efficiency = LocalAchiever.calculate_chain_efficiency(state, "logistics")

      assert efficiency == 0.84  # Base 0.7 * 1.2 optimization = 0.84
    end

    test "returns base efficiency when no optimization" do
      state = AriaState.RelationalState.new()

      efficiency = LocalAchiever.calculate_chain_efficiency(state, "logistics")

      assert efficiency == 0.7  # Base efficiency
    end
  end

  describe "calculate_refinement_factor/1" do
    test "calculates higher refinement for lower efficiency" do
      metrics = %{overall_efficiency: 0.3}

      factor = LocalAchiever.calculate_refinement_factor(metrics)

      assert factor > 0.5  # Higher refinement needed
    end

    test "calculates lower refinement for higher efficiency" do
      metrics = %{overall_efficiency: 0.8}

      factor = LocalAchiever.calculate_refinement_factor(metrics)

      assert factor < 0.3  # Lower refinement needed
    end
  end

  describe "check_allocation_conflicts/2" do
    test "identifies resource conflicts" do
      state = AriaState.RelationalState.new()
      # Set up existing allocation
      state = AriaState.RelationalState.set_fact(state, "resource_allocation", "current", %{weapons: 80})

      allocation = %{weapons: 30, ammo: 10}
      conflicts = LocalAchiever.check_allocation_conflicts(state, allocation)

      assert [:weapons] == conflicts
    end

    test "returns empty list for no conflicts" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "resource_allocation", "current", %{weapons: 30})

      allocation = %{ammo: 40, supplies: 20}
      conflicts = LocalAchiever.check_allocation_conflicts(state, allocation)

      assert [] == conflicts
    end
  end
end
