#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Add the lib directories to the path
Code.prepend_path("apps/aria_engine/lib")
Code.prepend_path("apps/aria_storage/lib")

# Require the modules
require Logger

# Load test support
Code.require_file("apps/aria_engine/test/support/test_domains.ex")

alias AriaEngine.{TestDomains, State, Plan}

# Create test setup
domain = TestDomains.build_backtracking_domain()
state = TestDomains.create_backtracking_state()

IO.puts "=== DEBUGGING BACKTRACKING ==="
IO.puts "Initial state: flag = #{AriaEngine.get_fact(state, "flag", "system")}"

IO.puts "\n=== Testing need01 case ==="
goals = [{"put_it", []}, {"need01", []}]

IO.puts "Goals: #{inspect(goals)}"

case AriaEngine.plan(domain, state, goals, verbose: true) do
  {:ok, plan} ->
    IO.puts "SUCCESS: Got plan #{inspect(plan)}"
    IO.puts "Expected: #{inspect([{"putv", [0]}, {"getv", [0]}, {"getv", [0]}])}"
  {:error, reason} ->
    IO.puts "FAILED: #{inspect(reason)}"
end

IO.puts "\n=== Testing need10 case ==="
goals = [{"put_it", []}, {"need10", []}]

IO.puts "Goals: #{inspect(goals)}"

case AriaEngine.plan(domain, state, goals, verbose: true) do
  {:ok, plan} ->
    IO.puts "SUCCESS: Got plan #{inspect(plan)}"
    IO.puts "Expected: #{inspect([{"putv", [0]}, {"getv", [0]}, {"getv", [0]}])}"
  {:error, reason} ->
    IO.puts "FAILED: #{inspect(reason)}"
end

IO.puts "\n=== Testing individual methods manually ==="

# Test put_it methods individually
IO.puts "\nTesting put_it methods:"
put_it_methods = AriaEngine.Domain.get_methods(domain, "put_it")
IO.puts "put_it has #{length(put_it_methods)} methods"

Enum.with_index(put_it_methods) |> Enum.each(fn {method, idx} ->
  result = method.(state, [])
  IO.puts "  Method #{idx}: #{inspect(result)}"
end)

# Test need01 methods individually
IO.puts "\nTesting need01 methods:"
need01_methods = AriaEngine.Domain.get_methods(domain, "need01")
IO.puts "need01 has #{length(need01_methods)} methods"

Enum.with_index(need01_methods) |> Enum.each(fn {method, idx} ->
  result = method.(state, [])
  IO.puts "  Method #{idx}: #{inspect(result)}"
end)

# Test need10 methods individually  
IO.puts "\nTesting need10 methods:"
need10_methods = AriaEngine.Domain.get_methods(domain, "need10")
IO.puts "need10 has #{length(need10_methods)} methods"

Enum.with_index(need10_methods) |> Enum.each(fn {method, idx} ->
  result = method.(state, [])
  IO.puts "  Method #{idx}: #{inspect(result)}"
end)
