# Debug script for AriaEngine.Plan blacklisting
# Usage: mix run debug_planner_blacklisting.exs

defmodule DebugPlannerBlacklisting do
  alias AriaEngine.{Domain, State, Plan}

  @doc """
  Runs a planning scenario to test method blacklisting.
  """
  def run do
    IO.puts("=== Starting DebugPlannerBlacklisting ===")

    # Define a simple domain
    domain = Domain.new("test_blacklisting_domain")
    |> Domain.add_action(:move, &move_action/2) # Add this line
    |> Domain.add_task_methods("move_with_failure", [
      {"failing_method", &failing_method/2},
      {"successful_method", &successful_method/2}
    ])
    # Initial state
    initial_state = State.new()
    |> State.set_fact("location", "robot", "start")

    # Goals (now a single task)
    todos = [{"move_with_failure", ["robot", "start", "goal"]}]

    IO.puts("\n--- Attempting to plan ---")
    # Set replan_depth to a small number to observe the limit
    case Plan.plan(domain, initial_state, todos, verbose: 3, replan_depth: 3) do
      {:ok, solution_tree} ->
        IO.puts("\nPlan succeeded!")
        IO.inspect(solution_tree, label: "Solution Tree")
        IO.puts("\n--- Running lazy refineahead ---")
        case Plan.run_lazy_refineahead(domain, initial_state, solution_tree, verbose: 3) do
          {:ok, final_state} ->
            IO.puts("\nExecution succeeded!")
            IO.inspect(final_state, label: "Final State")
          {:error, reason} ->
            IO.puts("\nExecution failed: #{reason}")
        end
      {:error, reason} ->
        IO.puts("\nPlanning failed: #{reason}")
    end

    IO.puts("\n=== DebugPlannerBlacklisting Finished ===")
  end

  # Method designed to fail its preconditions
  defp failing_method(state, _args) do
    IO.puts("  [Method] Failing method called. Preconditions not met.")
    false # Simulate failure
  end

  # Method designed to succeed
  defp successful_method(state, _args) do
    IO.puts("  [Method] Successful method called. Returning subtasks.")
    # Simulate moving the robot
    [
      {:move, ["robot", "start", "goal"]}
    ]
  end

  # Dummy action for the primitive task
  defp move_action(state, [robot, from, to]) do
    IO.puts("  [Action] Executing move action: #{robot} from #{from} to #{to}")
    State.set_fact(state, "location", robot, to)
  end

end

# Add the dummy action to the domain for primitive task execution
# This needs to be done outside the module definition if it's a simple script
# For a proper application, this would be part of domain definition.
# For this debug script, we'll add it dynamically.
# This part will be executed when the script is run.
# We need to ensure the domain used in Plan.plan has this action.
# The current Plan.plan expects a Domain.t() which is built outside.
# Let's modify the run function to add the action to the domain.

DebugPlannerBlacklisting.run()
