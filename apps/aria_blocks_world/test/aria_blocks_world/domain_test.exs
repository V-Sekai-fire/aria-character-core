# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.DomainTest do
  use ExUnit.Case, async: true
  doctest AriaBlocksWorld.Domain

  alias AriaBlocksWorld.Domain
  alias AriaState.RelationalState

  describe "basic domain functionality" do
    test "creates domain successfully" do
      domain = Domain.create()
      assert is_struct(domain)
      assert domain.name == :blocks_world
    end

    test "provides domain info" do
      info = Domain.info()
      assert info.name == "Blocks World Domain"
      assert :pickup in info.actions
      assert :unstack in info.actions
      assert :putdown in info.actions
      assert :stack in info.actions
    end
  end

  describe "basic actions" do
    setup do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "b")
      |> RelationalState.set_fact("pos", "b", "table")
      |> RelationalState.set_fact("pos", "c", "table")
      |> RelationalState.set_fact("clear", "a", true)
      |> RelationalState.set_fact("clear", "b", false)
      |> RelationalState.set_fact("clear", "c", true)
      |> RelationalState.set_fact("holding", "hand", false)

      {:ok, state: state}
    end

    test "pickup action works correctly", %{state: state} do
      {:ok, new_state} = Domain.pickup(state, ["c"])

      assert RelationalState.get_fact(new_state, "pos", "c") == "hand"
      assert RelationalState.get_fact(new_state, "clear", "c") == false
      assert RelationalState.get_fact(new_state, "holding", "hand") == "c"
    end

    test "unstack action works correctly", %{state: state} do
      {:ok, new_state} = Domain.unstack(state, ["a", "b"])

      assert RelationalState.get_fact(new_state, "pos", "a") == "hand"
      assert RelationalState.get_fact(new_state, "clear", "a") == false
      assert RelationalState.get_fact(new_state, "holding", "hand") == "a"
      assert RelationalState.get_fact(new_state, "clear", "b") == true
    end

    test "putdown action works correctly" do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "hand")
      |> RelationalState.set_fact("clear", "a", false)
      |> RelationalState.set_fact("holding", "hand", "a")

      {:ok, new_state} = Domain.putdown(state, ["a"])

      assert RelationalState.get_fact(new_state, "pos", "a") == "table"
      assert RelationalState.get_fact(new_state, "clear", "a") == true
      assert RelationalState.get_fact(new_state, "holding", "hand") == false
    end

    test "stack action works correctly" do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "hand")
      |> RelationalState.set_fact("clear", "a", false)
      |> RelationalState.set_fact("clear", "b", true)
      |> RelationalState.set_fact("holding", "hand", "a")

      {:ok, new_state} = Domain.stack(state, ["a", "b"])

      assert RelationalState.get_fact(new_state, "pos", "a") == "b"
      assert RelationalState.get_fact(new_state, "clear", "a") == true
      assert RelationalState.get_fact(new_state, "holding", "hand") == false
      assert RelationalState.get_fact(new_state, "clear", "b") == false
    end
  end

  describe "task methods" do
    test "move_block from table to table" do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "table")
      |> RelationalState.set_fact("clear", "a", true)

      {:ok, actions} = Domain.move_block(state, ["a", "table"])

      assert actions == [{:pickup, ["a"]}, {:putdown, ["a"]}]
    end

    test "move_block from block to table" do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "b")

      {:ok, actions} = Domain.move_block(state, ["a", "table"])

      assert actions == [{:unstack, ["a", "b"]}, {:putdown, ["a"]}]
    end

    test "move_block from table to block" do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "table")

      {:ok, actions} = Domain.move_block(state, ["a", "c"])

      assert actions == [{:pickup, ["a"]}, {:stack, ["a", "c"]}]
    end

    test "move_block from block to block" do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "b")

      {:ok, actions} = Domain.move_block(state, ["a", "c"])

      assert actions == [{:unstack, ["a", "b"]}, {:stack, ["a", "c"]}]
    end
  end

  describe "unigoal methods" do
    test "achieve_position when goal already satisfied" do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "table")

      {:ok, actions} = Domain.achieve_position(state, {"a", "table"})

      assert actions == []
    end

    test "achieve_position when goal not satisfied" do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "b")

      {:ok, actions} = Domain.achieve_position(state, {"a", "table"})

      assert actions == [{:validate_move, ["a", "table"]}, {:move_block, ["a", "table"]}]
    end

    test "achieve_clear when block already clear" do
      state = RelationalState.new()
      |> RelationalState.set_fact("clear", "a", true)

      {:ok, actions} = Domain.achieve_clear(state, {"a", true})

      assert actions == []
    end

    test "achieve_clear when block has something on top" do
      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "b", "a")
      |> RelationalState.set_fact("clear", "a", false)
      |> RelationalState.set_fact("clear", "b", true)

      {:ok, actions} = Domain.achieve_clear(state, {"a", true})

      assert actions == [{:validate_move, ["b", "table"]}, {:move_block, ["b", "table"]}]
    end
  end

  describe "GTpyhop test cases" do
    test "simple state1 configuration" do
      # Replicates the state1 from GTpyhop examples
      # pos={'a':'b', 'b':'table', 'c':'table'}
      # clear={'c':True, 'b':False,'a':True}
      # holding={'hand':False}

      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "b")
      |> RelationalState.set_fact("pos", "b", "table")
      |> RelationalState.set_fact("pos", "c", "table")
      |> RelationalState.set_fact("clear", "a", true)
      |> RelationalState.set_fact("clear", "b", false)
      |> RelationalState.set_fact("clear", "c", true)
      |> RelationalState.set_fact("holding", "hand", false)

      # Test pickup 'c' should work
      {:ok, _new_state} = Domain.pickup(state, ["c"])

      # Test take 'a' should work (unstack)
      {:ok, actions} = Domain.achieve_position(state, {"a", "hand"})
      assert actions == [{:validate_move, ["a", "hand"]}, {:move_block, ["a", "hand"]}]

      # Test take 'c' should work (pickup)
      {:ok, actions} = Domain.achieve_position(state, {"c", "hand"})
      assert actions == [{:validate_move, ["c", "hand"]}, {:move_block, ["c", "hand"]}]
    end

    test "Sussman anomaly initial state" do
      # Replicates the Sussman anomaly from GTpyhop examples
      # pos={'c':'a', 'a':'table', 'b':'table'}
      # clear={'c':True, 'a':False,'b':True}
      # holding={'hand':False}

      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "c", "a")
      |> RelationalState.set_fact("pos", "a", "table")
      |> RelationalState.set_fact("pos", "b", "table")
      |> RelationalState.set_fact("clear", "c", true)
      |> RelationalState.set_fact("clear", "a", false)
      |> RelationalState.set_fact("clear", "b", true)
      |> RelationalState.set_fact("holding", "hand", false)

      # Goal: pos={'a':'b', 'b':'c'}
      # This should require moving c off a first, then b onto c, then a onto b

      # Test that we can identify the blocking relationship
      {:ok, actions} = Domain.achieve_clear(state, {"a", true})
      assert actions == [{:validate_move, ["c", "table"]}, {:move_block, ["c", "table"]}]

      # Test basic goal achievement
      {:ok, actions} = Domain.achieve_position(state, {"a", "b"})
      assert actions == [{:validate_move, ["a", "b"]}, {:move_block, ["a", "b"]}]

      {:ok, actions} = Domain.achieve_position(state, {"b", "c"})
      assert actions == [{:validate_move, ["b", "c"]}, {:move_block, ["b", "c"]}]
    end

    test "state2 configuration" do
      # Replicates state2 from GTpyhop examples
      # pos={'a':'c', 'b':'d', 'c':'table', 'd':'table'}
      # clear={'a':True, 'c':False,'b':True, 'd':False}
      # holding={'hand':False}

      state = RelationalState.new()
      |> RelationalState.set_fact("pos", "a", "c")
      |> RelationalState.set_fact("pos", "b", "d")
      |> RelationalState.set_fact("pos", "c", "table")
      |> RelationalState.set_fact("pos", "d", "table")
      |> RelationalState.set_fact("clear", "a", true)
      |> RelationalState.set_fact("clear", "b", true)
      |> RelationalState.set_fact("clear", "c", false)
      |> RelationalState.set_fact("clear", "d", false)
      |> RelationalState.set_fact("holding", "hand", false)

      # Goal: pos={'b':'c', 'a':'d'}
      # This should require unstacking a from c, unstacking b from d,
      # then stacking b on c and a on d

      {:ok, actions} = Domain.achieve_position(state, {"b", "c"})
      assert actions == [{:validate_move, ["b", "c"]}, {:move_block, ["b", "c"]}]

      {:ok, actions} = Domain.achieve_position(state, {"a", "d"})
      assert actions == [{:validate_move, ["a", "d"]}, {:move_block, ["a", "d"]}]
    end
  end

  describe "helper functions" do
    test "get_all_blocks returns all blocks with clear predicates" do
      state = RelationalState.new()
      |> RelationalState.set_fact("clear", "a", true)
      |> RelationalState.set_fact("clear", "b", false)
      |> RelationalState.set_fact("clear", "c", true)
      |> RelationalState.set_fact("pos", "a", "b")  # Block "a" is on top of block "b"
      |> RelationalState.set_fact("pos", "b", "table")
      |> RelationalState.set_fact("pos", "c", "table")

      # This is testing the private function indirectly through achieve_clear
      # Block "b" is not clear because "a" is on top of it
      {:ok, _actions} = Domain.achieve_clear(state, {"b", true})
    end
  end

end
