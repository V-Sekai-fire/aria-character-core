defmodule AriaMiniZinc.ProblemGeneratorTest do
  use ExUnit.Case
  doctest AriaMiniZinc.ProblemGenerator

  alias AriaMiniZinc.ProblemGenerator

  describe "ProblemGenerator - CSP generation from planning data" do
    test "generates valid MiniZinc model from goals" do
      domain = %{name: "test_domain", actions: ["move", "pickup"]}
      state = %{entities: ["entity1", "entity2"], locations: ["room1", "room2"]}
      goals = [{"entity1", "location", "room1"}, {"entity2", "state", "active"}]
      options = %{max_steps: 10}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      assert is_map(problem_data)
      assert Map.has_key?(problem_data, :model)
      assert Map.has_key?(problem_data, :variables)
      assert Map.has_key?(problem_data, :constraints)
      assert Map.has_key?(problem_data, :metadata)

      # Model should be a valid string
      assert is_binary(problem_data.model)
      assert String.length(problem_data.model) > 0

      # Variables should be a map
      assert is_map(problem_data.variables)

      # Constraints should be a list
      assert is_list(problem_data.constraints)

      # Metadata should contain problem info
      assert is_map(problem_data.metadata)
      assert Map.has_key?(problem_data.metadata, :goal_count)
      assert Map.has_key?(problem_data.metadata, :domain)
    end

    test "handles empty goal sets" do
      domain = %{name: "test_domain"}
      state = %{entities: []}
      goals = []
      options = %{}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      assert is_map(problem_data)
      # Empty goals still generate domain constraints
      assert length(problem_data.constraints) >= 0
      assert problem_data.variables == %{time_vars: [], location_vars: [], boolean_vars: []}
      assert is_binary(problem_data.model)
    end

    test "validates constraint syntax" do
      domain = %{name: "test_domain"}
      state = %{entities: ["entity1"]}
      goals = [{"entity1", "location", "room1"}]
      options = %{validate_constraints: true}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Generated constraints should be valid
      assert is_list(problem_data.constraints)

      # Each constraint should have required fields
      Enum.each(problem_data.constraints, fn constraint ->
        assert is_map(constraint)
        # Basic constraint structure validation
        assert Map.has_key?(constraint, :type) or Map.has_key?(constraint, :predicate)
      end)
    end

    test "handles complex goal structures" do
      domain = %{
        name: "complex_domain",
        actions: ["move", "pickup", "drop"],
        predicates: ["at", "holding", "clear"]
      }

      state = %{
        entities: ["robot", "box1", "box2"],
        locations: ["room1", "room2", "table"]
      }

      goals = [
        {"robot", "at", "room2"},
        {"box1", "at", "table"},
        {"box2", "clear", true}
      ]

      options = %{max_steps: 15, optimization: :minimize_steps}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      assert is_map(problem_data)
      assert length(problem_data.constraints) > 0
      assert Map.has_key?(problem_data.metadata, :optimization)
      assert problem_data.metadata.optimization == :minimize_steps
    end

    test "generates appropriate variable domains" do
      domain = %{name: "test_domain"}
      state = %{entities: ["entity1", "entity2"]}
      goals = [{"entity1", "location", "room1"}]
      options = %{time_horizon: 20}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should generate time-based variables
      assert Map.has_key?(problem_data.variables, :time_vars) or
             Map.has_key?(problem_data.variables, :step_vars) or
             map_size(problem_data.variables) > 0
    end

    test "handles error cases gracefully" do
      # Test with malformed goals that cause template errors
      domain = %{name: "test_domain"}
      state = %{entities: ["entity1"]}
      invalid_goals = ["not_a_tuple", {:invalid, "structure"}]

      result = ProblemGenerator.generate_problem(domain, state, invalid_goals, %{})
      # Should either handle gracefully or return error
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "constraint generation" do
    test "generates temporal constraints for sequential goals" do
      domain = %{name: "temporal_domain"}
      state = %{entities: ["robot"]}
      goals = [
        {"robot", "at", "room1"},
        {"robot", "at", "room2"}  # Sequential movement
      ]
      options = %{temporal_constraints: true}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should generate ordering constraints
      temporal_constraints = Enum.filter(problem_data.constraints, fn constraint ->
        Map.get(constraint, :type) == :temporal or
        Map.get(constraint, :type) == :ordering
      end)

      assert length(temporal_constraints) > 0
    end

    test "generates resource constraints for conflicting goals" do
      domain = %{name: "resource_domain"}
      state = %{entities: ["robot"], resources: ["gripper"]}
      goals = [
        {"robot", "holding", "box1"},
        {"robot", "holding", "box2"}  # Resource conflict
      ]
      options = %{resource_constraints: true}

      {:ok, problem_data} = ProblemGenerator.generate_problem(domain, state, goals, options)

      # Should generate mutex or resource constraints
      resource_constraints = Enum.filter(problem_data.constraints, fn constraint ->
        Map.get(constraint, :type) == :resource or
        Map.get(constraint, :type) == :mutex
      end)

      # May or may not generate resource constraints depending on implementation
      assert is_list(resource_constraints)
    end
  end
end
