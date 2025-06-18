defmodule AriaEngine.ASTTranslator.CodeGenerator do
  @moduledoc """
  Code generation for executable functions from KHR node sequences.

  Generates Elixir functions that coordinate the execution of KHR_interactivity 
  nodes in the correct dependency order, handling parameter binding, node result 
  retrieval, and final result extraction.

  ## Generated Function Structure

  The generated functions follow this pattern:

      def ast_function_name(state, param_values) do
        # 1. Bind parameters to a map
        param_map = bind_parameters(param_values, [:param1, :param2])
        
        # 2. Execute KHR operations in sequence
        state_after_op1 = execute_khr_action(state, :khr_math_add, [1, param1, param2])
        state_after_op2 = execute_khr_action(state_after_op1, :khr_math_mul, [2, node_1_result, literal_value])
        
        # 3. Extract final result
        final_result = StateV2.get_fact(final_state, "final_node_id", "value")
        {final_result, final_state}
      end

  ## Usage

      execution_sequence = [
        {:khr_math_add, [1, {:param_value, :x}, {:param_value, :y}]},
        {:khr_math_abs, [2, {:node_result, 1}]}
      ]
      
      func = CodeGenerator.generate_executable_function(
        "calculate", [:x, :y], execution_sequence, annotation
      )
  """

  alias AriaEngine.ASTTranslator.DataFlow

  @type execution_sequence :: [DataFlow.execution_step()]
  @type function_annotation :: %{
    input: [atom()],
    output: atom(),
    name: String.t()
  }

  @doc """
  Generate an executable function from an execution sequence.

  ## Parameters
  - `func_name`: Original function name
  - `func_params`: List of function parameter names
  - `execution_sequence`: List of KHR operations to execute
  - `annotation`: Function type annotation

  ## Returns
  - Executable function that takes (state, param_values) and returns {result, state}

  ## Example

      execution_sequence = [
        {:khr_math_add, [1, {:param_value, :x}, {:param_value, :y}]},
        {:khr_math_abs, [2, {:node_result, 1}]}
      ]
      
      func = CodeGenerator.generate_executable_function(
        "calculate", [:x, :y], execution_sequence, %{output: :number}
      )
      
      # Usage:
      {result, final_state} = func.(initial_state, [10, 5])
  """
  @spec generate_executable_function(
    String.t(), 
    [atom()], 
    execution_sequence(), 
    function_annotation()
  ) :: function()
  def generate_executable_function(func_name, func_params, execution_sequence, annotation) do
    # Generate the function code
    function_code = quote do
      fn state, param_values ->
        # Parameter binding
        param_map = unquote(func_params)
                   |> Enum.zip(param_values)
                   |> Map.new()

        # Execute operations in sequence
        final_state = unquote(generate_execution_pipeline(execution_sequence))

        # Extract final result
        final_result = unquote(generate_result_extraction(execution_sequence))

        {final_result, final_state}
      end
    end

    # Compile and return the function
    {func, _binding} = Code.eval_quoted(function_code, [])
    func
  end

  @doc """
  Generate code for the execution pipeline.

  ## Parameters
  - `execution_sequence`: List of execution steps

  ## Returns
  - Quoted code that executes all operations in sequence
  """
  @spec generate_execution_pipeline(execution_sequence()) :: tuple()
  def generate_execution_pipeline(execution_sequence) do
    # Build a sequence of state transformations
    {final_state_var, execution_steps} = 
      Enum.map_reduce(execution_sequence, :state, fn {action, [node_id | args]}, current_state_var ->
        next_state_var = String.to_atom("state_after_node_#{node_id}")
        
        execution_step = quote do
          unquote(next_state_var) = execute_khr_action(
            unquote(current_state_var),
            unquote(action),
            unquote(resolve_execution_arguments(args))
          )
        end
        
        {execution_step, next_state_var}
      end)

    # Combine all execution steps into a pipeline
    case execution_steps do
      [] -> 
        quote do: state
      
      [single_step] ->
        quote do
          unquote(single_step)
          unquote(final_state_var)
        end
      
      steps ->
        quote do
          (unquote_splicing(steps))
          unquote(final_state_var)
        end
    end
  end

  @doc """
  Generate code for extracting the final result.

  ## Parameters
  - `execution_sequence`: List of execution steps

  ## Returns
  - Quoted code that extracts the result from the final node
  """
  @spec generate_result_extraction(execution_sequence()) :: tuple()
  def generate_result_extraction([]) do
    quote do: nil
  end

  def generate_result_extraction(execution_sequence) do
    final_node_id = DataFlow.get_final_result_node_id(execution_sequence)
    
    if final_node_id do
      quote do
        StateV2.get_fact(final_state, unquote(Integer.to_string(final_node_id)), "value")
      end
    else
      quote do: nil
    end
  end

  @doc """
  Generate the complete module code for a translated function.

  Creates a full module with all necessary helper functions and the translated
  function itself. Useful for debugging and standalone execution.

  ## Parameters
  - `module_name`: Name for the generated module
  - `func_name`: Original function name
  - `func_params`: Function parameter names
  - `execution_sequence`: KHR operations sequence
  - `annotation`: Function annotation

  ## Returns
  - String containing the complete module code
  """
  @spec generate_module_code(
    atom(),
    String.t(),
    [atom()],
    execution_sequence(),
    function_annotation()
  ) :: String.t()
  def generate_module_code(module_name, func_name, func_params, execution_sequence, annotation) do
    module_code = quote do
      defmodule unquote(module_name) do
        @moduledoc """
        Generated module for translated function: #{unquote(func_name)}
        
        Original function annotation: #{inspect(unquote(annotation))}
        Parameter names: #{inspect(unquote(func_params))}
        """

        alias StateV2
        alias AriaEngine.NodeLibrary.KHRInteractivity.{MathInteger, ControlFlow, Variables}

        # Generated function
        def unquote(String.to_atom("ast_#{func_name}"))(state, param_values) do
          # Parameter binding
          param_map = unquote(func_params)
                     |> Enum.zip(param_values)
                     |> Map.new()

          # Execute operations in sequence
          final_state = unquote(generate_execution_pipeline(execution_sequence))

          # Extract final result
          final_result = unquote(generate_result_extraction(execution_sequence))

          {final_result, final_state}
        end

        # Helper functions
        unquote(DataFlow.generate_argument_resolver())
        unquote(DataFlow.generate_action_executor())

        # Debug and inspection functions
        def get_execution_sequence do
          unquote(Macro.escape(execution_sequence))
        end

        def get_function_info do
          %{
            original_name: unquote(func_name),
            parameters: unquote(func_params),
            annotation: unquote(Macro.escape(annotation)),
            node_count: unquote(length(execution_sequence))
          }
        end
      end
    end

    Macro.to_string(module_code)
  end

  @doc """
  Generate a debug-friendly version of an executable function.

  Includes detailed logging and intermediate state inspection capabilities.

  ## Parameters
  - `func_name`: Original function name
  - `func_params`: Function parameter names  
  - `execution_sequence`: KHR operations sequence
  - `annotation`: Function annotation

  ## Returns
  - Executable function with debug capabilities
  """
  @spec generate_debug_function(
    String.t(),
    [atom()],
    execution_sequence(),
    function_annotation()
  ) :: function()
  def generate_debug_function(func_name, func_params, execution_sequence, annotation) do
    function_code = quote do
      fn state, param_values, opts \\ [] ->
        debug_mode = Keyword.get(opts, :debug, false)
        
        if debug_mode do
          IO.puts("=== AST Function Debug: #{unquote(func_name)} ===")
          IO.puts("Parameters: #{inspect(unquote(func_params))}")
          IO.puts("Values: #{inspect(param_values)}")
          IO.puts("Execution sequence: #{length(unquote(execution_sequence))} operations")
        end

        # Parameter binding
        param_map = unquote(func_params)
                   |> Enum.zip(param_values)
                   |> Map.new()

        if debug_mode do
          IO.puts("Parameter map: #{inspect(param_map)}")
        end

        # Execute operations with debug output
        final_state = unquote(generate_debug_execution_pipeline(execution_sequence))

        # Extract final result
        final_result = unquote(generate_result_extraction(execution_sequence))

        if debug_mode do
          IO.puts("Final result: #{inspect(final_result)}")
          IO.puts("=== End Debug ===")
        end

        {final_result, final_state}
      end
    end

    {func, _binding} = Code.eval_quoted(function_code, [])
    func
  end

  @doc """
  Validate that a generated function works correctly.

  ## Parameters
  - `generated_func`: Generated function to test
  - `test_cases`: List of {input_params, expected_output} tuples
  - `initial_state`: StateV2 instance for testing

  ## Returns
  - `:ok` if all test cases pass
  - `{:error, failures}` if any test cases fail
  """
  @spec validate_generated_function(
    function(),
    [{[any()], any()}],
    StateV2.t()
  ) :: :ok | {:error, [String.t()]}
  def validate_generated_function(generated_func, test_cases, initial_state) do
    failures = Enum.flat_map(test_cases, fn {input_params, expected_output} ->
      try do
        {actual_output, _final_state} = generated_func.(initial_state, input_params)
        
        if actual_output == expected_output do
          []
        else
          ["Expected #{inspect(expected_output)}, got #{inspect(actual_output)} for inputs #{inspect(input_params)}"]
        end
      rescue
        error ->
          ["Function failed with error: #{Exception.message(error)} for inputs #{inspect(input_params)}"]
      end
    end)

    case failures do
      [] -> :ok
      failures -> {:error, failures}
    end
  end

  @doc """
  Generate performance benchmarking code for a translated function.

  ## Parameters
  - `func_name`: Function name for identification
  - `generated_func`: Generated executable function
  - `benchmark_params`: Parameter values for benchmarking

  ## Returns
  - Function that runs performance benchmarks
  """
  @spec generate_benchmark_function(String.t(), function(), [any()]) :: function()
  def generate_benchmark_function(func_name, generated_func, benchmark_params) do
    fn state, iterations ->
      start_time = :os.system_time(:microsecond)
      
      Enum.each(1..iterations, fn _i ->
        {_result, _final_state} = generated_func.(state, benchmark_params)
      end)
      
      end_time = :os.system_time(:microsecond)
      total_time = end_time - start_time
      avg_time = total_time / iterations

      %{
        function_name: func_name,
        iterations: iterations,
        total_time_microseconds: total_time,
        average_time_microseconds: avg_time,
        operations_per_second: 1_000_000 / avg_time
      }
    end
  end

  # Private helper functions

  defp resolve_execution_arguments(args) do
    quote do
      Enum.map(unquote(args), fn
        {:param_value, param_name} -> 
          Map.get(param_map, param_name)
        
        {:node_result, node_id} ->
          StateV2.get_fact(current_state, Integer.to_string(node_id), "value")
        
        {:literal_value, value} ->
          value
        
        direct_value ->
          direct_value
      end)
    end
  end

  defp generate_debug_execution_pipeline(execution_sequence) do
    {final_state_var, execution_steps} = 
      Enum.map_reduce(execution_sequence, :state, fn {action, [node_id | args]}, current_state_var ->
        next_state_var = String.to_atom("state_after_node_#{node_id}")
        
        execution_step = quote do
          if debug_mode do
            IO.puts("Executing node #{unquote(node_id)}: #{unquote(action)}")
            IO.puts("  Args: #{inspect(unquote(args))}")
          end
          
          unquote(next_state_var) = execute_khr_action(
            unquote(current_state_var),
            unquote(action),
            unquote(resolve_execution_arguments(args))
          )
          
          if debug_mode do
            result = StateV2.get_fact(unquote(next_state_var), unquote(Integer.to_string(node_id)), "value")
            IO.puts("  Result: #{inspect(result)}")
          end
          
          unquote(next_state_var)
        end
        
        {execution_step, next_state_var}
      end)

    case execution_steps do
      [] -> 
        quote do: state
      
      steps ->
        quote do
          (unquote_splicing(steps))
          unquote(final_state_var)
        end
    end
  end

  defp execute_khr_action(state, action_name, args) do
    # This is a simplified version - the real implementation would
    # be injected via DataFlow.generate_action_executor()
    case action_name do
      :khr_math_add -> 
        [node_id, left, right] = args
        result = left + right
        StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
      
      :khr_math_sub ->
        [node_id, left, right] = args
        result = left - right
        StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
      
      :khr_math_mul ->
        [node_id, left, right] = args
        result = left * right
        StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
      
      :khr_math_abs ->
        [node_id, value] = args
        result = abs(value)
        StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
      
      _ ->
        raise ArgumentError, "Unsupported KHR action in CodeGenerator: #{action_name}"
    end
  end

  @doc """
  Generate code for handling error cases in execution.

  ## Returns
  - Quoted code for error handling wrapper
  """
  @spec generate_error_handling() :: tuple()
  def generate_error_handling do
    quote do
      defp execute_with_error_handling(state, action, args) do
        try do
          execute_khr_action(state, action, args)
        rescue
          error ->
            error_info = %{
              action: action,
              args: args,
              error: Exception.message(error),
              stacktrace: __STACKTRACE__
            }
            
            # Store error information in state for debugging
            StateV2.set_fact(state, "last_error", "info", error_info)
        end
      end
    end
  end

  @doc """
  Generate optimization hints for the execution sequence.

  ## Parameters
  - `execution_sequence`: Sequence to analyze

  ## Returns
  - List of optimization suggestions
  """
  @spec generate_optimization_hints(execution_sequence()) :: [String.t()]
  def generate_optimization_hints(execution_sequence) do
    hints = []
    
    # Check for constant folding opportunities
    hints = if has_constant_operations?(execution_sequence) do
      ["Consider constant folding for literal-only operations" | hints]
    else
      hints
    end

    # Check for redundant operations
    hints = if has_redundant_operations?(execution_sequence) do
      ["Redundant operations detected - consider eliminating duplicates" | hints]
    else
      hints
    end

    # Check for optimization potential
    hints = if length(execution_sequence) > 20 do
      ["Large operation sequence - consider breaking into smaller functions" | hints]
    else
      hints
    end

    hints
  end

  # Additional private helpers

  defp has_constant_operations?(execution_sequence) do
    Enum.any?(execution_sequence, fn {_action, [_node_id | args]} ->
      Enum.all?(args, fn
        {:literal_value, _} -> true
        _ -> false
      end)
    end)
  end

  defp has_redundant_operations?(execution_sequence) do
    # Simplified check - in a full implementation, this would be more sophisticated
    operation_signatures = Enum.map(execution_sequence, fn {action, [_node_id | args]} ->
      {action, args}
    end)
    
    length(operation_signatures) != length(Enum.uniq(operation_signatures))
  end
end
