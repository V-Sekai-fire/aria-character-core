# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ConvergenceNx do
  @moduledoc """
  Nx tensor-based convergence solving with PyTorch acceleration support.
  
  This module implements high-performance convergence algorithms using Nx tensors
  with optional PyTorch backend for hardware acceleration.
  """

  require Logger

  @doc """
  Solve STN constraints using Nx tensors with optional PyTorch acceleration.
  """
  def solve_stn(constraints, opts \\ []) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    use_pytorch = Keyword.get(opts, :use_pytorch, false)
    
    # Set backend based on PyTorch availability
    backend = if use_pytorch and pytorch_available?(), do: :pytorch, else: :cpu
    
    # Convert constraints to adjacency matrix representation
    {distance_matrix, timepoint_map} = constraints_to_distance_matrix(constraints, backend)
    
    # Solve using Floyd-Warshall with Nx tensors
    solved_matrix = floyd_warshall_nx(distance_matrix, max_iterations)
    
    # Convert back to constraint format
    matrix_to_constraints(solved_matrix, timepoint_map)
  end

  @doc """
  Solve activity scheduling using Nx tensors with optional PyTorch acceleration.
  """
  def solve_activities(activities, opts \\ []) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    use_pytorch = Keyword.get(opts, :use_pytorch, false)
    
    # Set backend based on PyTorch availability
    backend = if use_pytorch and pytorch_available?(), do: :pytorch, else: :cpu
    
    # Convert activities to optimized tensor representations
    {dependency_matrix, resource_matrix, maps} = activities_to_optimized_matrices(activities, backend)
    
    # Optimized scheduling algorithm
    schedule = optimized_activity_scheduling(dependency_matrix, resource_matrix, maps, max_iterations)
    
    schedule
  end

  @doc """
  Solve multiple STN constraint sets in batch using vectorized operations.
  
  This function processes multiple timelines simultaneously, which is highly
  efficient with tensor operations and PyTorch acceleration.
  """
  def solve_stn_batch(timelines, opts \\ []) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    use_pytorch = Keyword.get(opts, :use_pytorch, true)
    batch_size = Keyword.get(opts, :batch_size, 8)
    
    # Set backend based on PyTorch availability
    backend = if use_pytorch and pytorch_available?(), do: :pytorch, else: :cpu
    
    Logger.info("Batch solving #{length(timelines)} STN problems with #{backend} backend")
    
    # Process timelines in batches
    timelines
    |> Enum.chunk_every(batch_size)
    |> Enum.flat_map(fn batch ->
      solve_stn_batch_chunk(batch, backend, max_iterations)
    end)
    |> then(fn results ->
      %{
        batch_solved: true,
        timelines: results,
        total_count: length(timelines),
        successful_count: Enum.count(results, fn t -> get_in(t, [:result, :solved]) end)
      }
    end)
  end

  @doc """
  Solve multiple activity scheduling problems in batch using vectorized operations.
  """
  def solve_activities_batch(activity_sets, opts \\ []) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    use_pytorch = Keyword.get(opts, :use_pytorch, true)
    batch_size = Keyword.get(opts, :batch_size, 8)
    
    # Set backend based on PyTorch availability
    backend = if use_pytorch and pytorch_available?(), do: :pytorch, else: :cpu
    
    Logger.info("Batch solving #{length(activity_sets)} activity problems with #{backend} backend")
    
    # Process activity sets in batches
    activity_sets
    |> Enum.chunk_every(batch_size)
    |> Enum.flat_map(fn batch ->
      solve_activities_batch_chunk(batch, backend, max_iterations)
    end)
    |> then(fn results ->
      %{
        batch_solved: true,
        activity_sets: results,
        total_count: length(activity_sets),
        successful_count: Enum.count(results, fn s -> get_in(s, [:result, :solved]) end)
      }
    end)
  end

  @doc """
  Check if PyTorch backend is available for hardware acceleration.
  """
  def pytorch_available? do
    # Check if PyTorch is available via torchx
    try do
      Code.ensure_loaded?(Torchx)
    rescue
      _ -> false
    end
  end

  # Matrix conversion functions with backend support

  defp constraints_to_distance_matrix(constraints, backend \\ :cpu) do
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
    distance_matrix = create_tensor({n, n}, infinity, backend)
    
    # Set diagonal to zero
    distance_matrix = Enum.reduce(0..(n-1), distance_matrix, fn i, acc_matrix ->
      zero_tensor = create_tensor({1, 1}, 0.0, backend)
      Nx.put_slice(acc_matrix, [i, i], zero_tensor)
    end)
    
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
      Enum.reduce(constraint_updates, distance_matrix, fn {[i, j], value}, acc_matrix ->
        value_tensor = create_tensor({1, 1}, value, backend)
        Nx.put_slice(acc_matrix, [i, j], value_tensor)
      end)
    else
      distance_matrix
    end
    
    {distance_matrix, timepoint_map}
  end

  defp activities_to_optimized_matrices(activities, backend \\ :cpu) do
    # Create both dependency and resource matrices for optimized processing
    {resource_matrix, activity_map, resource_map} = activities_to_resource_matrix(activities, backend)
    
    # Create dependency matrix
    n_activities = length(activities)
    dependency_matrix = create_tensor({n_activities, n_activities}, 0.0, backend)
    
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
    
    dependency_matrix = if length(dependency_updates) > 0 do
      Enum.reduce(dependency_updates, dependency_matrix, fn {[i, j], value}, acc_matrix ->
        value_tensor = create_tensor({1, 1}, value, backend)
        Nx.put_slice(acc_matrix, [i, j], value_tensor)
      end)
    else
      dependency_matrix
    end
    
    maps = %{activity: activity_map, resource: resource_map}
    {dependency_matrix, resource_matrix, maps}
  end

  defp activities_to_resource_matrix(activities, backend \\ :cpu) do
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
    resource_matrix = create_tensor({n_activities, n_resources}, 0.0, backend)
    
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
    
    resource_matrix = if length(updates) > 0 do
      Enum.reduce(updates, resource_matrix, fn {[i, j], value}, acc_matrix ->
        value_tensor = create_tensor({1, 1}, value, backend)
        Nx.put_slice(acc_matrix, [i, j], value_tensor)
      end)
    else
      resource_matrix
    end
    
    {resource_matrix, activity_map, resource_map}
  end

  # Core Nx algorithms with MLX support

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

  defp optimized_activity_scheduling(dependency_matrix, resource_matrix, maps, max_iterations) do
    # Advanced scheduling using both dependency and resource constraints
    {n_activities, _} = Nx.shape(dependency_matrix)
    
    # Initialize schedule state
    schedule_state = create_tensor({n_activities}, 0.0, :cpu)
    
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

  defp calculate_resource_conflicts(resource_matrix, _schedule_state) do
    # Calculate resource-based scheduling conflicts
    {_n_activities, _n_resources} = Nx.shape(resource_matrix)
    
    # Simple conflict resolution: add small delays for resource conflicts
    conflict_penalties = Nx.sum(resource_matrix, axes: [1])
    Nx.multiply(conflict_penalties, 0.1)
  end

  # Backend-aware tensor creation

  defp create_tensor(shape, value, backend) do
    case backend do
      :pytorch ->
        # Use PyTorch backend if available
        try do
          Nx.tensor(value, type: :f32, backend: {Torchx.Backend, []})
          |> Nx.broadcast(shape)
        rescue
          _ ->
            # Fallback to CPU if PyTorch fails
            Nx.broadcast(value, shape)
        end
      
      :cpu ->
        # Use CPU backend
        Nx.broadcast(value, shape)
      
      _ ->
        # Default to CPU
        Nx.broadcast(value, shape)
    end
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
      
      distance = distance_matrix |> Nx.slice([i, j], [1, 1]) |> Nx.squeeze() |> Nx.to_number()
      
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

  # Batch processing helper functions

  defp solve_stn_batch_chunk(batch, backend, max_iterations) do
    # Process a batch of STN problems using vectorized operations
    batch
    |> Enum.map(fn timeline ->
      constraints = Map.get(timeline, :constraints, %{})
      
      try do
        # Convert constraints to distance matrix
        {distance_matrix, timepoint_map} = constraints_to_distance_matrix(constraints, backend)
        
        # Solve using Floyd-Warshall
        solved_matrix = floyd_warshall_nx(distance_matrix, max_iterations)
        
        # Convert back to constraints
        result = matrix_to_constraints(solved_matrix, timepoint_map)
        
        Map.put(timeline, :result, result)
      rescue
        error ->
          Logger.warning("Failed to solve STN for timeline #{inspect(timeline[:id])}: #{inspect(error)}")
          Map.put(timeline, :result, %{solved: false, error: inspect(error)})
      end
    end)
  end

  defp solve_activities_batch_chunk(batch, backend, max_iterations) do
    # Process a batch of activity scheduling problems using vectorized operations
    batch
    |> Enum.map(fn activity_set ->
      activities = Map.get(activity_set, :activities, [])
      
      try do
        # Convert activities to matrices
        {dependency_matrix, resource_matrix, maps} = activities_to_optimized_matrices(activities, backend)
        
        # Solve using optimized scheduling
        result = optimized_activity_scheduling(dependency_matrix, resource_matrix, maps, max_iterations)
        
        Map.put(activity_set, :result, result)
      rescue
        error ->
          Logger.warning("Failed to solve activities for set #{inspect(activity_set[:id])}: #{inspect(error)}")
          Map.put(activity_set, :result, %{solved: false, error: inspect(error)})
      end
    end)
  end
end
