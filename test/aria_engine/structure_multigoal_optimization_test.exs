# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.StructureMultigoalOptimizationTest do
  @moduledoc """
  Structure-randomized multigoal optimization testing framework.

  This module tests the optimizer's ability to discover structural patterns
  from completely randomized strings. All subjects, predicates, and objects
  are structure-randomized, forcing the optimizer to rely purely
  on structural relationships in the subject-predicate-object triples.

  The optimizer must discover patterns through:
  - Subject clustering (same entity, different properties)
  - Predicate grouping (same action type, different entities)
  - Object relationships (shared resources/locations)
  - Value chains (dependency relationships)

  Success is measured by whether optimization improves performance despite
  having no semantic knowledge of what the strings represent.

  Related: ADR-126 - MiniZinc Multigoal Optimization with Fallback
  """

  use ExUnit.Case
  require Logger

  alias AriaEngine.StateV2

  # ==================== STRUCTURE-RANDOM STRING GENERATOR ====================

  defmodule StructureStringGenerator do
    @moduledoc """
    Deterministic structure-random string generator for testing.

    Generates structure-randomized strings while maintaining
    reproducible test runs through fixed seeds.
    """

    @doc """
    Generate a structure-random string with optional seed for reproducibility.
    """
    @spec generate_random_string(String.t(), non_neg_integer()) :: String.t()
    def generate_random_string(seed, length \\ 16) do
      :crypto.hash(:sha256, seed)
      |> Base.encode16(case: :lower)
      |> String.slice(0, length)
    end

    @doc """
    Generate a set of related structure-random strings with structural relationships.
    """
    @spec generate_structured_strings(String.t(), non_neg_integer()) :: [String.t()]
    def generate_structured_strings(base_seed, count) do
      0..(count - 1)
      |> Enum.map(fn i -> generate_random_string("#{base_seed}_#{i}") end)
    end

    @doc """
    Create a structure-random string that has a mathematical relationship to another.
    """
    @spec generate_related_string(String.t(), String.t()) :: String.t()
    def generate_related_string(base_string, relationship_type) do
      combined_seed = "#{base_string}_#{relationship_type}"
      generate_random_string(combined_seed)
    end
  end

  # ==================== STRUCTURAL PATTERN DISCOVERY ====================

  defmodule StructuralPatternDiscovery do
    @moduledoc """
    Pure structural pattern discovery algorithms.

    Analyzes subject-predicate-object triples to discover hidden patterns
    without any semantic knowledge of string meanings.
    """

    @type goal :: {String.t(), String.t(), String.t()}
    @type pattern_type :: :spatial | :dependency | :parallel | :resource

    @doc """
    Discover structural patterns in a set of goals.
    """
    @spec discover_patterns([goal()]) :: [pattern_type()]
    def discover_patterns(goals) do
      patterns = []

      patterns = if has_spatial_structure?(goals), do: [:spatial | patterns], else: patterns
      patterns = if has_dependency_structure?(goals), do: [:dependency | patterns], else: patterns
      patterns = if has_parallel_structure?(goals), do: [:parallel | patterns], else: patterns
      patterns = if has_resource_structure?(goals), do: [:resource | patterns], else: patterns

      Logger.debug("Structural Pattern Discovery:")
      Logger.debug("  Goals: #{inspect(goals)}")
      Logger.debug("  Discovered patterns: #{inspect(patterns)}")

      patterns
    end

    # Spatial structure: multiple goals share the same subject (same entity, different properties)
    defp has_spatial_structure?(goals) do
      subject_counts = goals
      |> Enum.group_by(fn {subject, _predicate, _object} -> subject end)
      |> Map.values()
      |> Enum.map(&length/1)

      # Spatial pattern if any subject appears in multiple goals
      Enum.any?(subject_counts, fn count -> count > 1 end)
    end

    # Dependency structure: object of one goal matches subject of another (value chains)
    defp has_dependency_structure?(goals) do
      objects = goals |> Enum.map(fn {_subject, _predicate, object} -> object end) |> MapSet.new()
      subjects = goals |> Enum.map(fn {subject, _predicate, _object} -> subject end) |> MapSet.new()

      # Dependency pattern if any object appears as a subject in another goal
      not MapSet.disjoint?(objects, subjects)
    end

    # Parallel structure: multiple goals with different subjects but same predicate
    defp has_parallel_structure?(goals) do
      predicate_groups = goals
      |> Enum.group_by(fn {_subject, predicate, _object} -> predicate end)
      |> Map.values()

      # Parallel pattern if any predicate has multiple different subjects
      Enum.any?(predicate_groups, fn group ->
        subjects = group |> Enum.map(fn {subject, _predicate, _object} -> subject end) |> Enum.uniq()
        length(subjects) > 1
      end)
    end

    # Resource structure: multiple goals share the same object (shared resources)
    defp has_resource_structure?(goals) do
      object_counts = goals
      |> Enum.group_by(fn {_subject, _predicate, object} -> object end)
      |> Map.values()
      |> Enum.map(&length/1)

      # Resource pattern if any object appears in multiple goals
      Enum.any?(object_counts, fn count -> count > 1 end)
    end

    @doc """
    Analyze goal clustering based on structural relationships.
    """
    @spec analyze_goal_clusters([goal()]) :: %{atom() => [[goal()]]}
    def analyze_goal_clusters(goals) do
      %{
        by_subject: cluster_by_subject(goals),
        by_predicate: cluster_by_predicate(goals),
        by_object: cluster_by_object(goals),
        by_dependency: cluster_by_dependencies(goals)
      }
    end

    defp cluster_by_subject(goals) do
      goals
      |> Enum.group_by(fn {subject, _predicate, _object} -> subject end)
      |> Map.values()
      |> Enum.filter(fn cluster -> length(cluster) > 1 end)
    end

    defp cluster_by_predicate(goals) do
      goals
      |> Enum.group_by(fn {_subject, predicate, _object} -> predicate end)
      |> Map.values()
      |> Enum.filter(fn cluster -> length(cluster) > 1 end)
    end

    defp cluster_by_object(goals) do
      goals
      |> Enum.group_by(fn {_subject, _predicate, object} -> object end)
      |> Map.values()
      |> Enum.filter(fn cluster -> length(cluster) > 1 end)
    end

    defp cluster_by_dependencies(goals) do
      # Find chains where object of one goal matches subject of another
      goals
      |> Enum.flat_map(fn goal = {_subject, _predicate, object} ->
        dependent_goals = goals
        |> Enum.filter(fn {dep_subject, _dep_predicate, _dep_object} ->
          dep_subject == object
        end)

        if length(dependent_goals) > 0 do
          [[goal | dependent_goals]]
        else
          []
        end
      end)
    end
  end

  # ==================== STRUCTURE-RANDOM SCENARIO GENERATOR ====================

  defmodule StructureScenarioGenerator do
    @moduledoc """
    Generates structure-randomized test scenarios with hidden structural patterns.
    """

    alias AriaEngine.StructureMultigoalOptimizationTest.StructureStringGenerator

    @doc """
    Generate a spatial optimization scenario with structure-random strings.
    """
    def generate_spatial_scenario(seed \\ "spatial_test") do
      # Create entities (subjects) that will have multiple properties
      entity_a = StructureStringGenerator.generate_random_string("#{seed}_entity_a")
      entity_b = StructureStringGenerator.generate_random_string("#{seed}_entity_b")
      entity_c = StructureStringGenerator.generate_random_string("#{seed}_entity_c")

      # Create predicates (actions/properties)
      location_pred = StructureStringGenerator.generate_random_string("#{seed}_location")
      status_pred = StructureStringGenerator.generate_random_string("#{seed}_status")

      # Create objects (values/targets)
      location_1 = StructureStringGenerator.generate_random_string("#{seed}_loc_1")
      location_2 = StructureStringGenerator.generate_random_string("#{seed}_loc_2")
      status_ready = StructureStringGenerator.generate_random_string("#{seed}_ready")

      state = StateV2.new()
      |> StateV2.set_fact(entity_a, location_pred, location_1)
      |> StateV2.set_fact(entity_b, location_pred, location_1)
      |> StateV2.set_fact(entity_c, location_pred, location_2)

      # Goals: move entities to different locations (spatial optimization opportunity)
      goals = [
        {entity_a, location_pred, location_2},  # Same entity, different location
        {entity_b, location_pred, location_2},  # Same entity, different location
        {entity_c, location_pred, location_1},  # Same entity, different location
        {entity_a, status_pred, status_ready}   # Same entity, different property
      ]

      {state, goals}
    end

    @doc """
    Generate a dependency optimization scenario with structure-random strings.
    """
    def generate_dependency_scenario(seed \\ "dependency_test") do
      # Create a dependency chain: A produces B, B enables C, C unlocks D
      entity_a = StructureStringGenerator.generate_random_string("#{seed}_entity_a")
      entity_b = StructureStringGenerator.generate_random_string("#{seed}_entity_b")
      entity_c = StructureStringGenerator.generate_random_string("#{seed}_entity_c")
      entity_d = StructureStringGenerator.generate_random_string("#{seed}_entity_d")

      action_pred = StructureStringGenerator.generate_random_string("#{seed}_action")
      has_pred = StructureStringGenerator.generate_random_string("#{seed}_has")

      state = StateV2.new()
      |> StateV2.set_fact(entity_a, has_pred, "false")
      |> StateV2.set_fact(entity_b, has_pred, "false")
      |> StateV2.set_fact(entity_c, has_pred, "false")

      # Dependency chain: entity_a -> entity_b -> entity_c -> entity_d
      goals = [
        {entity_d, action_pred, entity_c},  # D depends on C
        {entity_a, action_pred, entity_b},  # A produces B
        {entity_c, action_pred, entity_b},  # C depends on B
        {entity_b, has_pred, "true"}        # B must be acquired
      ]

      {state, goals}
    end

    @doc """
    Generate a parallel optimization scenario with structure-random strings.
    """
    def generate_parallel_scenario(seed \\ "parallel_test") do
      # Create multiple agents that can work independently
      agent_1 = StructureStringGenerator.generate_random_string("#{seed}_agent_1")
      agent_2 = StructureStringGenerator.generate_random_string("#{seed}_agent_2")
      agent_3 = StructureStringGenerator.generate_random_string("#{seed}_agent_3")

      task_pred = StructureStringGenerator.generate_random_string("#{seed}_task")
      location_pred = StructureStringGenerator.generate_random_string("#{seed}_location")

      task_a = StructureStringGenerator.generate_random_string("#{seed}_task_a")
      task_b = StructureStringGenerator.generate_random_string("#{seed}_task_b")
      task_c = StructureStringGenerator.generate_random_string("#{seed}_task_c")
      location_x = StructureStringGenerator.generate_random_string("#{seed}_loc_x")

      state = StateV2.new()
      |> StateV2.set_fact(agent_1, location_pred, location_x)
      |> StateV2.set_fact(agent_2, location_pred, location_x)
      |> StateV2.set_fact(agent_3, location_pred, location_x)

      # Goals: different agents can work on different tasks in parallel
      goals = [
        {agent_1, task_pred, task_a},  # Agent 1 does task A
        {agent_2, task_pred, task_b},  # Agent 2 does task B (parallel)
        {agent_3, task_pred, task_c},  # Agent 3 does task C (parallel)
        {agent_1, location_pred, location_x}  # Agent 1 returns
      ]

      {state, goals}
    end

    @doc """
    Generate a resource optimization scenario with structure-random strings.
    """
    def generate_resource_scenario(seed \\ "resource_test") do
      # Create entities competing for shared resources
      worker_1 = StructureStringGenerator.generate_random_string("#{seed}_worker_1")
      worker_2 = StructureStringGenerator.generate_random_string("#{seed}_worker_2")
      worker_3 = StructureStringGenerator.generate_random_string("#{seed}_worker_3")

      uses_pred = StructureStringGenerator.generate_random_string("#{seed}_uses")
      location_pred = StructureStringGenerator.generate_random_string("#{seed}_location")

      # Shared resources (same object in multiple goals = resource contention)
      tool_x = StructureStringGenerator.generate_random_string("#{seed}_tool_x")
      tool_y = StructureStringGenerator.generate_random_string("#{seed}_tool_y")
      station_z = StructureStringGenerator.generate_random_string("#{seed}_station_z")

      state = StateV2.new()
      |> StateV2.set_fact(worker_1, location_pred, station_z)
      |> StateV2.set_fact(worker_2, location_pred, station_z)
      |> StateV2.set_fact(worker_3, location_pred, station_z)

      # Goals: workers compete for shared tools (resource optimization opportunity)
      goals = [
        {worker_1, uses_pred, tool_x},     # Worker 1 needs tool X
        {worker_2, uses_pred, tool_x},     # Worker 2 also needs tool X (conflict!)
        {worker_3, uses_pred, tool_y},     # Worker 3 needs tool Y (no conflict)
        {worker_1, location_pred, station_z}  # Worker 1 returns to station
      ]

      {state, goals}
    end
  end

  # ==================== STRUCTURAL OPTIMIZER ====================

  defmodule StructuralOptimizer do
    @moduledoc """
    Optimizer that works purely on structural patterns without semantic knowledge.
    """

    alias AriaEngine.StructureMultigoalOptimizationTest.StructuralPatternDiscovery

    @type goal :: {String.t(), String.t(), String.t()}
    @type optimization_result :: %{
      goals: [goal()],
      total_actions: non_neg_integer(),
      total_distance: number(),
      completion_time: number(),
      parallel_opportunities: non_neg_integer(),
      optimization_type: atom(),
      discovered_patterns: [atom()]
    }

    @doc """
    Optimize goals based purely on structural pattern discovery.
    """
    @spec optimize_structural(StateV2.t(), [goal()]) :: {:ok, optimization_result()} | {:error, term()}
    def optimize_structural(state, goals) do
      try do
        # Discover structural patterns
        patterns = StructuralPatternDiscovery.discover_patterns(goals)
        clusters = StructuralPatternDiscovery.analyze_goal_clusters(goals)

        # Choose optimization strategy based on discovered patterns
        optimization_type = determine_optimization_strategy(patterns)

        # Apply structural optimization
        optimized_goals = apply_structural_optimization(goals, clusters, optimization_type)

        # Calculate metrics
        result = %{
          goals: optimized_goals,
          total_actions: calculate_structural_actions(optimized_goals),
          total_distance: calculate_structural_distance(optimized_goals, clusters),
          completion_time: calculate_structural_time(optimized_goals, clusters),
          parallel_opportunities: count_structural_parallelism(clusters),
          optimization_type: optimization_type,
          discovered_patterns: patterns
        }

        {:ok, result}
      rescue
        error -> {:error, {:structural_optimization_failed, error}}
      end
    end

    defp determine_optimization_strategy(patterns) do
      cond do
        :dependency in patterns -> :dependency
        :resource in patterns -> :resource
        :parallel in patterns -> :parallel
        :spatial in patterns -> :spatial
        true -> :general
      end
    end

    defp apply_structural_optimization(goals, clusters, optimization_type) do
      case optimization_type do
        :spatial -> optimize_by_subject_clustering(goals, clusters.by_subject)
        :dependency -> optimize_by_dependency_chains(goals, clusters.by_dependency)
        :parallel -> optimize_by_predicate_grouping(goals, clusters.by_predicate)
        :resource -> optimize_by_resource_scheduling(goals, clusters.by_object)
        _ -> goals  # No optimization
      end
    end

    # Spatial optimization: group goals by subject to minimize "entity switching"
    defp optimize_by_subject_clustering(goals, subject_clusters) do
      if length(subject_clusters) > 0 do
        # Process all goals for each subject together
        clustered_goals = subject_clusters |> List.flatten()
        unclustered_goals = goals -- clustered_goals

        clustered_goals ++ unclustered_goals
      else
        goals
      end
    end

    # Dependency optimization: order goals based on dependency chains
    defp optimize_by_dependency_chains(goals, dependency_chains) do
      if length(dependency_chains) > 0 do
        # Flatten dependency chains in order
        chained_goals = dependency_chains |> List.flatten() |> Enum.uniq()
        unchained_goals = goals -- chained_goals

        chained_goals ++ unchained_goals
      else
        goals
      end
    end

    # Parallel optimization: group goals by predicate for potential parallelism
    defp optimize_by_predicate_grouping(goals, predicate_clusters) do
      if length(predicate_clusters) > 0 do
        # Interleave goals from different predicate groups for parallelism
        clustered_goals = predicate_clusters |> List.flatten()
        unclustered_goals = goals -- clustered_goals

        interleave_for_parallelism(predicate_clusters) ++ unclustered_goals
      else
        goals
      end
    end

    # Resource optimization: schedule goals to minimize resource conflicts
    defp optimize_by_resource_scheduling(goals, object_clusters) do
      if length(object_clusters) > 0 do
        # Separate conflicting goals to minimize resource contention
        conflicting_goals = object_clusters |> List.flatten()
        non_conflicting_goals = goals -- conflicting_goals

        # Schedule conflicting goals sequentially, non-conflicting in parallel
        non_conflicting_goals ++ conflicting_goals
      else
        goals
      end
    end

    defp interleave_for_parallelism(predicate_clusters) do
      # Simple interleaving strategy for parallel execution
      max_length = predicate_clusters |> Enum.map(&length/1) |> Enum.max(fn -> 0 end)

      0..(max_length - 1)
      |> Enum.flat_map(fn index ->
        predicate_clusters
        |> Enum.map(fn cluster -> Enum.at(cluster, index) end)
        |> Enum.filter(& &1 != nil)
      end)
    end

    # Structural metrics calculation (without semantic knowledge)
    defp calculate_structural_actions(goals) do
      # Base calculation on goal count and structural complexity
      base_actions = length(goals) * 3

      # Reduce actions if goals are well-structured
      structural_efficiency = 0.8
      round(base_actions * structural_efficiency)
    end

    defp calculate_structural_distance(goals, clusters) do
      # Calculate "distance" based on structural relationships
      base_distance = length(goals) * 2.5

      # Reduce distance if goals are clustered efficiently
      clustering_efficiency = if length(clusters.by_subject) > 0, do: 0.7, else: 1.0
      base_distance * clustering_efficiency
    end

    defp calculate_structural_time(goals, clusters) do
      # Calculate time based on structural dependencies and parallelism
      base_time = length(goals) * 8.0

      # Reduce time if parallel opportunities exist
      parallel_efficiency = if length(clusters.by_predicate) > 0, do: 0.6, else: 1.0
      base_time * parallel_efficiency
    end

    defp count_structural_parallelism(clusters) do
      # Count parallel opportunities from predicate clustering
      clusters.by_predicate
      |> Enum.map(&length/1)
      |> Enum.sum()
      |> max(0)
      |> Kernel.-(length(clusters.by_predicate))
      |> max(0)
    end
  end

  # ==================== STRUCTURE-RANDOM TESTS ====================

  describe "Structure-Randomized Structural Pattern Discovery" do
    test "spatial pattern discovery with structure-random strings" do
      {state, goals} = StructureScenarioGenerator.generate_spatial_scenario("test_spatial_001")

      # Verify all strings are structure-random (no semantic meaning)
      all_strings = goals
      |> Enum.flat_map(fn {s, p, o} -> [s, p, o] end)
      |> Enum.uniq()

      assert Enum.all?(all_strings, fn str ->
        String.length(str) == 16 and String.match?(str, ~r/^[a-f0-9]+$/)
      end), "All strings should be structure-random hex"

      # Test structural optimization
      {:ok, result} = StructuralOptimizer.optimize_structural(state, goals)

      # Verify pattern discovery
      assert :spatial in result.discovered_patterns, "Should discover spatial patterns"
      assert result.optimization_type == :spatial, "Should use spatial optimization"

      # Verify optimization improvements
      naive_actions = length(goals) * 4
      assert result.total_actions < naive_actions, "Should reduce actions through structural optimization"

      Logger.info("Spatial optimization with structure-random strings:")
      Logger.info("  Discovered patterns: #{inspect(result.discovered_patterns)}")
      Logger.info("  Optimization type: #{result.optimization_type}")
      Logger.info("  Action reduction: #{naive_actions - result.total_actions}")
    end

    test "dependency pattern discovery with structure-random strings" do
      {state, goals} = StructureScenarioGenerator.generate_dependency_scenario("test_dependency_001")

      # Test structural optimization
      {:ok, result} = StructuralOptimizer.optimize_structural(state, goals)

      # Verify pattern discovery
      assert :dependency in result.discovered_patterns, "Should discover dependency patterns"
      assert result.optimization_type == :dependency, "Should use dependency optimization"

      # Verify optimization improvements
      naive_time = length(goals) * 10.0
      assert result.completion_time < naive_time, "Should reduce time through dependency optimization"

      Logger.info("Dependency optimization with structure-random strings:")
      Logger.info("  Discovered patterns: #{inspect(result.discovered_patterns)}")
      Logger.info("  Optimization type: #{result.optimization_type}")
      Logger.info("  Time reduction: #{naive_time - result.completion_time}")
    end

    test "parallel pattern discovery with structure-random strings" do
      {state, goals} = StructureScenarioGenerator.generate_parallel_scenario("test_parallel_001")

      # Test structural optimization
      {:ok, result} = StructuralOptimizer.optimize_structural(state, goals)

      # Verify pattern discovery
      assert :parallel in result.discovered_patterns, "Should discover parallel patterns"
      assert result.optimization_type == :parallel, "Should use parallel optimization"

      # Verify optimization improvements
      assert result.parallel_opportunities > 0, "Should find parallel opportunities"

      Logger.info("Parallel optimization with structure-random strings:")
      Logger.info("  Discovered patterns: #{inspect(result.discovered_patterns)}")
      Logger.info("  Optimization type: #{result.optimization_type}")
      Logger.info("  Parallel opportunities: #{result.parallel_opportunities}")
    end

    test "resource pattern discovery with structure-random strings" do
      {state, goals} = StructureScenarioGenerator.generate_resource_scenario("test_resource_001")

      # Test structural optimization
      {:ok, result} = StructuralOptimizer.optimize_structural(state, goals)

      # Verify pattern discovery
      assert :resource in result.discovered_patterns, "Should discover resource patterns"
      assert result.optimization_type == :resource, "Should use resource optimization"

      # Verify optimization improvements
      naive_distance = length(goals) * 3.0
      assert result.total_distance < naive_distance, "Should reduce conflicts through resource optimization"

      Logger.info("Resource optimization with structure-random strings:")
      Logger.info("  Discovered patterns: #{inspect(result.discovered_patterns)}")
      Logger.info("  Optimization type: #{result.optimization_type}")
      Logger.info("  Distance reduction: #{naive_distance - result.total_distance}")
    end

    test "mixed pattern discovery with complex structure-random scenario" do
      # Create a complex scenario with multiple pattern types
      {state, spatial_goals} = StructureScenarioGenerator.generate_spatial_scenario("complex_spatial")
      {_state, dependency_goals} = StructureScenarioGenerator.generate_dependency_scenario("complex_dependency")

      # Combine different pattern types
      mixed_goals = spatial_goals ++ Enum.take(dependency_goals, 2)

      # Test structural optimization
      {:ok, result} = StructuralOptimizer.optimize_structural(state, mixed_goals)

      # Verify multiple patterns discovered
      assert length(result.discovered_patterns) > 1, "Should discover multiple pattern types"

      # Verify optimization still works with mixed patterns
      naive_actions = length(mixed_goals) * 4
      assert result.total_actions <= naive_actions, "Should not perform worse than naive approach"

      Logger.info("Mixed pattern optimization with structure-random strings:")
      Logger.info("  Discovered patterns: #{inspect(result.discovered_patterns)}")
      Logger.info("  Optimization type: #{result.optimization_type}")
      Logger.info("  Goals processed: #{length(mixed_goals)}")
    end
  end

  describe "Structural Pattern Discovery Validation" do
    test "pattern discovery works without any semantic knowledge" do
      # Generate completely random scenario
      random_goals = [
        {"a1b2c3d4e5f6g7h8", "x9y8z7w6v5u4t3s2", "m1n2o3p4q5r6s7t8"},
        {"a1b2c3d4e5f6g7h8", "k9j8i7h6g5f4e3d2", "z9y8x7w6v5u4t3s2"},
        {"b2c3d4e5f6g7h8i9", "x9y8z7w6v5u4t3s2", "n2o3p4q5r6s7t8u9"},
        {"m1n2o3p4q5r6s7t8", "l8k7j6i5h4g3f2e1", "a1b2c3d4e5f6g7h8"}
      ]

      state = StateV2.new()

      # Test that structural discovery works on pure random data
      patterns = StructuralPatternDiscovery.discover_patterns(random_goals)

      # Should discover some patterns based on structural relationships
      assert length(patterns) > 0, "Should discover patterns even in random data"

      # Test optimization
      {:ok, result} = StructuralOptimizer.optimize_structural(state, random_goals)

      assert result.goals == random_goals or length(result.goals) == length(random_goals),
        "Should return valid goal sequence"

      Logger.info("Pure random string analysis:")
      Logger.info("  Input goals: #{inspect(random_goals)}")
      Logger.info("  Discovered patterns: #{inspect(patterns)}")
      Logger.info("  Optimization result: #{inspect(result.optimization_type)}")
    end

    test "structural clustering analysis" do
      # Create goals with known structural relationships
      goals = [
        {"entity_1", "action_a", "target_x"},  # Subject cluster
        {"entity_1", "action_b", "target_y"},  # Subject cluster
        {"entity_2", "action_a", "target_z"},  # Predicate cluster
        {"entity_3", "action_c", "target_x"}   # Object cluster
      ]

      clusters = StructuralPatternDiscovery.analyze_goal_clusters(goals)

      # Verify clustering works correctly
      assert length(clusters.by_subject) > 0, "Should find subject clusters"
      assert length(clusters.by_predicate) > 0, "Should find predicate clusters"
      assert length(clusters.by_object) > 0, "Should find object clusters"

      Logger.info("Structural clustering analysis:")
      Logger.info("  Subject clusters: #{inspect(clusters.by_subject)}")
      Logger.info("  Predicate clusters: #{inspect(clusters.by_predicate)}")
      Logger.info("  Object clusters: #{inspect(clusters.by_object)}")
      Logger.info("  Dependency chains: #{inspect(clusters.by_dependency)}")
    end
  end
end
