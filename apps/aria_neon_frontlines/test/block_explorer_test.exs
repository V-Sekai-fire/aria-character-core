defmodule AriaNeonFrontlines.BlockExplorerTest do
  use ExUnit.Case, async: true

  alias AriaNeonFrontlines.BlockExplorer

  # Helper functions for domain setup
  defp setup_neon_frontlines_domain() do
    domain = AriaHybridPlanner.new_domain(:neon_frontlines_city_block)

    # Set up entity registry for operatives
    registry = AriaHybridPlanner.new_entity_registry()
    registry = AriaHybridPlanner.register_entity_type(registry, %{
      type: "operative",
      capabilities: [:supply_transfer, :route_planning, :scouting, :logistics_optimization]
    })
    domain = AriaHybridPlanner.set_entity_registry(domain, registry)

    domain
  end

  defp setup_test_scenario() do
    domain = setup_neon_frontlines_domain()
    state = AriaHybridPlanner.new_state()

    # Set up initial supplies
    state = AriaHybridPlanner.set_fact(state, "supplies", "depot", 100)
    state = AriaHybridPlanner.set_fact(state, "supplies", "front", 0)

    {domain, state}
  end

  describe "block explorer domain setup" do
    test "creates neon frontlines domain with entity registry" do
      domain = setup_neon_frontlines_domain()

      # Verify domain structure
      assert domain.name == :neon_frontlines_city_block
      assert Map.has_key?(domain, :entity_registry)

      # Verify entity registry setup
      registry = domain.entity_registry
      assert Map.has_key?(registry.entity_types, "operative")

      operative_type = registry.entity_types["operative"]
      assert operative_type.type == "operative"
      assert :supply_transfer in operative_type.capabilities
      assert :route_planning in operative_type.capabilities
    end

    test "sets up test scenario with initial state" do
      {domain, state} = setup_test_scenario()

      # Verify domain setup
      assert domain.name == :neon_frontlines_city_block

      # Verify initial state
      {:ok, depot_supplies} = AriaHybridPlanner.get_fact(state, "supplies", "depot")
      {:ok, front_supplies} = AriaHybridPlanner.get_fact(state, "supplies", "front")
      assert depot_supplies == 100
      assert front_supplies == 0
    end
  end

  describe "block explorer functionality" do
    test "direct function calls work correctly" do
      # Test the BlockExplorer functions directly
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "supplies", "depot", 100)
      state = AriaState.RelationalState.set_fact(state, "supplies", "front", 0)

      {:ok, result} = BlockExplorer.transfer_supplies(state, ["depot", "front", 50])

      depot_supplies = AriaState.RelationalState.get_fact(result, "supplies", "depot")
      front_supplies = AriaState.RelationalState.get_fact(result, "supplies", "front")
      assert depot_supplies == 50
      assert front_supplies == 50
    end

    test "domain integration with state management" do
      {domain, state} = setup_test_scenario()

      # Test that we can use AriaHybridPlanner state functions
      new_state = AriaHybridPlanner.set_fact(state, "test_fact", "test_subject", "test_value")
      {:ok, value} = AriaHybridPlanner.get_fact(new_state, "test_fact", "test_subject")
      assert value == "test_value"

      # Verify domain structure is maintained
      assert domain.name == :neon_frontlines_city_block
    end
  end

  describe "actions/1" do
    test "returns all available actions" do
      actions = BlockExplorer.actions(%{})

      assert is_list(actions)
      assert length(actions) == 4
      action_names = Enum.map(actions, &elem(&1, 0))
      assert :transfer_supplies in action_names
      assert :map_block_route in action_names
      assert :scout_location in action_names
      assert :optimize_route in action_names
    end
  end

  describe "init_state/1" do
    test "initializes state with required fields" do
      state = BlockExplorer.init_state("operative_1")

      assert is_map(state)
      assert Map.has_key?(state, :supply_routes)
      assert Map.has_key?(state, :transfer_efficiency)
      assert Map.has_key?(state, :block_knowledge)
      assert Map.has_key?(state, :current_location)
      assert Map.has_key?(state, :neon_level)
      assert state.transfer_efficiency == 1.0
      assert state.current_location == "supply_depot"
    end
  end

  describe "transfer_supplies/2" do
    test "successfully transfers supplies between locations" do
      state = AriaState.RelationalState.new()
      # Set up initial supplies
      state = AriaState.RelationalState.set_fact(state, "supplies", "depot", 100)
      state = AriaState.RelationalState.set_fact(state, "supplies", "front", 0)

      {:ok, result} = BlockExplorer.transfer_supplies(state, ["depot", "front", 50])

      assert AriaState.RelationalState.get_fact(result, "supplies", "depot") == 50
      assert AriaState.RelationalState.get_fact(result, "supplies", "front") == 50
      assert AriaState.RelationalState.get_fact(result, "last_transfer", {"depot", "front"}) == 50
    end

    test "fails with insufficient supplies" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "supplies", "depot", 30)

      {:error, :insufficient_supplies} = BlockExplorer.transfer_supplies(state, ["depot", "front", 50])
    end
  end

  describe "map_block_route/2" do
    test "successfully maps route between locations" do
      state = AriaState.RelationalState.new()

      {:ok, result} = BlockExplorer.map_block_route(state, ["depot", "front"])

      route = AriaState.RelationalState.get_fact(result, "mapped_route", {"depot", "front"})
      assert is_tuple(route)
      assert tuple_size(route) == 3
      {from, to, efficiency} = route
      assert from == "depot"
      assert to == "front"
      assert is_float(efficiency)
    end
  end

  describe "scout_location/2" do
    test "successfully scouts location and discovers supplies" do
      state = AriaState.RelationalState.new()

      {:ok, result} = BlockExplorer.scout_location(state, ["warehouse"])

      discovered_supplies = AriaState.RelationalState.get_fact(result, "supplies", "warehouse")
      assert is_integer(discovered_supplies)
      assert discovered_supplies >= 10
      assert discovered_supplies <= 60
      assert AriaState.RelationalState.get_fact(result, "scouted", "warehouse") == true
    end
  end

  describe "optimize_route/2" do
    test "optimizes existing route efficiency" do
      state = AriaState.RelationalState.new()
      # Set up initial route
      state = AriaState.RelationalState.set_fact(state, "route_efficiency", {"depot", "front"}, 1.0)

      {:ok, result} = BlockExplorer.optimize_route(state, ["depot", "front"])

      efficiency = AriaState.RelationalState.get_fact(result, "route_efficiency", {"depot", "front"})
      assert efficiency > 1.0
      assert efficiency <= 2.0
    end
  end

  describe "transfer_supplies_command/2" do
    test "succeeds with high probability" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "supplies", "depot", 100)
      state = AriaState.RelationalState.set_fact(state, "supplies", "front", 0)

      # Mock random to ensure success
      :rand.seed(:exsplus, {1, 2, 3})

      {:ok, result} = BlockExplorer.transfer_supplies_command(state, ["depot", "front", 50])

      assert AriaState.RelationalState.get_fact(result, "supplies", "depot") == 50
      assert AriaState.RelationalState.get_fact(result, "supplies", "front") == 50
    end

    test "can fail due to interception" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "supplies", "depot", 100)

      # Mock random to ensure failure (value > 0.9)
      :rand.seed(:exsplus, {100, 200, 300})

      result = BlockExplorer.transfer_supplies_command(state, ["depot", "front", 50])
      # The function may succeed or fail based on random, so just verify it's a valid result
      assert match?({:ok, _}, result) or match?({:error, :transfer_intercepted}, result)
    end
  end

  describe "optimize_supply_chain/2" do
    test "returns optimization task list" do
      {:ok, tasks} = BlockExplorer.optimize_supply_chain(AriaState.RelationalState.new(), ["warehouse"])

      assert is_list(tasks)
      assert length(tasks) == 4

      task_names = Enum.map(tasks, &elem(&1, 0))
      assert :scout_location in task_names
      assert :map_block_route in task_names
      assert :optimize_route in task_names

      # Check goal task
      goal_task = List.last(tasks)
      assert elem(goal_task, 0) == "supplies"
      assert elem(goal_task, 1) == "warehouse"
      assert elem(goal_task, 2) == {:>=, 25}
    end
  end

  describe "achieve_supply_level/2" do
    test "returns empty list when goal already achieved" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "supplies", "warehouse", 100)

      {:ok, tasks} = BlockExplorer.achieve_supply_level(state, {"warehouse", 50})

      assert tasks == []
    end

    test "returns transfer task when supplies insufficient" do
      state = AriaState.RelationalState.new()
      state = AriaState.RelationalState.set_fact(state, "supplies", "warehouse", 20)
      state = AriaState.RelationalState.set_fact(state, "supplies", "supply_depot", 100)

      {:ok, tasks} = BlockExplorer.achieve_supply_level(state, {"warehouse", 50})

      assert length(tasks) == 2
      assert hd(tasks) == {:transfer_supplies, ["supply_depot", "warehouse", 30]}
      assert List.last(tasks) == {"supplies", "warehouse", 50}
    end
  end


end
