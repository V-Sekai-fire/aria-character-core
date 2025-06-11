# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.SOPEngineTest do
  @moduledoc """
  Tests for the SOP Engine functionality and workflow execution.
  """

  use ExUnit.Case, async: false
  require Logger

  alias AriaWorkflow.{SOPEngine, SOPRegistry, SOPDefinition}
  alias AriaEngine.State

  setup do
    # Start fresh registry for each test
    registry_name = :"test_engine_registry_#{:rand.uniform(1000)}"
    {:ok, registry_pid} = SOPRegistry.start_link(name: registry_name)
    
    on_exit(fn ->
      if Process.alive?(registry_pid) do
        GenServer.stop(registry_pid)
      end
    end)
    
    %{registry: registry_name, registry_pid: registry_pid}
  end

  describe "SOP Engine Core Functions" do
    test "gets SOP from registry", %{registry: registry} do
      case SOPEngine.get_sop("basic_timing", registry: registry) do
        {:ok, sop} ->
          assert sop.id == "basic_timing"
          assert %SOPDefinition{} = sop
          
        {:error, reason} ->
          flunk("Failed to get SOP: #{inspect(reason)}")
      end
    end

    test "lists all SOPs through engine", %{registry: registry} do
      sops = SOPEngine.list_sops(registry: registry)
      
      assert is_list(sops)
      assert length(sops) >= 2
      
      sop_ids = Enum.map(sops, & &1.id)
      assert "basic_timing" in sop_ids
      assert "command_tracing" in sop_ids
    end

    test "validates SOP structure" do
      {:ok, sop} = SOPRegistry.get("basic_timing")
      
      # Check required fields
      assert is_binary(sop.id)
      assert is_list(sop.goals)
      assert is_list(sop.tasks)
      assert is_list(sop.methods)
      assert is_map(sop.documentation)
      assert is_map(sop.metadata)
      
      # Check goals structure
      Enum.each(sop.goals, fn goal ->
        assert is_tuple(goal)
        assert tuple_size(goal) == 3
      end)
      
      # Check tasks structure
      Enum.each(sop.tasks, fn task ->
        assert is_tuple(task)
        assert tuple_size(task) == 2
        {name, func} = task
        assert is_binary(name)
        assert is_function(func, 2)
      end)
    end
  end

  describe "SOP Planning and Execution" do
    test "plans basic timing SOP execution", %{registry: registry} do
      {:ok, sop} = SOPEngine.get_sop("basic_timing", registry: registry)
      initial_state = %{}
      
      case SOPEngine.plan_sop(sop, initial_state) do
        {:ok, execution_plan} ->
          assert is_map(execution_plan)
          assert Map.has_key?(execution_plan, :sop_id)
          assert Map.has_key?(execution_plan, :steps)
          assert execution_plan.sop_id == "basic_timing"
          
        {:error, reason} ->
          flunk("SOP planning failed: #{inspect(reason)}")
      end
    end

    test "executes basic timing operations", %{registry: registry} do
      {:ok, sop} = SOPEngine.get_sop("basic_timing", registry: registry)
      initial_state = %{}
      
      case SOPEngine.plan_sop(sop, initial_state) do
        {:ok, execution_plan} ->
          case SOPEngine.execute_plan(execution_plan, background: false) do
            :ok ->
              Logger.info("SOP execution completed successfully")
              
            {:error, reason} ->
              flunk("SOP execution failed: #{inspect(reason)}")
          end
          
        {:error, reason} ->
          flunk("SOP planning failed: #{inspect(reason)}")
      end
    end
  end

  describe "Error Handling" do
    test "handles non-existent SOP gracefully", %{registry: registry} do
      result = SOPEngine.get_sop("non_existent_sop", registry: registry)
      assert {:error, :not_found} = result
    end

    test "handles invalid SOP data gracefully" do
      # Create an invalid SOP with missing required fields
      invalid_sop = %SOPDefinition{
        id: "invalid_sop",
        goals: [],  # Empty goals should be invalid
        tasks: [],
        methods: [],
        documentation: %{},
        metadata: %{}
      }
      
      case SOPDefinition.validate(invalid_sop) do
        {:error, _reason} ->
          # This should fail validation
          assert true
          
        :ok ->
          flunk("Invalid SOP should not pass validation")
      end
    end
  end

  describe "Registry Statistics and Management" do
    test "provides registry statistics", %{registry: registry} do
      stats = GenServer.call(registry, :stats)
      
      assert is_map(stats)
      assert Map.has_key?(stats, :total_sops)
      assert Map.has_key?(stats, :builtin_sops)
      assert Map.has_key?(stats, :started_at)
      assert Map.has_key?(stats, :uptime_seconds)
      assert Map.has_key?(stats, :uptime_human)
      
      assert stats.builtin_sops >= 2
      assert is_integer(stats.uptime_seconds)
      assert is_binary(stats.uptime_human)
    end

    test "tracks registry uptime correctly", %{registry: registry} do
      # Get initial stats
      stats1 = GenServer.call(registry, :stats)
      
      # Wait a moment
      :timer.sleep(100)
      
      # Get updated stats
      stats2 = GenServer.call(registry, :stats)
      
      # Uptime should have increased
      assert stats2.uptime_seconds >= stats1.uptime_seconds
    end
  end

  describe "SOP Documentation" do
    test "retrieves SOP documentation sections" do
      {:ok, sop} = SOPRegistry.get("basic_timing")
      
      assert Map.has_key?(sop.documentation, :overview)
      assert Map.has_key?(sop.documentation, :timing_procedures)
      assert Map.has_key?(sop.documentation, :timezone_handling)
      assert Map.has_key?(sop.documentation, :execution_logging)
      
      # Each section should have meaningful content
      Enum.each(sop.documentation, fn {_section, content} ->
        assert is_binary(content)
        assert String.length(content) > 50  # Should have substantial content
      end)
    end

    test "includes proper metadata" do
      {:ok, sop} = SOPRegistry.get("command_tracing")
      
      metadata = sop.metadata
      assert metadata.version == "1.0"
      assert %Date{} = metadata.last_updated
      assert %Date{} = metadata.next_review
      assert is_binary(metadata.approved_by)
      assert is_list(metadata.dependencies)
      assert length(metadata.dependencies) > 0
    end
  end

  describe "Performance and Reliability" do
    test "handles concurrent registry access" do
      registry_name = :"concurrent_test_registry_#{:rand.uniform(1000)}"
      {:ok, _pid} = SOPRegistry.start_link(name: registry_name)
      
      # Spawn multiple concurrent processes accessing the registry
      tasks = for i <- 1..10 do
        Task.async(fn ->
          case SOPRegistry.get("basic_timing", registry: registry_name) do
            {:ok, sop} -> 
              assert sop.id == "basic_timing"
              :ok
            error -> 
              error
          end
        end)
      end
      
      # Wait for all tasks to complete
      results = Task.await_many(tasks, 5000)
      
      # All should succeed
      Enum.each(results, fn result ->
        assert result == :ok
      end)
      
      GenServer.stop(registry_name)
    end

    test "registry survives large number of operations" do
      {:ok, sop} = SOPRegistry.get("basic_timing")
      
      # Perform many operations
      for _i <- 1..100 do
        {:ok, _} = SOPRegistry.get("basic_timing")
        _stats = AriaWorkflow.SOPRegistry.get_current_time_info()
      end
      
      # Registry should still be responsive
      {:ok, sop_final} = SOPRegistry.get("basic_timing")
      assert sop_final.id == sop.id
    end
  end
end
