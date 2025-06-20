defmodule AriaEngine.PlanConverterISO8601Test do
  use ExUnit.Case
  alias AriaEngine.Scheduler.PlanConverter

  test "convert_plan_to_enhanced_schedule uses ISO8601 strings and add_durations/2" do
    # Simulate a plan with ISO8601 DateTime and duration strings
    base_time = "2025-06-20T18:00:00Z"
    activities = [
      %{id: "a", duration: "PT5M", dependencies: []},
      %{id: "b", duration: "PT10M", dependencies: ["a"]}
    ]

    # Simulate a primitive plan: a then b
    encapsulated_plan = %{
      internal_plan: [
        {"a", []},
        {"b", []}
      ]
    }

    # Patch PlanConverter to use our test plan and base_time
    defmodule Dummy do
      def get_internal_plan(plan), do: plan.internal_plan
    end

    # Patch Plan.Utils to just return the primitive actions
    defmodule DummyPlanUtils do
      def get_primitive_actions_dfs(plan), do: plan
    end

    # Inject dummy modules
    Code.put_compiler_option(:ignore_module_conflict, true)
    :code.purge(AriaEngine.Plan.Utils)
    :code.delete(AriaEngine.Plan.Utils)
    defmodule AriaEngine.Plan.Utils do
      def get_primitive_actions_dfs(plan), do: plan
    end
    Code.put_compiler_option(:ignore_module_conflict, false)

    # Patch HybridPlanner.DataStructures.EncapsulatedPlan
    :code.purge(HybridPlanner.DataStructures.EncapsulatedPlan)
    :code.delete(HybridPlanner.DataStructures.EncapsulatedPlan)
    defmodule HybridPlanner.DataStructures.EncapsulatedPlan do
      def get_internal_plan(plan), do: plan.internal_plan
    end

    # Call PlanConverter with ISO8601 strings
    entities = []
    resources = []
    base_datetime = base_time

    # This should not raise and should produce ISO8601 start/end times
    result =
      PlanConverter.convert_plan_to_enhanced_schedule(
        encapsulated_plan,
        activities,
        entities,
        resources,
        base_datetime
      )

    assert is_list(result)
    assert Enum.all?(result, fn act ->
      is_binary(act.start_time) and String.match?(act.start_time, ~r/T.*Z$/)
    end)
    assert Enum.all?(result, fn act ->
      is_binary(act.end_time) and String.match?(act.end_time, ~r/T.*Z$/)
    end)
  end
end
