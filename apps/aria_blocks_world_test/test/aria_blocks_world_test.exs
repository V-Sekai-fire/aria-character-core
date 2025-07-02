# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorldTestTest do
  use ExUnit.Case
  doctest AriaBlocksWorldTest

  alias AriaBlocksWorldTest.{Domain, State, Examples}

  describe "domain creation" do
    test "creates domain with correct configuration" do
      domain = Domain.create()

      assert domain != nil
      assert is_map(domain)
    end

    test "domain info returns expected structure" do
      info = Domain.info()

      assert info.name == "Blocks World Domain"
      assert :pickup in info.actions
      assert :unstack in info.actions
      assert :putdown in info.actions
      assert :stack in info.actions
      assert "pos" in info.predicates
      assert "clear" in info.predicates
      assert "holding" in info.predicates
    end
  end

  describe "state creation and manipulation" do
    test "creates state from data" do
      state = State.create(%{
        pos: %{"a" => "table", "b" => "table"},
        clear: %{"a" => true, "b" => true},
        holding: %{"hand" => false}
      })

      assert state != nil

      # Verify facts are set correctly
      assert AriaState.RelationalState.get_fact(state, "pos", "a") == "table"
      assert AriaState.RelationalState.get_fact(state, "pos", "b") == "table"
      assert AriaState.RelationalState.get_fact(state, "clear", "a") == true
      assert AriaState.RelationalState.get_fact(state, "clear", "b") == true
      assert AriaState.RelationalState.get_fact(state, "holding", "hand") == false
    end

    test "creates multigoal from goal data" do
      goal = State.create_multigoal(%{
        pos: %{"a" => "b", "b" => "table"}
      })

      assert {:multigoal, _} = goal
    end
  end

  describe "basic actions" do
    setup do
      state = State.create(%{
        pos: %{"a" => "table", "b" => "table"},
        clear: %{"a" => true, "b" => true},
        holding: %{"hand" => false}
      })
      |> setup_entities()

      {:ok, state: state}
    end

    test "pickup action works correctly", %{state: state} do
      {:ok, new_state} = Domain.pickup(state, ["a"])

      assert AriaState.RelationalState.get_fact(new_state, "pos", "a") == "hand"
      assert AriaState.RelationalState.get_fact(new_state, "clear", "a") == false
      assert AriaState.RelationalState.get_fact(new_state, "holding", "hand") == "a"
    end

    test "putdown action works correctly", %{state: state} do
      # First pickup a block
      {:ok, state_with_block} = Domain.pickup(state, ["a"])

      # Then put it down
      {:ok, final_state} = Domain.putdown(state_with_block, ["a"])

      assert AriaState.RelationalState.get_fact(final_state, "pos", "a") == "table"
      assert AriaState.RelationalState.get_fact(final_state, "clear", "a") == true
      assert AriaState.RelationalState.get_fact(final_state, "holding", "hand") == false
    end

    test "stack action works correctly", %{state: state} do
      # First pickup a block
      {:ok, state_with_block} = Domain.pickup(state, ["a"])

      # Then stack it on another block
      {:ok, final_state} = Domain.stack(state_with_block, ["a", "b"])

      assert AriaState.RelationalState.get_fact(final_state, "pos", "a") == "b"
      assert AriaState.RelationalState.get_fact(final_state, "clear", "a") == true
      assert AriaState.RelationalState.get_fact(final_state, "clear", "b") == false
      assert AriaState.RelationalState.get_fact(final_state, "holding", "hand") == false
    end

    test "unstack action works correctly" do
      # Create state with a on b
      state = State.create(%{
        pos: %{"a" => "b", "b" => "table"},
        clear: %{"a" => true, "b" => false},
        holding: %{"hand" => false}
      })
      |> setup_entities()

      {:ok, final_state} = Domain.unstack(state, ["a", "b"])

      assert AriaState.RelationalState.get_fact(final_state, "pos", "a") == "hand"
      assert AriaState.RelationalState.get_fact(final_state, "clear", "a") == false
      assert AriaState.RelationalState.get_fact(final_state, "clear", "b") == true
      assert AriaState.RelationalState.get_fact(final_state, "holding", "hand") == "a"
    end
  end

  describe "task methods" do
    test "move_block decomposes correctly for table to table" do
      state = State.create(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })
      |> setup_entities()

      {:ok, actions} = Domain.move_block(state, ["a", "table"])

      assert actions == [{:pickup, ["a"]}, {:putdown, ["a"]}]
    end

    test "move_block decomposes correctly for table to block" do
      state = State.create(%{
        pos: %{"a" => "table", "b" => "table"},
        clear: %{"a" => true, "b" => true},
        holding: %{"hand" => false}
      })
      |> setup_entities()

      {:ok, actions} = Domain.move_block(state, ["a", "b"])

      assert actions == [{:pickup, ["a"]}, {:stack, ["a", "b"]}]
    end

    test "move_block decomposes correctly for block to table" do
      state = State.create(%{
        pos: %{"a" => "b", "b" => "table"},
        clear: %{"a" => true, "b" => false},
        holding: %{"hand" => false}
      })
      |> setup_entities()

      {:ok, actions} = Domain.move_block(state, ["a", "table"])

      assert actions == [{:unstack, ["a", "b"]}, {:putdown, ["a"]}]
    end
  end

  describe "unigoal methods" do
    test "achieve_position returns empty list when goal already achieved" do
      state = State.create(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })
      |> setup_entities()

      {:ok, actions} = Domain.achieve_position(state, {"a", "table"})

      assert actions == []
    end

    test "achieve_position returns move_block when goal not achieved" do
      state = State.create(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })
      |> setup_entities()

      {:ok, actions} = Domain.achieve_position(state, {"a", "b"})

      assert actions == [{:validate_move, ["a", "b"]}, {:move_block, ["a", "b"]}]
    end

    test "achieve_clear returns empty list when block already clear" do
      state = State.create(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })
      |> setup_entities()

      {:ok, actions} = Domain.achieve_clear(state, {"a", true})

      assert actions == []
    end

    test "achieve_clear returns move_block for blocking block" do
      state = State.create(%{
        pos: %{"a" => "b", "b" => "table"},
        clear: %{"a" => true, "b" => false},
        holding: %{"hand" => false}
      })
      |> setup_entities()

      {:ok, actions} = Domain.achieve_clear(state, {"b", true})

      assert actions == [{:validate_move, ["a", "table"]}, {:move_block, ["a", "table"]}]
    end
  end

  describe "examples" do
    test "lists all available examples" do
      examples = Examples.list_all()

      assert :sussman_anomaly in examples
      assert :simple_pickup in examples
      assert :simple_stack in examples
      assert :complex_multiblock in examples
    end

    test "runs simple pickup example" do
      {:ok, result} = Examples.run(:simple_pickup)

      assert result.name == "Simple Pickup"
      assert result.description == "Basic pickup operation test"
      assert result.goals == [{"pos", "a", "hand"}]
      assert result.initial_state != nil
      assert result.final_state != nil
    end

    test "runs simple stack example" do
      {:ok, result} = Examples.run(:simple_stack)

      assert result.name == "Simple Stack"
      assert result.description == "Basic stacking operation: A on B"
      assert result.goals == [{"pos", "a", "b"}]
      assert result.initial_state != nil
      assert result.final_state != nil
    end

    test "returns error for unknown example" do
      {:error, reason} = Examples.run(:unknown_example)

      assert reason == :unknown_example
    end
  end

  describe "integration with AriaBlocksWorldTest module" do
    test "creates state through main module" do
      state = AriaBlocksWorldTest.create_state(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })

      assert state != nil
    end

    test "creates multigoal through main module" do
      goal = AriaBlocksWorldTest.create_multigoal(%{
        pos: %{"a" => "b"}
      })

      assert goal != nil
    end

    test "gets domain info through main module" do
      info = AriaBlocksWorldTest.domain_info()

      assert info.name == "Blocks World Domain"
      assert is_list(info.actions)
      assert is_list(info.predicates)
    end

    test "lists examples through main module" do
      examples = AriaBlocksWorldTest.list_examples()

      assert is_list(examples)
      assert :sussman_anomaly in examples
    end

    test "runs example through main module" do
      {:ok, result} = AriaBlocksWorldTest.run_example(:simple_pickup)

      assert result.name == "Simple Pickup"
      assert result.initial_state != nil
      assert result.final_state != nil
    end
  end

  # Helper function to setup entities in state
  defp setup_entities(state) do
    state
    |> AriaState.RelationalState.set_fact("type", "hand", "agent")
    |> AriaState.RelationalState.set_fact("capabilities", "hand", [:manipulation])
    |> AriaState.RelationalState.set_fact("status", "hand", "available")
    |> AriaState.RelationalState.set_fact("type", "table", "surface")
    |> AriaState.RelationalState.set_fact("capabilities", "table", [:support])
    |> AriaState.RelationalState.set_fact("status", "table", "available")
  end
end
