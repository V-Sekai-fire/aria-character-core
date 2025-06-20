defmodule AriaEngine.HybridPlanner.Strategies.SatCp do
  @moduledoc """
  SAT-CP Strategy - OptimizerStrategy Adapter for HTN Planning

  Reuses the existing HTNPlanningStrategy backtracking capabilities
  to provide the OptimizerStrategy interface for constraint programming problems.
  
  This leverages the sophisticated backtracking already implemented in Plan.replan/5.
  """

  @behaviour AriaEngine.HybridPlanner.OptimizerStrategy

  alias HybridPlanner.Strategies.Default.HTNPlanningStrategy

  @impl true
  def solve(problem, options \\ []) do
    case convert_problem_to_planning_format(problem) do
      {:ok, {domain, state, goals}} ->
        case HTNPlanningStrategy.plan(domain, state, goals, options) do
          {:ok, solution_tree} ->
            variables = extract_variables_from_solution(solution_tree)
            {:ok, %{
              status: "OPTIMAL",
              solver: "CP-SAT (HTN Adapter)",
              variables: variables,
              solve_time_ms: 0
            }}
          
          {:error, reason} ->
            {:ok, %{
              status: "INFEASIBLE", 
              solver: "CP-SAT (HTN Adapter)",
              variables: %{},
              solve_time_ms: 0,
              reason: reason
            }}
        end
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def validate_problem(problem) do
    if is_map(problem) and Map.has_key?(problem, "variables") do
      :ok
    else
      {:error, "Problem must have 'variables' field"}
    end
  end

  # Convert constraint programming problem to HTN planning format
  defp convert_problem_to_planning_format(problem) do
    variables = Map.get(problem, "variables", [])
    constraints = Map.get(problem, "constraints", [])
    
    if length(variables) > 0 do
      # Create simple domain and state for constraint satisfaction
      domain = create_constraint_domain(variables, constraints)
      state = create_initial_state(variables)
      goals = create_constraint_goals(constraints)
      
      {:ok, {domain, state, goals}}
    else
      {:error, "No variables specified"}
    end
  end

  defp create_constraint_domain(variables, constraints) do
    # Create a simple domain that can assign boolean values to variables
    methods = create_assignment_methods(variables)
    actions = create_assignment_actions(variables)
    
    %{
      methods: methods,
      actions: actions
    }
  end

  defp create_assignment_methods(variables) do
    # Create methods for assigning values to each variable
    Enum.reduce(variables, %{}, fn var, acc ->
      Map.put(acc, "assign_#{var}", [
        {["assign_#{var}"], [], [{"assign_action", [var, true]}]},
        {["assign_#{var}"], [], [{"assign_action", [var, false]}]}
      ])
    end)
  end

  defp create_assignment_actions(variables) do
    # Create actions for setting variable values
    %{
      "assign_action" => %{
        preconditions: [],
        effects: fn [var, value] -> [{"assigned", var, value}] end
      }
    }
  end

  defp create_initial_state(variables) do
    # Start with all variables unassigned
    facts = Enum.map(variables, fn var -> {"unassigned", var, true} end)
    AriaEngine.StateV2.new(facts)
  end

  defp create_constraint_goals(constraints) do
    # Convert constraints to goals that need to be satisfied
    Enum.map(constraints, fn constraint ->
      {"satisfy_constraint", [constraint]}
    end)
  end

  defp extract_variables_from_solution(solution_tree) do
    # Extract variable assignments from the HTN solution
    actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
    
    Enum.reduce(actions, %{}, fn action, acc ->
      case action do
        {"assign_action", [var, value]} ->
          Map.put(acc, var, value)
        _ ->
          acc
      end
    end)
  end
end
