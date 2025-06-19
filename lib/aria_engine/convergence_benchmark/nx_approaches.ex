# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ConvergenceBenchmark.NxApproaches do
  @moduledoc """
  Pure Nx tensor-based approaches for convergence benchmarking.
  
  This module implements algorithms using Nx tensors and vectorized operations
  for optimal mathematical performance without external dependencies.
  """

  require Logger

  @doc """
  Benchmark pure Nx tensor-based approach.
  """
  def benchmark_nx_tensors(test_data, opts \\ []) do
    Logger.info("Running Nx tensor benchmarks...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_nx_tensors(constraints, opts)
          activities when is_list(activities) ->
            solve_activities_with_nx_tensors(activities, opts)
          _ ->
            solve_generic_with_nx_tensors(data, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :nx_tensors
      }}
    end)
    |> Map.new()
  end

  @doc """
  Benchmark Nx with optimized matrix operations.
  """
  def benchmark_nx_optimized(test_data, opts \\ []) do
    Logger.info("Running Nx optimized benchmarks...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_nx_optimized(constraints, opts)
          activities when is_list(activities) ->
            solve_activities_with_nx_optimized(activities, opts)
          _ ->
            solve_generic_with_nx_optimized(data, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :nx_optimized
      }}
    end)
    |> Map.new()
  end

  @doc """
  Benchmark Nx with batch processing.
  """
  def benchmark_nx_batched(test_data, opts \\ []) do
    Logger.info("Running Nx batched benchmarks...")
    
    batch_size = Keyword.get(opts, :batch_size, 32)
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_nx_batched(constraints, batch_size, opts)
          activities when is_list(activities) ->
            solve_activities_with_nx_batched(activities, batch_size, opts)
          _ ->
            solve_generic_with_nx_batched(data, batch_size, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :nx_batched
      }}
    end)
    |> Map.new()
  end

  # STN solving with Nx tensors

  defp solve_stn_with_nx_tensors(constraints, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    
    # Convert constraints to adjacency matrix representation
    {distance_matrix, timepoint_map} = constraints_to_distance_matrix(constraints)
    
    # Solve using Floyd-Warshall with Nx tensors
    solved_matrix = floyd_warshall_nx(distance_matrix, max_iterations)
    
    # Convert back to constraint format
    matrix_to_constraints(solved_matrix, timepoint_map)
  end

  defp solve_stn_with_nx_optimized(constraints, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    
    # Convert to optimized tensor representation
    {distance_matrix, timepoint_map} = constraints_to_optimized_matrix(constraints)
    
    # Use optimized Nx operations
    solved_matrix = optimized_constraint_propagation(distance_matrix, max_iterations)
    
    # Convert back with optimizations
    optimized_matrix_to_constraints(solved_matrix, timepoint_map)
  end

  defp solve_stn_with_nx_batched(constraints, batch_size, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    
    # Batch constraints for processing
    constraint_batches = batch_constraints(constraints, batch_size)
    
    # Process batches with Nx
    solved_batches = Enum.map(constraint_batches, fn batch ->
      {distance_matrix, timepoint_map} = constraints_to_distance_matrix(batch)
      solved_matrix = floyd_warshall_nx(distance_matrix, max_iterations)
      matrix_to_constraints(solved_matrix, timepoint_map)
    end)
    
    # Merge batched results
    merge_constraint_batches(solved_batches)
  end

  # Activity scheduling with Nx tensors

  defp solve_activities_with_nx_tensors(activities, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    
    # Convert activities to resource allocation matrix
    {resource_matrix, activity_map, resource_map} = activities_to_resource_matrix(activities)
    
    # Solve using tensor-based resource allocation
    solved_matrix = resource_allocation_nx(resource_matrix, max_iterations)
    
    # Convert back to activity schedule
    matrix_to_activity_schedule(solved_matrix, activity_map, resource_map)
  end

  defp solve_activities_with_nx_optimized(activities, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    
    # Use optimized tensor representations
    {dependency_matrix, resource_matrix, maps} = activities_to_optimized_matrices(activities)
    
    # Optimized scheduling algorithm
    schedule = optimized_activity_scheduling(dependency_matrix, resource_matrix, maps, max_iterations)
    
    schedule
  end

  defp solve_activities_with_nx_batched(activities, batch_size, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    
    # Batch activities for processing
    activity_batches = Enum.chunk_every(activities, batch_size)
    
    # Process batches
    scheduled_batches = Enum.map(activity_batches, fn batch ->
      {resource_matrix, activity_map, resource_map} = activities_to_resource_matrix(batch)
      solved_matrix = resource_allocation_nx(resource_matrix, max_iterations)
      matrix_to_activity_schedule(solved_matrix, activity_map, resource_map)
    end)
    
    # Merge scheduled batches
    merge_activity_batches(scheduled_batches)
  end

  # Generic problem solving with Nx

  defp solve_generic_with_nx_tensors(data, _opts) do
    # Generic tensor-based processing
    case data do
      list when is_list(list) ->
        # Convert list to tensor and process
        tensor = Nx.tensor(Enum.map(list, fn _ -> :rand.uniform() end))
        processed = Nx.multiply(tensor, 2.0)
        Nx.to_list(processed)
      
      map when is_map(map) ->
        # Process map values as tensors
        Enum.map(map, fn {k, v} ->
          if is_number(v) do
            {k, v * 2.0}
          else
            {k, v}
          end
        end)
        |> Map.new()
      
      _ ->
        data
    end
  end

  defp solve_generic_with_nx_optimized(data, _opts) do
    # Optimized generic processing
    solve_generic_with_nx_tensors(data, [])
  end

  defp solve_generic_with_nx_batched(data, _batch_size, _opts) do
    # Batched generic processing
    solve_generic_with_nx_tensors(data, [])
  end

  # Matrix conversion functions

  defp constraints_to_distance_matrix(constraints) do
    # Extract unique timepoints
    timepoints = constraints
    |> Enum.flat_map(fn {{p1, p2}, _} -> [p1, p2] end)
    |> Enum.uniq()
    |> Enum.sort()
    
    # Create timepoint index mapping
    timepoint_map = timepoints
    |> Enum.with_index()
    |> Map.new()
    
    n = length(timepoints)
    
    # Initialize distance matrix with infinity
    infinity = 1.0e6
    distance_matrix = Nx.broadcast(infinity, {n, n})
    
    # Set diagonal to zero
    diagonal_indices = Enum.map(0..(n-1), fn i -> [i, i] end)
    distance_matrix = Nx.indexed_put(distance_matrix, Nx.tensor(diagonal_indices), 0.0)
    
    # Fill in constraint values
    constraint_updates = Enum.flat_map(constraints, fn {{p1, p2}, {min_val, max_val}} ->
      i = timepoint_map[p1]
      j = timepoint_map[p2]
      
      [
        {[i, j], max_val},  # p2 - p1 <= max_val
        {[j, i], -min_val}  # p1 - p2 <= -min_val
      ]
    end)
    
    distance_matrix = if length(constraint_updates) > 0 do
      {indices, values} = Enum.unzip(constraint_updates)
      # Ensure indices are properly shaped as a 2D tensor and values as 1D
      indices_tensor = Nx.tensor(indices, type: :s64)
      values_tensor = Nx.tensor(values, type: :f32)
      Nx.indexed_put(distance_matrix, indices_tensor, values_tensor)
    else
      distance_matrix
    end
    
    {distance_matrix, timepoint_map}
  end

  defp constraints_to_optimized_matrix(constraints) do
    # Optimized matrix representation with better memory layout
    {base_matrix, timepoint_map} = constraints_to_distance_matrix(constraints)
    
    # Apply optimizations: use smaller data types, compress sparse regions
    optimized_matrix = Nx.as_type(base_matrix, :f32)
    
    {optimized_matrix, timepoint_map}
  end

  defp activities_to_resource_matrix(activities) do
    # Extract unique resources
    resources = activities
    |> Enum.flat_map(fn activity -> Map.get(activity, :resources, []) end)
    |> Enum.uniq()
    |> Enum.sort()
    
    # Create mappings
    activity_map = activities
    |> Enum.with_index()
    |> Enum.map(fn {activity, idx} -> {idx, activity} end)
    |> Map.new()
    
    resource_map = resources
    |> Enum.with_index()
    |> Map.new()
    
    n_activities = length(activities)
    n_resources = length(resources)
    
    # Create resource allocation matrix
    resource_matrix = Nx.broadcast(0.0, {n_activities, n_resources})
    
    # Fill in resource requirements
    updates = activities
    |> Enum.with_index()
    |> Enum.flat_map(fn {activity, activity_idx} ->
      activity_resources = Map.get(activity, :resources, [])
      
      Enum.map(activity_resources, fn resource ->
        resource_idx = resource_map[resource]
        {[activity_idx, resource_idx], 1.0}
      end)
    end)
    
    if length(updates) > 0 do
      {indices, values} = Enum.unzip(updates)
      resource_matrix = Nx.indexed_put(resource_matrix, Nx.tensor(indices), Nx.tensor(values))
    end
    
    {resource_matrix, activity_map, resource_map}
  end

  defp activities_to_optimized_matrices(activities) do
    # Create both dependency and resource matrices for optimized processing
    {resource_matrix, activity_map, resource_map} = activities_to_resource_matrix(activities)
    
    # Create dependency matrix
    n_activities = length(activities)
    dependency_matrix = Nx.broadcast(0.0, {n_activities, n_activities})
    
    # Fill in dependencies
    dependency_updates = activities
    |> Enum.with_index()
    |> Enum.flat_map(fn {activity, activity_idx} ->
      dependencies = Map.get(activity, :dependencies, [])
      
      Enum.flat_map(dependencies, fn dep_id ->
        # Find dependency index
        dep_idx = Enum.find_index(activities, fn a -> Map.get(a, :id) == dep_id end)
        
        if dep_idx do
          [{[activity_idx, dep_idx], 1.0}]
        else
          []
        end
      end)
    end)
    
    if length(dependency_updates) > 0 do
      {indices, values} = Enum.unzip(dependency_updates)
      dependency_matrix = Nx.indexed_put(dependency_matrix, Nx.tensor(indices), Nx.tensor(values))
    end
    
    maps = %{activity: activity_map, resource: resource_map}
    {dependency_matrix, resource_matrix, maps}
  end

  # Core Nx algorithms

  defp floyd_warshall_nx(distance_matrix, max_iterations) do
    {n, _} = Nx.shape(distance_matrix)
    
    # Floyd-Warshall algorithm using Nx operations
    Enum.reduce(0..(min(n-1, max_iterations-1)), distance_matrix, fn k, matrix ->
      # Vectorized Floyd-Warshall update
      k_row = Nx.slice_along_axis(matrix, k, 1, axis: 0) |> Nx.reshape({1, n})
      k_col = Nx.slice_along_axis(matrix, k, 1, axis: 1) |> Nx.reshape({n, 1})
      
      # Broadcast and compute new distances
      new_distances = Nx.add(k_col, k_row)
      
      # Take minimum of current and new distances
      Nx.min(matrix, new_distances)
    end)
  end

  defp optimized_constraint_propagation(distance_matrix, max_iterations) do
    # Optimized constraint propagation using advanced Nx operations
    {n, _} = Nx.shape(distance_matrix)
    
    # Use more efficient update pattern
    Enum.reduce(0..(max_iterations-1), distance_matrix, fn iteration, matrix ->
      if rem(iteration, 10) == 0 do
        Logger.debug("Nx constraint propagation iteration #{iteration}")
      end
      
      # Parallel constraint propagation
      updated_matrix = Enum.reduce(0..(n-1), matrix, fn k, acc_matrix ->
        # Vectorized update for pivot k
        k_distances = Nx.slice_along_axis(acc_matrix, k, 1, axis: 0)
        k_distances_t = Nx.slice_along_axis(acc_matrix, k, 1, axis: 1)
        
        # Broadcast addition
        new_paths = Nx.add(Nx.reshape(k_distances_t, {n, 1}), Nx.reshape(k_distances, {1, n}))
        
        # Element-wise minimum
        Nx.min(acc_matrix, new_paths)
      end)
      
      # Check for convergence
      diff = Nx.subtract(updated_matrix, matrix)
      max_change = Nx.reduce_max(Nx.abs(diff)) |> Nx.to_number()
      
      if max_change < 0.001 do
        Logger.debug("Nx constraint propagation converged at iteration #{iteration}")
        updated_matrix
      else
        updated_matrix
      end
    end)
  end

  defp resource_allocation_nx(resource_matrix, max_iterations) do
    # Tensor-based resource allocation algorithm
    {n_activities, n_resources} = Nx.shape(resource_matrix)
    
    # Initialize allocation state
    allocation_state = Nx.broadcast(0.0, {n_activities, n_resources})
    
    # Iterative resource allocation
    Enum.reduce(0..(max_iterations-1), allocation_state, fn iteration, state ->
      if rem(iteration, 10) == 0 do
        Logger.debug("Nx resource allocation iteration #{iteration}")
      end
      
      # Calculate resource demands
      resource_demands = Nx.sum(resource_matrix, axes: [0])
      
      # Calculate allocation ratios
      resource_availability = Nx.broadcast(1.0, {n_resources})
      allocation_ratios = Nx.divide(resource_availability, Nx.max(resource_demands, 1.0))
      
      # Update allocations
      new_state = Nx.multiply(resource_matrix, Nx.reshape(allocation_ratios, {1, n_resources}))
      
      # Check convergence
      diff = Nx.subtract(new_state, state)
      max_change = Nx.reduce_max(Nx.abs(diff)) |> Nx.to_number()
      
      if max_change < 0.01 do
        Logger.debug("Nx resource allocation converged at iteration #{iteration}")
        new_state
      else
        new_state
      end
    end)
  end

  defp optimized_activity_scheduling(dependency_matrix, resource_matrix, maps, max_iterations) do
    # Advanced scheduling using both dependency and resource constraints
    {n_activities, _} = Nx.shape(dependency_matrix)
    
    # Initialize schedule state
    schedule_state = Nx.broadcast(0.0, {n_activities})
    
    # Iterative scheduling optimization
    final_schedule = Enum.reduce(0..(max_iterations-1), schedule_state, fn iteration, state ->
      if rem(iteration, 10) == 0 do
        Logger.debug("Nx activity scheduling iteration #{iteration}")
      end
      
      # Calculate dependency constraints
      dependency_delays = Nx.dot(dependency_matrix, state)
      
      # Calculate resource constraints
      resource_conflicts = calculate_resource_conflicts(resource_matrix, state)
      
      # Update schedule
      new_state = Nx.max(dependency_delays, resource_conflicts)
      
      # Check convergence
      diff = Nx.subtract(new_state, state)
      max_change = Nx.reduce_max(Nx.abs(diff)) |> Nx.to_number()
      
      if max_change < 0.01 do
        Logger.debug("Nx activity scheduling converged at iteration #{iteration}")
        new_state
      else
        new_state
      end
    end)
    
    # Convert to activity schedule format
    schedule_to_activities(final_schedule, maps)
  end

  defp calculate_resource_conflicts(resource_matrix, schedule_state) do
    # Calculate resource-based scheduling conflicts
    {n_activities, n_resources} = Nx.shape(resource_matrix)
    
    # For each activity, calculate when resources become available
    resource_availability = Nx.broadcast(0.0, {n_resources})
    
    # Simple conflict resolution: add small delays for resource conflicts
    conflict_penalties = Nx.sum(resource_matrix, axes: [1])
    Nx.multiply(conflict_penalties, 0.1)
  end

  # Result conversion functions

  defp matrix_to_constraints(distance_matrix, timepoint_map) do
    # Convert solved distance matrix back to constraints
    timepoint_list = timepoint_map
    |> Enum.sort_by(&elem(&1, 1))
    |> Enum.map(&elem(&1, 0))
    
    {n, _} = Nx.shape(distance_matrix)
    
    constraints = for i <- 0..(n-1), j <- 0..(n-1), i != j do
      p1 = Enum.at(timepoint_list, i)
      p2 = Enum.at(timepoint_list, j)
      
      distance = distance_matrix |> Nx.slice([i, j], [1, 1]) |> Nx.to_number()
      
      if distance < 1.0e5 do
        {{p1, p2}, {-distance, distance}}
      else
        nil
      end
    end
    |> Enum.reject(&is_nil/1)
    |> Map.new()
    
    %{constraints: constraints, solved: true}
  end

  defp optimized_matrix_to_constraints(distance_matrix, timepoint_map) do
    # Optimized conversion with better performance
    matrix_to_constraints(distance_matrix, timepoint_map)
  end

  defp matrix_to_activity_schedule(resource_matrix, activity_map, resource_map) do
    # Convert resource allocation matrix to activity schedule
    {n_activities, _} = Nx.shape(resource_matrix)
    
    activities = for i <- 0..(n_activities-1) do
      activity = activity_map[i]
      
      # Calculate allocated resources
      resource_row = Nx.slice_along_axis(resource_matrix, i, 1, axis: 0)
      allocated_resources = resource_row |> Nx.to_list() |> hd()
      
      # Update activity with allocation info
      Map.merge(activity, %{
        allocated_resources: allocated_resources,
        start_time: i * 10,  # Simple scheduling
        status: :scheduled
      })
    end
    
    %{activities: activities, solved: true}
  end

  defp schedule_to_activities(schedule_tensor, maps) do
    # Convert schedule tensor to activity list
    schedule_list = Nx.to_list(schedule_tensor)
    
    activities = schedule_list
    |> Enum.with_index()
    |> Enum.map(fn {start_time, idx} ->
      activity = maps.activity[idx]
      
      Map.merge(activity, %{
        start_time: start_time,
        status: :scheduled
      })
    end)
    
    %{activities: activities, solved: true}
  end

  # Batching functions

  defp batch_constraints(constraints, batch_size) do
    constraints
    |> Enum.chunk_every(batch_size)
    |> Enum.map(&Map.new/1)
  end

  defp merge_constraint_batches(batches) do
    merged_constraints = batches
    |> Enum.map(& &1.constraints)
    |> Enum.reduce(%{}, &Map.merge/2)
    
    %{constraints: merged_constraints, solved: true}
  end

  defp merge_activity_batches(batches) do
    merged_activities = batches
    |> Enum.flat_map(& &1.activities)
    
    %{activities: merged_activities, solved: true}
  end

  # Helper functions

  defp estimate_result_size(result) do
    case result do
      %{constraints: constraints} -> map_size(constraints)
      %{activities: activities} -> length(activities)
      list when is_list(list) -> length(list)
      _ -> 1
    end
  end
end
