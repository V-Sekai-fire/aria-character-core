defmodule AriaEngine.ScalingProblemGeneratorTest do
  @moduledoc """
  Comprehensive test suite for scaling problem generator validation.

  Tests the `validate_scheduling_solutions` tool and its scaling problem generator
  across all activity counts (1-6) with identity case validation, dependency chains,
  resource scaling, and MCP integration.
  """

  use ExUnit.Case
  alias AriaEngine.MCPToolsV2
  alias AriaEngine.Membrane.PipelineManager

  setup do
    # Start pipeline manager for MCP integration tests
    case GenServer.start_link(PipelineManager, [], name: PipelineManager) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    on_exit(fn ->
      if Process.whereis(PipelineManager) do
        GenServer.stop(PipelineManager)
      end
    end)

    :ok
  end

  describe "direct function testing" do
    test "generate_new_validation_problem/1 creates valid problems" do
      problem_name = "test_problem"

      # Generate multiple problems to test scaling behavior
      problems =
        for _i <- 1..20 do
          MCPToolsV2.generate_new_validation_problem(problem_name)
        end

      # Verify all problems are valid
      Enum.each(problems, fn problem ->
        assert is_map(problem)
        assert Map.has_key?(problem, :name)
        assert Map.has_key?(problem, :activities)
        assert Map.has_key?(problem, :entities)
        assert Map.has_key?(problem, :resources)
        assert Map.has_key?(problem, :constraints)
        assert Map.has_key?(problem, :metadata)

        # Verify activity count is in valid range
        activity_count = length(problem.activities)
        assert activity_count >= 1 and activity_count <= 6

        # Verify metadata consistency
        assert problem.metadata.activity_count == activity_count
        assert problem.metadata.scaling_factor == activity_count
        assert problem.metadata.problem_type == "scaling_task_chain"
      end)

      # Verify we get different activity counts across multiple generations
      activity_counts = Enum.map(problems, fn p -> length(p.activities) end)
      unique_counts = Enum.uniq(activity_counts)

      # Should see multiple different activity counts
      assert length(unique_counts) > 1

      IO.puts(
        "✅ Generated #{length(problems)} problems with activity counts: #{inspect(Enum.sort(unique_counts))}"
      )
    end

    test "problems have unique identifiers and timestamps" do
      problems =
        for _i <- 1..10 do
          # Ensure different timestamps
          Process.sleep(1)
          MCPToolsV2.generate_new_validation_problem("uniqueness_test")
        end

      # Verify all problem names are unique
      problem_names = Enum.map(problems, & &1.name)
      assert length(problem_names) == length(Enum.uniq(problem_names))

      # Verify all problem IDs are unique
      problem_ids = Enum.map(problems, & &1.metadata.problem_id)
      assert length(problem_ids) == length(Enum.uniq(problem_ids))

      IO.puts("✅ All #{length(problems)} problems have unique identifiers")
    end
  end

  describe "identity case validation (1 activity)" do
    test "single activity creates proper identity structure" do
      # Force generation of 1-activity problems by testing multiple times
      identity_problems =
        for _i <- 1..50 do
          MCPToolsV2.generate_new_validation_problem("identity_test")
        end
        |> Enum.filter(fn p -> length(p.activities) == 1 end)

      # Should have at least some 1-activity problems
      assert length(identity_problems) > 0

      Enum.each(identity_problems, fn problem ->
        [activity] = problem.activities

        # Verify identity task structure
        assert activity["id"] == "identity_task"
        assert activity["name"] == "Identity Task"
        assert activity["duration"] == "PT30M"
        assert activity["required_capabilities"] == ["basic"]
        assert activity["required_resources"] == ["workstation_1"]
        assert activity["dependencies"] == []

        # Verify complexity is trivial
        assert problem.metadata.complexity == "trivial"

        # Verify single entity and resource
        assert length(problem.entities) == 1
        assert Map.has_key?(problem.resources, "workstation_1")

        # Verify constraints for single activity
        assert problem.constraints["max_concurrent_activities"] == 1
        assert problem.constraints["require_resources"] == false
      end)

      IO.puts("✅ Validated #{length(identity_problems)} identity case problems")
    end
  end

  describe "scaling progression tests" do
    test "dependency chains form correctly for multi-activity problems" do
      # Generate problems until we get examples of each activity count
      all_problems =
        for _i <- 1..100 do
          MCPToolsV2.generate_new_validation_problem("scaling_test")
        end

      # Group by activity count
      problems_by_count = Enum.group_by(all_problems, fn p -> length(p.activities) end)

      # Test each activity count from 2-6
      for count <- 2..6 do
        problems = Map.get(problems_by_count, count, [])

        if length(problems) > 0 do
          problem = hd(problems)

          # Verify dependency chain structure
          activities = problem.activities
          assert length(activities) == count

          # Check dependency chain: task_2 depends on task_1, task_3 depends on task_2, etc.
          for i <- 2..count do
            task = Enum.find(activities, fn a -> a["id"] == "task_#{i}" end)
            assert task != nil
            assert task["dependencies"] == ["task_#{i - 1}"]
          end

          # First task should have no dependencies
          first_task = Enum.find(activities, fn a -> a["id"] == "task_1" end)
          assert first_task["dependencies"] == []

          # Verify increasing duration pattern
          for i <- 1..count do
            task = Enum.find(activities, fn a -> a["id"] == "task_#{i}" end)
            # 45, 60, 75, 90, 105
            expected_duration = 30 + i * 15
            assert task["duration"] == "PT#{expected_duration}M"
          end

          IO.puts("✅ Validated #{count}-activity dependency chain")
        end
      end
    end

    test "resource and entity scaling follows expected patterns" do
      all_problems =
        for _i <- 1..100 do
          MCPToolsV2.generate_new_validation_problem("resource_scaling_test")
        end

      problems_by_count = Enum.group_by(all_problems, fn p -> length(p.activities) end)

      for count <- 1..6 do
        problems = Map.get(problems_by_count, count, [])

        if length(problems) > 0 do
          problem = hd(problems)

          # Verify entity scaling (max 3 entities)
          expected_entity_count = min(count, 3)
          assert length(problem.entities) == expected_entity_count

          # Verify resource scaling
          if count == 1 do
            # Single activity: only workstation
            assert Map.has_key?(problem.resources, "workstation_1")
            refute Map.has_key?(problem.resources, "shared_storage")
          else
            # Multi-activity: workstations + shared storage
            resource_count = min(count, 3)

            for i <- 1..resource_count do
              assert Map.has_key?(problem.resources, "workstation_#{i}")
            end

            assert Map.has_key?(problem.resources, "shared_storage")

            # Shared storage capacity should match activity count
            shared_storage = problem.resources["shared_storage"]
            assert shared_storage["capacity"] == count
          end

          IO.puts("✅ Validated resource/entity scaling for #{count} activities")
        end
      end
    end

    test "complexity progression follows expected pattern" do
      all_problems =
        for _i <- 1..100 do
          MCPToolsV2.generate_new_validation_problem("complexity_test")
        end

      problems_by_count = Enum.group_by(all_problems, fn p -> length(p.activities) end)

      expected_complexity = %{
        1 => "trivial",
        2 => "simple",
        3 => "medium",
        4 => "medium",
        5 => "high",
        6 => "high"
      }

      for {count, expected} <- expected_complexity do
        problems = Map.get(problems_by_count, count, [])

        if length(problems) > 0 do
          problem = hd(problems)
          assert problem.metadata.complexity == expected
          IO.puts("✅ #{count} activities → #{expected} complexity")
        end
      end
    end
  end

  describe "MCP tool integration" do
    @describetag :integration

    test "validate_scheduling_solutions tool creates and processes problems" do
      params = %{
        "problem_name" => "mcp_integration_test"
      }

      result = MCPToolsV2.handle_tool_call(:validate_scheduling_solutions, params)

      # Verify successful response structure
      assert is_map(result)
      assert result["status"] == "success"
      assert Map.has_key?(result, "message")
      assert Map.has_key?(result, "pipeline_id")
      assert Map.has_key?(result, "validation_type")
      assert Map.has_key?(result, "generated_problem")

      # Verify validation type
      assert result["validation_type"] == "hybrid_vs_minizinc"

      # Verify generated problem metadata
      problem_info = result["generated_problem"]
      assert Map.has_key?(problem_info, "name")
      assert Map.has_key?(problem_info, "activities_count")
      assert Map.has_key?(problem_info, "entities_count")
      assert Map.has_key?(problem_info, "resources_count")
      assert Map.has_key?(problem_info, "complexity")
      assert Map.has_key?(problem_info, "problem_type")

      # Verify activity count is in valid range
      assert problem_info["activities_count"] >= 1
      assert problem_info["activities_count"] <= 6

      # Verify problem type
      assert problem_info["problem_type"] == "scaling_task_chain"

      IO.puts("✅ MCP tool integration successful")
      IO.puts("   Generated problem: #{problem_info["name"]}")
      IO.puts("   Activities: #{problem_info["activities_count"]}")
      IO.puts("   Complexity: #{problem_info["complexity"]}")
    end

    test "MCP tool handles multiple concurrent requests" do
      # Test concurrent problem generation
      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            params = %{"problem_name" => "concurrent_test_#{i}"}
            MCPToolsV2.handle_tool_call(:validate_scheduling_solutions, params)
          end)
        end

      results = Task.await_many(tasks, 10_000)

      # Verify all requests succeeded
      Enum.each(results, fn result ->
        assert result["status"] == "success"
        assert Map.has_key?(result, "generated_problem")
      end)

      # Verify different problems were generated
      problem_names = Enum.map(results, fn r -> r["generated_problem"]["name"] end)
      assert length(problem_names) == length(Enum.uniq(problem_names))

      IO.puts("✅ Concurrent MCP requests handled successfully")
    end
  end

  describe "performance benchmarks" do
    test "problem generation performance is acceptable" do
      # Measure generation time for different activity counts
      measurements =
        for _i <- 1..50 do
          start_time = System.monotonic_time(:microsecond)
          _problem = MCPToolsV2.generate_new_validation_problem("perf_test")
          end_time = System.monotonic_time(:microsecond)
          end_time - start_time
        end

      avg_time = Enum.sum(measurements) / length(measurements)
      max_time = Enum.max(measurements)
      min_time = Enum.min(measurements)

      # Performance assertions (times in microseconds)
      # Average under 10ms
      assert avg_time < 10_000
      # Max under 50ms
      assert max_time < 50_000

      IO.puts("✅ Performance benchmarks:")
      IO.puts("   Average: #{Float.round(avg_time / 1000, 2)}ms")
      IO.puts("   Min: #{Float.round(min_time / 1000, 2)}ms")
      IO.puts("   Max: #{Float.round(max_time / 1000, 2)}ms")
    end

    test "scaling distribution covers all activity counts" do
      # Generate large sample to verify distribution
      problems =
        for _i <- 1..300 do
          MCPToolsV2.generate_new_validation_problem("distribution_test")
        end

      # Count occurrences of each activity count
      activity_counts = Enum.map(problems, fn p -> length(p.activities) end)
      distribution = Enum.frequencies(activity_counts)

      # Verify all counts 1-6 are represented
      for count <- 1..6 do
        assert Map.has_key?(distribution, count)
        assert distribution[count] > 0
      end

      # Calculate distribution percentages
      total = length(problems)

      percentages =
        for count <- 1..6 do
          {count, Float.round(distribution[count] / total * 100, 1)}
        end

      IO.puts("✅ Activity count distribution (#{total} problems):")

      Enum.each(percentages, fn {count, pct} ->
        IO.puts("   #{count} activities: #{distribution[count]} (#{pct}%)")
      end)

      # Verify roughly even distribution (each should be ~16.7%)
      Enum.each(percentages, fn {_count, pct} ->
        # Allow some variance
        assert pct > 10.0 and pct < 25.0
      end)
    end
  end

  describe "problem structure validation" do
    test "all generated problems have required fields and valid structure" do
      problems =
        for _i <- 1..30 do
          MCPToolsV2.generate_new_validation_problem("structure_test")
        end

      Enum.each(problems, fn problem ->
        # Verify top-level structure
        assert is_binary(problem.name)
        assert is_list(problem.activities)
        assert is_list(problem.entities)
        assert is_map(problem.resources)
        assert is_map(problem.constraints)
        assert is_map(problem.metadata)

        # Verify activities structure
        Enum.each(problem.activities, fn activity ->
          assert Map.has_key?(activity, "id")
          assert Map.has_key?(activity, "name")
          assert Map.has_key?(activity, "duration")
          assert Map.has_key?(activity, "required_capabilities")
          assert Map.has_key?(activity, "required_resources")
          assert Map.has_key?(activity, "dependencies")

          assert is_binary(activity["id"])
          assert is_binary(activity["name"])
          assert is_binary(activity["duration"])
          assert is_list(activity["required_capabilities"])
          assert is_list(activity["required_resources"])
          assert is_list(activity["dependencies"])
        end)

        # Verify entities structure
        Enum.each(problem.entities, fn entity ->
          assert Map.has_key?(entity, "id")
          assert Map.has_key?(entity, "type")
          assert Map.has_key?(entity, "capabilities")
          assert Map.has_key?(entity, "availability")

          assert is_binary(entity["id"])
          assert is_binary(entity["type"])
          assert is_list(entity["capabilities"])
          assert is_binary(entity["availability"])
        end)

        # Verify resources structure
        Enum.each(problem.resources, fn {resource_id, resource_config} ->
          assert is_binary(resource_id)
          assert is_map(resource_config)
          assert Map.has_key?(resource_config, "type")
          assert Map.has_key?(resource_config, "capacity")
          assert is_binary(resource_config["type"])
          assert is_number(resource_config["capacity"])
        end)

        # Verify metadata structure
        metadata = problem.metadata
        assert Map.has_key?(metadata, :complexity)
        assert Map.has_key?(metadata, :problem_type)
        assert Map.has_key?(metadata, :activity_count)
        assert Map.has_key?(metadata, :generated_at)
        assert Map.has_key?(metadata, :problem_id)
        assert Map.has_key?(metadata, :scaling_factor)

        assert is_binary(metadata.complexity)
        assert is_binary(metadata.problem_type)
        assert is_number(metadata.activity_count)
        assert %DateTime{} = metadata.generated_at
        assert is_number(metadata.problem_id)
        assert is_number(metadata.scaling_factor)
      end)

      IO.puts("✅ All #{length(problems)} problems have valid structure")
    end
  end
end
