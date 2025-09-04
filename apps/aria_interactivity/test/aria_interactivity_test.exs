defmodule AriaInteractivityTest do
  @moduledoc """
  Test suite for Aria Interactivity glTF domain implementation

  Tests the core functionality of the glTF interactivity extension
  as a temporal planning domain.
  """

  use ExUnit.Case
  doctest AriaInteractivity

  alias AriaInteractivity.Domain
  alias AriaInteractivity.Temporal
  alias AriaInteractivity.NodeParser

  # Mock AriaState for testing
  defmodule MockAriaState do
    defstruct facts: %{}
  end

  describe "Domain Functions" do
    test "math_add adds two numbers correctly" do
      state = %MockAriaState{}
      {:ok, result} = Domain.math_add(state, [3, 5])
      assert result == %MockAriaState{facts: %{"math_result" => "current" => 8}}
    end

    test "math_subtract subtracts correctly" do
      state = %MockAriaState{}
      {:ok, result} = Domain.math_subtract(state, [10, 3])
      assert result == %MockAriaState{facts: %{"math_result" => "current" => 7}}
    end

    test "math_divide handles division by zero" do
      state = %MockAriaState{}
      assert {:error, :division_by_zero} = Domain.math_divide(state, [10, 0])
    end

    test "flow_sequence creates n-to-n mapping of tasks to todo_items" do
      state = %MockAriaState{}
      tasks = [{:task_a, []}, {:task_b, [1, 2]}, :task_c]

      {:ok, todo_items} = Domain.flow_sequence(state, tasks)

      assert length(todo_items) == 3
      assert {:task, {:task_a, []}} in todo_items
      assert {:task, {:task_b, [1, 2]}} in todo_items
      assert {:task, {:execute_task, :task_c}} in todo_items
    end

    test "set_variable creates variable update action" do
      state = %MockAriaState{}
      {:ok, todo_items} = Domain.set_variable(state, {:my_var, "test_value"})

      assert todo_items == [
        {:action, {:update_variable, [:my_var, "test_value"]}}
      ]
    end

    test "play_animation creates temporal animation action" do
      state = %MockAriaState{}
      {:ok, todo_items} = Domain.play_animation(state, {0, true})

      assert length(todo_items) == 1
      assert match?([{:temporal_action, _}], todo_items)
    end

    test "create_temporal_animation uses manual lambda annotation" do
      state = %MockAriaState{}
      {:ok, todo_items} = Domain.create_temporal_animation(state, [0, "PT2S", 0, 2, 1.0])

      assert length(todo_items) == 1
      assert match?([{:temporal_action, %{type: :temporal_action}}], todo_items)
    end
  end

  describe "Temporal Functions" do
    test "parse_iso8601_duration handles basic durations" do
      assert {:ok, 5400.0} = Temporal.parse_iso8601_duration("PT1H30M")
      assert {:ok, 150.0} = Temporal.parse_iso8601_duration("PT2M30S")
      assert {:ok, 86400.0} = Temporal.parse_iso8601_duration("P1D")
    end

    test "format_iso8601_duration converts seconds to duration string" do
      assert "PT1H30M" = Temporal.format_iso8601_duration(5400)
      assert "PT2M30S" = Temporal.format_iso8601_duration(150)
      assert "P1DT0H0M0S" = Temporal.format_iso8601_duration(86400)
    end

    test "create_fixed_duration_action creates correct pattern" do
      action = Temporal.create_fixed_duration_action(:test_action, 5.0)

      assert action.type == :fixed_duration
      assert action.action == :test_action
      assert action.duration == 5.0
      assert {:duration_equals, 5.0} in action.constraints
    end

    test "create_concurrent_actions creates concurrent pattern" do
      actions = [:action1, :action2]
      concurrent = Temporal.create_concurrent_actions(actions)

      assert concurrent.type == :concurrent
      assert concurrent.actions == actions
      assert {:all_start_simultaneously, actions} in concurrent.constraints
    end

    test "create_sequential_actions creates sequential pattern" do
      actions = [:action1, :action2]
      sequential = Temporal.create_sequential_actions(actions, [1.0])

      assert sequential.type == :sequential
      assert sequential.actions == actions
      assert sequential.gaps == [1.0]
    end

    test "validate_temporal_constraints handles valid actions" do
      actions = [%{constraints: []}]
      assert {:ok, %{valid: true}} = Temporal.validate_temporal_constraints(actions)
    end
  end

  describe "Node Parser" do
    test "parse_node handles math operations" do
      state = %MockAriaState{}
      node = %{
        "operation" => "math/add",
        "values" => %{
          "a" => %{"value" => [3]},
          "b" => %{"value" => [5]}
        }
      }

      {:ok, result} = NodeParser.parse_node(node, state)
      assert match?(%MockAriaState{facts: %{"math_result" => "current" => 8}}, result)
    end

    test "parse_node handles variable operations" do
      state = %MockAriaState{}
      node = %{
        "operation" => "variable/set",
        "configuration" => %{"variable" => "test_var"},
        "values" => %{
          "value" => %{"value" => ["test_value"]}
        }
      }

      {:ok, todo_items} = NodeParser.parse_node(node, state)
      assert length(todo_items) == 1
      assert match?([{:action, {:update_variable, _}}], todo_items)
    end

    test "graph_to_planning_problem converts glTF graph structure" do
      graph = %{
        "nodes" => [
          %{"id" => 0, "operation" => "math/add", "values" => %{}}
        ],
        "variables" => [
          %{"name" => "test_var", "value" => [42]}
        ],
        "events" => []
      }

      {:ok, problem} = NodeParser.graph_to_planning_problem(graph)

      assert Map.has_key?(problem, :initial_state)
      assert Map.has_key?(problem, :goal)
      assert Map.has_key?(problem, :operators)
      assert problem.domain == :aria_interactivity
    end

    test "extract_dependencies converts node connections" do
      nodes = [
        %{
          "id" => 0,
          "flows" => %{
            "out" => %{"node" => 1, "socket" => "in"}
          }
        }
      ]

      dependencies = NodeParser.extract_dependencies(nodes)

      assert length(dependencies) == 1
      dep = hd(dependencies)
      assert dep.from_node == 0
      assert dep.to_node == 1
      assert dep.dependency_type == :flow_dependency
    end
  end

  describe "Integration Tests" do
    test "AriaInteractivity.create_temporal_animation works end-to-end" do
      {:ok, result} = AriaInteractivity.create_temporal_animation(0, "PT2S", 0, 2, 1.0)
      assert length(result) == 1
      assert match?([{:temporal_action, _}], result)
    end

    test "AriaInteractivity.parse_duration handles ISO 8601" do
      assert {:ok, 5400.0} = AriaInteractivity.parse_duration("PT1H30M")
      assert {:ok, 150.0} = AriaInteractivity.parse_duration("PT2M30S")
    end

    test "AriaInteractivity.graph_to_problem converts glTF graphs" do
      graph = %{"nodes" => [], "variables" => []}
      {:ok, problem} = AriaInteractivity.graph_to_problem(graph)

      assert Map.has_key?(problem, :initial_state)
      assert Map.has_key?(problem, :goal)
      assert Map.has_key?(problem, :operators)
    end
  end
end
