# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.STNIntegrationTest do
  use ExUnit.Case
  doctest AriaMiniZinc.ProblemGenerator

  alias AriaMiniZinc.ProblemGenerator

  describe "End-to-End STN Problem Generation" do
    test "generates complete STN problem from temporal goals" do
      domain = %{
        name: "temporal_scheduling",
        actions: ["start_task", "complete_task", "move_resource"]
      }

      state = %{
        entities: ["task_1", "task_2", "task_3"],
        resources: ["worker", "equipment"]
      }

      goals = [
        {"task_1", "state", "completed"},
        {"task_2", "state", "completed"},
        {"task_3", "state", "completed"}
      ]

      # Provide explicit timepoints and distance matrix for STN
      timepoints = ["task_1_start", "task_1_end", "task_2_start", "task_2_end", "task_3_start", "task_3_end"]
      distance_matrix = [
        [0, 60, 999999, 999999, 999999, 999999],     # task_1_start
        [999999, 0, 0, 999999, 999999, 999999],      # task_1_end -> task_2_start
        [999999, 999999, 0, 60, 999999, 999999],     # task_2_start
        [999999, 999999, 999999, 0, 0, 999999],      # task_2_end -> task_3_start
        [999999, 999999, 999999, 999999, 0, 60],     # task_3_start
        [999999, 999999, 999999, 999999, 999999, 0]  # task_3_end
      ]

      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        default_duration: 60,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify complete STN problem structure
      assert is_binary(problem_data.model)
      assert String.length(problem_data.model) > 100

      # Check STN-specific elements
      assert String.contains?(problem_data.model, "Simple Temporal Network Problem")
      assert String.contains?(problem_data.model, "num_time_points = 6")
      assert String.contains?(problem_data.model, "distance_matrix")
      assert String.contains?(problem_data.model, "solve minimize makespan")

      # Verify metadata
      assert problem_data.metadata.goal_count == 0  # STNs don't have goals
      assert problem_data.metadata.variable_count == 6  # 6 timepoints
      assert is_binary(problem_data.metadata.generation_start)
      assert is_binary(problem_data.metadata.generation_end)
    end

    test "optimizes makespan for scheduling problem" do
      domain = %{name: "makespan_optimization"}
      state = %{entities: ["job1", "job2", "job3", "job4"]}
      goals = [
        {"job1", "state", "done"},
        {"job2", "state", "done"},
        {"job3", "state", "done"},
        {"job4", "state", "done"}
      ]

      # Provide timepoints and distance matrix for 4 jobs
      timepoints = ["job1_start", "job1_end", "job2_start", "job2_end", "job3_start", "job3_end", "job4_start", "job4_end"]
      distance_matrix = [
        [0, 25, 999999, 999999, 999999, 999999, 999999, 999999],     # job1_start
        [999999, 0, 0, 999999, 999999, 999999, 999999, 999999],      # job1_end -> job2_start
        [999999, 999999, 0, 25, 999999, 999999, 999999, 999999],     # job2_start
        [999999, 999999, 999999, 0, 0, 999999, 999999, 999999],      # job2_end -> job3_start
        [999999, 999999, 999999, 999999, 0, 25, 999999, 999999],     # job3_start
        [999999, 999999, 999999, 999999, 999999, 0, 0, 999999],      # job3_end -> job4_start
        [999999, 999999, 999999, 999999, 999999, 999999, 0, 25],     # job4_start
        [999999, 999999, 999999, 999999, 999999, 999999, 999999, 0]  # job4_end
      ]

      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        default_duration: 25,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify makespan optimization objective
      assert String.contains?(problem_data.model, "solve minimize makespan")
      assert String.contains?(problem_data.model, "makespan = max(time_points)")

      # Check that all jobs have proper time points
      assert String.contains?(problem_data.model, "num_time_points = 8")

      # Verify temporal constraints for sequential execution
      assert String.contains?(problem_data.model, "distance_matrix")
    end

    test "handles complex STN with multiple constraints" do
      domain = %{
        name: "complex_scheduling",
        constraints: ["precedence", "resource_limits", "deadlines"]
      }

      state = %{
        entities: ["prep", "cook", "serve", "clean"],
        resources: ["chef", "kitchen", "waiter"]
      }

      goals = [
        {"prep", "state", "completed"},
        {"cook", "state", "completed"},
        {"serve", "state", "completed"},
        {"clean", "state", "completed"}
      ]

      # Provide timepoints and distance matrix for complex scheduling
      timepoints = ["prep_start", "prep_end", "cook_start", "cook_end", "serve_start", "serve_end", "clean_start", "clean_end"]
      distance_matrix = [
        [0, 15, 999999, 999999, 999999, 999999, 999999, 999999],     # prep_start
        [999999, 0, 0, 999999, 999999, 999999, 999999, 999999],      # prep_end -> cook_start
        [999999, 999999, 0, 15, 999999, 999999, 999999, 999999],     # cook_start
        [999999, 999999, 999999, 0, 0, 999999, 999999, 999999],      # cook_end -> serve_start
        [999999, 999999, 999999, 999999, 0, 15, 999999, 999999],     # serve_start
        [999999, 999999, 999999, 999999, 999999, 0, 0, 999999],      # serve_end -> clean_start
        [999999, 999999, 999999, 999999, 999999, 999999, 0, 15],     # clean_start
        [999999, 999999, 999999, 999999, 999999, 999999, 999999, 0]  # clean_end
      ]

      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        default_duration: 15,
        max_makespan: 120,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify complex STN structure
      assert String.contains?(problem_data.model, "num_time_points = 8")
      assert String.contains?(problem_data.model, "distance_matrix")

      # Check constraint format for complex scheduling
      assert String.contains?(problem_data.model, "time_points[j] - time_points[i] <= distance_matrix[i,j]")
      assert String.contains?(problem_data.model, "makespan = max(time_points)")
    end
  end

  describe "Template Comparison Tests" do
    test "equivalent problems produce consistent results across templates" do
      domain = %{name: "comparison_domain"}
      state = %{entities: ["entity1", "entity2"]}
      goals = [
        {"entity1", "location", "target1"},
        {"entity2", "location", "target2"}
      ]

      # Generate with goal_solving template
      {:ok, goal_solving_data} = ProblemGenerator.generate_problem(domain, state, goals, %{})

      # Generate with STN template - provide timepoints and distance matrix
      timepoints = ["entity1_start", "entity1_end", "entity2_start", "entity2_end"]
      distance_matrix = [
        [0, 30, 999999, 999999],      # entity1_start
        [999999, 0, 0, 999999],       # entity1_end -> entity2_start
        [999999, 999999, 0, 30],      # entity2_start
        [999999, 999999, 999999, 0]   # entity2_end
      ]

      {:ok, stn_data} = ProblemGenerator.generate_problem(domain, state, goals, %{
        problem_type: :stn,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      })

      # Both should succeed but have different metadata (STN doesn't count goals)
      assert goal_solving_data.metadata.goal_count == 2
      assert stn_data.metadata.goal_count == 0  # STNs don't have goals
      assert goal_solving_data.metadata.variable_count == 6  # 2 entities * 3 variable types
      assert stn_data.metadata.variable_count == 4  # 4 timepoints

      # Models should be different but both valid
      refute goal_solving_data.model == stn_data.model
      assert is_binary(goal_solving_data.model)
      assert is_binary(stn_data.model)
      assert String.length(goal_solving_data.model) > 0
      assert String.length(stn_data.model) > 0
    end

    test "STN template produces valid MiniZinc syntax" do
      domain = %{name: "syntax_test"}
      state = %{entities: ["task_x", "task_y", "task_z"]}
      goals = [
        {"task_x", "state", "active"},
        {"task_y", "state", "active"},
        {"task_z", "state", "active"}
      ]

      # Provide timepoints and distance matrix
      timepoints = ["task_x_start", "task_x_end", "task_y_start", "task_y_end", "task_z_start", "task_z_end"]
      distance_matrix = [
        [0, 20, 999999, 999999, 999999, 999999],     # task_x_start
        [999999, 0, 0, 999999, 999999, 999999],      # task_x_end -> task_y_start
        [999999, 999999, 0, 20, 999999, 999999],     # task_y_start
        [999999, 999999, 999999, 0, 0, 999999],      # task_y_end -> task_z_start
        [999999, 999999, 999999, 999999, 0, 20],     # task_z_start
        [999999, 999999, 999999, 999999, 999999, 0]  # task_z_end
      ]

      options = %{
        problem_type: :stn,
        temporal_constraints: true,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      model = problem_data.model

      # Basic MiniZinc syntax validation
      assert String.contains?(model, "int: num_time_points")
      assert String.contains?(model, "set of int: TIME_POINTS")
      assert String.contains?(model, "array[TIME_POINTS, TIME_POINTS] of int: distance_matrix")
      assert String.contains?(model, "constraint forall")
      assert String.contains?(model, "solve minimize")
      assert String.contains?(model, "output [")

      # Verify no obvious syntax errors
      refute String.contains?(model, "ERROR")
      refute String.contains?(model, "undefined")

      # Check proper array syntax
      assert String.contains?(model, "distance_matrix = [|") or String.contains?(model, "time_point_names = [")
    end

    test "goal_solving template maintains existing functionality" do
      domain = %{name: "legacy_test"}
      state = %{entities: ["robot", "package"]}
      goals = [
        {"robot", "location", "warehouse"},
        {"package", "state", "delivered"}
      ]
      options = %{}  # Default to goal_solving template

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify goal_solving template structure
      assert String.contains?(problem_data.model, "Generated MiniZinc Model - Goal Solving")
      assert String.contains?(problem_data.model, "Time Variables")
      assert String.contains?(problem_data.model, "Location Variables")
      assert String.contains?(problem_data.model, "Boolean Variables")

      # Check variable structure
      assert is_map(problem_data.variables)
      assert Map.has_key?(problem_data.variables, :time_vars)
      assert Map.has_key?(problem_data.variables, :location_vars)
      assert Map.has_key?(problem_data.variables, :boolean_vars)
    end
  end

  describe "STN Error Handling Tests" do
    test "handles STN generation errors gracefully" do
      domain = %{name: "error_test"}
      state = %{entities: ["problematic_entity"]}
      goals = [{"problematic_entity", "invalid_predicate", "invalid_value"}]

      # Provide valid timepoints and distance matrix even with problematic goals
      timepoints = ["problematic_start", "problematic_end"]
      distance_matrix = [
        [0, 30],
        [999999, 0]
      ]

      options = %{
        problem_type: :stn,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      # Should not crash, even with unusual goals
      result = ProblemGenerator.generate_problem(domain, state, goals, options)

      case result do
        {:ok, problem_data} ->
          # If it succeeds, should produce valid STN structure
          assert String.contains?(problem_data.model, "Simple Temporal Network Problem")
        {:error, reason} ->
          # If it fails, should provide meaningful error
          assert is_binary(reason)
          assert String.length(reason) > 0
      end
    end

    test "validates STN template data completeness" do
      domain = %{name: "validation_test"}
      state = %{entities: ["task1", "task2"]}
      goals = [{"task1", "location", "a"}, {"task2", "location", "b"}]

      # Provide timepoints and distance matrix
      timepoints = ["task1_start", "task1_end", "task2_start", "task2_end"]
      distance_matrix = [
        [0, 40, 999999, 999999],      # task1_start
        [999999, 0, 0, 999999],       # task1_end -> task2_start
        [999999, 999999, 0, 40],      # task2_start
        [999999, 999999, 999999, 0]   # task2_end
      ]

      options = %{
        problem_type: :stn,
        default_duration: 40,
        timepoints: timepoints,
        distance_matrix: distance_matrix
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify all required STN elements are present
      model = problem_data.model

      # Required declarations
      assert String.contains?(model, "int: num_time_points")
      assert String.contains?(model, "set of int: TIME_POINTS")

      # Required arrays
      assert String.contains?(model, "array[TIME_POINTS, TIME_POINTS] of int: distance_matrix")
      assert String.contains?(model, "array[TIME_POINTS] of var 0..horizon: time_points")

      # Required constraints
      assert String.contains?(model, "constraint forall(i, j in TIME_POINTS)")
      assert String.contains?(model, "time_points[j] - time_points[i] <= distance_matrix[i,j]")

      # Required objective and output
      assert String.contains?(model, "solve minimize makespan")
      assert String.contains?(model, "output [")
    end

    test "handles empty STN problems correctly" do
      domain = %{name: "empty_test"}
      state = %{entities: []}
      goals = []
      options = %{problem_type: :stn}  # No timepoints provided

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should generate valid empty STN model
      assert problem_data.model == "% Empty STN - no timepoints"
      assert problem_data.num_time_points == 0

      # Metadata should reflect empty problem
      assert problem_data.metadata.goal_count == 0
      assert problem_data.metadata.variable_count == 0
    end
  end
end
