# Debug script to test domain registration and planning
alias AriaEngine.StateV2
alias Plan.Core

# Create the simple domain like in the test
move_action = fn state, [from, to] ->
  robot_location = StateV2.get_fact(state, "robot", "location")
  if robot_location == from do
    StateV2.set_fact(state, "robot", "location", to)
  else
    false
  end
end

domain = Domain.new("simple_test") |> Domain.add_action(:move, move_action)

IO.puts("=== DOMAIN DEBUG ===")
IO.puts("Domain has :move action: #{Domain.has_action?(domain, :move)}")
IO.puts("Domain actions: #{inspect(Domain.actions(domain))}")

# Create initial state
initial_state = StateV2.new() 
  |> StateV2.set_fact("robot", "location", "start") 
  |> StateV2.set_fact("robot", "prepared", false) 
  |> StateV2.set_fact("robot", "optimized", false)

IO.puts("\n=== ACTION TEST ===")
IO.puts("Testing action directly:")
result = Domain.get_action(domain, :move).(initial_state, ["start", "goal"])
IO.puts("Action result: #{inspect(result)}")

IO.puts("\n=== PLANNING TEST ===")
IO.puts("Testing planning:")
todos = [{:move, ["start", "goal"]}]
plan_result = Core.plan(domain, initial_state, todos, [verbose: 3])
IO.puts("Plan result: #{inspect(plan_result)}")
