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

      # Provide timepoints and distance matrix for STN
      timepoints = ["robot_start", "robot_end", "box_start", "box_end"]
      distance_matrix = [
        [0, 30, 999999, 999999],      # robot_start
        [999999, 0, 0, 999999],       # robot_end -> box_start (precedence)
        [999999, 999999, 0, 25],      # box_start
        [999999, 999999, 999999, 0]   # box_end
      ]

      options = %{
        problem_type: :stn,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

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

      # Test with empty goals and STN problem type - no timepoints provided
      options = %{problem_type: :stn}
      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should return minimal STN for empty case
      assert problem_data.model == "% Empty STN - no timepoints"
      assert problem_data.num_time_points == 0
    end

    test "selects STN template for temporal constraint problems" do
      domain = %{name: "temporal_domain"}
      state = %{entities: ["task1", "task2", "task3"]}
      goals = [
        {"task1", "location", "start"},
        {"task2", "location", "middle"},
        {"task3", "location", "end"}
      ]

      # Provide timepoints and distance matrix
      timepoints = ["task1_start", "task1_end", "task2_start", "task2_end", "task3_start", "task3_end"]
      distance_matrix = [
        [0, 20, 999999, 999999, 999999, 999999],     # task1_start
        [999999, 0, 0, 999999, 999999, 999999],      # task1_end -> task2_start
        [999999, 999999, 0, 15, 999999, 999999],     # task2_start
        [999999, 999999, 999999, 0, 0, 999999],      # task2_end -> task3_start
        [999999, 999999, 999999, 999999, 0, 10],     # task3_start
        [999999, 999999, 999999, 999999, 999999, 0]  # task3_end
      ]

      options = %{
        problem_type: :stn,
        temporal_constraints: true,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify STN template with temporal constraints
      assert String.contains?(problem_data.model, "Simple Temporal Network Problem")
      assert String.contains?(problem_data.model, "distance_matrix")
    end
  end

  describe "STN Data Transformation Tests" do
    test "converts timepoints to STN format with durations" do
      domain = %{name: "test_domain"}
      state = %{entities: ["robot", "box", "truck"]}
      goals = [
        {"robot", "location", "warehouse"},
        {"box", "location", "truck"},
        {"truck", "location", "destination"}
      ]

      # Provide explicit timepoints (2 per entity: start and end)
      timepoints = ["robot_start", "robot_end", "box_start", "box_end", "truck_start", "truck_end"]
      distance_matrix = [
        [0, 45, 999999, 999999, 999999, 999999],     # robot_start
        [999999, 0, 0, 999999, 999999, 999999],      # robot_end -> box_start
        [999999, 999999, 0, 45, 999999, 999999],     # box_start
        [999999, 999999, 999999, 0, 0, 999999],      # box_end -> truck_start
        [999999, 999999, 999999, 999999, 0, 45],     # truck_start
        [999999, 999999, 999999, 999999, 999999, 0]  # truck_end
      ]

      options = %{
        problem_type: :stn,
        default_duration: 45,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

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

      timepoints = ["task_a_start", "task_a_end", "task_b_start", "task_b_end"]
      distance_matrix = [
        [0, 30, 999999, 999999],      # task_a_start
        [999999, 0, 0, 999999],       # task_a_end -> task_b_start (ordering)
        [999999, 999999, 0, 25],      # task_b_start
        [999999, 999999, 999999, 0]   # task_b_end
      ]

      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify STN constraints were generated
      assert String.contains?(problem_data.model, "distance_matrix")
      assert String.contains?(problem_data.model, "time_points[j] - time_points[i] <= distance_matrix[i,j]")
    end

    test "transforms timepoints to proper STN format" do
      domain = %{name: "test_domain"}
      state = %{entities: ["entity1", "entity2"]}
      goals = [{"entity1", "location", "room1"}, {"entity2", "location", "room2"}]

      timepoints = ["entity1_start", "entity1_end", "entity2_start", "entity2_end"]
      distance_matrix = [
        [0, 20, 999999, 999999],      # entity1_start
        [999999, 0, 0, 999999],       # entity1_end -> entity2_start
        [999999, 999999, 0, 20],      # entity2_start
        [999999, 999999, 999999, 0]   # entity2_end
      ]

      options = %{
        problem_type: :stn,
        default_duration: 20,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Check that timepoints were used correctly
      assert String.contains?(problem_data.model, "num_time_points")
      assert String.contains?(problem_data.model, "time_points")
      assert String.contains?(problem_data.model, "distance_matrix")
    end

    test "handles malformed STN data gracefully" do
      domain = %{name: "test_domain"}
      state = %{entities: ["valid_entity"]}

      # Mix of valid and invalid goals (goals are ignored for STN anyway)
      goals = [
        {"valid_entity", "location", "room1"},
        "invalid_goal_format",
        {:invalid, "tuple", "format"}
      ]

      # Provide valid timepoints and matrix
      timepoints = ["valid_start", "valid_end"]
      distance_matrix = [
        [0, 30],
        [999999, 0]
      ]

      options = %{
        problem_type: :stn,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should handle gracefully with provided timepoints
      assert String.contains?(problem_data.model, "num_time_points")
      assert is_binary(problem_data.model)
    end

    test "handles single time point STN problems" do
      domain = %{name: "test_domain"}
      state = %{entities: ["single_task"]}
      goals = [{"single_task", "location", "target"}]

      # Single timepoint
      timepoints = ["single_task_point"]
      distance_matrix = [[0]]  # 1x1 matrix

      options = %{
        problem_type: :stn,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Single time point should work
      assert String.contains?(problem_data.model, "num_time_points")
      assert String.contains?(problem_data.model, "distance_matrix")
    end

    test "uses default configuration when minimal timepoints provided" do
      domain = %{name: "test_domain"}
      state = %{entities: ["task1", "task2"]}
      goals = [{"task1", "location", "a"}, {"task2", "location", "b"}]

      # Minimal timepoints
      timepoints = ["task1_start", "task1_end", "task2_start", "task2_end"]
      distance_matrix = [
        [0, 30, 999999, 999999],      # task1_start
        [999999, 0, 0, 999999],       # task1_end -> task2_start
        [999999, 999999, 0, 30],      # task2_start
        [999999, 999999, 999999, 0]   # task2_end
      ]

      options = %{
        problem_type: :stn,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }  # No default_duration specified

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should use provided timepoints
      assert String.contains?(problem_data.model, "num_time_points")
      assert String.contains?(problem_data.model, "distance_matrix")
    end
  end

  describe "STN Template Validation Tests" do
    test "generates valid MiniZinc syntax for STN problems" do
      domain = %{name: "test_domain"}
      state = %{entities: ["a", "b", "c"]}
      goals = [{"a", "location", "1"}, {"b", "location", "2"}, {"c", "location", "3"}]

      timepoints = ["a_start", "a_end", "b_start", "b_end", "c_start", "c_end"]
      distance_matrix = [
        [0, 20, 999999, 999999, 999999, 999999],     # a_start
        [999999, 0, 0, 999999, 999999, 999999],      # a_end -> b_start
        [999999, 999999, 0, 20, 999999, 999999],     # b_start
        [999999, 999999, 999999, 0, 0, 999999],      # b_end -> c_start
        [999999, 999999, 999999, 999999, 0, 20],     # c_start
        [999999, 999999, 999999, 999999, 999999, 0]  # c_end
      ]

      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

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

      timepoints = ["x_start", "x_end", "y_start", "y_end"]
      distance_matrix = [
        [0, 15, 999999, 999999],      # x_start
        [999999, 0, 0, 999999],       # x_end -> y_start
        [999999, 999999, 0, 15],      # y_start
        [999999, 999999, 999999, 0]   # y_end
      ]

      options = %{
        problem_type: :stn,
        temporal_constraints: true,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify constraint format matches STN template expectations (time-point based)
      assert String.contains?(problem_data.model, "distance_matrix")
      assert String.contains?(problem_data.model, "time_points[j] - time_points[i] <= distance_matrix[i,j]")
    end

    test "handles empty STN problems without errors" do
      domain = %{name: "empty_domain"}
      state = %{entities: []}
      goals = []
      options = %{problem_type: :stn}  # No timepoints provided

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should generate valid empty STN model
      assert problem_data.model == "% Empty STN - no timepoints"
      assert problem_data.num_time_points == 0
      assert is_binary(problem_data.model)
      assert String.length(problem_data.model) > 0
    end
  end
end
