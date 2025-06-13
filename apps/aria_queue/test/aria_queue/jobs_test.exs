# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.JobsTest do
  use ExUnit.Case, async: true

  alias AriaQueue.Oban

  describe "job creation" do
    test "can create worker job structs without database" do
      # Test that we can create job structs for our Membrane-based system
      job_data = %{
        worker: "AriaQueue.Workers.AIGenerationWorker",
        args: %{
          type: "character_generation",
          user_id: 123,
          context: %{name: "test"}
        },
        queue: "ai_generation"
      }

      result = Oban.insert(job_data)
      assert {:ok, _} = result
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
