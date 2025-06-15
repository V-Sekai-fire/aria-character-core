# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.FlowProcessor do
  @moduledoc """
  Queue-specific adapter for AriaFlow parallel processing.
  
  This module provides queue-specific convenience functions while delegating
  actual Flow processing to AriaFlow. This maintains proper encapsulation by
  keeping Flow implementation details within AriaFlow.
  
  ## Responsibilities
  - Provide queue-specific processing interfaces
  - Handle queue-specific error handling and logging
  - Delegate actual parallel processing to AriaFlow
  """

  @doc """
  Process actions in parallel using AriaFlow's GPU convergence processing.
  """
  def process_actions(actions, opts \\ []) do
    AriaFlow.process_batch(actions, &process_single_action/1, opts)
  end

  @doc """
  Process constraints in parallel for temporal planning using AriaFlow.
  """
  def process_constraints(constraints, opts \\ []) do
    AriaFlow.process_batch(constraints, &process_single_constraint/1, opts)
  end

  @doc """
  Process a batch of queue items using AriaFlow's parallel processing.
  """
  def process_batch(items, processor_fn, opts \\ []) do
    AriaFlow.process_batch(items, processor_fn, opts)
  end

  @doc """
  Get processing metrics from AriaFlow.
  """
  def get_metrics do
    AriaFlow.get_processing_metrics()
  end

  # Queue-specific processing functions

  defp process_single_action(action) do
    # Queue-specific action processing
    case action do
      %{action: action_type, data: data} ->
        %{
          action: action_type,
          result: :processed,
          data: Map.put(data, :processed_at, System.monotonic_time(:microsecond)),
          queue_metadata: %{
            processed_by: :aria_queue,
            processing_node: Node.self()
          }
        }
      {:move, params} -> {:ok, :moved, params}
      {:attack, params} -> {:ok, :attacked, params}
      {:wait, params} -> {:ok, :waited, params}
      {:plan, params} -> {:ok, :planned, params}
      _ ->
        %{
          action: :unknown,
          result: :processed,
          data: %{processed_at: System.monotonic_time(:microsecond)},
          queue_metadata: %{
            processed_by: :aria_queue,
            processing_node: Node.self()
          }
        }
    end
  end

  defp process_single_constraint(constraint) do
    # Queue-specific constraint processing
    case constraint do
      %{type: constraint_type, params: params} ->
        %{
          type: constraint_type,
          params: params,
          result: :satisfied,
          processed_at: System.monotonic_time(:microsecond),
          queue_metadata: %{
            processed_by: :aria_queue,
            processing_node: Node.self()
          }
        }
      constraint when is_list(constraint) ->
        constraint_type = constraint[:type] || :unknown
        case constraint_type do
          :temporal -> {:ok, :temporal_solved, constraint}
          :resource -> {:ok, :resource_solved, constraint}
          :synchronization -> {:ok, :sync_solved, constraint}
          _ -> {:ok, :constraint_solved, constraint}
        end
      _ ->
        %{
          type: :unknown,
          params: %{},
          result: :satisfied,
          processed_at: System.monotonic_time(:microsecond),
          queue_metadata: %{
            processed_by: :aria_queue,
            processing_node: Node.self()
          }
        }
    end
  end
end
