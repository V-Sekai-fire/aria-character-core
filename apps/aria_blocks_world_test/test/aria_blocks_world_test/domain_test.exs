defmodule AriaBlocksWorldTest.DomainTest do
  use ExUnit.Case
  doctest AriaBlocksWorldTest.Domain

  alias AriaBlocksWorldTest.{Domain, State}

  describe "domain creation" do
    test "creates blocks world domain" do
      domain = Domain.create()
      assert domain != nil
    end

    test "provides domain info" do
      info = Domain.info()
      assert info.name == "Blocks World Domain"
      assert info.description =~ "Classic blocks world planning domain"
      assert :pickup in info.actions
      assert :unstack in info.actions
      assert :putdown in info.actions
      assert :stack in info.actions
      assert :move_block in info.actions
      assert "pos" in info.predicates
      assert "clear" in info.predicates
      assert "holding" in info.predicates
    end
  end

  describe "basic actions" do
    setup do
      state = State.create(%{
        pos: %{"a" => "table", "b" => "table", "c" => "b"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      })
      {:ok, state: state}
    end

    test "pickup action", %{state: state} do
      {:ok, new_state} = Domain.pickup(state, ["a"])

      assert AriaState.RelationalState.get_fact(new_state, "pos", "a") == "hand"
      assert AriaState.RelationalState.get_fact(new_state, "clear", "a") == false
      assert AriaState.RelationalState.get_fact(new_state, "holding", "hand") == "a"
    end

    test "unstack action", %{state: state} do
      {:ok, new_state} = Domain.unstack(state, ["c", "b"])

      assert AriaState.RelationalState.get_fact(new_state, "pos", "c") == "hand"
      assert AriaState.RelationalState.get_fact(new_state, "clear", "c") == false
      assert AriaState.RelationalState.get_fact(new_state, "holding", "hand") == "c"
      assert AriaState.RelationalState.get_fact(new_state, "clear", "b") == true
    end

    test "putdown action" do
      # Create state with block in hand
      state = State.create(%{
        pos: %{"a" => "hand"},
        clear: %{"a" => false},
        holding: %{"hand" => "a"}
      })

      {:ok, new_state} = Domain.putdown(state, ["a"])

      assert AriaState.RelationalState.get_fact(new_state, "pos", "a") == "table"
      assert AriaState.RelationalState.get_fact(new_state, "clear", "a") == true
      assert AriaState.RelationalState.get_fact(new_state, "holding", "hand") == false
    end

    test "stack action" do
      # Create state with block in hand and clear target
      state = State.create(%{
        pos: %{"a" => "hand", "b" => "table"},
        clear: %{"a" => false, "b" => true},
        holding: %{"hand" => "a"}
      })

      {:ok, new_state} = Domain.stack(state, ["a", "b"])

      assert AriaState.RelationalState.get_fact(new_state, "pos", "a") == "b"
      assert AriaState.RelationalState.get_fact(new_state, "clear", "a") == true
      assert AriaState.RelationalState.get_fact(new_state, "holding", "hand") == false
      assert AriaState.RelationalState.get_fact(new_state, "clear", "b") == false
    end
  end

  describe "task methods" do
    test "move_block from table to table" do
      state = State.create(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })

      {:ok, actions} = Domain.move_block(state, ["a", "table"])
      assert actions == [{:pickup, ["a"]}, {:putdown, ["a"]}]
    end

    test "move_block from block to table" do
      state = State.create(%{
        pos: %{"a" => "b", "b" => "table"},
        clear: %{"a" => true, "b" => false},
        holding: %{"hand" => false}
      })

      {:ok, actions} = Domain.move_block(state, ["a", "table"])
      assert actions == [{:unstack, ["a", "b"]}, {:putdown, ["a"]}]
    end

    test "move_block from table to block" do
      state = State.create(%{
        pos: %{"a" => "table", "b" => "table"},
        clear: %{"a" => true, "b" => true},
        holding: %{"hand" => false}
      })

      {:ok, actions} = Domain.move_block(state, ["a", "b"])
      assert actions == [{:pickup, ["a"]}, {:stack, ["a", "b"]}]
    end
  end

  describe "unigoal methods" do
    test "achieve_position when already achieved" do
      state = State.create(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })

      {:ok, actions} = Domain.achieve_position(state, {"a", "table"})
      assert actions == []
    end

    test "achieve_position when not achieved" do
      state = State.create(%{
        pos: %{"a" => "b"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })

      {:ok, actions} = Domain.achieve_position(state, {"a", "table"})
      assert actions == [{:move_block, ["a", "table"]}]
    end

    test "achieve_clear when already clear" do
      state = State.create(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })

      {:ok, actions} = Domain.achieve_clear(state, {"a", true})
      assert actions == []
    end

    test "achieve_clear when blocked" do
      state = State.create(%{
        pos: %{"a" => "table", "b" => "a"},
        clear: %{"a" => false, "b" => true},
        holding: %{"hand" => false}
      })

      {:ok, actions} = Domain.achieve_clear(state, {"a", true})
      assert actions == [{:move_block, ["b", "table"]}]
    end

    test "achieve_clear false" do
      state = State.create(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })

      {:ok, actions} = Domain.achieve_clear(state, {"a", false})
      assert actions == []
    end
  end
end
