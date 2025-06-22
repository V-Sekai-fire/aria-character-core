# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Convergence do
  @moduledoc """
  Unified convergence solving API with Flow-based parallel processing.

  This module provides a clean interface for solving convergence problems
  using Flow-based parallel processing with automatic batch optimization
  for multiple problems via the new BatchProcessor.
  """

  require Logger

  # Type definitions
  @type constraint :: map()
  @type activity :: map()
  @type solve_options :: [
          max_iterations: pos_integer(),
          stages: pos_integer()
        ]
  @type solve_result :: {:ok, term()} | {:error, String.t()}
  @type approach_info :: %{
          description: String.t(),
          strengths: [String.t()],
          backend: String.t()
        }
  @type system_info :: %{
          total_cores: pos_integer(),
          architecture: String.t(),
          recommended_approach: atom()
        }
  @type core_strategies :: %{
          all_cores: String.t(),
          single_core: String.t()
        }
  @type convergence_info :: %{
          approaches: %{
            flow: approach_info(),
            batch_processor: approach_info()
          },
          system: system_info(),
          core_strategies: core_strategies()
        }

  @doc """
  Solve STN constraints using Flow-based parallel processing.

  ## Options

  - `:max_iterations` - Maximum iterations for convergence (default: 100)
  - `:stages` - Number of Flow stages for parallel processing (default: System.schedulers_online())

  ## Examples

      # Single problem
      Convergence.solve_stn(constraints)

      # With custom options
      Convergence.solve_stn(constraints, max_iterations: 200, stages: 8)
  """
  @spec solve_stn([constraint()], solve_options()) :: solve_result()
  def solve_stn(_constraints, _opts \\ []) do
    raise "ConvergenceFlow.solve_stn_with_convergence/2 is not implemented"
  end

  @doc """
  Solve activity scheduling using Flow-based parallel processing.

  ## Options

  - `:max_iterations` - Maximum iterations for convergence (default: 50)
  - `:stages` - Number of Flow stages for parallel processing (default: System.schedulers_online())

  ## Examples

      # Single problem
      Convergence.solve_activities(activities)

      # With custom options
      Convergence.solve_activities(activities, max_iterations: 100, stages: 4)
  """
  @spec solve_activities([activity()], solve_options()) :: solve_result()
  def solve_activities(_activities, _opts \\ []) do
    raise "ConvergenceFlow.solve_activities_with_convergence/2 is not implemented"
  end

  @doc """
  Get information about available convergence approaches and their capabilities.
  """
  @spec info() :: convergence_info()
  def info do
    %{
      approaches: %{
        flow: %{
          description: "Pure Elixir parallel processing with Flow library",
          strengths: [
            "Activity scheduling",
            "STN constraints",
            "Consistent performance",
            "Large datasets"
          ],
          backend: "CPU (Elixir processes)"
        },
        batch_processor: %{
          description: "Optimized batch processing for multiple problems with core distribution",
          strengths: [
            "Multiple problems",
            "Core utilization",
            "Parallel scaling",
            "Performance optimization"
          ],
          backend: "CPU (Task.async_stream + Flow)"
        }
      },
      system: %{
        total_cores: System.schedulers_online(),
        architecture: get_system_architecture(),
        recommended_approach: :batch_processor_for_multiple_problems
      },
      core_strategies: %{
        all_cores: "Distribute all cores across problems (default)",
        single_core: "Use 1 core per problem, maximize cross-problem parallelism"
      }
    }
  end

  # Private helper functions

  @spec get_system_architecture() :: String.t()
  defp get_system_architecture do
    case :erlang.system_info(:system_architecture) do
      arch when is_list(arch) -> List.to_string(arch)
      _ -> "unknown"
    end
  end
end
