# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTemporalBlocks.GtpyhopExamplesTest do
  @moduledoc """
  Test suite that validates AriaTemporalBlocks against the GTpyhop blocks_gtn examples.

  This test suite implements the same test cases found in:
  thirdparty/GTPyhop/Examples/blocks_gtn/examples.py

  These tests ensure our Elixir temporal blocks implementation produces the same results as the
  reference GTpyhop implementation for the blocks world domain with temporal extensions.
  """

  use ExUnit.Case, async: true
  require Logger

  describe "GTpyhop blocks_gtn examples" do
    test "simple pickup operations that should fail" do
      # state1.pos={'a':'b', 'b':'table', 'c':'table'}
      # state1.clear={'c':True, 'b':False,'a':True}
      # state1.holding={'hand':False}
      state1 = AriaState.new(%{
        "a" => %{"pos" => "b", "clear" => true},
        "b" => %{"pos" => "table", "clear" => false},
        "c" => %{"pos" => "table", "clear" => true},
        "hand" => %{"holding" => false}
      })

      domain = AriaTemporalBlocks.Domain.create()
      # These should fail because 'a' is on 'b' (can't pickup something that's not clear)
      # and 'b' has something on it
      result = AriaHybridPlanner.plan(domain, state1, [{:pickup, ["a"]}])
      assert {:error, _} = result
      result = AriaHybridPlanner.plan(domain, state1, [{:pickup, ["b"]}])
      assert {:error, _} = result
      result = AriaHybridPlanner.plan(domain, state1, [{:take, ["b"]}])
      assert {:error, _} = result
    end

    test "simple pickup operations that should succeed" do
      state1 = AriaState.new(%{
        "a" => %{"pos" => "b", "clear" => true},
        "b" => %{"pos" => "table", "clear" => false},
        "c" => %{"pos" => "table", "clear" => true},
        "hand" => %{"holding" => false}
      })
      domain = AriaTemporalBlocks.Domain.create()
      # pickup 'c' should work (it's clear and on table)
      {:ok, result} = AriaHybridPlanner.plan(domain, state1, [{:pickup, ["c"]}])
      todos = AriaEngineCore.Plan.get_primitive_actions_dfs(result.solution_tree)
      assert [pickup: ["c"]] = todos

      # take 'a' should work (unstack from 'b')
      {:ok, result} = AriaHybridPlanner.plan(domain, state1, [{:take, ["a"]}])
      todos = AriaEngineCore.Plan.get_primitive_actions_dfs(result.solution_tree)
      assert [unstack: ["a", "b"]] = todos

      # take 'c' should work (pickup from table)
      {:ok, result} = AriaHybridPlanner.plan(domain, state1, [{:take, ["c"]}])
      todos = AriaEngineCore.Plan.get_primitive_actions_dfs(result.solution_tree)
      assert [pickup: ["c"]] = todos
    end

    test "multigoal: c on b, b on a, a on table" do
      Logger.debug("=== Test: multigoal: c on b, b on a, a on table ===")

      state1 = AriaState.new(%{
        "a" => %{"pos" => "b", "clear" => true},
        "b" => %{"pos" => "table", "clear" => false},
        "c" => %{"pos" => "table", "clear" => true},
        "hand" => %{"holding" => false}
      })

      # Goal: c on b, b on a, a on table
      goal1a = %AriaEngineCore.Multigoal{
        goals: [
          {"pos", "c", "b"},
          {"pos", "a", "table"},
          {"pos", "b", "a"},
        ],
      }

      Logger.debug("Goals: #{inspect(goal1a.goals)}")
      domain = AriaTemporalBlocks.Domain.create()
      {:ok, result} = AriaHybridPlanner.plan(domain, state1, [goal1a], verbose: 3)
      assert [{:unstack, ["a", "b"]}, {:putdown, ["a"]}, {:pickup, ["b"]}, {:stack, ["b", "a"]}, {:pickup, ["c"]}, {:stack, ["c", "b"]}] = AriaEngineCore.Plan.get_primitive_actions_dfs(result.solution_tree)
    end

    test "Sussman anomaly" do
      Logger.debug("=== Test: Sussman anomaly ===")

      # sus_s0.pos={'c':'a', 'a':'table', 'b':'table'}
      # sus_s0.clear={'c':True, 'a':False,'b':True}
      # sus_s0.holding={'hand':False}
      sussman_initial = AriaState.new(%{
        "c" => %{"pos" => "a", "clear" => true},
        "a" => %{"pos" => "table", "clear" => false},
        "b" => %{"pos" => "table", "clear" => true},
        "hand" => %{"holding" => false}
      })

      # Goal: a on b, b on c
      sussman_goal = %AriaEngineCore.Multigoal{
        goals: [
          {"pos", "a", "b"},
          {"pos", "b", "c"}
        ],
      }

      Logger.debug("Goals: #{inspect(sussman_goal.goals)}")

      domain = AriaTemporalBlocks.Domain.create()
      {:ok, result} = AriaHybridPlanner.plan(domain, sussman_initial, [sussman_goal])
      todos = AriaEngineCore.Plan.get_primitive_actions_dfs(result.solution_tree)
      assert [{:unstack, ["c", "a"]}, {:putdown, ["c"]}, {:pickup, ["b"]}, {:stack, ["b", "c"]}, {:pickup, ["a"]}, {:stack, ["a", "b"]}] = todos
    end

    test "complex rearrangement problem" do
      Logger.debug("=== Test: complex rearrangement problem ===")

      # state2.pos={'a':'c', 'b':'d', 'c':'table', 'd':'table'}
      # state2.clear={'a':True, 'c':False,'b':True, 'd':False}
      # state2.holding={'hand':False}
      state2 = AriaState.new(%{
        "a" => %{"pos" => "c", "clear" => true},
        "b" => %{"pos" => "d", "clear" => true},
        "c" => %{"pos" => "table", "clear" => false},
        "d" => %{"pos" => "table", "clear" => false},
        "hand" => %{"holding" => false}
      })

      # Goal: b on c, a on d
      goal2 = %AriaEngineCore.Multigoal{
        goals: [
          {"pos", "b", "c"},
          {"pos", "a", "d"}
        ],
      }

      Logger.debug("Goals: #{inspect(goal2.goals)}")
      Logger.debug("Expected GTpyhop plan: [('unstack', 'a', 'c'), ('putdown', 'a'), ('unstack', 'b', 'd'), ('stack', 'b', 'c'), ('pickup', 'a'), ('stack', 'a', 'd')]")
      domain = AriaTemporalBlocks.Domain.create()

      # Expected plan from GTpyhop:
      #
      {:ok, result} = AriaHybridPlanner.plan(domain, state2, [goal2])
      assert [{:unstack, ["a", "c"]}, {:putdown, ["a"]}, {:unstack, ["b", "d"]}, {:stack, ["b", "c"]}, {:pickup, ["a"]}, {:stack, ["a", "d"]}] = AriaEngineCore.Plan.get_primitive_actions_dfs(result.solution_tree)
    end

    test "planning only (no execution)" do
      state1 = AriaState.new(%{
        "a" => %{"pos" => "b", "clear" => true},
        "b" => %{"pos" => "table", "clear" => false},
        "c" => %{"pos" => "table", "clear" => true},
        "hand" => %{"holding" => false}
      })

      goal = %AriaEngineCore.Multigoal{
        goals: [
          {"pos", "c", "b"},
          {"pos", "b", "a"},
          {"pos", "a", "table"}
        ],
      }
      domain = AriaTemporalBlocks.Domain.create()

      # Test planning without execution
      assert {:ok, solution_tree} = AriaHybridPlanner.plan(domain, state1, [goal])
      assert is_map(solution_tree)
      # The solution_tree is nested under :solution_tree key
      assert Map.has_key?(solution_tree, :solution_tree)
      assert Map.has_key?(solution_tree.solution_tree, :root_id)
      assert Map.has_key?(solution_tree.solution_tree, :nodes)
    end
  end

  describe "state validation" do
    test "create_multigoal produces valid goal" do
      goal = %AriaEngineCore.Multigoal{
        goals: [
          {"pos", "a", "b"},
          {"pos", "b", "table"}
        ],
      }

      assert %AriaEngineCore.Multigoal{} = goal
      assert goal.goals == [{"pos", "a", "b"}, {"pos", "b", "table"}]
    end
  end
end
