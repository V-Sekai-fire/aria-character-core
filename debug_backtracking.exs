#!/usr/bin/env elixir
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

Mix.install([])

# Add the compiled app to the path
Code.prepend_path("_build/test/lib/aria_engine/ebin")
Code.prepend_path("_build/test/lib/aria_storage/ebin")

# Load the modules
Code.ensure_loaded(AriaEngine)
Code.ensure_loaded(AriaEngine.TestDomains)

# Create the domain and state
domain = AriaEngine.TestDomains.build_backtracking_domain()
state = AriaEngine.TestDomains.create_backtracking_state()

# Get domain summary
summary = AriaEngine.domain_summary(domain)
IO.puts("Domain: #{summary.name}")
IO.puts("Actions: #{inspect(summary.actions)}")
IO.puts("Task methods: #{inspect(summary.task_methods)}")

# Check initial state
IO.puts("\nInitial state:")
IO.puts("Flag: #{AriaEngine.get_fact(state, "flag", "system")}")

# Check what methods are available for put_it
IO.puts("\nMethods for put_it:")
put_it_methods = AriaEngine.Domain.get_task_methods(domain, "put_it")
IO.puts("Count: #{length(put_it_methods)}")

# Test each method
put_it_methods
|> Enum.with_index()
|> Enum.each(fn {method, index} ->
  IO.puts("Method #{index}: #{inspect(method)}")
  result = method.(state, [])
  IO.puts("  Result: #{inspect(result)}")
end)

# Test the planning with verbose output
IO.puts("\n=== Testing plan with verbose output ===")
goals = [{"put_it", []}, {"need0", []}]
IO.puts("Goals: #{inspect(goals)}")

case AriaEngine.plan(domain, state, goals, verbose: 3) do
  {:ok, plan} ->
    IO.puts("SUCCESS: #{inspect(plan)}")
  {:error, reason} ->
    IO.puts("FAILED: #{reason}")
end
