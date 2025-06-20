defmodule AriaEngine.HybridPlanner.Strategies.SatCp do
  @moduledoc """
  SAT-CP Strategy - Simple CP-SAT Solver in Pure Elixir

  A small but functional constraint programming solver that actually solves problems.
  Implements basic SAT solving with constraint propagation for simple CP problems.
  """

  @behaviour AriaEngine.HybridPlanner.OptimizerStrategy

  @impl true
  def solve(problem, _options \\ []) do
    case extract_variables_and_constraints(problem) do
      {:ok, {variables, constraints}} ->
        case solve_sat(variables, constraints) do
          {:ok, assignment} ->
            {:ok, %{
              status: "OPTIMAL",
              solver: "CP-SAT (Pure Elixir)",
              variables: assignment,
              solve_time_ms: 0
            }}
          
          :unsat ->
            {:ok, %{
              status: "INFEASIBLE",
              solver: "CP-SAT (Pure Elixir)",
              variables: %{},
              solve_time_ms: 0
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

  # Simple SAT solver with constraint propagation
  defp solve_sat(variables, constraints) do
    # Start with all variables unassigned
    assignment = Map.new(variables, fn var -> {var, :unassigned} end)
    
    case backtrack_search(assignment, constraints, variables) do
      {:ok, final_assignment} -> {:ok, final_assignment}
      :fail -> :unsat
    end
  end

  defp backtrack_search(assignment, constraints, variables) do
    # Check if assignment is complete
    if all_assigned?(assignment) do
      if satisfies_all_constraints?(assignment, constraints) do
        {:ok, assignment}
      else
        :fail
      end
    else
      # Pick next unassigned variable
      var = find_unassigned_variable(assignment)
      
      # Try values for this variable
      try_values(var, [true, false], assignment, constraints, variables)
    end
  end

  defp try_values(_var, [], _assignment, _constraints, _variables), do: :fail

  defp try_values(var, [value | rest], assignment, constraints, variables) do
    new_assignment = Map.put(assignment, var, value)
    
    # Check if this assignment is consistent with constraints
    if consistent_with_constraints?(new_assignment, constraints) do
      case backtrack_search(new_assignment, constraints, variables) do
        {:ok, result} -> {:ok, result}
        :fail -> try_values(var, rest, assignment, constraints, variables)
      end
    else
      try_values(var, rest, assignment, constraints, variables)
    end
  end

  defp all_assigned?(assignment) do
    Enum.all?(assignment, fn {_var, value} -> value != :unassigned end)
  end

  defp find_unassigned_variable(assignment) do
    {var, :unassigned} = Enum.find(assignment, fn {_var, value} -> value == :unassigned end)
    var
  end

  defp consistent_with_constraints?(assignment, constraints) do
    Enum.all?(constraints, fn constraint ->
      evaluate_constraint(constraint, assignment)
    end)
  end

  defp satisfies_all_constraints?(assignment, constraints) do
    Enum.all?(constraints, fn constraint ->
      evaluate_constraint_complete(constraint, assignment)
    end)
  end

  # Evaluate constraint with possibly unassigned variables (for consistency check)
  defp evaluate_constraint(constraint, assignment) do
    case constraint do
      {:and, left, right} ->
        evaluate_constraint(left, assignment) and evaluate_constraint(right, assignment)
      
      {:or, left, right} ->
        evaluate_constraint(left, assignment) or evaluate_constraint(right, assignment)
      
      {:not, expr} ->
        not evaluate_constraint(expr, assignment)
      
      {:eq, var1, var2} ->
        val1 = Map.get(assignment, var1)
        val2 = Map.get(assignment, var2)
        if val1 == :unassigned or val2 == :unassigned do
          true  # Can't violate yet
        else
          val1 == val2
        end
      
      {:neq, var1, var2} ->
        val1 = Map.get(assignment, var1)
        val2 = Map.get(assignment, var2)
        if val1 == :unassigned or val2 == :unassigned do
          true  # Can't violate yet
        else
          val1 != val2
        end
      
      var when is_binary(var) ->
        case Map.get(assignment, var) do
          :unassigned -> true
          value -> value
        end
    end
  end

  # Evaluate constraint with complete assignment
  defp evaluate_constraint_complete(constraint, assignment) do
    case constraint do
      {:and, left, right} ->
        evaluate_constraint_complete(left, assignment) and evaluate_constraint_complete(right, assignment)
      
      {:or, left, right} ->
        evaluate_constraint_complete(left, assignment) or evaluate_constraint_complete(right, assignment)
      
      {:not, expr} ->
        not evaluate_constraint_complete(expr, assignment)
      
      {:eq, var1, var2} ->
        Map.get(assignment, var1) == Map.get(assignment, var2)
      
      {:neq, var1, var2} ->
        Map.get(assignment, var1) != Map.get(assignment, var2)
      
      var when is_binary(var) ->
        Map.get(assignment, var)
    end
  end

  defp extract_variables_and_constraints(problem) do
    variables = Map.get(problem, "variables", [])
    constraints = Map.get(problem, "constraints", [])
    
    if length(variables) > 0 do
      parsed_constraints = Enum.map(constraints, &parse_constraint/1)
      {:ok, {variables, parsed_constraints}}
    else
      {:error, "No variables specified"}
    end
  end

  defp parse_constraint(constraint) when is_map(constraint) do
    case constraint do
      %{"type" => "and", "left" => left, "right" => right} ->
        {:and, parse_constraint(left), parse_constraint(right)}
      
      %{"type" => "or", "left" => left, "right" => right} ->
        {:or, parse_constraint(left), parse_constraint(right)}
      
      %{"type" => "not", "expr" => expr} ->
        {:not, parse_constraint(expr)}
      
      %{"type" => "eq", "var1" => var1, "var2" => var2} ->
        {:eq, var1, var2}
      
      %{"type" => "neq", "var1" => var1, "var2" => var2} ->
        {:neq, var1, var2}
      
      %{"type" => "var", "name" => name} ->
        name
    end
  end

  defp parse_constraint(constraint) when is_binary(constraint) do
    constraint
  end
end
