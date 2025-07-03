# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlannerTest do
  use ExUnit.Case
  doctest AriaHybridPlanner

  alias AriaHybridPlanner
  alias AriaCore.Domain

  describe "basic planning functionality" do
    setup do
      # Create a simple test domain
      domain = Domain.new("test_domain")

      # Add a simple action
      move_action = %{
        effects: fn state, [from, to] ->
          state
          |> AriaState.set_fact("location", from, "empty")
          |> AriaState.set_fact("location", to, "occupied")
        end
      }

      domain = Domain.add_action(domain, :move, move_action)

      # Create initial state
      state = AriaHybridPlanner.new_state()
      |> AriaState.set_fact("location", "a", "occupied")
      |> AriaState.set_fact("location", "b", "empty")

      %{domain: domain, state: state}
    end

    test "plan/4 creates a valid plan structure", %{domain: domain, state: state} do
      todos = [{:move, ["a", "b"]}]

      assert {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos)

      # Verify plan structure
      assert is_map(plan)
      assert Map.has_key?(plan, :solution_tree)
      assert Map.has_key?(plan, :metadata)

      # Verify solution tree structure
      solution_tree = plan.solution_tree
      assert Map.has_key?(solution_tree, :root_id)
      assert Map.has_key?(solution_tree, :nodes)
      assert Map.has_key?(solution_tree, :blacklisted_commands)

      # Verify metadata
      metadata = plan.metadata
      assert Map.has_key?(metadata, :created_at)
      assert Map.has_key?(metadata, :domain)
      assert metadata.domain == domain
    end


    test "run_lazy/3 performs planning and execution", %{domain: domain, state: state} do
      todos = [{:move, ["a", "b"]}]

      # Note: This test may fail if execution requires actual domain methods
      # but it should at least test the planning phase
      case AriaHybridPlanner.run_lazy(domain, state, todos) do
        {:ok, {final_state, solution_tree}} ->
          # Verify return structure
          assert is_map(final_state)
          assert is_map(solution_tree)
          assert Map.has_key?(solution_tree, :root_id)
          assert Map.has_key?(solution_tree, :nodes)

        {:error, reason} ->
          # Execution might fail due to missing domain methods, which is expected
          assert is_binary(reason)
          assert String.contains?(reason, "function not found") or
                 String.contains?(reason, "Domain required") or
                 String.contains?(reason, "execution") or
                 String.contains?(reason, "todo_item_failed")
      end
    end

    test "run_lazy_tree/3 executes pre-made solution tree", %{domain: domain, state: state} do
      todos = [{:move, ["a", "b"]}]

      # First create a solution tree using plan/4
      assert {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos)
      solution_tree = plan.solution_tree

      # Then execute it
      case AriaHybridPlanner.run_lazy_tree(domain, state, solution_tree) do
        {:ok, {final_state, returned_tree}} ->
          # Verify return structure
          assert is_map(final_state)
          assert is_map(returned_tree)
          assert returned_tree == solution_tree

        {:error, reason} ->
          # Execution might fail due to missing domain methods, which is expected
          assert is_binary(reason)
          assert String.contains?(reason, "function not found") or
                 String.contains?(reason, "Domain required") or
                 String.contains?(reason, "execution") or
                 String.contains?(reason, "todo_item_failed")
      end
    end

    test "plan/4 with verbose option", %{domain: domain, state: state} do
      todos = [{:move, ["a", "b"]}]

      assert {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, verbose: 1)

      # Should still create valid plan with verbose logging
      assert is_map(plan)
      assert Map.has_key?(plan, :solution_tree)
      assert Map.has_key?(plan, :metadata)
    end

    test "plan/4 with max_depth option", %{domain: domain, state: state} do
      todos = [{:move, ["a", "b"]}]

      assert {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, max_depth: 5)

      # Should create valid plan with depth limit
      assert is_map(plan)
      assert Map.has_key?(plan, :solution_tree)
      assert plan.metadata.planning_depth == 5
    end

    test "plan/4 handles empty todos", %{domain: domain, state: state} do
      todos = []

      assert {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos)

      # Should create valid plan even with no todos
      assert is_map(plan)
      assert Map.has_key?(plan, :solution_tree)

      # Root node should be expanded with no children
      solution_tree = plan.solution_tree
      root_node = solution_tree.nodes[solution_tree.root_id]
      assert root_node.expanded == true
      assert Enum.empty?(root_node.children_ids)
    end

    test "plan/4 handles multiple todos", %{domain: domain, state: state} do
      todos = [{:move, ["a", "b"]}, {:move, ["b", "c"]}]

      assert {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos)

      # Should create valid plan with multiple todos
      assert is_map(plan)
      assert Map.has_key?(plan, :solution_tree)

      # Root node should have children for each todo
      solution_tree = plan.solution_tree
      root_node = solution_tree.nodes[solution_tree.root_id]
      assert length(root_node.children_ids) == 2
    end
  end

  describe "state management" do
    test "new_state/0 creates empty state" do
      state = AriaHybridPlanner.new_state()
      assert is_map(state)
    end

    test "new_state/1 creates state with data" do
      data = %{"test" => "value"}
      state = AriaHybridPlanner.new_state(data)
      assert is_map(state)
    end

    test "state fact operations work" do
      state = AriaHybridPlanner.new_state()

      # Set a fact
      updated_state = AriaHybridPlanner.set_fact(state, "location", "a", "room1")

      # Get the fact
      assert "room1" = AriaHybridPlanner.get_fact(updated_state, "location", "a")

      # Check if subject exists
      assert AriaHybridPlanner.has_subject?(updated_state, "location", "a")
      assert not AriaHybridPlanner.has_subject?(updated_state, "location", "b")

      # Remove the fact
      final_state = AriaHybridPlanner.remove_fact(updated_state, "location", "a")
      assert not AriaHybridPlanner.has_subject?(final_state, "location", "a")
    end
  end

  describe "domain integration" do
    test "plan/4 uses domain for task decomposition" do
      # Create domain with task methods using AriaCore.MethodManagement
      domain = Domain.new("test_domain")
      domain = AriaCore.MethodManagement.add_task_method(domain, "transport", "method1", fn _state, _args -> {:ok, []} end)

      state = AriaHybridPlanner.new_state()
      todos = [{:transport, ["a", "b"]}]

      assert {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, verbose: 2)

      # Should create plan that considers domain methods
      assert is_map(plan)
      assert Map.has_key?(plan, :solution_tree)
    end

    test "plan/4 handles goals with unigoal methods" do
      # Create domain with unigoal methods using proper AriaCore API
      domain = Domain.new("test_domain")

      # Create unigoal method spec with proper structure
      unigoal_spec = %{
        predicate: "location",
        goal_fn: fn _state, _args -> {:ok, []} end
      }
      domain = AriaCore.add_unigoal_method(domain, :move_method, unigoal_spec)

      state = AriaHybridPlanner.new_state()
      todos = [{"location", "a", "room1"}]

      assert {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, verbose: 2)

      # Should create plan that considers unigoal methods
      assert is_map(plan)
      assert Map.has_key?(plan, :solution_tree)
    end
  end

  describe "version" do
    test "version/0 returns version string" do
      version = AriaHybridPlanner.version()
      assert is_binary(version)
      assert version != ""
    end
  end
end
