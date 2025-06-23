# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DomainConverterTest do
  use ExUnit.Case, async: true
  alias AriaEngine.Scheduler.DomainConverter
  alias AriaEngine.State
  alias Domain

  describe("convert_activities_to_khr_domain/4") do
    test "compiles and runs without StateV2 undefined errors" do
      activities = [
        %{
          "id" => "test_activity",
          "duration" => %{"hours" => 1, "minutes" => 0, "seconds" => 0},
          "required_resources" => [],
          "dependencies" => []
        }
      ]

      entities = []
      resources = []
      constraints = %{}

      result =
        DomainConverter.convert_activities_to_khr_domain(
          activities,
          entities,
          resources,
          constraints
        )

      assert is_tuple(result)
      assert elem(result, 0) in [:ok, :error]
    end

    test "creates valid domain structure" do
      activities = [
        %{
          "id" => "simple_task",
          "duration" => %{"hours" => 2, "minutes" => 30, "seconds" => 0},
          "required_resources" => ["resource1"],
          "dependencies" => []
        }
      ]

      entities = []
      resources = []
      constraints = %{}

      assert {:ok, domain} =
               DomainConverter.convert_activities_to_khr_domain(
                 activities,
                 entities,
                 resources,
                 constraints
               )

      assert %Domain.Core{} = domain
    end
  end

  describe("create_durative_activity_action/3") do
    test "creates function that works with StateV2" do
      activity = %{
        "id" => "test_activity",
        "duration" => %{"hours" => 1, "minutes" => 0, "seconds" => 0},
        "required_resources" => ["resource1"]
      }

      entities = []
      resources = []
      action_fn = DomainConverter.create_durative_activity_action(activity, entities, resources)
      assert is_function(action_fn, 2)
      initial_state = State.new()
      result_state = action_fn.(initial_state, [])
      assert %State{} = result_state
      assert State.get_fact(result_state, "test_activity", "completed") == true
    end
  end
end