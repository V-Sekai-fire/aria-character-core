defmodule AriaEngine.RegressionTest do
  @moduledoc """
  Regression tests that run all GTPyhop example domains to verify
  they work without error and return correct answers.

  This is the Elixir port of GTPyhop's regression_tests.py which
  systematically tests all example domains.

  Ported from GTPyhop Examples/regression_tests.py
  -- Dana Nau <nau@umd.edu>, July 20, 2021
  """

  use ExUnit.Case
  import ExUnit.CaptureIO

  alias AriaEngine.Planning.GTNPlanner
  alias AriaEngine.Planning.HTNPlanner
  alias AriaEngine.Domain
  alias AriaEngine.State
  alias AriaEngine.TestDomains

  @tag timeout: 30_000
  test "regression test - all example domains run without error" do
    # Test all the ported examples to ensure they work correctly

    # Run blocks_gtn tests
    assert run_blocks_gtn_tests() == :ok

    # Run blocks_hgn tests
    assert run_blocks_hgn_tests() == :ok

    # Run blocks_goal_splitting tests
    assert run_blocks_goal_splitting_tests() == :ok

    # Run pyhop_simple_travel tests
    assert run_pyhop_simple_travel_tests() == :ok

    IO.puts("\nAll regression tests finished without error.")
  end

  defp run_blocks_gtn_tests do
    # Basic blocks GTN test
    state = %State{
      data: %{
        pos: %{a: :b, b: :table, c: :table},
        clear: MapSet.new([:a, :c]),
        holding: false
      }
    }

    domain = TestDomains.build_blocks_gtn_domain()

    # Test multigoal planning
    goals = [
      {:pos, :b, :c},
      {:pos, :a, :b}
    ]

    case GTNPlanner.plan(state, goals, domain, max_depth: 10) do
      {:ok, _plan} -> :ok
      {:error, reason} ->
        IO.puts("blocks_gtn test failed: #{inspect(reason)}")
        :error
    end
  end

  defp run_blocks_hgn_tests do
    # Basic blocks HGN test
    state = %State{
      data: %{
        pos: %{a: :b, b: :table, c: :table},
        clear: MapSet.new([:a, :c]),
        holding: false
      }
    }

    domain = TestDomains.build_blocks_hgn_domain()

    # Test unigoal planning
    goals = [
      {:pos, :b, :c}
    ]

    case GTNPlanner.plan(state, goals, domain, max_depth: 10) do
      {:ok, _plan} -> :ok
      {:error, reason} ->
        IO.puts("blocks_hgn test failed: #{inspect(reason)}")
        :error
    end
  end

  defp run_blocks_goal_splitting_tests do
    # Basic blocks goal splitting test
    state = %State{
      data: %{
        pos: %{a: :b, b: :table, c: :table},
        clear: MapSet.new([:a, :c]),
        holding: false
      }
    }

    domain = TestDomains.build_blocks_goal_splitting_domain()

    # Test goal splitting approach
    goals = [
      {:pos, :b, :c},
      {:pos, :a, :b}
    ]

    case GTNPlanner.plan(state, goals, domain, max_depth: 15) do
      {:ok, _plan} -> :ok
      {:error, reason} ->
        IO.puts("blocks_goal_splitting test failed: #{inspect(reason)}")
        :error
    end
  end

  defp run_pyhop_simple_travel_tests do
    # Basic simple travel test
    state = %State{
      data: %{
        loc: %{me: :home},
        cash: %{me: 20},
        owe: %{me: 0}
      }
    }

    domain = TestDomains.build_pyhop_simple_travel_domain()

    # Test travel planning
    tasks = [
      {:travel, :me, :park}
    ]

    case HTNPlanner.plan(state, tasks, domain, max_depth: 10) do
      {:ok, _plan} -> :ok
      {:error, reason} ->
        IO.puts("pyhop_simple_travel test failed: #{inspect(reason)}")
        :error
    end
  end
