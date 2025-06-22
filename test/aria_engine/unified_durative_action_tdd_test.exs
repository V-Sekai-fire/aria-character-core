defmodule AriaEngine.UnifiedDurativeActionTDDTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Domain
  alias AriaEngine.StateV2

  describe "Iteration 1: Infrastructure Foundation (Action Atom Priority Rule)" do
    test "action atoms resolve with higher priority than task methods" do
      domain = Domain.new("test_domain")
      |> Domain.add_action(:move, &move_action/2, %{duration: "PT1H"})
      |> Domain.add_task_method("task_move", &move_task/2)

      # Action atom should resolve first
      assert {:action, _} = Domain.resolve(:move, domain)
      assert {:task_method, _} = Domain.resolve("task_move", domain)
    end

    test "task methods use task_ prefix to avoid aliasing conflicts" do
      domain = Domain.new("test_domain")
      |> Domain.add_action(:cook, &cook_action/2, %{duration: "PT2H"})
      |> Domain.add_task_method("task_cook", &cook_task/2)

      # Both should be resolvable without conflicts
      assert {:action, _} = Domain.resolve(:cook, domain)
      assert {:task_method, _} = Domain.resolve("task_cook", domain)

      # Should not have aliasing conflicts
      refute Domain.resolve("cook", domain) == Domain.resolve("task_cook", domain)
    end

    test "automatic primitive method creation for actions" do
      domain = Domain.new("test_domain")
      |> Domain.add_action(:build, &build_action/2, %{duration: "PT30M"})

      # Should automatically create primitive task method
      assert {:task_method, _} = Domain.resolve("build", domain)
      assert {:action, _} = Domain.resolve(:build, domain)
    end

    test "domain creation and action registration" do
      domain = Domain.new("test_domain")

      assert domain.name == "test_domain"
      assert Domain.has_action?(domain, :nonexistent) == false

      domain = Domain.add_action(domain, :test_action, &test_action/2, %{duration: "PT15M"})
      assert Domain.has_action?(domain, :test_action) == true
    end
  end

  describe "Iteration 2: Metadata Validation Framework" do
    test "basic metadata structure validation" do
      domain = Domain.new("test_domain")

      # Valid metadata should work
      domain = Domain.add_action(domain, :valid_action, &test_action/2, %{
        duration: "PT1H",
        agent: "robot",
        entity: "package"
      })

      assert Domain.has_action?(domain, :valid_action)
    end

    test "type specification enforcement" do
      domain = Domain.new("test_domain")

      # Duration must be string
      assert_raise ArgumentError, fn ->
        Domain.add_action(domain, :invalid_duration, &test_action/2, %{
          duration: 3600  # Should be "PT1H"
        })
      end
    end

    test "error message clarity and specificity" do
      domain = Domain.new("test_domain")

      # Missing temporal specification
      assert_raise ArgumentError, ~r/must have at least one temporal specification/, fn ->
        Domain.add_action(domain, :no_temporal, &test_action/2, %{
          agent: "robot"
        })
      end
    end

    test "validation integration with Domain.add_action/3" do
      domain = Domain.new("test_domain")

      # Should validate metadata during action addition
      domain = Domain.add_action(domain, :integrated_action, &test_action/2, %{
        duration: "PT2H",
        agent: "worker",
        resource: "tool"
      })

      metadata = Domain.get_action_metadata(domain, :integrated_action)
      # Duration gets converted to an Interval struct
      assert %AriaEngine.Timeline.Interval{} = metadata.duration
      assert metadata.agent == "worker"
      assert metadata.resource == "tool"
    end

    test "invalid metadata rejection" do
      domain = Domain.new("test_domain")

      # Invalid ISO 8601 duration
      assert_raise ArgumentError, fn ->
        Domain.add_action(domain, :bad_duration, &test_action/2, %{
          duration: "invalid_duration"
        })
      end
    end
  end

  # Helper action functions for tests
  defp move_action(state, _args), do: state
  defp move_task(_state, _args), do: [{"task_walk", []}]
  defp cook_action(state, _args), do: state
  defp cook_task(_state, _args), do: [{"task_prepare", []}, {"task_heat", []}]
  defp build_action(state, _args), do: state
  defp test_action(state, _args), do: state
end
