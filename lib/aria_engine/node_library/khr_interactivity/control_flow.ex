defmodule NodeLibrary.KHRInteractivity.ControlFlow do
  @moduledoc """
  KHR_interactivity Control Flow Nodes

  Implements control flow operations from the glTF KHR_interactivity specification.
  These are organized by complexity:

  **Instant Actions (atomic operations):**
  - khr_flow_switch: Conditional value selection
  - khr_flow_select: Index-based value selection
  - khr_flow_branch: Simple if-then-else evaluation

  **Task Methods (decompose into subtasks):**
  - khr_flow_sequence: Decompose into sequential subtasks
  
  **Durative Actions (temporal operations):**
  - khr_flow_loop: Loops with temporal duration
  - khr_flow_while: Conditional loops with timeout constraints

  This separation enables proper hierarchical planning and temporal reasoning.
  """

  alias StateV2
  alias Domain.{Actions, Methods, Core}
  alias Domain.DurativeAction

  @doc "Register all control flow operations with a domain (actions, methods, and durative actions)"
  @spec register_all(Core.t()) :: Core.t()
  def register_all(domain) do
    domain
    |> register_instant_actions()
    |> register_task_methods()
    |> register_durative_actions()
  end

  @doc "Register instant action operations"
  @spec register_instant_actions(Core.t()) :: Core.t()
  def register_instant_actions(domain) do
    domain
    |> Actions.add_action(:khr_flow_switch, &flow_switch/2, %{
      domain: "khr_interactivity",
      category: "control_flow",
      khr_node_type: "flow/switch",
      description: "Conditional branching based on value comparison"
    })
    |> Actions.add_action(:khr_flow_select, &flow_select/2, %{
      domain: "khr_interactivity",
      category: "control_flow", 
      khr_node_type: "flow/select",
      description: "Choose between multiple values based on index"
    })
    |> Actions.add_action(:khr_flow_branch, &flow_branch/2, %{
      domain: "khr_interactivity",
      category: "control_flow",
      khr_node_type: "flow/branch", 
      description: "Conditional execution (if-then-else)"
    })
    |> Actions.add_action(:khr_flow_sequence, &flow_sequence/2, %{
      domain: "khr_interactivity",
      category: "control_flow",
      khr_node_type: "flow/sequence",
      description: "Sequential execution of operations"
    })
  end

  @doc "Register task methods using exact KHR specification names"
  @spec register_task_methods(Core.t()) :: Core.t()
  def register_task_methods(domain) do
    domain
    |> Methods.add_task_methods("flow/switch", [
      {"basic_switch", &switch_task_method/2}
    ])
    |> Methods.add_task_methods("flow/select", [
      {"basic_select", &select_task_method/2}
    ])
    |> Methods.add_task_methods("flow/branch", [
      {"basic_branch", &branch_task_method/2}
    ])
    |> Methods.add_task_methods("flow/sequence", [
      {"sequence_decomposition", &sequence_task_method/2}
    ])
  end

  @doc "Register durative action operations"
  @spec register_durative_actions(Core.t()) :: Core.t()
  def register_durative_actions(domain) do
    # Loop durative action - has temporal constraints
    loop_durative = DurativeAction.new(
      :khr_flow_loop,
      {:range, 0.1, 30}, # 0.1s to 30s duration range
      %{
        at_start: [{"loop_count", "count", :exists}],
        over_all: [{"loop_state", "active", true}],
        at_end: [{"loop_state", "completed", true}]
      },
      %{
        at_start: [{"loop_state", "active", true}, {"loop_state", "iteration", 0}],
        at_end: [{"loop_state", "active", false}, {"loop_state", "completed", true}],
        over_time: [{"loop_state", "progress", :incrementing}]
      },
      &loop_durative_action/2
    )

    # While loop durative action - has timeout constraints  
    while_durative = DurativeAction.new(
      :khr_flow_while,
      {:range, 0.1, 60}, # 0.1s to 60s duration range
      %{
        at_start: [{"while_condition", "evaluable", true}],
        over_all: [{"while_state", "active", true}],
        at_end: [{"while_state", "completed", true}]
      },
      %{
        at_start: [{"while_state", "active", true}, {"while_state", "iterations", 0}],
        at_end: [{"while_state", "active", false}, {"while_state", "completed", true}],
        over_time: [{"while_state", "condition_checks", :incrementing}]
      },
      &while_durative_action/2
    )

    domain
    |> Core.add_durative_action(:khr_flow_loop, loop_durative)
    |> Core.add_durative_action(:khr_flow_while, while_durative)
  end

  @doc "Switch between values based on selector"
  def flow_switch(state, [node_index, selector, cases]) when is_list(cases) do
    result = case find_matching_case(selector, cases) do
      {:ok, value} -> value
      :error -> get_default_value(cases)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
    |> StateV2.set_fact(Integer.to_string(node_index), "selected_case", selector)
  end

  def flow_switch(state, [node_index, _selector, _cases]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", nil)
  end

  @doc "Select value from list based on index"
  def flow_select(state, [node_index, index, values]) when is_integer(index) and is_list(values) do
    result = if index >= 0 and index < length(values) do
      Enum.at(values, index)
    else
      nil
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
    |> StateV2.set_fact(Integer.to_string(node_index), "selected_index", index)
  end

  def flow_select(state, [node_index, _index, _values]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", nil)
  end

  @doc "Conditional branch (if-then-else)"
  def flow_branch(state, [node_index, condition, true_value, false_value]) do
    result = if evaluate_condition(condition) do
      true_value
    else
      false_value
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
    |> StateV2.set_fact(Integer.to_string(node_index), "condition_result", evaluate_condition(condition))
  end

  def flow_branch(state, [node_index, condition, true_value]) do
    # Single-branch version (if-then)
    result = if evaluate_condition(condition) do
      true_value
    else
      nil
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
    |> StateV2.set_fact(Integer.to_string(node_index), "condition_result", evaluate_condition(condition))
  end

  @doc "Execute sequence of operations"
  def flow_sequence(state, [node_index, operations]) when is_list(operations) do
    # Execute operations in sequence, storing intermediate results
    {final_state, results} = Enum.reduce(operations, {state, []}, fn operation, {current_state, acc_results} ->
      result = execute_operation(current_state, operation)
      {current_state, [result | acc_results]}
    end)
    
    final_state
    |> StateV2.set_fact(Integer.to_string(node_index), "results", Enum.reverse(results))
    |> StateV2.set_fact(Integer.to_string(node_index), "completed", true)
  end

  def flow_sequence(state, [node_index, _operations]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "completed", false)
  end

  @doc "Loop with counter"
  def flow_loop(state, [node_index, count, operation]) when is_integer(count) and count > 0 do
    # Execute operation count times
    {final_state, results} = Enum.reduce(1..count, {state, []}, fn iteration, {current_state, acc_results} ->
      result = execute_operation_with_context(current_state, operation, %{iteration: iteration})
      {current_state, [result | acc_results]}
    end)
    
    final_state
    |> StateV2.set_fact(Integer.to_string(node_index), "results", Enum.reverse(results))
    |> StateV2.set_fact(Integer.to_string(node_index), "iterations", count)
    |> StateV2.set_fact(Integer.to_string(node_index), "completed", true)
  end

  def flow_loop(state, [node_index, _count, _operation]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "completed", false)
  end

  @doc "While loop with condition"
  def flow_while(state, [node_index, condition_check, operation]) do
    flow_while(state, [node_index, condition_check, operation, 100])
  end

  def flow_while(state, [node_index, condition_check, operation, max_iterations]) do
    {final_state, results, iterations} = execute_while_loop(state, condition_check, operation, max_iterations, [])
    
    final_state
    |> StateV2.set_fact(Integer.to_string(node_index), "results", Enum.reverse(results))
    |> StateV2.set_fact(Integer.to_string(node_index), "iterations", iterations)
    |> StateV2.set_fact(Integer.to_string(node_index), "completed", true)
  end

  # Task method functions - decompose KHR spec strings to atom-based actions

  @doc "Task method for flow/switch - decomposes to atom-based action"
  def switch_task_method(_state, [node_id, condition, cases]) do
    [[:khr_flow_switch, node_id, condition, cases]]
  end

  @doc "Task method for flow/select - decomposes to atom-based action"
  def select_task_method(_state, [node_id, index, options]) do
    [[:khr_flow_select, node_id, index, options]]
  end

  @doc "Task method for flow/branch - decomposes to atom-based action"
  def branch_task_method(_state, [node_id, condition, true_branch, false_branch]) do
    [[:khr_flow_branch, node_id, condition, true_branch, false_branch]]
  end

  def branch_task_method(_state, [node_id, condition, true_branch]) do
    [[:khr_flow_branch, node_id, condition, true_branch]]
  end

  @doc "Task method for flow/sequence - decomposes to sequential subtasks (COMPOSITE)"
  def sequence_task_method(_state, [node_id, operations]) when is_list(operations) do
    # COMPOSITE PATTERN: Sequential decomposition
    # Each operation becomes a subtask in sequence
    sequential_tasks = Enum.map(operations, fn operation ->
      case operation do
        ["flow/switch", switch_node, condition, cases] -> 
          ["flow/switch", switch_node, condition, cases]
        ["flow/select", select_node, index, options] -> 
          ["flow/select", select_node, index, options]
        ["flow/branch", branch_node, condition, true_branch] -> 
          ["flow/branch", branch_node, condition, true_branch]
        ["flow/branch", branch_node, condition, true_branch, false_branch] -> 
          ["flow/branch", branch_node, condition, true_branch, false_branch]
        ["math" | _] = math_op -> math_op
        ["variable" | _] = var_op -> var_op
        other -> other
      end
    end)
    
    # Add final sequence completion action
    sequential_tasks ++ [[:khr_flow_sequence, node_id, operations]]
  end

  def sequence_task_method(_state, [node_id, _operations]) do
    # Empty sequence still needs completion action
    [[:khr_flow_sequence, node_id, []]]
  end

  # Helper functions

  defp find_matching_case(selector, cases) do
    case Enum.find(cases, fn {case_value, _result} -> case_value == selector end) do
      {_case_value, result} -> {:ok, result}
      nil -> :error
    end
  end

  defp get_default_value(cases) do
    case Enum.find(cases, fn 
      {:default, result} -> result
      _ -> false
    end) do
      {:default, result} -> result
      _ -> nil
    end
  end

  defp evaluate_condition(condition) when is_boolean(condition), do: condition
  defp evaluate_condition(condition) when is_number(condition), do: condition != 0
  defp evaluate_condition(condition) when is_function(condition, 0), do: evaluate_condition(condition.())
  defp evaluate_condition(nil), do: false
  defp evaluate_condition(_), do: true

  defp execute_operation(_state, operation) do
    # Placeholder for operation execution
    # In a full implementation, this would trigger the operation
    {:executed, operation}
  end

  defp execute_operation_with_context(_state, operation, context) do
    # Placeholder for operation execution with context
    {:executed, operation, context}
  end

  defp execute_while_loop(state, _condition_check, _operation, 0, results) do
    # Max iterations reached
    {state, results, length(results)}
  end

  defp execute_while_loop(state, condition_check, operation, max_iterations, results) do
    if evaluate_condition(condition_check) do
      result = execute_operation(state, operation)
      execute_while_loop(state, condition_check, operation, max_iterations - 1, [result | results])
    else
      {state, results, length(results)}
    end
  end

  # Durative action functions for loops

  @doc "Durative action function for loop execution"
  def loop_durative_action(state, [count, operation]) when is_integer(count) and count > 0 do
    # Execute the loop operation for the specified count
    {final_state, _results} = Enum.reduce(1..count, {state, []}, fn iteration, {current_state, acc_results} ->
      result = execute_operation_with_context(current_state, operation, %{iteration: iteration})
      {current_state, [result | acc_results]}
    end)
    
    final_state
    |> StateV2.set_fact("loop_state", "active", false)
    |> StateV2.set_fact("loop_state", "completed", true)
  end

  def loop_durative_action(state, _args) do
    state
    |> StateV2.set_fact("loop_state", "active", false)
    |> StateV2.set_fact("loop_state", "completed", false)
  end

  @doc "Durative action function for while loop execution"
  def while_durative_action(state, [condition_check, operation]) do
    # Execute the while loop with a reasonable max iteration limit
    {final_state, _results, iterations} = execute_while_loop(state, condition_check, operation, 100, [])
    
    final_state
    |> StateV2.set_fact("while_state", "active", false)
    |> StateV2.set_fact("while_state", "completed", true)
    |> StateV2.set_fact("while_state", "iterations", iterations)
  end

  def while_durative_action(state, _args) do
    state
    |> StateV2.set_fact("while_state", "active", false)
    |> StateV2.set_fact("while_state", "completed", false)
  end
end
