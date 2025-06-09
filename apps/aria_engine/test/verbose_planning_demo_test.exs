defmodule AriaEngine.VerbosePlanningDemoTest do
  use ExUnit.Case
  alias AriaEngine.TestDomains

  @moduletag :demo

  describe "Verbose Planning Demo" do
    test "demonstrates verbose planning at different levels" do
      IO.puts("\n#{String.duplicate("=", 80)}")
      IO.puts("ARIA ENGINE VERBOSE PLANNING DEMONSTRATION")
      IO.puts("#{String.duplicate("=", 80)}")
      
      domain = TestDomains.build_rpg_domain()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("location", "sword", "room2")

      IO.puts("\nINITIAL STATE:")
      IO.inspect(initial_state.data, label: "State Facts")

      tasks = [{"get_item", ["sword"]}]
      IO.puts("\nGOAL: #{inspect(tasks)}")

      # Test verbose level 0 (default)
      IO.puts("\n#{String.duplicate("-", 60)}")
      IO.puts("VERBOSE LEVEL 0 (Default - No verbose output)")
      IO.puts("#{String.duplicate("-", 60)}")
      
      case AriaEngine.plan(domain, initial_state, tasks, verbose: 0) do
        {:ok, plan} ->
          IO.puts("✓ Planning completed silently")
          IO.puts("Plan: #{inspect(plan)}")
        {:error, reason} ->
          IO.puts("✗ Planning failed: #{reason}")
      end

      # Test verbose level 1 (basic messages)
      IO.puts("\n#{String.duplicate("-", 60)}")
      IO.puts("VERBOSE LEVEL 1 (Basic planning messages)")
      IO.puts("#{String.duplicate("-", 60)}")
      
      case AriaEngine.plan(domain, initial_state, tasks, verbose: 1) do
        {:ok, plan} ->
          IO.puts("✓ Plan found with #{length(plan)} steps:")
          Enum.with_index(plan, 1)
          |> Enum.each(fn {step, index} ->
            IO.puts("  #{index}. #{inspect(step)}")
          end)
          
          # Execute plan and show state transitions
          IO.puts("\nEXECUTING PLAN:")
          case AriaEngine.execute_plan(domain, initial_state, plan) do
            {:ok, final_state} ->
              IO.puts("✓ Plan execution successful")
              IO.puts("FINAL STATE:")
              IO.inspect(final_state.data, label: "Final Facts")
              
              # Show what changed
              initial_facts = initial_state.data
              final_facts = final_state.data
              
              IO.puts("\nSTATE CHANGES:")
              new_facts = Map.drop(final_facts, Map.keys(initial_facts))
              changed_facts = Enum.filter(final_facts, fn {key, value} ->
                Map.has_key?(initial_facts, key) and Map.get(initial_facts, key) != value
              end)
              
              if map_size(new_facts) > 0 do
                IO.puts("  New facts: #{inspect(new_facts)}")
              end
              if length(changed_facts) > 0 do
                IO.puts("  Changed facts: #{inspect(changed_facts)}")
              end
              
            {:error, reason} ->
              IO.puts("✗ Plan execution failed: #{reason}")
          end
        {:error, reason} ->
          IO.puts("✗ Planning failed: #{reason}")
      end

      # Test verbose level 2 (detailed todo processing)
      IO.puts("\n#{String.duplicate("-", 60)}")
      IO.puts("VERBOSE LEVEL 2 (Detailed todo processing with indentation)")
      IO.puts("#{String.duplicate("-", 60)}")
      
      case AriaEngine.plan(domain, initial_state, tasks, verbose: 2) do
        {:ok, plan} ->
          IO.puts("✓ Detailed planning completed")
          IO.puts("Final plan: #{inspect(plan)}")
        {:error, reason} ->
          IO.puts("✗ Planning failed: #{reason}")
      end

      IO.puts("\n#{String.duplicate("=", 80)}")
      IO.puts("END OF VERBOSE PLANNING DEMONSTRATION")
      IO.puts("#{String.duplicate("=", 80)}\n")
    end

    test "shows plan comparison between different domains" do
      IO.puts("\n#{String.duplicate("=", 80)}")
      IO.puts("PLAN COMPARISON DEMONSTRATION")
      IO.puts("#{String.duplicate("=", 80)}")
      
      # Test simple domain
      simple_domain = TestDomains.build_simple_rpg_domain()
      rpg_domain = TestDomains.build_rpg_domain()
      
      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("location", "sword", "room2")
      
      goals = [{"has", "player", "sword"}]
      
      IO.puts("\nCOMPARING DIFFERENT DOMAINS:")
      IO.puts("Initial state: #{inspect(initial_state.data)}")
      IO.puts("Goal: #{inspect(goals)}")
      
      IO.puts("\n--- SIMPLE DOMAIN PLANNING ---")
      case AriaEngine.plan(simple_domain, initial_state, goals, verbose: 1) do
        {:ok, plan} ->
          IO.puts("Simple domain plan: #{inspect(plan)}")
        {:error, reason} ->
          IO.puts("Simple domain failed: #{reason}")
      end
      
      IO.puts("\n--- RPG DOMAIN PLANNING ---")
      case AriaEngine.plan(rpg_domain, initial_state, goals, verbose: 1) do
        {:ok, plan} ->
          IO.puts("RPG domain plan: #{inspect(plan)}")
        {:error, reason} ->
          IO.puts("RPG domain failed: #{reason}")
      end
    end
  end
end
