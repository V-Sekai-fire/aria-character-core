# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.Workers.StorageSyncWorker do
  @moduledoc """
  Worker for storage synchronization tasks.
  """

  use Oban.Worker, queue: :storage_sync, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "file_upload", "file_id" => file_id, "user_id" => user_id} = _args}) do
    require Logger
    Logger.info("Processing file upload sync for file #{file_id}, user #{user_id}")

    # This would interface with aria_storage service
    Process.sleep(800)

    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "file_delete", "file_id" => file_id} = _args}) do
    require Logger
    Logger.info("Processing file deletion for file #{file_id}")

    Process.sleep(200)

    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "backup_sync", "backup_id" => backup_id} = _args}) do
    require Logger
    Logger.info("Processing backup sync for backup #{backup_id}")

    Process.sleep(1500)

    :ok
  end

  def perform(%Oban.Job{args: args}) do
    {:error, "Unknown storage sync job type: #{inspect(args)}"}
  end
end
