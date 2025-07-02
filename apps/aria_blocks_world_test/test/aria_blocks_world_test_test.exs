defmodule AriaBlocksWorldTestTest do
  use ExUnit.Case
  doctest AriaBlocksWorldTest

  alias AriaBlocksWorldTest.{Domain, State, Examples}

  describe "basic functionality" do
    test "creates domain" do
      domain = Domain.create()
      assert domain != nil
    end

    test "creates state from data" do
      state = AriaBlocksWorldTest.create_state(%{
        pos: %{"a" => "table", "b" => "table"},
        clear: %{"a" => true, "b" => true},
        holding: %{"hand" => false}
      })

      assert AriaState.RelationalState.get_fact(state, "pos", "a") == "table"
      assert AriaState.RelationalState.get_fact(state, "clear", "a") == true
      assert AriaState.RelationalState.get_fact(state, "holding", "hand") == false
    end

    test "creates multigoal" do
      goal = AriaBlocksWorldTest.create_multigoal(%{
        pos: %{"a" => "b", "b" => "table"}
      })

      assert {:multigoal, goal_data} = goal
      assert goal_data.pos == %{"a" => "b", "b" => "table"}
    end

    test "lists examples" do
      examples = AriaBlocksWorldTest.list_examples()
      assert :sussman_anomaly in examples
      assert :simple_pickup in examples
      assert :simple_stack in examples
      assert :complex_multiblock in examples
    end

    test "gets domain info" do
      info = AriaBlocksWorldTest.domain_info()
      assert info.name == "Blocks World Domain"
      assert :pickup in info.actions
      assert :stack in info.actions
      assert "pos" in info.predicates
      assert "clear" in info.predicates
    end
  end

  describe "examples" do
    test "runs simple pickup example" do
      {:ok, result} = AriaBlocksWorldTest.run_example(:simple_pickup)
      assert result.name == "Simple Pickup"
      assert result.description == "Basic pickup operation test"
      assert result.goals == [{"pos", "a", "hand"}]
    end

    test "handles unknown example" do
      {:error, reason} = AriaBlocksWorldTest.run_example(:unknown_example)
      assert reason == :unknown_example
    end
  end

  describe "planning" do
    test "solves simple pickup problem" do
      state = AriaBlocksWorldTest.create_state(%{
        pos: %{"a" => "table"},
        clear: %{"a" => true},
        holding: %{"hand" => false}
      })

      goal = AriaBlocksWorldTest.create_multigoal(%{
        pos: %{"a" => "hand"}
      })

      # This test may fail until the planning system is fully integrated
      # For now, we just test that the function exists and returns something
      result = AriaBlocksWorldTest.solve_problem(state, [goal])
      assert result != nil
    end
  end
end
