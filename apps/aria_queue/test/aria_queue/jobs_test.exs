# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.JobsTest do
  use ExUnit.Case, async: true

  alias AriaQueue.Oban

  describe "job creation" do
    test "can create worker job structs without database" do
      # Test that we can create job structs for our Membrane-based system
      job_args = %{
        type: "character_generation",
        user_id: 123,
        context: %{name: "test"}
      }

      # Test creating a job struct using the worker module
      job = AriaQueue.Workers.AIGenerationWorker.new(job_args, queue: :ai_generation)
      
      assert %Oban.Job{} = job
      assert job.worker == "AriaQueue.Workers.AIGenerationWorker"
      assert job.args == %{"type" => "character_generation", "user_id" => 123, "context" => %{"name" => "test"}}
      assert job.queue == "ai_generation"
    end

    test "worker modules are available" do
      # Test that all our worker modules can be loaded
      workers = [
        AriaQueue.Workers.AIGenerationWorker,
        AriaQueue.Workers.PlanningWorker,
        AriaQueue.Workers.StorageSyncWorker,
        AriaQueue.Workers.MonitoringWorker
      ]

      Enum.each(workers, fn worker ->
        assert Code.ensure_loaded?(worker), "#{worker} should be loadable"
      end)
    end

    test "membrane-based job processing system is available" do
      # Test that our Membrane-based replacement modules are available
      modules = [
        AriaQueue.Oban,
        AriaQueue.Oban.Job,
        AriaQueue.MembraneWorker,
        AriaQueue.MembraneJobProcessor
      ]

      Enum.each(modules, fn module ->
        assert Code.ensure_loaded?(module), "#{module} should be loadable"
      end)
    end
  end
end
