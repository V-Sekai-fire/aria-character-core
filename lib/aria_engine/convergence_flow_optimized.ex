# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ConvergenceFlowOptimized do
  @moduledoc """
  High-performance convergence-based solving using optimized Flow patterns.
  
  This module implements several Flow optimization strategies:
  1. Streaming processing without intermediate materialization
  2. Smart resource-aware partitioning for activities
  3. Incremental convergence with persistent state
  4. Memory-optimized data structures
  5. Parallel resource allocation
  
  Designed to significantly outperform the baseline Flow implementation,
  especially for activity scheduling which shows the largest performance gaps.
  """

  require Logger

  @doc """
  Solve activities using high-performance streaming Flow approach.
  
  This implementation focuses on eliminating the major bottlenecks in
  activity scheduling:
  - Streaming dependency resolution
  - Resource-aware partitioning
  - Incremental conflict resolution
  - Memory-efficient processing
  """
  def solve_activities_streaming(activities, opts \\ []) do
    stages = Keyword.get(opts, :stages, System.schedulers_online())
    max_iterations = Keyword.get(opts, :max_iterations, 20)
    
    Logger.debug("Starting streaming activity solving with #{stages} stages")
    
    activities
    |> partition_by_resources(stages)
    |> solve_with_streaming_convergence(max_iterations)
    |> merge_streaming_results()
  end

  @doc """
  Solve STN constraints using optimized streaming approach.
  
  Optimized for constraint propagation and boundary condition handling.
  """
  def solve_stn_streaming(stn_data, opts \\ []) do
    stages = Keyword.get(opts, :stages, System.schedulers_online())
    max_iterations = Keyword.get(opts, :max_iterations, 15)
    
    stn_data
    |> partition_by_constraint_clusters(stages)
    |> solve_with_streaming_convergence(max_iterations)
    |> merge_streaming_results()
  end

  @doc """
  Solve activities using pipeline Flow architecture.
  
  Multi-stage pipeline with overlapped processing phases.
  """
  def solve_activities_pipeline(activities, opts \\ []) do
    stages = Keyword.get(opts, :stages, System.schedulers_online())
    
    activities
    |> Flow.from_enumerable()
    |> Flow.partition(stages: stages, key: &resource_partition_key/1)
    |> Flow.map(&preprocess_activity/1)
    |> Flow.partition(stages: stages, key: &dependency_partition_key/1)
    |> Flow.reduce(fn -> %{} end, &accumulate_schedule/2)
    |> Flow.map(&resolve_conflicts/1)
    |> Flow.partition(stages: 1)
    |> Flow.reduce(fn -> %{activities: [], conflicts: []} end, &merge_schedules/2)
    |> Enum.to_list()
    |> List.first()
  end

  @doc """
  Solve using adaptive partitioning that adjusts based on problem characteristics.
  """
  def solve_activities_adaptive(activities, opts \\ []) do
    # Analyze problem characteristics
    analysis = analyze_activity_characteristics(activities)
    
    # Determine optimal partitioning strategy
    strategy = select_partitioning_strategy(analysis)
    stages = calculate_optimal_stages(analysis, Keyword.get(opts, :stages, System.schedulers_online()))
    
    Logger.debug("Using #{strategy} partitioning with #{stages} stages")
    
    case strategy do
      :resource_based -> solve_activities_streaming(activities, Keyword.put(opts, :stages, stages))
      :dependency_based -> solve_activities_pipeline(activities, Keyword.put(opts, :stages, stages))
      :hybrid -> solve_activities_hybrid(activities, Keyword.put(opts, :stages, stages))
    end
  end

  @doc """
  Hybrid approach combining streaming and pipeline techniques.
  """
  def solve_activities_hybrid(activities, opts \\ []) do
    stages = Keyword.get(opts, :stages, System.schedulers_online())
    
    # Phase 1: Streaming resource allocation
    resource_allocated = activities
    |> Flow.from_enumerable()
    |> Flow.partition(stages: stages, key: &resource_partition_key/1)
    |> Flow.map(&allocate_resources_streaming/1)
    
    # Phase 2: Pipeline dependency resolution
    resource_allocated
    |> Flow.partition(stages: stages, key: &dependency_partition_key/1)
    |> Flow.reduce(fn -> %{schedule: [], dependencies: %{}} end, &resolve_dependencies_streaming/2)
    |> Flow.map(&finalize_schedule/1)
    |> Flow.partition(stages: 1)
    |> Flow.reduce(fn -> %{activities: []} end, &merge_final_schedules/2)
    |> Enum.to_list()
    |> List.first()
  end

  # Optimized partitioning functions

  defp partition_by_resources(activities, stages) do
    # Group activities by resource requirements to minimize conflicts
    resource_groups = activities
    |> Enum.group_by(&extract_primary_resource/1)
    |> Map.values()
    
    # Distribute resource groups across stages
    resource_groups
    |> Enum.with_index()
    |> Enum.group_by(fn {_group, index} -> rem(index, stages) end, fn {group, _} -> group end)
    |> Map.values()
    |> Enum.map(&List.flatten/1)
  end

  defp partition_by_constraint_clusters(stn_data, stages) do
    # Partition STN constraints by timepoint clusters
    case stn_data do
      %{constraints: constraints} when is_map(constraints) ->
        constraint_clusters = cluster_constraints_by_timepoints(constraints)
        distribute_clusters(constraint_clusters, stages)
      
      constraints when is_list(constraints) ->
        Enum.chunk_every(constraints, max(1, div(length(constraints), stages)))
      
      _ ->
        [stn_data]
    end
  end

  # Streaming convergence implementation

  defp solve_with_streaming_convergence(partitions, max_iterations) do
    partitions
    |> Flow.from_enumerable()
    |> Flow.partition(stages: length(partitions))
    |> Flow.map(&initialize_partition_state(&1, %{iteration: 0, converged: false, solution: nil}))
    |> stream_convergence_iterations(max_iterations, 0)
  end

  defp stream_convergence_iterations(flow, max_iterations, current_iteration) when current_iteration < max_iterations do
    # Process one convergence iteration
    updated_flow = flow
    |> Flow.map(&update_partition_streaming(&1, %{}))
    |> Flow.partition(stages: 1)
    |> Flow.reduce(fn -> %{converged: false, boundary_updates: []} end, &check_global_convergence/2)
    |> Flow.partition(stages: System.schedulers_online())
    |> Flow.map(&apply_boundary_updates(&1, %{boundary_updates: []}))
    
    # Check if we need another iteration (this would need actual convergence checking)
    # For now, we'll do a fixed number of iterations
    if current_iteration + 1 < max_iterations do
      stream_convergence_iterations(updated_flow, max_iterations, current_iteration + 1)
    else
      updated_flow
    end
  end

  defp stream_convergence_iterations(flow, _max_iterations, _current_iteration) do
    flow
  end

  # Activity processing functions

  defp preprocess_activity(activity) do
    # Extract and normalize activity data for efficient processing
    %{
      id: Map.get(activity, :id, generate_activity_id()),
      duration: Map.get(activity, :duration, 1),
      resources: extract_resources(activity),
      dependencies: extract_dependencies(activity),
      priority: Map.get(activity, :priority, 1),
      constraints: extract_constraints(activity),
      original: activity
    }
  end

  defp allocate_resources_streaming(activity) do
    # Streaming resource allocation without materializing full resource state
    allocated_resources = activity.resources
    |> Enum.reduce(%{}, fn resource, acc ->
      Map.put(acc, resource, allocate_resource_slot(resource, activity))
    end)
    
    Map.put(activity, :allocated_resources, allocated_resources)
  end

  defp resolve_dependencies_streaming(activity, acc) do
    # Incrementally resolve dependencies without full graph materialization
    resolved_deps = activity.dependencies
    |> Enum.filter(&dependency_satisfied?(&1, acc.dependencies))
    
    updated_schedule = [activity | acc.schedule]
    updated_deps = Map.put(acc.dependencies, activity.id, resolved_deps)
    
    %{schedule: updated_schedule, dependencies: updated_deps}
  end

  # Partition key functions for optimal distribution

  defp resource_partition_key(activity) do
    # Partition based on primary resource to minimize conflicts
    primary_resource = extract_primary_resource(activity)
    :erlang.phash2(primary_resource)
  end

  defp dependency_partition_key(activity) do
    # Partition based on dependency chains
    dep_hash = activity
    |> extract_dependencies()
    |> Enum.sort()
    |> :erlang.term_to_binary()
    |> :erlang.phash2()
    
    dep_hash
  end

  # Analysis and optimization functions

  def analyze_activity_characteristics(activities) do
    total_count = length(activities)
    
    resource_analysis = analyze_resource_patterns(activities)
    dependency_analysis = analyze_dependency_patterns(activities)
    complexity_analysis = analyze_complexity_patterns(activities)
    
    %{
      total_count: total_count,
      resource_contention: resource_analysis.contention_level,
      dependency_depth: dependency_analysis.max_depth,
      avg_dependencies: dependency_analysis.avg_dependencies,
      complexity_score: complexity_analysis.score,
      resource_diversity: resource_analysis.diversity
    }
  end

  defp select_partitioning_strategy(analysis) do
    cond do
      analysis.resource_contention > 0.7 -> :resource_based
      analysis.dependency_depth > 5 -> :dependency_based
      analysis.complexity_score > 0.8 -> :hybrid
      true -> :resource_based
    end
  end

  defp calculate_optimal_stages(analysis, default_stages) do
    # Calculate optimal number of stages based on problem characteristics
    base_stages = default_stages
    
    # Adjust based on complexity
    complexity_multiplier = case analysis.complexity_score do
      score when score > 0.8 -> 1.5
      score when score > 0.5 -> 1.2
      _ -> 1.0
    end
    
    # Adjust based on size
    size_multiplier = case analysis.total_count do
      count when count > 1000 -> 2.0
      count when count > 500 -> 1.5
      count when count > 100 -> 1.2
      _ -> 1.0
    end
    
    optimal = round(base_stages * complexity_multiplier * size_multiplier)
    max(1, min(optimal, System.schedulers_online() * 2))
  end

  # Helper functions for resource and dependency analysis

  defp analyze_resource_patterns(activities) do
    all_resources = activities
    |> Enum.flat_map(&extract_resources/1)
    |> Enum.frequencies()
    
    total_resources = map_size(all_resources)
    max_contention = if total_resources > 0, do: Enum.max(Map.values(all_resources)), else: 0
    avg_contention = if total_resources > 0, do: Enum.sum(Map.values(all_resources)) / total_resources, else: 0
    
    %{
      diversity: total_resources,
      contention_level: if(length(activities) > 0, do: max_contention / length(activities), else: 0),
      avg_contention: avg_contention
    }
  end

  defp analyze_dependency_patterns(activities) do
    all_deps = activities
    |> Enum.map(&extract_dependencies/1)
    
    max_depth = all_deps
    |> Enum.map(&length/1)
    |> Enum.max(fn -> 0 end)
    
    avg_deps = if length(activities) > 0 do
      total_deps = all_deps |> Enum.map(&length/1) |> Enum.sum()
      total_deps / length(activities)
    else
      0
    end
    
    %{
      max_depth: max_depth,
      avg_dependencies: avg_deps
    }
  end

  defp analyze_complexity_patterns(activities) do
    # Calculate overall complexity score based on various factors
    resource_complexity = activities
    |> Enum.map(fn activity -> length(extract_resources(activity)) end)
    |> Enum.sum()
    
    dependency_complexity = activities
    |> Enum.map(fn activity -> length(extract_dependencies(activity)) end)
    |> Enum.sum()
    
    total_complexity = resource_complexity + dependency_complexity
    max_possible = length(activities) * 10  # Assume max 10 resources + deps per activity
    
    score = if max_possible > 0, do: total_complexity / max_possible, else: 0
    
    %{score: min(score, 1.0)}
  end

  # State management functions

  defp initialize_partition_state(partition, _state) do
    %{
      iteration: 0,
      converged: false,
      solution: solve_partition_initial(partition),
      boundary_conditions: extract_boundary_conditions(partition)
    }
  end

  defp update_partition_streaming(partition_state, _state) do
    # Update partition solution based on current state and boundary conditions
    current_solution = Map.get(partition_state, :solution, %{})
    boundary_conditions = Map.get(partition_state, :boundary_conditions, %{})
    updated_solution = update_solution_incremental(current_solution, boundary_conditions)
    
    %{partition_state | 
      iteration: Map.get(partition_state, :iteration, 0) + 1,
      solution: updated_solution,
      converged: check_partition_convergence(current_solution, updated_solution)
    }
  end

  defp check_global_convergence(partition_state, acc) do
    boundary_update = extract_boundary_update(partition_state)
    
    %{
      converged: acc.converged and partition_state.converged,
      boundary_updates: [boundary_update | acc.boundary_updates]
    }
  end

  defp apply_boundary_updates(partition_state, global_state) do
    # Apply boundary updates from other partitions
    relevant_updates = global_state.boundary_updates
    |> Enum.filter(&affects_partition?(&1, partition_state))
    
    updated_boundaries = apply_updates_to_boundaries(partition_state.boundary_conditions, relevant_updates)
    
    %{partition_state | boundary_conditions: updated_boundaries}
  end

  # Merge and finalization functions

  defp merge_streaming_results(flow) do
    flow
    |> Flow.partition(stages: 1)
    |> Flow.reduce(fn -> %{activities: [], metadata: %{}} end, &merge_partition_results/2)
    |> Enum.to_list()
    |> List.first()
  end

  defp merge_partition_results(partition_state, acc) do
    activities = extract_activities_from_solution(partition_state.solution)
    
    %{
      activities: activities ++ acc.activities,
      metadata: Map.merge(acc.metadata, %{
        partitions_processed: Map.get(acc.metadata, :partitions_processed, 0) + 1,
        total_iterations: Map.get(acc.metadata, :total_iterations, 0) + partition_state.iteration
      })
    }
  end

  # Placeholder implementations for core solving functions
  # These would be replaced with actual algorithm implementations

  defp extract_primary_resource(activity) do
    resources = extract_resources(activity)
    List.first(resources) || :default_resource
  end

  defp extract_resources(activity) do
    case activity do
      %{resources: resources} when is_list(resources) -> resources
      %{resource: resource} -> [resource]
      _ -> [:default_resource]
    end
  end

  defp extract_dependencies(activity) do
    case activity do
      %{dependencies: deps} when is_list(deps) -> deps
      %{depends_on: deps} when is_list(deps) -> deps
      %{depends_on: dep} -> [dep]
      _ -> []
    end
  end

  defp extract_constraints(activity) do
    Map.get(activity, :constraints, [])
  end

  defp generate_activity_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16()
  end

  defp allocate_resource_slot(resource, _activity) do
    # Placeholder: Implement actual resource allocation
    %{resource: resource, allocated: true, slot: :crypto.strong_rand_bytes(4) |> Base.encode16()}
  end

  defp dependency_satisfied?(_dependency, _resolved_deps) do
    # Placeholder: Check if dependency is satisfied
    true
  end

  defp cluster_constraints_by_timepoints(constraints) do
    # Placeholder: Cluster constraints by shared timepoints
    constraints |> Enum.chunk_every(10)
  end

  defp distribute_clusters(clusters, stages) do
    # Distribute constraint clusters across stages
    clusters |> Enum.chunk_every(max(1, div(length(clusters), stages)))
  end

  defp solve_partition_initial(partition) do
    # Placeholder: Initial partition solving
    %{partition: partition, solved: true, activities: partition}
  end

  defp extract_boundary_conditions(_partition) do
    # Placeholder: Extract boundary conditions
    %{}
  end

  defp update_solution_incremental(solution, _boundary_conditions) do
    # Placeholder: Update solution incrementally
    solution
  end

  defp check_partition_convergence(_old_solution, _new_solution) do
    # Placeholder: Check if partition has converged
    true
  end

  defp extract_boundary_update(_partition_state) do
    # Placeholder: Extract boundary update for sharing
    %{}
  end

  defp affects_partition?(_update, _partition_state) do
    # Placeholder: Check if update affects this partition
    false
  end

  defp apply_updates_to_boundaries(boundaries, _updates) do
    # Placeholder: Apply boundary updates
    boundaries
  end

  defp extract_activities_from_solution(solution) do
    case solution do
      %{activities: activities} -> activities
      %{partition: activities} when is_list(activities) -> activities
      activities when is_list(activities) -> activities
      _ -> []
    end
  end

  # Additional optimization functions

  defp accumulate_schedule(activity, acc) do
    Map.update(acc, :activities, [activity], &[activity | &1])
  end

  defp resolve_conflicts(schedule_acc) do
    # Placeholder: Resolve scheduling conflicts
    schedule_acc
  end

  defp merge_schedules(schedule, acc) do
    %{
      activities: schedule.activities ++ acc.activities,
      conflicts: Map.get(schedule, :conflicts, []) ++ acc.conflicts
    }
  end

  defp finalize_schedule(schedule_state) do
    # Placeholder: Finalize schedule
    schedule_state
  end

  defp merge_final_schedules(schedule, acc) do
    %{activities: schedule.activities ++ acc.activities}
  end
end
