# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule BlocksGoalSplittingTest do
  @moduledoc "Test suite for Blocks World Goal Splitting planning.\n\nThis implements the blocks_goal_splitting example from GTPyhop, which\ndemonstrates how to achieve blocks-world multigoals using GTPyhop's\nbuilt-in goal splitting method that separates multigoals into unigoals\nand tries to achieve them sequentially.\n\nNote: This approach usually won't produce optimal plans due to\ndeleted-condition interactions, but will eventually find solutions.\n"
  use ExUnit.Case
  import AriaEngine
  alias {State, Multigoal, TestDomains}
  @moduletag timeout: 120_000
  describe("Blocks Goal Splitting domain") do
    test "domain creation and basic functionality" do
      domain = TestDomains.build_blocks_goal_splitting_domain()
      summary = domain_summary(domain)
      assert summary.name == "blocks_goal_splitting"
      assert :pickup in summary.actions
      assert :putdown in summary.actions
      assert :stack in summary.actions
      assert :unstack in summary.actions
    end

    test "multigoal splitting - tower c on b on a" do
      domain = TestDomains.build_blocks_goal_splitting_domain()

      state1 =
        create_state()
        |> set_fact("pos", "a", "b")
        |> set_fact("pos", "b", "table")
        |> set_fact("pos", "c", "table")
        |> set_fact("clear", "c", true)
        |> set_fact("clear", "b", false)
        |> set_fact("clear", "a", true)
        |> set_fact("holding", "hand", false)

      goal1a = %Multigoal{
        name: "goal1a",
        goals: %{"pos" => %{"c" => "b", "b" => "a", "a" => "table"}}
      }

      expected = [
        {"unstack", "a", "b"},
        {"putdown", "a"},
        {"pickup", "c"},
        {"stack", "c", "b"},
        {"unstack", "c", "b"},
        {"putdown", "c"},
        {"pickup", "b"},
        {"stack", "b", "a"},
        {"pickup", "c"},
        {"stack", "c", "b"}
      ]

      {:ok, plan} = plan(domain, state1, [goal1a])
      assert plan == expected
      goal1b = %Multigoal{name: "goal1b", goals: %{"pos" => %{"c" => "b", "b" => "a"}}}
      {:ok, plan} = plan(domain, state1, [goal1b])
      assert plan == expected
    end

    test "complex goal splitting example" do
      domain = TestDomains.build_blocks_goal_splitting_domain()

      state2 =
        create_state()
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

      goal2b = %Multigoal{name: "goal2b", goals: %{"pos" => %{"b" => "c", "a" => "d"}}}

      expected = [
        {"unstack", "a", "c"},
        {"putdown", "a"},
        {"unstack", "b", "d"},
        {"stack", "b", "c"},
        {"pickup", "a"},
        {"stack", "a", "d"}
      ]

      {:ok, plan1} = plan(domain, state2, [goal2a])
      {:ok, plan2} = plan(domain, state2, [goal2b])
      assert plan1 == expected
      assert plan2 == expected
    end

    test "large problem with goal splitting" do
      domain = TestDomains.build_blocks_goal_splitting_domain()
      state3 = create_state()

      initial_pos = %{
        1 => 12,
        12 => 13,
        13 => "table",
        11 => 10,
        10 => 5,
        5 => 4,
        4 => 14,
        14 => 15,
        15 => "table",
        9 => 8,
        8 => 7,
        7 => 6,
        6 => "table",
        19 => 18,
        18 => 17,
        17 => 16,
        16 => 3,
        3 => 2,
        2 => "table"
      }

      state3 =
        Enum.reduce(initial_pos, state3, fn {block, pos}, acc ->
          set_fact(acc, "pos", to_string(block), to_string(pos))
        end)

      clear_blocks = [1, 11, 9, 19]

      state3 =
        Enum.reduce(1..19, state3, fn block, acc ->
          is_clear = block in clear_blocks
          set_fact(acc, "clear", to_string(block), is_clear)
        end)

      state3 = set_fact(state3, "holding", "hand", false)

      goal3 = %Multigoal{
        name: "goal3",
        goals: %{
          "pos" => %{
            "15" => "13",
            "13" => "8",
            "8" => "9",
            "9" => "4",
            "4" => "12",
            "12" => "2",
            "2" => "3",
            "3" => "16",
            "16" => "11",
            "11" => "7",
            "7" => "6",
            "6" => "table"
          }
        }
      }

      {:ok, plan} = plan(domain, state3, [goal3])
      assert is_list(plan)
      assert length(plan) > 0
    end
  end
end