# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.Workers.MonitoringWorker do
  @moduledoc """
  Worker for monitoring and telemetry tasks.
  """

  use Oban.Worker, queue: :monitoring, max_attempts: 2

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "metrics_collection", "service" => service} = _args}) do
    require Logger
    Logger.info("Collecting metrics for service #{service}")

    # This would interface with aria_monitor service
    Process.sleep(100)

    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "health_check", "services" => services} = _args}) do
    require Logger
    Logger.info("Performing health check for #{length(services)} services")

    Process.sleep(200)

    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "alert_notification", "alert_id" => alert_id} = _args}) do
    require Logger
    Logger.info("Processing alert notification #{alert_id}")

    Process.sleep(50)

    :ok
  end

  def perform(%Oban.Job{args: args}) do
    {:error, "Unknown monitoring job type: #{inspect(args)}"}
  end
end
