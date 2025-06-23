defmodule BlocksGTNTest do
  @moduledoc "Test suite for Blocks World Goal-Task-Network (GTN) planning.\n\nThis implements the blocks_gtn example from GTPyhop, which uses both\ngoals and tasks for blocks world planning using the near-optimal\nalgorithm from Gupta & Nau (1992).\n"
  use ExUnit.Case
  import AriaEngine
  alias {State, Multigoal, TestDomains}
  @moduletag timeout: 120_000
  describe("Blocks GTN domain") do
    test "domain creation and basic functionality" do
      domain = TestDomains.build_blocks_gtn_domain()
      summary = domain_summary(domain)
      assert summary.name == "blocks_gtn"
      assert :pickup in summary.actions
      assert :putdown in summary.actions
      assert :stack in summary.actions
      assert :unstack in summary.actions
      assert "take" in summary.task_methods
      assert "put" in summary.task_methods
    end

    test "simple failing cases" do
      domain = TestDomains.build_blocks_gtn_domain()

      state1 =
        create_state()
        |> set_fact("pos", "a", "b")
        |> set_fact("pos", "b", "table")
        |> set_fact("pos", "c", "table")
        |> set_fact("clear", "c", true)
        |> set_fact("clear", "b", false)
        |> set_fact("clear", "a", true)
        |> set_fact("holding", "hand", false)

      assert {:error, _} = plan(domain, state1, [{"pickup", "a"}])
      assert {:error, _} = plan(domain, state1, [{"pickup", "b"}])
      assert {:error, _} = plan(domain, state1, [{"take", "b"}])
    end

    test "simple succeeding cases" do
      domain = TestDomains.build_blocks_gtn_domain()

      state1 =
        create_state()
        |> set_fact("pos", "a", "b")
        |> set_fact("pos", "b", "table")
        |> set_fact("pos", "c", "table")
        |> set_fact("clear", "c", true)
        |> set_fact("clear", "b", false)
        |> set_fact("clear", "a", true)
        |> set_fact("holding", "hand", false)

      {:ok, plan} = plan(domain, state1, [{"pickup", "c"}])
      assert plan == [{"pickup", "c"}]
      {:ok, plan} = plan(domain, state1, [{"take", "a"}])
      assert plan == [{"unstack", "a", "b"}]
      {:ok, plan} = plan(domain, state1, [{"take", "c"}])
      assert plan == [{"pickup", "c"}]
      {:ok, plan} = plan(domain, state1, [{"take", "a"}, {"put", "a", "table"}])
      assert plan == [{"unstack", "a", "b"}, {"putdown", "a"}]
    end

    test "multigoal planning - tower c on b on a" do
      domain = TestDomains.build_blocks_gtn_domain()

      state1 =
        create_state()
        |> set_fact("pos", "a", "b")
        |> set_fact("pos", "b", "table")
        |> set_fact("pos", "c", "table")
        |> set_fact("clear", "c", true)
        |> set_fact("clear", "b", false)
        |> set_fact("clear", "a", true)
        |> set_fact("holding", "hand", false)

      goal1a = %Multigoal{
        name: "goal1a",
        goals: %{"pos" => %{"c" => "b", "b" => "a", "a" => "table"}}
      }

      expected = [
        {"unstack", "a", "b"},
        {"putdown", "a"},
        {"pickup", "b"},
        {"stack", "b", "a"},
        {"pickup", "c"},
        {"stack", "c", "b"}
      ]

      {:ok, plan} = plan(domain, state1, [goal1a])
      assert plan == expected
      goal1b = %Multigoal{name: "goal1b", goals: %{"pos" => %{"c" => "b", "b" => "a"}}}
      {:ok, plan} = plan(domain, state1, [goal1b])
      assert plan == expected
    end

    test "sussman anomaly" do
      domain = TestDomains.build_blocks_gtn_domain()

      sus_s0 =
        create_state()
        |> set_fact("pos", "c", "a")
        |> set_fact("pos", "a", "table")
        |> set_fact("pos", "b", "table")
        |> set_fact("clear", "c", true)
        |> set_fact("clear", "a", false)
        |> set_fact("clear", "b", true)
        |> set_fact("holding", "hand", false)

      sus_sg = %Multigoal{name: "sussman_goal", goals: %{"pos" => %{"a" => "b", "b" => "c"}}}

      expected = [
        {"unstack", "c", "a"},
        {"putdown", "c"},
        {"pickup", "b"},
        {"stack", "b", "c"},
        {"pickup", "a"},
        {"stack", "a", "b"}
      ]

      {:ok, plan} = plan(domain, sus_s0, [sus_sg])
      assert plan == expected
    end

    test "complex state manipulation" do
      domain = TestDomains.build_blocks_gtn_domain()

      state2 =
        create_state()
        |> set_fact("pos", "a", "c")
        |> set_fact("pos", "b", "d")
        |> set_fact("pos", "c", "table")
        |> set_fact("pos", "d", "table")
        |> set_fact("clear", "a", true)
        |> set_fact("clear", "c", false)
        |> set_fact("clear", "b", true)
        |> set_fact("clear", "d", false)
        |> set_fact("holding", "hand", false)

      goal2a = %Multigoal{
        name: "goal2a",
        goals: %{
          "pos" => %{"b" => "c", "a" => "d", "c" => "table", "d" => "table"},
          "clear" => %{"a" => true, "c" => false, "b" => true, "d" => false},
          "holding" => %{"hand" => false}
        }
      }

      goal2b = %Multigoal{name: "goal2b", goals: %{"pos" => %{"b" => "c", "a" => "d"}}}

      expected = [
        {"unstack", "a", "c"},
        {"putdown", "a"},
        {"unstack", "b", "d"},
        {"stack", "b", "c"},
        {"pickup", "a"},
        {"stack", "a", "d"}
      ]

      {:ok, plan1} = plan(domain, state2, [goal2a])
      {:ok, plan2} = plan(domain, state2, [goal2b])
      assert plan1 == expected
      assert plan2 == expected
    end
  end
end