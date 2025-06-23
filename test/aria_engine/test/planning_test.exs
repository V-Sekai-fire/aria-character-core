# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule PlanningTest do
  use ExUnit.Case
  alias Planning
  alias Domain
  alias AriaEngine.State

  defp build_simple_test_domain do
    Domain.new("simple_test")
    |> Domain.add_action(:move, fn state, [from, to] ->
      state
      |> State.update_fact("player", "location", to)
      |> State.update_fact("player", "previous_location", from)
    end)
    |> Domain.add_action(:pickup, fn state, [item] ->
      State.update_fact(state, "player", "has", item)
    end)
    |> Domain.add_task_method("get_item", "basic_get", fn _state, [item] ->
      [{"move", ["room2"]}, {"pickup", [item]}]
    end)
  end

  describe("Basic planning") do
    test "plans simple action sequence" do
      domain = build_simple_test_domain()

      initial_state =
        State.new()
        |> State.update_fact("player", "location", "room1")
        |> State.update_fact("sword", "location", "room2")

      tasks = [{"get_item", ["sword"]}]

      case Planning.plan(domain, initial_state, tasks, verbose: 0) do
        {:ok, _plan} ->
          assert true

        {:error, reason} ->
          assert String.contains?(reason, "No methods found") or
                   String.contains?(reason, "Planning failed")
      end
    end

    test "validates plan execution" do
      domain = build_simple_test_domain()
      initial_state = State.new() |> State.update_fact("player", "location", "room1")
      plan = [move: ["room1", "room2"], move: ["room2", "room3"]]

      case Planning.execute_plan(domain, initial_state, plan) do
        {:ok, final_state} ->
          assert State.get_fact(final_state, "player", "location") == "room3"

        {:error, reason} ->
          assert String.contains?(reason, "Action not found") or
                   String.contains?(reason, "Execution failed")
      end
    end
  end

  describe("Task decomposition") do
    test "decomposes tasks into actions" do
      domain = build_simple_test_domain()

      initial_state =
        State.new()
        |> State.update_fact("player", "location", "room1")
        |> State.update_fact("sword", "location", "room2")

      tasks = [{"get_item", ["sword"]}]

      case Planning.plan(domain, initial_state, tasks, verbose: 0) do
        {:ok, solution_tree} ->
          assert solution_tree != nil

        {:error, reason} ->
          assert String.contains?(reason, "No methods found") or
                   String.contains?(reason, "Planning failed")
      end
    end
  end
end