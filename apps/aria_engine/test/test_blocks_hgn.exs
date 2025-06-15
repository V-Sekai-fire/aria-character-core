# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BlocksHGNTest do
  @moduledoc """
  Test suite for Blocks World Hierarchical Goal Network (HGN) planning.

  This implements the blocks_hgn example from GTPyhop, which uses only
  goals (no tasks) for blocks world planning using the near-optimal
  algorithm from Gupta & Nau (1992).
  """

  use ExUnit.Case

  import AriaEngine
  alias AriaEngine.{State, Multigoal, TestDomains}

  @moduletag timeout: 120_000

  describe "Blocks HGN domain" do
    test "domain creation and basic functionality" do
      domain = TestDomains.build_blocks_hgn_domain()
      summary = AriaEngine.domain_summary(domain)

      assert summary.name == "blocks_hgn"
      assert :pickup in summary.actions
      assert :putdown in summary.actions
      assert :stack in summary.actions
      assert :unstack in summary.actions
    end

    test "simple failing cases" do
      domain = TestDomains.build_blocks_hgn_domain()

      state1 = create_state()
      |> set_fact("pos", "a", "b")
      |> set_fact("pos", "b", "table")
      |> set_fact("pos", "c", "table")
      |> set_fact("clear", "c", true)
      |> set_fact("clear", "b", false)
      |> set_fact("clear", "a", true)
      |> set_fact("holding", "hand", false)

      # Should fail - can't pickup 'a' because it's on 'b'
      assert {:error, _} = plan(domain, state1, [{"pickup", "a"}])

      # Should fail - can't achieve pos(b, hand) because b is not clear
      assert {:error, _} = plan(domain, state1, [{"pos", "b", "hand"}])
    end

    test "simple succeeding cases" do
      domain = TestDomains.build_blocks_hgn_domain()

      state1 = create_state()
      |> set_fact("pos", "a", "b")
      |> set_fact("pos", "b", "table")
      |> set_fact("pos", "c", "table")
      |> set_fact("clear", "c", true)
      |> set_fact("clear", "b", false)
      |> set_fact("clear", "a", true)
      |> set_fact("holding", "hand", false)

      # Should succeed - can pickup 'c'
      {:ok, plan} = plan(domain, state1, [{"pickup", "c"}])
      assert plan == [{"pickup", "c"}]

      # Should succeed - can unstack 'a' from 'b'
      {:ok, plan} = plan(domain, state1, [{"unstack", "a", "b"}])
      assert plan == [{"unstack", "a", "b"}]

      # pos(a, b) is already true, so empty plan
      {:ok, plan} = plan(domain, state1, [{"pos", "a", "b"}])
      assert plan == []

      # pos(a, hand) requires unstacking a from b
      {:ok, plan} = plan(domain, state1, [{"pos", "a", "hand"}])
      assert plan == [{"unstack", "a", "b"}]

      # pos(c, hand) requires picking up c from table
      {:ok, plan} = plan(domain, state1, [{"pos", "c", "hand"}])
      assert plan == [{"pickup", "c"}]

      # pos(c, a) requires picking up c then stacking on a
      {:ok, plan} = plan(domain, state1, [{"pos", "c", "a"}])
      assert plan == [{"pickup", "c"}, {"stack", "c", "a"}]
    end

    test "multigoal planning - tower c on b on a" do
      domain = TestDomains.build_blocks_hgn_domain()

      state1 = create_state()
      |> set_fact("pos", "a", "b")
      |> set_fact("pos", "b", "table")
      |> set_fact("pos", "c", "table")
      |> set_fact("clear", "c", true)
      |> set_fact("clear", "b", false)
      |> set_fact("clear", "a", true)
      |> set_fact("holding", "hand", false)

      # Goal: c on b, b on a, a on table
      goal1a = %Multigoal{
        name: "goal1a",
        goals: %{
          "pos" => %{"c" => "b", "b" => "a", "a" => "table"}
        }
      }

      expected = [{"unstack", "a", "b"}, {"putdown", "a"}, {"pickup", "b"},
                  {"stack", "b", "a"}, {"pickup", "c"}, {"stack", "c", "b"}]

      {:ok, plan} = plan(domain, state1, [goal1a])
      assert plan == expected

      # Goal: c on b, b on a (omitting "a on table")
      goal1b = %Multigoal{
        name: "goal1b",
        goals: %{
          "pos" => %{"c" => "b", "b" => "a"}
        }
      }

      # Should produce same plan
      {:ok, plan} = plan(domain, state1, [goal1b])
      assert plan == expected
    end

    test "sussman anomaly" do
      domain = TestDomains.build_blocks_hgn_domain()

      sus_s0 = create_state()
      |> set_fact("pos", "a", "table")
      |> set_fact("pos", "b", "table")
      |> set_fact("pos", "c", "a")
      |> set_fact("clear", "a", false)
      |> set_fact("clear", "b", true)
      |> set_fact("clear", "c", true)
      |> set_fact("holding", "hand", false)

      sus_sg = %Multigoal{
        name: "sussman_goal",
        goals: %{
          "pos" => %{"a" => "b", "b" => "c"}
        }
      }

      expected = [{"unstack", "c", "a"}, {"putdown", "c"}, {"pickup", "b"},
                  {"stack", "b", "c"}, {"pickup", "a"}, {"stack", "a", "b"}]

      {:ok, plan} = plan(domain, sus_s0, [sus_sg])
      assert plan == expected
    end

    test "complex state manipulation" do
      domain = TestDomains.build_blocks_hgn_domain()

      state2 = create_state()
      |> set_fact("pos", "a", "c")
      |> set_fact("pos", "b", "d")
      |> set_fact("pos", "c", "table")
      |> set_fact("pos", "d", "table")
      |> set_fact("clear", "a", true)
      |> set_fact("clear", "c", false)
      |> set_fact("clear", "b", true)
      |> set_fact("clear", "d", false)
      |> set_fact("holding", "hand", false)

      goal2a = %Multigoal{
        name: "goal2a",
        goals: %{
          "pos" => %{"b" => "c", "a" => "d", "c" => "table", "d" => "table"},
          "clear" => %{"a" => true, "c" => false, "b" => true, "d" => false},
          "holding" => %{"hand" => false}
        }
      }

      goal2b = %Multigoal{
        name: "goal2b",
        goals: %{
          "pos" => %{"b" => "c", "a" => "d"}
        }
      }

      expected = [{"unstack", "a", "c"}, {"putdown", "a"}, {"unstack", "b", "d"},
                  {"stack", "b", "c"}, {"pickup", "a"}, {"stack", "a", "d"}]

      # Both should produce same plan
      {:ok, plan1} = plan(domain, state2, [goal2a])
      {:ok, plan2} = plan(domain, state2, [goal2b])

      assert plan1 == expected
      assert plan2 == expected
    end

    test "larger planning problem" do
      domain = build_blocks_hgn_domain()

      # Problem bw_large_d from SHOP distribution
      state3 = create_state()

      # Set up initial positions
      initial_pos = %{
        1 => 12, 12 => 13, 13 => "table",
        11 => 10, 10 => 5, 5 => 4, 4 => 14, 14 => 15, 15 => "table",
        9 => 8, 8 => 7, 7 => 6, 6 => "table",
        19 => 18, 18 => 17, 17 => 16, 16 => 3, 3 => 2, 2 => "table"
      }

      state3 = Enum.reduce(initial_pos, state3, fn {block, pos}, acc ->
        set_fact(acc, "pos", to_string(block), to_string(pos))
      end)

      # Set clear status (only top blocks are clear)
      clear_blocks = [1, 11, 9, 19]
      state3 = Enum.reduce(1..19, state3, fn block, acc ->
        is_clear = block in clear_blocks
        set_fact(acc, "clear", to_string(block), is_clear)
      end)

      state3 = set_fact(state3, "holding", "hand", false)

      goal3 = %Multigoal{
        name: "goal3",
        goals: %{
          "pos" => %{
            "15" => "13", "13" => "8", "8" => "9", "9" => "4",
            "4" => "12", "12" => "2", "2" => "3", "3" => "16",
            "16" => "11", "11" => "7", "7" => "6", "6" => "table"
          }
        }
      }

      # This should find a solution (may be long due to complexity)
      {:ok, plan} = plan(domain, state3, [goal3])
      assert is_list(plan)
      assert length(plan) > 0
    end
  end

  # Helper function to build the blocks HGN domain
  defp build_blocks_hgn_domain do
    domain = create_domain("blocks_hgn")

    # Add actions
    domain
    |> add_action(:pickup, &blocks_pickup/2)
    |> add_action(:putdown, &blocks_putdown/2)
    |> add_action(:stack, &blocks_stack/2)
    |> add_action(:unstack, &blocks_unstack/2)

    # Add unigoal methods for position goals
    |> add_unigoal_method("pos", &pos_take_method/2)
    |> add_unigoal_method("pos", &pos_put_method/2)
  end

  # Action implementations (same as blocks GTN)
  defp blocks_pickup(state, block) do
    pos = get_fact(state, "pos", block)
    clear = get_fact(state, "clear", block)
    holding = get_fact(state, "holding", "hand")

    if pos == "table" and clear == true and holding == false do
      state
      |> set_fact("pos", block, "hand")
      |> set_fact("clear", block, false)
      |> set_fact("holding", "hand", block)
    else
      nil
    end
  end

  defp blocks_putdown(state, block) do
    pos = get_fact(state, "pos", block)

    if pos == "hand" do
      state
      |> set_fact("pos", block, "table")
      |> set_fact("clear", block, true)
      |> set_fact("holding", "hand", false)
    else
      nil
    end
  end

  defp blocks_stack(state, block1, block2) do
    pos1 = get_fact(state, "pos", block1)
    clear2 = get_fact(state, "clear", block2)

    if pos1 == "hand" and clear2 == true do
      state
      |> set_fact("pos", block1, block2)
      |> set_fact("clear", block1, true)
      |> set_fact("holding", "hand", false)
      |> set_fact("clear", block2, false)
    else
      nil
    end
  end

  defp blocks_unstack(state, block1, block2) do
    pos1 = get_fact(state, "pos", block1)
    clear1 = get_fact(state, "clear", block1)
    holding = get_fact(state, "holding", "hand")

    if pos1 == block2 and block2 != "table" and clear1 == true and holding == false do
      state
      |> set_fact("pos", block1, "hand")
      |> set_fact("clear", block1, false)
      |> set_fact("holding", "hand", block1)
      |> set_fact("clear", block2, true)
    else
      nil
    end
  end

  # Unigoal method implementations for position goals
  defp pos_take_method(state, [block, dest]) do
    current_pos = get_fact(state, "pos", block)

    cond do
      current_pos == dest ->
        # Already at destination
        []
      dest == "hand" ->
        # Need to pick up or unstack the block
        if current_pos == "table" do
          [{"pickup", block}]
        else
          [{"unstack", block, current_pos}]
        end
      true ->
        # Need to pick up first, then put at destination
        if current_pos == "table" do
          [{"pos", block, "hand"}, {"pos", block, dest}]
        else
          [{"pos", block, "hand"}, {"pos", block, dest}]
        end
    end
  end

  defp pos_put_method(state, [block, dest]) do
    current_pos = get_fact(state, "pos", block)

    cond do
      current_pos == dest ->
        # Already at destination
        []
      current_pos == "hand" ->
        # Block is in hand, put it at destination
        if dest == "table" do
          [{"putdown", block}]
        else
          [{"stack", block, dest}]
        end
      true ->
        # Not applicable - block not in hand
        nil
    end
  end
end
