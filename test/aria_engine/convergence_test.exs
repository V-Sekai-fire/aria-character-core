# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ConvergenceTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Convergence

  describe "solve_stn/2" do
    test "solves STN constraints with Flow approach" do
      constraints = %{
        {{"A", "B"}, {0, 10}},
        {{"B", "C"}, {5, 15}},
        {{"A", "C"}, {0, 20}}
      }

      result = Convergence.solve_stn(constraints, approach: :flow)

      assert %{converged: true, activities: _} = result
    end

    test "solves STN constraints with Nx approach" do
      constraints = %{
        {{"A", "B"}, {0, 10}},
        {{"B", "C"}, {5, 15}},
        {{"A", "C"}, {0, 20}}
      }

      result = Convergence.solve_stn(constraints, approach: :nx)

      assert %{solved: true, constraints: _} = result
    end

    test "falls back to Flow for unknown approach" do
      constraints = %{
        {{"A", "B"}, {0, 10}}
      }

      result = Convergence.solve_stn(constraints, approach: :unknown)

      assert %{converged: true, activities: _} = result
    end
  end

  describe "solve_activities/2" do
    test "solves activities with Flow approach" do
      activities = [
        %{id: "task1", duration: 5, resources: ["cpu"]},
        %{id: "task2", duration: 3, resources: ["memory"], dependencies: ["task1"]},
        %{id: "task3", duration: 2, resources: ["cpu"]}
      ]

      result = Convergence.solve_activities(activities, approach: :flow)

      assert %{converged: true, activities: scheduled_activities} = result
      assert length(scheduled_activities) == 3
    end

    test "solves activities with Nx approach" do
      activities = [
        %{id: "task1", duration: 5, resources: ["cpu"]},
        %{id: "task2", duration: 3, resources: ["memory"], dependencies: ["task1"]}
      ]

      result = Convergence.solve_activities(activities, approach: :nx)

      assert %{solved: true, activities: scheduled_activities} = result
      assert length(scheduled_activities) == 2
    end
  end

  describe "info/0" do
    test "returns system information" do
      info = Convergence.info()

      assert %{
        approaches: %{
          flow: %{description: _, strengths: _, backend: _},
          nx: %{description: _, strengths: _, backend: _}
        },
        system: %{
          pytorch_available: _,
          architecture: _,
          recommended_approach: _
        }
      } = info
    end
  end

  @tag timeout: 10_000
  describe "benchmark/3" do
    test "benchmarks STN solving approaches" do
      constraints = %{
        {{"A", "B"}, {0, 10}},
        {{"B", "C"}, {5, 15}}
      }

      result = Convergence.benchmark(:stn, constraints)

      assert %{
        problem_type: :stn,
        results: %{
          flow: %{time_ms: _, status: _},
          nx: %{time_ms: _, status: _},
          nx_pytorch: %{status: _}
        },
        winner: _
      } = result
    end

    test "benchmarks activity scheduling approaches" do
      activities = [
        %{id: "task1", duration: 5, resources: ["cpu"]},
        %{id: "task2", duration: 3, resources: ["memory"]}
      ]

      result = Convergence.benchmark(:activities, activities)

      assert %{
        problem_type: :activities,
        results: %{
          flow: %{time_ms: _, status: _},
          nx: %{time_ms: _, status: _},
          nx_pytorch: %{status: _}
        },
        winner: _
      } = result
    end
  end

  @tag timeout: 15_000
  describe "solve_stn_batch/2" do
    test "solves multiple STN problems in batch with Nx approach" do
      timelines = [
        %{
          id: "npc1",
          constraints: %{
            {{"A", "B"}, {0, 10}},
            {{"B", "C"}, {5, 15}}
          }
        },
        %{
          id: "npc2", 
          constraints: %{
            {{"X", "Y"}, {2, 8}},
            {{"Y", "Z"}, {3, 12}}
          }
        },
        %{
          id: "npc3",
          constraints: %{
            {{"P", "Q"}, {1, 5}}
          }
        }
      ]

      result = Convergence.solve_stn_batch(timelines, approach: :nx, use_pytorch: false)

      assert %{
        batch_solved: true,
        timelines: solved_timelines,
        total_count: 3,
        successful_count: _
      } = result

      assert length(solved_timelines) == 3
      
      # Check that each timeline has a result
      Enum.each(solved_timelines, fn timeline ->
        assert Map.has_key?(timeline, :result)
        assert Map.has_key?(timeline.result, :solved)
      end)
    end

    test "solves multiple STN problems in batch with Flow approach" do
      timelines = [
        %{
          id: "timeline1",
          constraints: %{
            {{"A", "B"}, {0, 10}}
          }
        },
        %{
          id: "timeline2",
          constraints: %{
            {{"X", "Y"}, {2, 8}}
          }
        }
      ]

      result = Convergence.solve_stn_batch(timelines, approach: :flow, batch_size: 2)

      assert %{
        batch_solved: true,
        timelines: solved_timelines,
        total_count: 2,
        successful_count: _
      } = result

      assert length(solved_timelines) == 2
    end
  end

  @tag timeout: 15_000
  describe "solve_activities_batch/2" do
    test "solves multiple activity sets in batch with Nx approach" do
      activity_sets = [
        %{
          id: "project1",
          activities: [
            %{id: "task1", duration: 5, resources: ["cpu"]},
            %{id: "task2", duration: 3, resources: ["memory"]}
          ]
        },
        %{
          id: "project2",
          activities: [
            %{id: "taskA", duration: 4, resources: ["disk"]},
            %{id: "taskB", duration: 2, resources: ["network"], dependencies: ["taskA"]}
          ]
        }
      ]

      result = Convergence.solve_activities_batch(activity_sets, approach: :nx, use_pytorch: false)

      assert %{
        batch_solved: true,
        activity_sets: solved_sets,
        total_count: 2,
        successful_count: _
      } = result

      assert length(solved_sets) == 2
      
      # Check that each activity set has a result
      Enum.each(solved_sets, fn activity_set ->
        assert Map.has_key?(activity_set, :result)
        assert Map.has_key?(activity_set.result, :solved)
      end)
    end

    test "solves multiple activity sets in batch with Flow approach" do
      activity_sets = [
        %{
          id: "set1",
          activities: [
            %{id: "task1", duration: 3, resources: ["cpu"]}
          ]
        }
      ]

      result = Convergence.solve_activities_batch(activity_sets, approach: :flow)

      assert %{
        batch_solved: true,
        activity_sets: solved_sets,
        total_count: 1,
        successful_count: _
      } = result

      assert length(solved_sets) == 1
    end
  end
end
