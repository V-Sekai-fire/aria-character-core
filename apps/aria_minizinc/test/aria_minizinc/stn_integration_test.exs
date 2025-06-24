defmodule AriaMiniZinc.STNIntegrationTest do
  use ExUnit.Case
  doctest AriaMiniZinc.ProblemGenerator

  alias AriaMiniZinc.ProblemGenerator
  alias AriaMiniZinc.Solver

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

      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        default_duration: 60
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify complete STN problem structure
      assert is_binary(problem_data.model)
      assert String.length(problem_data.model) > 100

      # Check STN-specific elements
      assert String.contains?(problem_data.model, "STN Temporal Scheduling Problem")
      assert String.contains?(problem_data.model, "num_activities = 3")
      assert String.contains?(problem_data.model, "durations = [60, 60, 60]")
      assert String.contains?(problem_data.model, "solve minimize makespan")

      # Verify metadata
      assert problem_data.metadata.goal_count == 3
      assert problem_data.metadata.variable_count == 9  # 3 entities * 3 variable types
      assert is_binary(problem_data.metadata.generation_start)
      assert is_binary(problem_data.metadata.generation_end)
    end

    test "solves simple temporal network with 3 activities" do
      domain = %{name: "simple_scheduling"}
      state = %{entities: ["activity_a", "activity_b", "activity_c"]}
      goals = [
        {"activity_a", "location", "start"},
        {"activity_b", "location", "middle"},
        {"activity_c", "location", "end"}
      ]
      options = %{
        problem_type: :stn,
        temporal_constraints: true,
        default_duration: 30
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Test that the problem can be processed by the solver
      # Note: This tests the data format compatibility, not actual solving
      case Solver.validate_model(problem_data.model) do
        :ok ->
          # Model is syntactically valid
          assert true
        {:error, reason} ->
          # If validation fails, it should be for semantic reasons, not syntax
          refute String.contains?(reason, "syntax error")
      end

      # Verify STN constraint structure
      assert String.contains?(problem_data.model, "constraints = [|")
      assert String.contains?(problem_data.model, "num_constraints = 2")  # 3 activities = 2 precedence constraints
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
      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        default_duration: 25
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify makespan optimization objective
      assert String.contains?(problem_data.model, "solve minimize makespan")
      assert String.contains?(problem_data.model, "makespan = max(end_times)")

      # Check that all jobs have proper durations
      assert String.contains?(problem_data.model, "durations = [25, 25, 25, 25]")

      # Verify temporal constraints for sequential execution
      assert String.contains?(problem_data.model, "num_constraints = 3")  # 4 jobs = 3 precedence constraints
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

      options = %{
        problem_type: :stn,
        temporal_ordering: true,
        default_duration: 15,
        max_makespan: 120
      }

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify complex STN structure
      assert String.contains?(problem_data.model, "num_activities = 4")
      assert String.contains?(problem_data.model, "num_constraints = 3")

      # Check constraint format for complex scheduling
      model_lines = String.split(problem_data.model, "\n")
      constraint_lines = Enum.filter(model_lines, fn line ->
        String.contains?(line, "1, 2, 0, 100") or
        String.contains?(line, "2, 3, 0, 100") or
        String.contains?(line, "3, 4, 0, 100")
      end)

      assert length(constraint_lines) > 0
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

      # Generate with STN template
      {:ok, stn_data} = ProblemGenerator.generate_problem(domain, state, goals, %{problem_type: :stn})

      # Both should succeed and have consistent metadata
      assert goal_solving_data.metadata.goal_count == stn_data.metadata.goal_count
      assert goal_solving_data.metadata.variable_count == stn_data.metadata.variable_count

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
      options = %{problem_type: :stn, temporal_constraints: true}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      model = problem_data.model

      # Basic MiniZinc syntax validation
      assert String.contains?(model, "int: num_activities")
      assert String.contains?(model, "set of int: ACTIVITIES")
      assert String.contains?(model, "array[ACTIVITIES] of int: durations")
      assert String.contains?(model, "constraint forall")
      assert String.contains?(model, "solve minimize")
      assert String.contains?(model, "output [")

      # Verify no obvious syntax errors
      refute String.contains?(model, "ERROR")
      refute String.contains?(model, "undefined")

      # Check proper array syntax
      assert String.contains?(model, "[|") or String.contains?(model, "durations = [")
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
      options = %{problem_type: :stn}

      # Should not crash, even with unusual goals
      result = ProblemGenerator.generate_problem(domain, state, goals, options)

      case result do
        {:ok, problem_data} ->
          # If it succeeds, should produce valid STN structure
          assert String.contains?(problem_data.model, "STN Temporal Scheduling Problem")
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
      options = %{problem_type: :stn, default_duration: 40}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Verify all required STN elements are present
      model = problem_data.model

      # Required declarations
      assert String.contains?(model, "int: num_activities")
      assert String.contains?(model, "int: num_constraints")
      assert String.contains?(model, "set of int: ACTIVITIES")

      # Required arrays
      assert String.contains?(model, "array[ACTIVITIES] of int: durations")
      assert String.contains?(model, "array[ACTIVITIES] of var 0..1000: start_times")
      assert String.contains?(model, "array[ACTIVITIES] of var 0..1000: end_times")

      # Required constraints
      assert String.contains?(model, "constraint forall(i in ACTIVITIES)")
      assert String.contains?(model, "end_times[i] = start_times[i] + durations[i]")

      # Required objective and output
      assert String.contains?(model, "solve minimize makespan")
      assert String.contains?(model, "output [")
    end

    test "handles empty STN problems correctly" do
      domain = %{name: "empty_test"}
      state = %{entities: []}
      goals = []
      options = %{problem_type: :stn}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should generate valid empty STN model
      assert String.contains?(problem_data.model, "num_activities = 0")
      assert String.contains?(problem_data.model, "num_constraints = 0")

      # Should still have proper STN structure
      assert String.contains?(problem_data.model, "STN Temporal Scheduling Problem")
      assert String.contains?(problem_data.model, "solve minimize makespan")

      # Metadata should reflect empty problem
      assert problem_data.metadata.goal_count == 0
      assert problem_data.metadata.variable_count == 0
    end
  end
end
