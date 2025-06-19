# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Convergence do
  @moduledoc """
  Unified convergence solving API with Flow and Nx-PyTorch backends.
  
  This module provides a clean interface for solving convergence problems
  using either Flow-based parallel processing or Nx tensor operations
  with optional PyTorch hardware acceleration.
  """

  alias AriaEngine.ConvergenceFlow
  alias AriaEngine.ConvergenceNx

  require Logger

  @doc """
  Solve STN constraints using the specified approach.
  
  ## Options
  
  - `:approach` - `:flow` or `:nx` (default: `:flow`)
  - `:use_pytorch` - Enable PyTorch acceleration for Nx approach (default: `false`)
  - `:max_iterations` - Maximum iterations for convergence (default: 100)
  
  ## Examples
  
      # Use Flow approach (default)
      Convergence.solve_stn(constraints)
      
      # Use Nx with CPU backend
      Convergence.solve_stn(constraints, approach: :nx)
      
      # Use Nx with PyTorch acceleration
      Convergence.solve_stn(constraints, approach: :nx, use_pytorch: true)
  """
  def solve_stn(constraints, opts \\ []) do
    approach = Keyword.get(opts, :approach, :flow)
    
    case approach do
      :flow ->
        ConvergenceFlow.solve_stn_with_convergence(constraints, opts)
      
      :nx ->
        ConvergenceNx.solve_stn(constraints, opts)
      
      _ ->
        Logger.warning("Unknown approach #{inspect(approach)}, falling back to Flow")
        ConvergenceFlow.solve_stn_with_convergence(constraints, opts)
    end
  end

  @doc """
  Solve activity scheduling using the specified approach.
  
  ## Options
  
  - `:approach` - `:flow` or `:nx` (default: `:flow`)
  - `:use_pytorch` - Enable PyTorch acceleration for Nx approach (default: `false`)
  - `:max_iterations` - Maximum iterations for convergence (default: 50)
  
  ## Examples
  
      # Use Flow approach (default)
      Convergence.solve_activities(activities)
      
      # Use Nx with CPU backend
      Convergence.solve_activities(activities, approach: :nx)
      
      # Use Nx with PyTorch acceleration
      Convergence.solve_activities(activities, approach: :nx, use_pytorch: true)
  """
  def solve_activities(activities, opts \\ []) do
    approach = Keyword.get(opts, :approach, :flow)
    
    case approach do
      :flow ->
        ConvergenceFlow.solve_activities_with_convergence(activities, opts)
      
      :nx ->
        ConvergenceNx.solve_activities(activities, opts)
      
      _ ->
        Logger.warning("Unknown approach #{inspect(approach)}, falling back to Flow")
        ConvergenceFlow.solve_activities_with_convergence(activities, opts)
    end
  end

  @doc """
  Solve multiple STN constraint sets in batch for improved performance.
  
  This function processes multiple timelines simultaneously using vectorized
  operations, which is particularly efficient with the Nx approach and PyTorch
  acceleration.
  
  ## Options
  
  - `:approach` - `:flow` or `:nx` (default: `:nx`)
  - `:use_pytorch` - Enable PyTorch acceleration for Nx approach (default: `true`)
  - `:max_iterations` - Maximum iterations for convergence (default: 100)
  - `:batch_size` - Maximum number of timelines to process simultaneously (default: 8)
  
  ## Examples
  
      # Batch solve multiple timelines
      timelines = [
        %{id: "npc1", constraints: constraints1},
        %{id: "npc2", constraints: constraints2},
        %{id: "npc3", constraints: constraints3}
      ]
      
      Convergence.solve_stn_batch(timelines)
      
      # Use specific batch size and PyTorch
      Convergence.solve_stn_batch(timelines, batch_size: 16, use_pytorch: true)
  """
  def solve_stn_batch(timelines, opts \\ []) do
    approach = Keyword.get(opts, :approach, :nx)
    batch_size = Keyword.get(opts, :batch_size, 8)
    
    case approach do
      :nx ->
        ConvergenceNx.solve_stn_batch(timelines, opts)
      
      :flow ->
        # For Flow approach, process in parallel chunks
        solve_stn_batch_flow(timelines, batch_size, opts)
      
      _ ->
        Logger.warning("Unknown approach #{inspect(approach)}, falling back to Nx")
        ConvergenceNx.solve_stn_batch(timelines, opts)
    end
  end

  @doc """
  Solve multiple activity scheduling problems in batch for improved performance.
  
  ## Options
  
  - `:approach` - `:flow` or `:nx` (default: `:nx`)
  - `:use_pytorch` - Enable PyTorch acceleration for Nx approach (default: `true`)
  - `:max_iterations` - Maximum iterations for convergence (default: 50)
  - `:batch_size` - Maximum number of activity sets to process simultaneously (default: 8)
  
  ## Examples
  
      # Batch solve multiple activity sets
      activity_sets = [
        %{id: "project1", activities: activities1},
        %{id: "project2", activities: activities2}
      ]
      
      Convergence.solve_activities_batch(activity_sets)
  """
  def solve_activities_batch(activity_sets, opts \\ []) do
    approach = Keyword.get(opts, :approach, :nx)
    batch_size = Keyword.get(opts, :batch_size, 8)
    
    case approach do
      :nx ->
        ConvergenceNx.solve_activities_batch(activity_sets, opts)
      
      :flow ->
        # For Flow approach, process in parallel chunks
        solve_activities_batch_flow(activity_sets, batch_size, opts)
      
      _ ->
        Logger.warning("Unknown approach #{inspect(approach)}, falling back to Nx")
        ConvergenceNx.solve_activities_batch(activity_sets, opts)
    end
  end

  @doc """
  Get information about available convergence approaches and their capabilities.
  """
  def info do
    %{
      approaches: %{
        flow: %{
          description: "Pure Elixir parallel processing with Flow library",
          strengths: ["Activity scheduling", "Consistent performance", "Large datasets"],
          backend: "CPU (Elixir processes)"
        },
        nx: %{
          description: "Tensor-based operations with optional PyTorch acceleration",
          strengths: ["STN constraints", "Mathematical precision", "Hardware acceleration"],
          backend: if(ConvergenceNx.pytorch_available?(), do: "PyTorch", else: "CPU (Nx tensors)")
        }
      },
      system: %{
        pytorch_available: ConvergenceNx.pytorch_available?(),
        architecture: get_system_architecture(),
        recommended_approach: get_recommended_approach()
      }
    }
  end

  @doc """
  Benchmark both approaches on the given problem and return performance comparison.
  """
  def benchmark(problem_type, data, opts \\ []) do
    Logger.info("Benchmarking Flow vs Nx approaches for #{problem_type}")
    
    # Benchmark Flow approach
    {flow_time_us, flow_result} = :timer.tc(fn ->
      case problem_type do
        :stn -> ConvergenceFlow.solve_stn_with_convergence(data, opts)
        :activities -> ConvergenceFlow.solve_activities_with_convergence(data, opts)
      end
    end)
    
    # Benchmark Nx approach
    {nx_time_us, nx_result} = :timer.tc(fn ->
      case problem_type do
        :stn -> ConvergenceNx.solve_stn(data, opts)
        :activities -> ConvergenceNx.solve_activities(data, opts)
      end
    end)
    
    # Benchmark Nx with PyTorch if available
    {nx_pytorch_time_us, nx_pytorch_result} = if ConvergenceNx.pytorch_available?() do
      pytorch_opts = Keyword.put(opts, :use_pytorch, true)
      :timer.tc(fn ->
        case problem_type do
          :stn -> ConvergenceNx.solve_stn(data, pytorch_opts)
          :activities -> ConvergenceNx.solve_activities(data, pytorch_opts)
        end
      end)
    else
      {nil, nil}
    end
    
    %{
      problem_type: problem_type,
      results: %{
        flow: %{
          time_ms: flow_time_us / 1000,
          time_us: flow_time_us,
          result_size: estimate_result_size(flow_result),
          status: if(flow_result[:solved], do: :success, else: :failed)
        },
        nx: %{
          time_ms: nx_time_us / 1000,
          time_us: nx_time_us,
          result_size: estimate_result_size(nx_result),
          status: if(nx_result[:solved], do: :success, else: :failed)
        },
        nx_pytorch: if nx_pytorch_time_us do
          %{
            time_ms: nx_pytorch_time_us / 1000,
            time_us: nx_pytorch_time_us,
            result_size: estimate_result_size(nx_pytorch_result),
            status: if(nx_pytorch_result[:solved], do: :success, else: :failed)
          }
        else
          %{status: :unavailable, reason: "PyTorch not available"}
        end
      },
      winner: determine_winner(flow_time_us, nx_time_us, nx_pytorch_time_us)
    }
  end

  # Private helper functions

  defp solve_stn_batch_flow(timelines, batch_size, opts) do
    # Process timelines in parallel chunks using Flow
    timelines
    |> Enum.chunk_every(batch_size)
    |> Flow.from_enumerable()
    |> Flow.flat_map(fn chunk ->
      chunk
      |> Enum.map(fn timeline ->
        constraints = Map.get(timeline, :constraints, %{})
        result = ConvergenceFlow.solve_stn_with_convergence(constraints, opts)
        Map.put(timeline, :result, result)
      end)
    end)
    |> Enum.to_list()
    |> then(fn results ->
      %{
        batch_solved: true,
        timelines: results,
        total_count: length(timelines),
        successful_count: Enum.count(results, fn t -> get_in(t, [:result, :converged]) end)
      }
    end)
  end

  defp solve_activities_batch_flow(activity_sets, batch_size, opts) do
    # Process activity sets in parallel chunks using Flow
    activity_sets
    |> Enum.chunk_every(batch_size)
    |> Flow.from_enumerable()
    |> Flow.flat_map(fn chunk ->
      chunk
      |> Enum.map(fn activity_set ->
        activities = Map.get(activity_set, :activities, [])
        result = ConvergenceFlow.solve_activities_with_convergence(activities, opts)
        Map.put(activity_set, :result, result)
      end)
    end)
    |> Enum.to_list()
    |> then(fn results ->
      %{
        batch_solved: true,
        activity_sets: results,
        total_count: length(activity_sets),
        successful_count: Enum.count(results, fn s -> get_in(s, [:result, :converged]) end)
      }
    end)
  end

  defp get_system_architecture do
    case :erlang.system_info(:system_architecture) do
      arch when is_list(arch) -> List.to_string(arch)
      _ -> "unknown"
    end
  end

  defp get_recommended_approach do
    cond do
      ConvergenceNx.pytorch_available?() -> :nx_with_pytorch
      true -> :flow
    end
  end

  defp estimate_result_size(result) do
    case result do
      %{constraints: constraints} -> map_size(constraints)
      %{activities: activities} -> length(activities)
      list when is_list(list) -> length(list)
      _ -> 1
    end
  end

  defp determine_winner(flow_time, nx_time, nx_pytorch_time) do
    times = [
      {:flow, flow_time},
      {:nx, nx_time}
    ]
    
    times = if nx_pytorch_time do
      [{:nx_pytorch, nx_pytorch_time} | times]
    else
      times
    end
    
    {winner, _time} = Enum.min_by(times, &elem(&1, 1))
    winner
  end
end
