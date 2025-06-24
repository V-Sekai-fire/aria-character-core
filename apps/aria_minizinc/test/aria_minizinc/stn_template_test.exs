# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.STNTemplateTest do
  use ExUnit.Case
  doctest AriaMiniZinc.ProblemGenerator

  alias AriaMiniZinc.ProblemGenerator

  describe "Template Selection Tests" do
    test "selects STN template for explicit STN problem type" do
      domain = %{name: "test_domain"}
      state = %{entities: ["robot", "box"]}
      goals = [{"robot", "location", "room1"}, {"box", "location", "room2"}]
      options = %{problem_type: :stn}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify STN template was used by checking model structure
      assert String.contains?(problem_data.model, "Simple Temporal Network Problem")
      assert String.contains?(problem_data.model, "num_time_points")
      assert String.contains?(problem_data.model, "time_points")
      assert String.contains?(problem_data.model, "distance_matrix")
      assert String.contains?(problem_data.model, "makespan")
    end

    test "selects goal_solving template for general problems" do
      domain = %{name: "test_domain"}
      state = %{entities: ["robot"]}
      goals = [{"robot", "location", "room1"}]
      options = %{}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify goal_solving template was used
      assert String.contains?(problem_data.model, "Generated MiniZinc Model - Goal Solving")
      assert String.contains?(problem_data.model, "Time Variables")
      assert String.contains?(problem_data.model, "Location Variables")
    end

    test "handles template selection edge cases" do
      domain = %{name: "test_domain"}
      state = %{entities: []}
      goals = []

      # Test with empty goals and STN problem type
      options = %{problem_type: :stn}
      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should still use STN template but with no time points
      assert String.contains?(problem_data.model, "Simple Temporal Network Problem")
      assert String.contains?(problem_data.model, "num_time_points = 0")
    end

    test "selects STN template for temporal constraint problems" do
      domain = %{name: "temporal_domain"}
      state = %{entities: ["task1", "task2", "task3"]}
      goals = [
        {"task1", "location", "start"},
        {"task2", "location", "middle"},
        {"task3", "location", "end"}
      ]
      options = %{problem_type: :stn, temporal_constraints: true}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify STN template with temporal constraints
      assert String.contains?(problem_data.model, "Simple Temporal Network Problem")
      assert String.contains?(problem_data.model, "distance_matrix")
    end
  end

  describe "STN Data Transformation Tests" do
    test "converts goals to STN time points with durations" do
      domain = %{name: "test_domain"}
      state = %{entities: ["robot", "box", "truck"]}
      goals = [
        {"robot", "location", "warehouse"},
        {"box", "location", "truck"},
        {"truck", "location", "destination"}
      ]
      options = %{problem_type: :stn, default_duration: 45}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify time points were created (2 per entity: start and end)
      assert String.contains?(problem_data.model, "num_time_points = 6")
      assert String.contains?(problem_data.model, "robot_start")
      assert String.contains?(problem_data.model, "robot_end")
    end

    test "generates STN constraints from temporal relationships" do
      domain = %{name: "scheduling_domain"}
      state = %{entities: ["task_a", "task_b"]}
      goals = [
        {"task_a", "state", "completed"},
        {"task_b", "state", "completed"}
      ]
      options = %{problem_type: :stn, temporal_ordering: true}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify STN constraints were generated
      assert String.contains?(problem_data.model, "constraints = [|")
      assert String.contains?(problem_data.model, "1, 2, 0, 100")  # from_activity, to_activity, min_distance, max_distance
    end

    test "transforms structured variables to time point format" do
      domain = %{name: "test_domain"}
      state = %{entities: ["entity1", "entity2"]}
      goals = [{"entity1", "location", "room1"}, {"entity2", "location", "room2"}]
      options = %{problem_type: :stn, default_duration: 20}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Check that variables were transformed to time point format
      assert String.contains?(problem_data.model, "num_time_points")
      assert String.contains?(problem_data.model, "time_points")
      assert String.contains?(problem_data.model, "distance_matrix")
    end

    test "handles malformed STN data gracefully" do
      domain = %{name: "test_domain"}
      state = %{entities: ["valid_entity"]}

      # Mix of valid and invalid goals
      goals = [
        {"valid_entity", "location", "room1"},
        "invalid_goal_format",
        {:invalid, "tuple", "format"}
      ]
      options = %{problem_type: :stn}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should handle gracefully and only process valid goals
      assert String.contains?(problem_data.model, "num_time_points")
      assert is_binary(problem_data.model)
    end

    test "handles single time point STN problems" do
      domain = %{name: "test_domain"}
      state = %{entities: ["single_task"]}
      goals = [{"single_task", "location", "target"}]
      options = %{problem_type: :stn}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Single time point should work without constraints
      assert String.contains?(problem_data.model, "num_time_points")
      assert String.contains?(problem_data.model, "distance_matrix")
    end

    test "uses default time point configuration when not specified" do
      domain = %{name: "test_domain"}
      state = %{entities: ["task1", "task2"]}
      goals = [{"task1", "location", "a"}, {"task2", "location", "b"}]
      options = %{problem_type: :stn}  # No default_duration specified

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should use default time point configuration
      assert String.contains?(problem_data.model, "num_time_points")
      assert String.contains?(problem_data.model, "distance_matrix")
    end
  end

  describe "STN Template Validation Tests" do
    test "generates valid MiniZinc syntax for STN problems" do
      domain = %{name: "test_domain"}
      state = %{entities: ["a", "b", "c"]}
      goals = [{"a", "location", "1"}, {"b", "location", "2"}, {"c", "location", "3"}]
      options = %{problem_type: :stn, temporal_ordering: true}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      model = problem_data.model

      # Check for required STN template elements (time-point based)
      assert String.contains?(model, "int: num_time_points")
      assert String.contains?(model, "array[TIME_POINTS] of string: time_point_names")
      assert String.contains?(model, "array[TIME_POINTS, TIME_POINTS] of int: distance_matrix")
      assert String.contains?(model, "array[TIME_POINTS] of var 0..horizon: time_points")
      assert String.contains?(model, "var 0..horizon: makespan")
      assert String.contains?(model, "solve minimize makespan")
    end

    test "STN template produces consistent constraint format" do
      domain = %{name: "test_domain"}
      state = %{entities: ["x", "y"]}
      goals = [{"x", "state", "done"}, {"y", "state", "done"}]
      options = %{problem_type: :stn, temporal_constraints: true}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify constraint format matches STN template expectations (time-point based)
      assert String.contains?(problem_data.model, "distance_matrix")
      assert String.contains?(problem_data.model, "time_points[j] - time_points[i] >= distance_matrix[i,j]")
    end

    test "handles empty STN problems without errors" do
      domain = %{name: "empty_domain"}
      state = %{entities: []}
      goals = []
      options = %{problem_type: :stn}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should generate valid empty STN model with new template format
      assert String.contains?(problem_data.model, "num_time_points = 0")
      assert is_binary(problem_data.model)
      assert String.length(problem_data.model) > 0
    end
  end
end
