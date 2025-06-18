# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Unit.MathNodesPlannerTest do
  use ExUnit.Case
  alias StateV2
  alias NodeLibrary.KHRInteractivityDomain
  alias Domain.Core
  alias Planner

  setup do
    # Create domain with complete KHR registration (actions + task methods)
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    # Initial state
    initial_state = StateV2.new()
    |> StateV2.add_fact("test", "ready", true)
    
    {:ok, domain: domain, state: initial_state}
  end

  # Helper function to execute a plan and return final state
  defp execute_plan(plan, domain, initial_state) do
    Enum.reduce(plan, initial_state, fn {action, args}, current_state ->
      case Domain.execute_action(domain, current_state, action, args) do
        {:ok, new_state} -> new_state
        {:error, _reason} -> current_state
      end
    end)
  end

  describe "math constants via planner" do
    test "khr_math_e returns Euler's number", %{domain: domain, state: state} do
      goals = [{"math/e", [0]}]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          final_state = execute_plan(plan, domain, state)
          
          assert StateV2.get_fact(final_state, 0, "value") == :math.exp(1)
          assert_in_delta StateV2.get_fact(final_state, 0, "value"), 2.718281828459045, 1.0e-15
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
    
    test "khr_math_pi returns pi constant", %{domain: domain, state: state} do
      goals = [{"math/pi", [1]}]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          final_state = execute_plan(plan, domain, state)
          
          assert StateV2.get_fact(final_state, 1, "value") == :math.pi()
          assert_in_delta StateV2.get_fact(final_state, 1, "value"), 3.141592653589793, 1.0e-15
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
  end

  describe "math arithmetic via planner" do
    test "khr_math_add with two positive numbers", %{domain: domain, state: state} do
      goals = [{"math/add", [25, 2.1, 3.5]}]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          final_state = execute_plan(plan, domain, state)
          
          assert_in_delta StateV2.get_fact(final_state, 25, "value"), 5.6, 1.0e-15
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
    
    test "khr_math_mul basic multiplication", %{domain: domain, state: state} do
      goals = [{"math/mul", [28, 3.0, 4.0]}]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          final_state = execute_plan(plan, domain, state)
          
          assert StateV2.get_fact(final_state, 28, "value") == 12.0
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
    
    test "khr_math_div by zero with positive numerator", %{domain: domain, state: state} do
      goals = [{"math/div", [30, 5.0, 0.0]}]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          final_state = execute_plan(plan, domain, state)
          
          assert StateV2.get_fact(final_state, 30, "value") == :positive_infinity
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
  end

  describe "sequential math operations via planner" do
    test "complex math chain: ((5 + 3) * 2) / 4 = 4", %{domain: domain, state: state} do
      goals = [
        {"math/add", [1, 5, 3]},      # Step 1: Add 5 + 3, store in node 1
        {"math/mul", [2, 1, 2]},      # Step 2: Multiply node 1 by 2, store in node 2 
        {"math/div", [3, 2, 4]}       # Step 3: Divide node 2 by 4, store in node 3
      ]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          final_state = execute_plan(plan, domain, state)
          
          # Verify intermediate and final results
          assert StateV2.get_fact(final_state, 1, "value") == 8  # 5 + 3
          assert StateV2.get_fact(final_state, 2, "value") == 16 # 8 * 2
          assert StateV2.get_fact(final_state, 3, "value") == 4.0 # 16 / 4
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
  end
end
