# Debug script for phone charging backtracking test
# Usage: mix run debug_phone_charging.exs

defmodule PhoneChargingDebug do
  alias AriaEngine.{Domain, State}
  alias AriaEngine.Domain.DurativeAction
  alias AriaEngine.Timeline.STN
  alias AriaEngine.Plan

  def test_phone_charging do
    IO.puts("=== Testing Phone Charging Backtracking ===")
    
    # Create domain for phone charging scenario
    domain = Domain.Core.new("phone_charging")
    
    # Create STN for timeline management
    stn = STN.new()
    
    # Add fast charging durative action - will fail (no fast charger available)
    fast_charge = DurativeAction.new(
      :fast_charge,
      {:fixed, 300000},  # 5 minutes in milliseconds
      %{
        at_start: [{"fast_charger", "available", true}],  # Will fail - not available
        over_all: [],
        at_end: []
      },
      %{
        at_start: [],
        at_end: [{"battery", "phone", "50%"}],
        over_time: []
      },
      fn state, _args ->
        state |> State.set_fact("battery", "phone", "50%")
      end
    )
    domain = Domain.Core.add_durative_action(domain, :fast_charge, fast_charge)
    stn = STN.Core.add_durative_action(stn, fast_charge)
    
    # Add slow charging durative action - will succeed
    slow_charge = DurativeAction.new(
      :slow_charge,
      {:fixed, 1200000},  # 20 minutes in milliseconds
      %{
        at_start: [{"power_outlet", "available", true}],  # Will succeed
        over_all: [],
        at_end: []
      },
      %{
        at_start: [],
        at_end: [{"battery", "phone", "50%"}],
        over_time: []
      },
      fn state, _args ->
        state |> State.set_fact("battery", "phone", "50%")
      end
    )
    domain = Domain.Core.add_durative_action(domain, :slow_charge, slow_charge)
    stn = STN.Core.add_durative_action(stn, slow_charge)
    
    # Add timeline constraint: must finish charging before meeting (30 min deadline)
    stn = STN.add_constraint(stn, "start", "meeting_deadline", {1800000, 1800000})  # 30 min total
    
    # Add multiple methods for the same goal so planner can backtrack
    # Method 1: Try fast charging first (will fail)
    domain = Domain.add_unigoal_method(domain, "battery", "try_fast_charge", fn state, [device, target_level] ->
      current_level = State.get_fact(state, "battery", device)
      if current_level != target_level do
        IO.puts("Fast charge method called: current=#{current_level}, target=#{target_level}")
        result = [{:fast_charge, []}]
        IO.puts("Fast charge method returning: #{inspect(result)}")
        result
      else
        []
      end
    end)
    
    # Method 2: Try slow charging (will succeed after fast charge fails)
    domain = Domain.add_unigoal_method(domain, "battery", "try_slow_charge", fn state, [device, target_level] ->
      current_level = State.get_fact(state, "battery", device)
      if current_level != target_level do
        IO.puts("Slow charge method called: current=#{current_level}, target=#{target_level}")
        result = [{:slow_charge, []}]
        IO.puts("Slow charge method returning: #{inspect(result)}")
        result
      else
        []
      end
    end)
    
    # Initial state - no fast charger available, but power outlet available
    initial_state = State.new()
    |> State.set_fact("battery", "phone", "10%")
    |> State.set_fact("fast_charger", "available", false)  # Fast charger unavailable
    |> State.set_fact("power_outlet", "available", true)   # Power outlet available
    
    IO.puts("Initial state:")
    IO.inspect(initial_state, label: "State")
    
    IO.puts("\nDomain info:")
    IO.puts("Durative actions: #{inspect(Map.keys(domain.durative_actions))}")
    
    # Goal: charge phone to 50%
    todos = [{"battery", "phone", "50%"}]
    
    IO.puts("\nTrying to plan with todos: #{inspect(todos)}")
    
    # Verify STN is consistent before planning
    IO.puts("STN consistent? #{STN.consistent?(stn)}")
    
    # Planning should backtrack from failed fast charge to successful slow charge
    case AriaEngine.Plan.Core.plan(domain, initial_state, todos, verbose: 3) do
      {:ok, solution_tree} ->
        IO.puts("✅ Planning succeeded!")
        
        # Verify the solution used slow charge (not fast charge)
        actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
        IO.puts("Actions found: #{inspect(actions)}")
        IO.puts("Number of actions: #{length(actions)}")
        
        # Print solution tree structure
        IO.puts("\nSolution tree nodes:")
        Enum.each(solution_tree.nodes, fn {id, node} ->
          IO.puts("Node #{id}: task=#{inspect(node.task)}, primitive=#{node.is_primitive}, durative=#{node.is_durative}, expanded=#{node.expanded}")
        end)
        
      {:error, reason} ->
        IO.puts("❌ Planning failed: #{reason}")
    end
  end
end

PhoneChargingDebug.test_phone_charging()
