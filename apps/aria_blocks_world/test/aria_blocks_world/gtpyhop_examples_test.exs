# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.GtpyhopExamplesTest do
  @moduledoc """
  Test suite that validates AriaBlocksWorld against the GTpyhop blocks_gtn examples.

  This test suite implements the same test cases found in:
  thirdparty/GTPyhop/Examples/blocks_gtn/examples.py

  These tests ensure our Elixir implementation produces the same results as the
  reference GTpyhop implementation for the blocks world domain.
  """

  use ExUnit.Case, async: true
  require Logger
  doctest AriaBlocksWorld

  # Helper function to log state in readable format
  defp log_state(state, label) do
    all_facts = AriaState.RelationalState.get_all_facts(state)

    pos_facts = Enum.filter(all_facts, fn {{pred, _}, _} -> pred == "pos" end)
    clear_facts = Enum.filter(all_facts, fn {{pred, _}, _} -> pred == "clear" end)
    holding_facts = Enum.filter(all_facts, fn {{pred, _}, _} -> pred == "holding" end)

    Logger.debug("#{label}:")
    Logger.debug("  pos: #{inspect(pos_facts)}")
    Logger.debug("  clear: #{inspect(clear_facts)}")
    Logger.debug("  holding: #{inspect(holding_facts)}")
  end

  # Helper function to log primitive actions from solution tree
  defp log_primitive_actions(solution_tree) do
    case solution_tree do
      %{solution_tree: tree} ->
        actions = AriaEngineCore.Plan.get_primitive_actions_dfs(tree)
        Logger.debug("Primitive Actions: #{inspect(actions)}")
        actions
      tree when is_map(tree) and is_map_key(tree, :root_id) ->
        actions = AriaEngineCore.Plan.get_primitive_actions_dfs(tree)
        Logger.debug("Primitive Actions: #{inspect(actions)}")
        actions
      _ ->
        Logger.debug("No solution tree available for primitive action extraction")
        Logger.debug("Solution tree structure: #{inspect(solution_tree)}")
        []
    end
  end

  describe "GTpyhop blocks_gtn examples" do
    test "simple pickup operations that should fail" do
      # state1.pos={'a':'b', 'b':'table', 'c':'table'}
      # state1.clear={'c':True, 'b':False,'a':True}
      # state1.holding={'hand':False}
      state1 = AriaBlocksWorld.create_state(%{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      })

      # These should fail because 'a' is on 'b' (can't pickup something that's not clear)
      # and 'b' has something on it
      assert {:error, _} = AriaBlocksWorld.solve_problem(state1, [{:pickup, ["a"]}])
      assert {:error, _} = AriaBlocksWorld.solve_problem(state1, [{:pickup, ["b"]}])
      assert {:error, _} = AriaBlocksWorld.solve_problem(state1, [{:take, ["b"]}])
    end

    test "simple pickup operations that should succeed" do
      state1 = AriaBlocksWorld.create_state(%{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      })

      # pickup 'c' should work (it's clear and on table)
      assert {:ok, {_final_state, _solution_tree}} = AriaBlocksWorld.solve_problem(state1, [{:pickup, ["c"]}])

      # take 'a' should work (unstack from 'b')
      assert {:ok, {_final_state, _solution_tree}} = AriaBlocksWorld.solve_problem(state1, [{:take, ["a"]}])

      # take 'c' should work (pickup from table)
      assert {:ok, {_final_state, _solution_tree}} = AriaBlocksWorld.solve_problem(state1, [{:take, ["c"]}])
    end

    test "multigoal: c on b, b on a, a on table" do
      Logger.debug("=== Test: multigoal: c on b, b on a, a on table ===")

      state1 = AriaBlocksWorld.create_state(%{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      })

      log_state(state1, "Initial State")

      # Goal: c on b, b on a, a on table
      goal1a = AriaBlocksWorld.create_multigoal(%{
        pos: %{"c" => "b", "b" => "a", "a" => "table"}
      })

      Logger.debug("Goals: #{inspect(goal1a.goals)}")
      Logger.debug("Expected GTpyhop plan: [{:unstack, ['a', 'b']}, {:putdown, ['a']), {:pickup, ['b']}, {:stack, ['b', 'a']}, {:pickup, ['c']}, {:stack, ['c', 'b']}]")

      # Expected plan from GTpyhop:
      # [('unstack', 'a', 'b'), ('putdown', 'a'), ('pickup', 'b'), ('stack', 'b', 'a'), ('pickup', 'c'), ('stack', 'c', 'b')]
      result = AriaBlocksWorld.solve_problem(state1, [goal1a])
      Logger.debug("Planning result: #{inspect(elem(result, 0))}")

      assert {:ok, {final_state, solution_tree}} = result

      # Log primitive actions
      log_primitive_actions(solution_tree)

      log_state(final_state, "Final State")

      # Verify final state matches goal
      assert AriaState.RelationalState.get_fact(final_state, "pos", "c") == "b"
      assert AriaState.RelationalState.get_fact(final_state, "pos", "b") == "a"
      assert AriaState.RelationalState.get_fact(final_state, "pos", "a") == "table"
    end

    test "Sussman anomaly" do
      Logger.debug("=== Test: Sussman anomaly ===")

      # sus_s0.pos={'c':'a', 'a':'table', 'b':'table'}
      # sus_s0.clear={'c':True, 'a':False,'b':True}
      # sus_s0.holding={'hand':False}
      sussman_initial = AriaBlocksWorld.create_state(%{
        pos: %{"c" => "a", "a" => "table", "b" => "table"},
        clear: %{"c" => true, "a" => false, "b" => true},
        holding: %{"hand" => false}
      })

      log_state(sussman_initial, "Initial State")

      # Goal: a on b, b on c
      sussman_goal = AriaBlocksWorld.create_multigoal(%{
        pos: %{"a" => "b", "b" => "c"}
      })

      Logger.debug("Goals: #{inspect(sussman_goal.goals)}")
      Logger.debug("Expected GTpyhop plan: [{:unstack, ['c', 'a']}, {:putdown, ['c']}, {:pickup, ['b']), (:stack, ['b', 'c']}, {:pickup, ['a']}, {:stack, ['a', 'b']}]")

      result = AriaBlocksWorld.solve_problem(sussman_initial, [sussman_goal])
      Logger.debug("Planning result: #{inspect(elem(result, 0))}")

      assert {:ok, {final_state, solution_tree}} = result

      # Log primitive actions
      log_primitive_actions(solution_tree)

      log_state(final_state, "Final State")

      # Verify final state matches goal
      assert AriaState.RelationalState.get_fact(final_state, "pos", "a") == "b"
      assert AriaState.RelationalState.get_fact(final_state, "pos", "b") == "c"
    end

    test "complex rearrangement problem" do
      Logger.debug("=== Test: complex rearrangement problem ===")

      # state2.pos={'a':'c', 'b':'d', 'c':'table', 'd':'table'}
      # state2.clear={'a':True, 'c':False,'b':True, 'd':False}
      # state2.holding={'hand':False}
      state2 = AriaBlocksWorld.create_state(%{
        pos: %{"a" => "c", "b" => "d", "c" => "table", "d" => "table"},
        clear: %{"a" => true, "b" => true, "c" => false, "d" => false},
        holding: %{"hand" => false}
      })

      log_state(state2, "Initial State")

      # Goal: b on c, a on d
      goal2 = AriaBlocksWorld.create_multigoal(%{
        pos: %{"b" => "c", "a" => "d"}
      })

      Logger.debug("Goals: #{inspect(goal2.goals)}")
      Logger.debug("Expected GTpyhop plan: [('unstack', 'a', 'c'), ('putdown', 'a'), ('unstack', 'b', 'd'), ('stack', 'b', 'c'), ('pickup', 'a'), ('stack', 'a', 'd')]")

      # Expected plan from GTpyhop:
      # [('unstack', 'a', 'c'), ('putdown', 'a'), ('unstack', 'b', 'd'), ('stack', 'b', 'c'), ('pickup', 'a'), ('stack', 'a', 'd')]
      result = AriaBlocksWorld.solve_problem(state2, [goal2])
      Logger.debug("Planning result: #{inspect(elem(result, 0))}")

      assert {:ok, {final_state, solution_tree}} = result

      # Log primitive actions
      log_primitive_actions(solution_tree)

      log_state(final_state, "Final State")

      # Verify final state matches goal
      assert AriaState.RelationalState.get_fact(final_state, "pos", "b") == "c"
      assert AriaState.RelationalState.get_fact(final_state, "pos", "a") == "d"
    end

    test "planning only (no execution)" do
      state1 = AriaBlocksWorld.create_state(%{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      })

      goal = AriaBlocksWorld.create_multigoal(%{
        pos: %{"c" => "b", "b" => "a", "a" => "table"}
      })

      # Test planning without execution
      assert {:ok, solution_tree} = AriaBlocksWorld.plan_problem(state1, [goal])
      assert is_map(solution_tree)
      # The solution_tree is nested under :solution_tree key
      assert Map.has_key?(solution_tree, :solution_tree)
      assert Map.has_key?(solution_tree.solution_tree, :root_id)
      assert Map.has_key?(solution_tree.solution_tree, :nodes)
    end
  end

  describe "domain information" do
    test "domain info provides correct metadata" do
      info = AriaBlocksWorld.domain_info()

      assert info.name == "Blocks World Domain"
      assert is_list(info.actions)
      assert is_list(info.predicates)

      # Check that key actions are present
      assert :pickup in info.actions
      assert :putdown in info.actions
      assert :stack in info.actions
      assert :unstack in info.actions

      # Check that key predicates are present
      assert "pos" in info.predicates
      assert "clear" in info.predicates
      assert "holding" in info.predicates
    end
  end

  describe "state validation" do
    test "create_state produces valid state" do
      state = AriaBlocksWorld.create_state(%{
        pos: %{"a" => "table", "b" => "a"},
        clear: %{"a" => false, "b" => true},
        holding: %{"hand" => false}
      })

      assert AriaState.RelationalState.get_fact(state, "pos", "a") == "table"
      assert AriaState.RelationalState.get_fact(state, "pos", "b") == "a"
      assert AriaState.RelationalState.get_fact(state, "clear", "a") == false
      assert AriaState.RelationalState.get_fact(state, "clear", "b") == true
      assert AriaState.RelationalState.get_fact(state, "holding", "hand") == false
    end

    test "create_multigoal produces valid goal" do
      goal = AriaBlocksWorld.create_multigoal(%{
        pos: %{"a" => "b", "b" => "table"}
      })

      assert %AriaEngineCore.Multigoal{} = goal
      assert goal.goals == [{"pos", "a", "b"}, {"pos", "b", "table"}]
    end
  end
end
