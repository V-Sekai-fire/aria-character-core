# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMonitor do
  @moduledoc """
  AriaMonitor provides monitoring and metrics collection for the Aria Character Core system.

  This module includes functionality for:
  - System metrics collection
  - Performance monitoring
  - Health checks
  - Telemetry integration
  """

  @doc """
  Gets system health status.
  """
  def health_check do
    %{
      status: :ok,
      timestamp: DateTime.utc_now(),
      vm_memory: :erlang.memory(),
      process_count: :erlang.system_info(:process_count),
      run_queue: :erlang.statistics(:run_queue)
    }
  end

  @doc """
  Gets current system metrics.
  """
  def get_metrics do
    memory = :erlang.memory()

    %{
      memory: %{
        total: memory[:total],
        processes: memory[:processes],
        system: memory[:system],
        atom: memory[:atom],
        binary: memory[:binary],
        ets: memory[:ets]
      },
      system: %{
        process_count: :erlang.system_info(:process_count),
        port_count: :erlang.system_info(:port_count),
        run_queue: :erlang.statistics(:run_queue),
        uptime: :erlang.statistics(:wall_clock)
      }
    }
  end
end
