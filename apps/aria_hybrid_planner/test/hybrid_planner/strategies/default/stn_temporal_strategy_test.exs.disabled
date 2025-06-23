defmodule HybridPlanner.Strategies.Default.STNTemporalStrategyTest do
  use ExUnit.Case, async: true

  alias HybridPlanner.Strategies.Default.STNTemporalStrategy

  describe "add_temporal_constraints/3" do
    test "adds temporal constraints for actions" do
      actions = [
        {"action1", %{duration: 5}},
        {"action2", %{duration: 3}},
        {"action3", %{duration: 2}}
      ]

      case STNTemporalStrategy.add_temporal_constraints(%{}, actions, verbose: 2) do
        {:ok, constraints} ->
          assert %{temporal_problem: problem} = constraints
          assert length(problem.actions) == 3
          assert problem.current_time == 0

        {:error, "MiniZinc solver is not available"} ->
          # This is expected if MiniZinc is not installed
          :ok

        {:error, reason} ->
          flunk("Unexpected error: #{reason}")
      end
    end

    test "handles empty actions list" do
      case STNTemporalStrategy.add_temporal_constraints(%{}, [], verbose: 2) do
        {:ok, constraints} ->
          assert %{temporal_problem: problem} = constraints
          assert length(problem.actions) == 0

        {:error, "MiniZinc solver is not available"} ->
          # This is expected if MiniZinc is not installed
          :ok

        {:error, reason} ->
          flunk("Unexpected error: #{reason}")
      end
    end
  end

  describe "validate_temporal_consistency/2" do
    test "validates consistent temporal constraints" do
      temporal_problem = %{
        actions: [
          {"action1", %{duration: 5}},
          {"action2", %{duration: 3}}
        ],
        constraints: [
          {:before, "action1", "action2"}
        ],
        current_time: 0
      }

      constraints = %{temporal_problem: temporal_problem}

      case STNTemporalStrategy.validate_temporal_consistency(constraints, verbose: 2) do
        {:ok, is_consistent} ->
          assert is_boolean(is_consistent)

        {:error, "MiniZinc solver is not available"} ->
          # This is expected if MiniZinc is not installed
          :ok

        {:error, reason} ->
          flunk("Unexpected error: #{reason}")
      end
    end

    test "handles empty constraints" do
      case STNTemporalStrategy.validate_temporal_consistency(%{}, verbose: 2) do
        {:ok, is_consistent} ->
          assert is_consistent == true

        {:error, "MiniZinc solver is not available"} ->
          # This is expected if MiniZinc is not installed
          :ok

        {:error, reason} ->
          flunk("Unexpected error: #{reason}")
      end
    end
  end

  describe "get_temporal_schedule/2" do
    test "generates temporal schedule" do
      temporal_problem = %{
        actions: [
          {"action1", %{duration: 5}},
          {"action2", %{duration: 3}},
          {"action3", %{duration: 2}}
        ],
        constraints: [
          {:before, "action1", "action2"},
          {:before, "action2", "action3"}
        ],
        current_time: 0
      }

      constraints = %{temporal_problem: temporal_problem}

      case STNTemporalStrategy.get_temporal_schedule(constraints, verbose: 2) do
        {:ok, schedule_result} ->
          assert %{schedule: schedule, generated_at: timestamp} = schedule_result
          assert is_integer(timestamp)
          assert is_map(schedule)

        {:error, "MiniZinc solver is not available"} ->
          # This is expected if MiniZinc is not installed
          :ok

        {:error, reason} ->
          flunk("Unexpected error: #{reason}")
      end
    end

    test "handles empty temporal problem" do
      case STNTemporalStrategy.get_temporal_schedule(%{}, verbose: 2) do
        {:ok, schedule_result} ->
          assert %{schedule: schedule, generated_at: timestamp} = schedule_result
          assert is_integer(timestamp)
          assert schedule == %{}

        {:error, "MiniZinc solver is not available"} ->
          # This is expected if MiniZinc is not installed
          :ok

        {:error, reason} ->
          flunk("Unexpected error: #{reason}")
      end
    end
  end

  describe "update_constraints/3" do
    test "updates constraints with modifications" do
      temporal_problem = %{
        actions: [{"action1", %{duration: 5}}],
        constraints: [],
        current_time: 0
      }

      constraints = %{temporal_problem: temporal_problem}
      modifications = [{:add_constraint, {:before, "action1", "action2"}}]

      case STNTemporalStrategy.update_constraints(constraints, modifications, verbose: 2) do
        {:ok, updated_constraints} ->
          assert %{temporal_problem: updated_problem} = updated_constraints
          assert length(updated_problem.constraints) == 1

        {:error, "MiniZinc solver is not available"} ->
          # This is expected if MiniZinc is not installed
          :ok

        {:error, reason} ->
          flunk("Unexpected error: #{reason}")
      end
    end
  end

  describe "strategy_info/0" do
    test "returns strategy metadata" do
      info = STNTemporalStrategy.strategy_info()

      assert %{
               name: "STN Temporal Strategy",
               version: "1.0.0",
               capabilities: capabilities,
               limitations: limitations
             } = info

      assert is_list(capabilities)
      assert is_list(limitations)
      assert :temporal_constraints in capabilities
    end
  end

  describe "supports?/1" do
    test "checks feature support" do
      assert STNTemporalStrategy.supports?(:temporal_constraints) == true
      assert STNTemporalStrategy.supports?(:consistency_checking) == true
      assert STNTemporalStrategy.supports?(:nonexistent_feature) == false
    end
  end

  describe "performance_profile/0" do
    test "returns performance characteristics" do
      profile = STNTemporalStrategy.performance_profile()

      assert %{
               constraint_addition_complexity: :linear,
               consistency_check_complexity: :polynomial,
               memory_usage: :moderate,
               scalability: :good,
               precision: :discrete_time
             } = profile
    end
  end
end
