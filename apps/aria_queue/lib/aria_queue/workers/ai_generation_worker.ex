# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.Workers.AIGenerationWorker do
  @moduledoc """
  Worker for AI content generation tasks.
  """

  use Oban.Worker, queue: :ai_generation, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "character_generation", "user_id" => user_id, "prompt" => prompt} = _args}) do
    # This would interface with aria_interpret or aria_shape services
    # For now, we'll just log the job
    require Logger
    Logger.info("Processing character generation for user #{user_id} with prompt: #{prompt}")
    
    # Simulate processing time
    Process.sleep(1000)
    
    # Return success
    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "story_generation", "user_id" => user_id, "context" => _context} = _args}) do
    require Logger
    Logger.info("Processing story generation for user #{user_id}")
    
    # Simulate processing time
    Process.sleep(2000)
    
    :ok
  end

  def perform(%Oban.Job{args: args}) do
    # Handle unknown job types
    {:error, "Unknown AI generation job type: #{inspect(args)}"}
  end
end
