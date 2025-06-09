# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMonitor.Application do
  @moduledoc """
  Application module for AriaMonitor.

  This application provides monitoring and metrics collection
  for the Aria Character Core system.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Telemetry supervisors
      {Telemetry.Metrics.ConsoleReporter, metrics: telemetry_metrics()},

      # Optional: Add Prometheus metrics if needed
      # {TelemetryMetricsPrometheus, metrics: telemetry_metrics()},

      # System monitoring processes
      {Task.Supervisor, name: AriaMonitor.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: AriaMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp telemetry_metrics do
    [
      # Phoenix metrics
      Telemetry.Metrics.counter("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      Telemetry.Metrics.summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),

      # VM metrics
      Telemetry.Metrics.summary("vm.memory.total", unit: {:byte, :kilobyte}),
      Telemetry.Metrics.summary("vm.total_run_queue_lengths.total"),
      Telemetry.Metrics.summary("vm.total_run_queue_lengths.cpu"),
      Telemetry.Metrics.summary("vm.total_run_queue_lengths.io"),

      # Database metrics
      Telemetry.Metrics.summary("aria_data.repo.query.total_time",
        unit: {:native, :millisecond},
        tags: [:source, :command]
      ),
      Telemetry.Metrics.counter("aria_data.repo.query.count",
        tags: [:source, :command]
      )
    ]
  end
end
