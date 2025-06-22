defmodule AriaEngine.UnifiedDurativeActionTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Domain
  alias AriaEngine.StateV2

  describe "Iteration 1: Fixed Schedule Support" do
    test "validates ISO 8601 datetime strings for fixed scheduling" do
      domain = Domain.new("test_domain")

      # Valid fixed interval (start + end)
      domain = Domain.add_action(domain, :meeting, &meeting_action/2, %{
        start: "2025-06-22T10:00:00Z",
        end: "2025-06-22T11:00:00Z",
        description: "Team meeting"
      })

      # Valid open-ended interval (start only)
      domain = Domain.add_action(domain, :project_start, &project_action/2, %{
        start: "2025-06-22T09:00:00Z",
        description: "Project kickoff"
      })

      # Valid open-ended interval (end only)
      domain = Domain.add_action(domain, :deadline, &deadline_action/2, %{
        end: "2025-06-22T17:00:00Z",
        description: "Must finish by end of day"
      })

      # Verify all actions were added successfully
      assert Domain.has_action?(domain, :meeting)
      assert Domain.has_action?(domain, :project_start)
      assert Domain.has_action?(domain, :deadline)
    end

    test "rejects invalid temporal specification combinations" do
      domain = Domain.new("test_domain")

      # Cannot mix duration with start/end
      assert_raise ArgumentError, ~r/invalid temporal specification/, fn ->
        Domain.add_action(domain, :invalid_action, &test_action/2, %{
          duration: "PT2H",
          start: "2025-06-22T10:00:00Z"
        })
      end

      # Missing temporal specification now defaults to PT0S duration
      domain = Domain.add_action(domain, :default_duration_action, &test_action/2, %{
        description: "No temporal info - should default to PT0S"
      })

      # Verify action was added with default duration
      assert Domain.has_action?(domain, :default_duration_action)
      metadata = Domain.get_action_metadata(domain, :default_duration_action)
      assert %AriaEngine.Timeline.Interval{} = metadata.duration
    end

    test "validates ISO 8601 datetime format" do
      domain = Domain.new("test_domain")

      # Invalid datetime format
      assert_raise ArgumentError, ~r/invalid ISO 8601 datetime/, fn ->
        Domain.add_action(domain, :invalid_action, &test_action/2, %{
          start: "invalid-datetime"
        })
      end

      # Missing timezone
      assert_raise ArgumentError, ~r/invalid ISO 8601 datetime/, fn ->
        Domain.add_action(domain, :invalid_action, &test_action/2, %{
          start: "2025-06-22T10:00:00"
        })
      end
    end

    test "validates start time before end time for fixed intervals" do
      domain = Domain.new("test_domain")

      # Start time after end time
      assert_raise ArgumentError, ~r/start time must be before end time/, fn ->
        Domain.add_action(domain, :invalid_action, &test_action/2, %{
          start: "2025-06-22T11:00:00Z",
          end: "2025-06-22T10:00:00Z"
        })
      end
    end

    test "preserves existing floating duration support" do
      domain = Domain.new("test_domain")

      # Existing floating duration should still work
      domain = Domain.add_action(domain, :cook_meal, &cook_action/2, %{
        duration: "PT2H",
        description: "Cooking task"
      })

      metadata = Domain.get_action_metadata(domain, :cook_meal)
      assert metadata.description == "Cooking task"
      # Duration should be normalized to Interval struct
      assert %AriaEngine.Timeline.Interval{} = metadata.duration
    end
  end

  describe "Iteration 2: Metadata Validation Framework" do
    test "validates unified entity requirements structure" do
      domain = Domain.new("test_domain")

      # Valid entity requirements
      domain = Domain.add_action(domain, :cook_meal, &cook_action/2, %{
        duration: "PT2H",
        requires_entities: [
          %{type: "agent", capabilities: [:cooking, :menu_planning]},
          %{type: "oven", capabilities: [:heating, :baking]},
          %{type: "flour", capabilities: [:consumable]},
          %{type: "mixing_bowl", capabilities: [:container, :reusable]}
        ],
        description: "Prepare a meal"
      })

      # Verify action was added successfully
      assert Domain.has_action?(domain, :cook_meal)
    end

    test "rejects invalid entity requirements" do
      domain = Domain.new("test_domain")

      # Missing type field
      assert_raise ArgumentError, ~r/entity requirement must have :type field/, fn ->
        Domain.add_action(domain, :invalid_action, &test_action/2, %{
          duration: "PT1H",
          requires_entities: [
            %{capabilities: [:cooking]}  # Missing type
          ]
        })
      end

      # Invalid capabilities (not list of atoms)
      assert_raise ArgumentError, ~r/capabilities must be list of atoms/, fn ->
        Domain.add_action(domain, :invalid_action, &test_action/2, %{
          duration: "PT1H",
          requires_entities: [
            %{type: "agent", capabilities: "cooking"}  # String instead of list
          ]
        })
      end
    end
  end

  describe "End-to-End Integration" do
    test "complete unified action specification works" do
      domain = Domain.new("test_domain")

      # Add action with full unified specification
      domain = Domain.add_action(domain, :cook_meal, &cook_meal_implementation/2, %{
        duration: "PT2H",
        requires_entities: [
          %{type: "agent", capabilities: [:cooking]},
          %{type: "oven", capabilities: [:heating]}
        ],
        description: "Complete cooking action"
      })

      # Verify action was added
      assert Domain.has_action?(domain, :cook_meal)

      # Verify metadata was stored correctly
      metadata = Domain.get_action_metadata(domain, :cook_meal)
      assert metadata.description == "Complete cooking action"
      assert length(metadata.requires_entities) == 2

      # Verify action can be executed
      state = StateV2.new()
      |> StateV2.set_fact("chef", "capabilities", [:cooking])
      |> StateV2.set_fact("oven", "capabilities", [:heating])

      assert {:ok, _new_state} = Domain.execute_action(domain, state, :cook_meal, ["pasta"])
    end
  end

  # Helper action functions for tests
  defp meeting_action(state, _args), do: state
  defp project_action(state, _args), do: state
  defp deadline_action(state, _args), do: state
  defp test_action(state, _args), do: state
  defp cook_action(state, _args), do: state

  defp cook_meal_implementation(state, [meal_type]) do
    StateV2.set_fact(state, "meal", "status", "cooked")
    |> StateV2.set_fact("meal", "type", meal_type)
  end
end
