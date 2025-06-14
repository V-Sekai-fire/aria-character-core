# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.Workers.PlanningWorker do
  @moduledoc """
  Worker for planning and coordination tasks.
  """

  use AriaQueue.MembraneWorker, queue: :planning, max_attempts: 5

  @impl AriaQueue.MembraneWorker
  def perform(%{"type" => "workflow_planning", "workflow_id" => workflow_id} = args) do
    set_logger_level_from_args(args)
    require Logger
    Logger.info("Processing workflow planning for workflow #{workflow_id}")

    # This would interface with aria_engine service
    # Simulate processing time
    Process.sleep(500)

    :ok
  end

  def perform(%{"type" => "resource_allocation", "resources" => resources} = args) do
    set_logger_level_from_args(args)
    require Logger
    Logger.info("Processing resource allocation for #{length(resources)} resources")

    Process.sleep(300)

    :ok
  end

  def perform(args) do
    set_logger_level_from_args(args)
    {:error, "Unknown planning job type: #{inspect(args)}"}
  end

  # Set Logger level from args (internal worker verbosity)
  defp set_logger_level_from_args(args) do
    log_level = Map.get(args, "log_level", :info)
    verbose = Map.get(args, "verbose", false)

    cond do
      log_level != :info -> Logger.configure(level: log_level)
      verbose -> Logger.configure(level: :debug)
      true -> Logger.configure(level: :info)
    end
  end
end
