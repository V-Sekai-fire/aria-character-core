defmodule AriaBlocksWorldTest.GtpyhopExamplesTest do
  use ExUnit.Case
  doctest AriaBlocksWorldTest.Examples

  alias AriaBlocksWorldTest.Examples

  describe "example listing" do
    test "lists all available examples" do
      examples = Examples.list_all()
      assert :sussman_anomaly in examples
      assert :simple_pickup in examples
      assert :simple_stack in examples
      assert :complex_multiblock in examples
      assert length(examples) == 4
    end
  end

  describe "example execution" do
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

    test "runs sussman anomaly example" do
      {:ok, result} = Examples.run(:sussman_anomaly)

      assert result.name == "Sussman Anomaly"
      assert result.description == "Classic subgoal interaction problem: A on B, B on C"
      assert result.goals == [{"pos", "a", "b"}, {"pos", "b", "c"}]
      assert result.initial_state != nil
      assert result.final_state != nil
    end

    test "runs complex multiblock example" do
      {:ok, result} = Examples.run(:complex_multiblock)

      assert result.name == "Complex Multiblock"
      assert result.description == "Complex rearrangement: reverse a 3-block stack"
      assert result.goals == [{"pos", "c", "b"}, {"pos", "b", "a"}, {"pos", "a", "table"}]
      assert result.initial_state != nil
      assert result.final_state != nil
    end

    test "handles unknown example" do
      {:error, reason} = Examples.run(:unknown_example)
      assert reason == :unknown_example
    end
  end

  describe "gtpyhop compatibility" do
    test "sussman anomaly matches gtpyhop problem structure" do
      {:ok, result} = Examples.run(:sussman_anomaly)

      # Verify initial state structure matches GTpyhop blocks_gtn
      initial_state = result.initial_state

      # A on C, B on table, C on table
      assert AriaState.RelationalState.get_fact(initial_state, "pos", "a") == "c"
      assert AriaState.RelationalState.get_fact(initial_state, "pos", "b") == "table"
      assert AriaState.RelationalState.get_fact(initial_state, "pos", "c") == "table"

      # A and B clear, C not clear
      assert AriaState.RelationalState.get_fact(initial_state, "clear", "a") == true
      assert AriaState.RelationalState.get_fact(initial_state, "clear", "b") == true
      assert AriaState.RelationalState.get_fact(initial_state, "clear", "c") == false

      # Hand empty
      assert AriaState.RelationalState.get_fact(initial_state, "holding", "hand") == false

      # Goals: A on B, B on C
      assert result.goals == [{"pos", "a", "b"}, {"pos", "b", "c"}]
    end

    test "complex multiblock matches gtpyhop structure" do
      {:ok, result} = Examples.run(:complex_multiblock)

      # Verify initial state: A on B on C on table
      initial_state = result.initial_state

      assert AriaState.RelationalState.get_fact(initial_state, "pos", "a") == "b"
      assert AriaState.RelationalState.get_fact(initial_state, "pos", "b") == "c"
      assert AriaState.RelationalState.get_fact(initial_state, "pos", "c") == "table"

      # Only A is clear
      assert AriaState.RelationalState.get_fact(initial_state, "clear", "a") == true
      assert AriaState.RelationalState.get_fact(initial_state, "clear", "b") == false
      assert AriaState.RelationalState.get_fact(initial_state, "clear", "c") == false

      # Goals: reverse the stack (C on B on A on table)
      assert result.goals == [{"pos", "c", "b"}, {"pos", "b", "a"}, {"pos", "a", "table"}]
    end
  end

  describe "planning integration" do
    @tag :slow
    test "examples produce valid solution trees" do
      # Test that examples actually solve and produce solution trees
      # This may be slow as it involves actual planning

      {:ok, result} = Examples.run(:simple_pickup)

      # Should have a solution tree
      assert result.solution_tree != nil

      # Final state should achieve the goals
      final_state = result.final_state
      assert AriaState.RelationalState.get_fact(final_state, "pos", "a") == "hand"
    end

    @tag :slow
    test "sussman anomaly produces non-trivial solution" do
      # The Sussman anomaly requires subgoal interaction
      # and should produce a multi-step solution

      {:ok, result} = Examples.run(:sussman_anomaly)

      # Should have a solution tree with multiple steps
      assert result.solution_tree != nil

      # Final state should achieve both goals
      final_state = result.final_state
      assert AriaState.RelationalState.get_fact(final_state, "pos", "a") == "b"
      assert AriaState.RelationalState.get_fact(final_state, "pos", "b") == "c"
    end
  end
end