end
    Domain.new()
    |> Domain.add_multigoal_method(:moveblocks, &moveblocks_method/3)
    |> Domain.add_task_method(:take, &take_method/3)
    |> Domain.add_task_method(:put, &put_method/3)
    |> Domain.add_action(:pickup, &pickup_action/2, &pickup_precond/1)
    |> Domain.add_action(:unstack, &unstack_action/2, &unstack_precond/1)
    |> Domain.add_action(:putdown, &putdown_action/2, &putdown_precond/1)
    |> Domain.add_action(:stack, &stack_action/2, &stack_precond/1)
  end

  defp build_blocks_hgn_domain do
    Domain.new()
    |> Domain.add_unigoal_method(:pos, &pos_take_method/3)
    |> Domain.add_unigoal_method(:pos, &pos_put_method/3)
    |> Domain.add_action(:pickup, &pickup_action/2, &pickup_precond/1)
    |> Domain.add_action(:unstack, &unstack_action/2, &unstack_precond/1)
    |> Domain.add_action(:putdown, &putdown_action/2, &putdown_precond/1)
    |> Domain.add_action(:stack, &stack_action/2, &stack_precond/1)
  end

  defp build_blocks_goal_splitting_domain do
    Domain.new()
    |> Domain.add_multigoal_method(:split_multigoal, &split_multigoal_method/3)
    |> Domain.add_unigoal_method(:pos, &pos_unigoal_method/3)
    |> Domain.add_unigoal_method(:clear, &clear_unigoal_method/3)
    |> Domain.add_unigoal_method(:holding, &holding_unigoal_method/3)
    |> Domain.add_action(:pickup, &pickup_action/2, &pickup_precond/1)
    |> Domain.add_action(:unstack, &unstack_action/2, &unstack_precond/1)
    |> Domain.add_action(:putdown, &putdown_action/2, &putdown_precond/1)
    |> Domain.add_action(:stack, &stack_action/2, &stack_precond/1)
  end

  defp build_simple_travel_domain do
    Domain.new()
    |> Domain.add_method(:travel, &travel_by_foot/3)
    |> Domain.add_method(:travel, &travel_by_taxi/3)
    |> Domain.add_action(:walk, &walk_action/2, &walk_precond/1)
    |> Domain.add_action(:call_taxi, &call_taxi_action/2, &call_taxi_precond/1)
    |> Domain.add_action(:ride_taxi, &ride_taxi_action/2, &ride_taxi_precond/1)
    |> Domain.add_action(:pay_driver, &pay_driver_action/2, &pay_driver_precond/1)
  end

  # Simplified method implementations for testing

  defp moveblocks_method(state, goals, _domain) do
    if Enum.empty?(goals) do
      {:ok, []}
    else
      # Simple implementation - just return take/put tasks for each goal
      tasks = Enum.flat_map(goals, fn
        {:pos, block, dest} ->
          [{:take, block}, {:put, block, dest}]
        _ -> []
      end)
      {:ok, tasks}
    end
  end

  defp take_method(state, [block], _domain) do
    current_pos = get_in(state.data, [:pos, block])
    if current_pos == :table do
      {:ok, [{:pickup, block}]}
    else
      {:ok, [{:unstack, block, current_pos}]}
    end
  end

  defp put_method(state, [block, dest], _domain) do
    if dest == :table do
      {:ok, [{:putdown, block}]}
    else
      {:ok, [{:stack, block, dest}]}
    end
  end

  defp pos_take_method(state, [:pos, block, dest], _domain) do
    current_pos = get_in(state.data, [:pos, block])
    if current_pos != dest do
      clear_block = MapSet.member?(get_in(state.data, [:clear]) || MapSet.new(), block)
      holding = get_in(state.data, [:holding])

      cond do
        not clear_block -> {:fail, "block not clear"}
        holding != false -> {:fail, "already holding something"}
        current_pos == :table -> {:ok, [{:pickup, block}]}
        true -> {:ok, [{:unstack, block, current_pos}]}
      end
    else
      {:fail, "already at destination"}
    end
  end

  defp pos_put_method(state, [:pos, block, dest], _domain) do
    holding = get_in(state.data, [:holding])
    if holding == block do
      if dest == :table do
        {:ok, [{:putdown, block}]}
      else
        clear_dest = MapSet.member?(get_in(state.data, [:clear]) || MapSet.new(), dest)
        if clear_dest do
          {:ok, [{:stack, block, dest}]}
        else
          {:fail, "destination not clear"}
        end
      end
    else
      {:fail, "not holding the block"}
    end
  end

  defp split_multigoal_method(_state, goals, _domain) do
    # Convert multigoals to sequential unigoals
    if length(goals) > 1 do
      [first_goal | rest_goals] = goals
      {:ok, [first_goal, rest_goals]}
    else
      {:ok, goals}
    end
  end

  defp pos_unigoal_method(state, [:pos, block, dest], _domain) do
    current_pos = get_in(state.data, [:pos, block])
    if current_pos != dest do
      tasks = []
      # Add take task if not holding
      tasks = if get_in(state.data, [:holding]) != block do
        tasks ++ [{:take, block}]
      else
        tasks
      end
      # Add put task
      tasks = tasks ++ [{:put, block, dest}]
      {:ok, tasks}
    else
      {:ok, []}
    end
  end

  defp clear_unigoal_method(state, [:clear, block], _domain) do
    clear = MapSet.member?(get_in(state.data, [:clear]) || MapSet.new(), block)
    if not clear do
      # Find what's on top and move it
      on_top = Enum.find_value(get_in(state.data, [:pos]) || %{}, fn {b, pos} ->
        if pos == block, do: b, else: nil
      end)
      if on_top do
        {:ok, [
          {:take, on_top},
          {:put, on_top, :table}
        ]}
      else
        {:fail, "cannot clear block"}
      end
    else
      {:ok, []}
    end
  end

  defp holding_unigoal_method(state, [:holding, block], _domain) do
    current_holding = get_in(state.data, [:holding])
    if current_holding != block do
      {:ok, [{:take, block}]}
    else
      {:ok, []}
    end
  end

  defp travel_by_foot(_state, [_person, dest], _domain) do
    {:ok, [{:walk, dest}]}
  end

  defp travel_by_taxi(state, [person, dest], _domain) do
    cash = get_in(state.data, [:cash, person]) || 0
    if cash >= 10 do
      {:ok, [
        {:call_taxi, dest},
        {:ride_taxi, dest},
        {:pay_driver}
      ]}
    else
      {:fail, "not enough cash for taxi"}
    end
  end

  # Action implementations (simplified for testing)

  defp pickup_action(state, [block]) do
    new_state = state
    |> put_in([:data, :holding], block)
    |> update_in([:data, :clear], &MapSet.delete(&1, block))
    |> update_in([:data, :clear], &MapSet.put(&1, get_in(state.data, [:pos, block])))
    |> put_in([:data, :pos, block], :held)

    {:ok, new_state}
  end

  defp pickup_precond(state) do
    get_in(state.data, [:holding]) == false
  end

  defp unstack_action(state, [block, _from]) do
    pickup_action(state, [block])
  end

  defp unstack_precond(state) do
    pickup_precond(state)
  end

  defp putdown_action(state, [block]) do
    new_state = state
    |> put_in([:data, :holding], false)
    |> put_in([:data, :pos, block], :table)
    |> update_in([:data, :clear], &MapSet.put(&1, block))

    {:ok, new_state}
  end

  defp putdown_precond(state) do
    get_in(state.data, [:holding]) != false
  end

  defp stack_action(state, [block, dest]) do
    new_state = state
    |> put_in([:data, :holding], false)
    |> put_in([:data, :pos, block], dest)
    |> update_in([:data, :clear], &MapSet.put(&1, block))
    |> update_in([:data, :clear], &MapSet.delete(&1, dest))

    {:ok, new_state}
  end

  defp stack_precond(state) do
    get_in(state.data, [:holding]) != false
  end

  defp walk_action(state, [dest]) do
    new_state = put_in(state, [:data, :loc, :me], dest)
    {:ok, new_state}
  end

  defp walk_precond(_state), do: true

  defp call_taxi_action(state, [_dest]) do
    {:ok, state}  # No state change for calling taxi
  end

  defp call_taxi_precond(_state), do: true

  defp ride_taxi_action(state, [dest]) do
    new_state = put_in(state, [:data, :loc, :me], dest)
    {:ok, new_state}
  end

  defp ride_taxi_precond(_state), do: true

  defp pay_driver_action(state, []) do
    current_cash = get_in(state.data, [:cash, :me]) || 0
    new_state = put_in(state, [:data, :cash, :me], current_cash - 10)
    {:ok, new_state}
  end

  defp pay_driver_precond(state) do
    cash = get_in(state.data, [:cash, :me]) || 0
    cash >= 10
  end
end
