# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.JobsTest do
  use ExUnit.Case, async: true

  alias AriaQueue.Workers.AIGenerationWorker

  describe "job creation" do
    test "can create worker job structs without database" do
      # Test that we can create job structs for Oban v2.19.4
      changeset = AIGenerationWorker.new(%{
        type: "character_generation",
        user_id: 123,
        context: %{name: "test"}
      })

      assert changeset.changes.worker == "AriaQueue.Workers.AIGenerationWorker"
      assert changeset.changes.args == %{context: %{name: "test"}, type: "character_generation", user_id: 123}
      assert changeset.changes.queue == "ai_generation"
      assert changeset.valid?
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

    test "oban v2.19.4 modules are available" do
      # Test that required Oban v2.19.4 modules are available
      modules = [
        Oban,
        Oban.Job,
        Oban.Worker,
        Oban.Plugins.Pruner
      ]

      Enum.each(modules, fn module ->
        assert Code.ensure_loaded?(module), "#{module} should be loadable"
      end)
    end
  end
end
