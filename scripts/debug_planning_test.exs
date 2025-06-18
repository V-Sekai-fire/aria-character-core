# Debug script to understand what error message is returned from plan execution
# Usage: mix run scripts/debug_planning_test.exs

alias {StateV2, BasicActionsDomainProvider}

# Create test domain and state
domain = BasicActionsDomainProvider.create_domain()
state = StateV2.new()
  |> StateV2.set_fact("player", "location", "room1")
  |> StateV2.set_fact("room1", "has_exit", "room2")

# Test with invalid plan (non-existent action)
invalid_plan = %{
  "goal" => %{
    "action" => "invalid_action",
    "args" => ["arg1"],
    "id" => "goal"
  }
}

IO.puts("Testing plan execution with invalid action...")
IO.puts("Domain: #{inspect(domain)}")
IO.puts("State: #{inspect(state)}")
IO.puts("Invalid plan: #{inspect(invalid_plan)}")

case execute_plan(domain, state, invalid_plan) do
  {:ok, final_state} ->
    IO.puts("Unexpected success: #{inspect(final_state)}")
  {:error, reason} ->
    IO.puts("Error as expected: #{inspect(reason)}")
    IO.puts("Error contains 'Action not found': #{String.contains?(reason, "Action not found")}")
    IO.puts("Error contains 'Execution failed': #{String.contains?(reason, "Execution failed")}")
    IO.puts("Full error message: '#{reason}'")
end
