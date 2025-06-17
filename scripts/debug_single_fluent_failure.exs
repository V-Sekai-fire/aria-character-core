# Debug a single fluent failure to understand the exact issue
# Usage: mix run scripts/debug_single_fluent_failure.exs

defmodule SingleFluentDebug do
  alias AriaEngine.{Domain, StateV2}
  alias AriaEngine.Plan.Core, as: PlanCore
  
  def run do
    IO.puts("=== Debugging Single Fluent Planning Failure ===")
    
    # Create the simplest possible test case
    domain = create_minimal_domain()
    initial_state = create_minimal_state()
    goals = [{"health_status", "robot", :healthy}]
    
    IO.puts("Domain actions: #{inspect(Map.keys(domain.actions))}")
    IO.puts("Domain durative actions: #{inspect(Map.keys(domain.durative_actions))}")
    IO.puts("Domain unigoal methods: #{inspect(Map.keys(domain.unigoal_methods))}")
    
    IO.puts("\nInitial state:")
    IO.inspect(initial_state.data)
    
    IO.puts("\nGoals:")
    IO.inspect(goals)
    
    IO.puts("\nTesting unigoal method manually:")
    test_unigoal_method(domain, initial_state, goals)
    
    IO.puts("\nTesting durative action manually:")
    test_durative_action(domain, initial_state)
    
    IO.puts("\nRunning full planning:")
    result = PlanCore.plan(domain, initial_state, goals, verbose: 3)
    
    case result do
      {:ok, solution_tree} ->
        IO.puts("SUCCESS!")
        actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
        IO.puts("Actions: #{inspect(actions)}")
      {:error, reason} ->
        IO.puts("FAILED: #{reason}")
    end
  end
  
  defp create_minimal_domain do
    domain = Domain.Core.new("minimal_test")
    
    # Add a simple durative action
    heal_action = AriaEngine.Domain.DurativeAction.new(
      :rest_heal,
      {:fixed, 5000},
      %{at_start: [], over_all: [], at_end: []}, # No preconditions
      %{at_start: [], at_end: [{"health_status", "robot", :healthy}], over_time: []},
      fn state, _args ->
        IO.puts("EXECUTING rest_heal action")
        StateV2.set_fact(state, "robot", "health_status", :healthy)
      end
    )
    
    domain = Domain.Core.add_durative_action(domain, :rest_heal, heal_action)
    
    # Add unigoal method
    domain = Domain.add_unigoal_method(domain, "health_status", "heal_method", fn state, [subject, target_status] ->
      IO.puts("UNIGOAL METHOD called with subject=#{inspect(subject)}, target=#{inspect(target_status)}")
      current_status = StateV2.get_fact(state, subject, "health_status")
      IO.puts("Current status: #{inspect(current_status)}")
      
      if current_status != target_status do
        IO.puts("Need to heal - returning rest_heal action")
        [{:rest_heal, []}]
      else
        IO.puts("Already at target status")
        []
      end
    end)
    
    domain
  end
  
  defp create_minimal_state do
    StateV2.new()
    |> StateV2.set_fact("robot", "health_status", :wounded)
  end
  
  defp test_unigoal_method(domain, state, goals) do
    [{predicate, subject, target_value}] = goals
    
    methods = Domain.get_unigoal_methods(domain, predicate)
    IO.puts("Available methods for #{predicate}: #{length(methods)}")
    
    Enum.each(methods, fn {method_name, method_fn} ->
      IO.puts("\nTesting method: #{method_name}")
      result = method_fn.(state, [subject, target_value])
      IO.puts("Method result: #{inspect(result)}")
    end)
  end
  
  defp test_durative_action(domain, state) do
    durative_action = Domain.Core.get_durative_action(domain, :rest_heal)
    
    if durative_action do
      IO.puts("Found durative action: #{inspect(durative_action.name)}")
      
      # Test execution
      try do
        result = durative_action.action_fn.(state, [])
        IO.puts("Durative action executed successfully")
        IO.puts("New state: #{inspect(result.data)}")
      rescue
        e ->
        IO.puts("Durative action failed: #{inspect(e)}")
      end
    else
      IO.puts("No durative action found!")
    end
  end
end

SingleFluentDebug.run()
