#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Debug script to test RPG planning directly

# Load the project
Code.require_file("mix.exs")
Code.require_file("apps/aria_engine/mix.exs")
Code.require_file("apps/aria_engine/lib/aria_engine.ex")
Code.require_file("apps/aria_engine/lib/aria_engine/state.ex")
Code.require_file("apps/aria_engine/lib/aria_engine/domain.ex")
Code.require_file("apps/aria_engine/lib/aria_engine/plan.ex")
Code.require_file("apps/aria_engine/test/support/test_domains.ex")

alias AriaEngine.TestDomains

# Build the RPG domain
domain = TestDomains.build_rpg_domain()

# Create initial state
initial_state = AriaEngine.create_state()
|> AriaEngine.set_fact("location", "player", "room1")
|> AriaEngine.set_fact("location", "sword", "room2")

# Task: get the sword
tasks = [{"get_item", ["sword"]}]

IO.puts("=== RPG Planning Debug ===")
IO.puts("Domain: #{inspect(AriaEngine.domain_summary(domain))}")
IO.puts("Initial state: #{inspect(AriaEngine.state_to_triples(initial_state))}")
IO.puts("Tasks: #{inspect(tasks)}")
IO.puts("")

# Try planning with verbose output
case AriaEngine.Plan.plan(domain, initial_state, tasks, verbose: 3) do
  {:ok, solution_tree} ->
    IO.puts("SUCCESS! Solution tree: #{inspect(solution_tree, pretty: true)}")
    actions = AriaEngine.Plan.get_primitive_actions_dfs(solution_tree)
    IO.puts("Extracted actions: #{inspect(actions)}")
    
  {:error, reason} ->
    IO.puts("FAILED: #{reason}")
end
