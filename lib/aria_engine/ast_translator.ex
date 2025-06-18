defmodule AriaEngine.ASTTranslator do
  @moduledoc """
  AST-to-glTF KHR_interactivity Node Translation System

  Automatically translates Elixir function ASTs into executable sequences of 
  glTF KHR_interactivity nodes, supporting all 125+ available operations including 
  math, control flow, variables, events, animation, and type conversion.

  ## Usage

      @khr_function input: [:number, :number], output: :number
      def calculate_damage(base, modifier) do
        temp = base + modifier
        result = temp * 2
        abs(result)
      end

      # Translates to executable KHR node sequence:
      # Node 1: base + modifier → facts["1"]["value"]
      # Node 2: temp * 2 → facts["2"]["value"]
      # Node 3: abs(result) → facts["3"]["value"]

  ## Supported Operations

  - **Math**: Arithmetic, comparison, trigonometry, vectors, matrices
  - **Control Flow**: Sequence, branch, switch, loops
  - **Variables**: Get, set, exists, delete, pointer operations
  - **Events**: Send, receive, lifecycle, debug operations
  - **Animation**: Start, stop, pause, resume, status queries
  - **Type Conversion**: bool ↔ int ↔ float conversions
  """

  alias AriaEngine.ASTTranslator.{NodeManager, DataFlow, OperationRegistry, PatternMatcher, MultiCategoryExtractor, CodeGenerator}
  alias StateV2

  @type function_annotation :: %{
    input: [atom()],
    output: atom(),
    name: String.t()
  }

  @type translation_result :: 
    {:ok, {atom(), function()}} |
    {:error, String.t()}

  @doc """
  Translate an Elixir function string into an executable KHR node sequence.

  ## Parameters
  - `function_string`: String containing the function definition
  - `annotation`: Optional function annotation with input/output types

  ## Returns
  - `{:ok, {function_name, executable_function}}` on success
  - `{:error, reason}` on failure

  ## Example

      iex> function_code = '''
      ...> @khr_function input: [:number, :number], output: :number
      ...> def calculate_damage(base, modifier) do
      ...>   temp = base + modifier
      ...>   result = temp * 2
      ...>   abs(result)
      ...> end
      ...> '''
      iex> ASTTranslator.translate_function(function_code)
      {:ok, {:ast_calculate_damage, #Function<...>}}
  """
  @spec translate_function(String.t(), function_annotation() | nil) :: translation_result()
  def translate_function(function_string, annotation \\ nil) do
    try do
      # Phase 1: Parse and validate AST
      ast = Code.string_to_quoted!(function_string)
      {func_name, func_params, func_body, resolved_annotation} = extract_function_info!(ast, annotation)
      
      # Phase 2: Fast-fail validation for KHR compatibility
      validate_khr_compatible!(func_body, resolved_annotation)
      
      # Phase 3: Extract operations with node management
      node_manager = NodeManager.new(func_params)
      {operations, final_manager} = MultiCategoryExtractor.extract_operations(func_body, node_manager)
      
      # Phase 4: Build execution sequence with data flow resolution
      execution_sequence = DataFlow.build_execution_sequence(operations, final_manager)
      
      # Phase 5: Generate executable function
      executable_func = CodeGenerator.generate_executable_function(
        func_name, func_params, execution_sequence, resolved_annotation
      )
      
      {:ok, {String.to_atom("ast_#{func_name}"), executable_func}}
      
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Extract function information from AST including name, parameters, body, and annotations.
  """
  @spec extract_function_info!(tuple(), function_annotation() | nil) :: 
    {String.t(), [atom()], tuple(), function_annotation()}
  def extract_function_info!(ast, annotation \\ nil) do
    case ast do
      # Function with annotation
      {:__block__, _, [
        {:@, _, [{:khr_function, _, [annotation_data]}]},
        {:def, _, [{func_name, _, params}, [do: body]]}
      ]} ->
        resolved_annotation = %{
          input: Keyword.get(annotation_data, :input, []),
          output: Keyword.get(annotation_data, :output, :any),
          name: Atom.to_string(func_name)
        }
        param_names = extract_parameter_names(params)
        {Atom.to_string(func_name), param_names, body, resolved_annotation}
      
      # Function without annotation
      {:def, _, [{func_name, _, params}, [do: body]]} ->
        param_names = extract_parameter_names(params)
        default_annotation = annotation || %{
          input: List.duplicate(:any, length(param_names)),
          output: :any,
          name: Atom.to_string(func_name)
        }
        {Atom.to_string(func_name), param_names, body, default_annotation}
      
      _ ->
        raise ArgumentError, "Invalid function AST structure"
    end
  end

  @doc """
  Extract parameter names from function parameter AST.
  """
  @spec extract_parameter_names(list() | nil) :: [atom()]
  def extract_parameter_names(nil), do: []
  def extract_parameter_names(params) when is_list(params) do
    Enum.map(params, fn
      {param_name, _, nil} -> param_name
      {param_name, _, _context} -> param_name
      other -> raise ArgumentError, "Unsupported parameter format: #{inspect(other)}"
    end)
  end

  @doc """
  Validate that the function body is compatible with KHR node translation.
  """
  @spec validate_khr_compatible!(tuple(), function_annotation()) :: :ok
  def validate_khr_compatible!(body, annotation) do
    # Check for unsupported patterns
    case find_unsupported_patterns(body) do
      [] -> :ok
      unsupported -> 
        patterns = Enum.join(unsupported, ", ")
        raise ArgumentError, "Unsupported AST patterns found: #{patterns}"
    end
    
    # Validate annotation compatibility
    validate_annotation_compatibility!(annotation)
  end

  @doc """
  Find unsupported AST patterns in the function body.
  """
  @spec find_unsupported_patterns(tuple()) :: [String.t()]
  def find_unsupported_patterns(ast) do
    # Walk the AST and collect unsupported patterns
    {_ast, unsupported} = Macro.prewalk(ast, [], fn node, acc ->
      case node do
        # Supported patterns
        {op, _, _} when op in [:+, :-, :*, :/, :rem, :==, :!=, :<, :>, :<=, :>=] -> {node, acc}
        {:=, _, _} -> {node, acc} # Variable assignment
        {:if, _, _} -> {node, acc} # Conditional
        {:case, _, _} -> {node, acc} # Switch
        {:__block__, _, _} -> {node, acc} # Sequence
        {func, _, _} when func in [:abs, :min, :max, :floor, :ceil] -> {node, acc} # Math functions
        {var_name, _, nil} when is_atom(var_name) -> {node, acc} # Variable reference
        literal when is_number(literal) or is_boolean(literal) or is_binary(literal) -> {node, acc}
        
        # Unsupported patterns
        {func, _, _} when func in [:send, :receive, :spawn, :exit] -> 
          {node, ["OTP operations (#{func})" | acc]}
        {:fn, _, _} -> 
          {node, ["Anonymous functions" | acc]}
        {:for, _, _} -> 
          {node, ["For comprehensions" | acc]}
        {:with, _, _} -> 
          {node, ["With expressions" | acc]}
        {:try, _, _} -> 
          {node, ["Try-catch blocks" | acc]}
        
        _ -> {node, acc}
      end
    end)
    
    unsupported |> Enum.uniq()
  end

  @doc """
  Translate a function from AST components to executable KHR function.

  ## Parameters
  - `func_name`: Function name string
  - `func_params`: List of parameter atoms
  - `func_body`: Function body AST

  ## Returns
  - `{executable_function, annotation}` tuple
  """
  @spec translate_function(String.t(), [atom()], tuple()) :: 
    {function(), function_annotation()}
  def translate_function(func_name, func_params, func_body) do
    translate_function(func_name, func_params, func_body, %{})
  end

  @doc """
  Translate a function from AST components with annotation to executable KHR function.

  ## Parameters
  - `func_name`: Function name string
  - `func_params`: List of parameter atoms
  - `func_body`: Function body AST
  - `annotation`: Function type annotation map

  ## Returns
  - `{executable_function, final_annotation}` tuple
  """
  @spec translate_function(String.t(), [atom()], tuple(), map()) :: 
    {function(), function_annotation()}
  def translate_function(func_name, func_params, func_body, annotation) do
    # Initialize node manager
    node_manager = NodeManager.new(func_params)

    # Extract operations from the function body
    {operations, final_manager} = MultiCategoryExtractor.extract_operations(func_body, node_manager)

    # Build execution sequence
    execution_sequence = DataFlow.build_execution_sequence(operations, final_manager)

    # Infer type annotation if not provided
    final_annotation = Map.merge(%{
      input: func_params,
      output: infer_output_type(operations),
      name: func_name
    }, annotation)

    # Generate executable function
    executable_func = CodeGenerator.generate_executable_function(
      func_name, func_params, execution_sequence, final_annotation
    )

    {executable_func, final_annotation}
  end

  @doc """
  Check if a specific operation is supported by the translator.
  """
  @spec operation_supported?(atom()) :: boolean()
  def operation_supported?(operation) do
    OperationRegistry.supported_operation?(operation)
  end

  # Private helper functions

  defp parse_function_with_annotation(function_code) do
    try do
      ast = Code.string_to_quoted!(function_code)
      {func_name, func_params, func_body, annotation} = extract_function_info!(ast)
      {:ok, {func_name, func_params, func_body, annotation}}
    rescue
      error ->
        {:error, "Failed to parse function: #{Exception.message(error)}"}
    end
  end

  defp validate_annotation_compatibility!(annotation) do
    # Validate input types
    if Map.has_key?(annotation, :input) do
      case annotation.input do
        list when is_list(list) -> :ok
        _ -> raise ArgumentError, "Input annotation must be a list of types"
      end
    end

    # Validate output type
    if Map.has_key?(annotation, :output) do
      valid_types = [:any, :number, :integer, :float, :boolean, :string]
      unless annotation.output in valid_types do
        raise ArgumentError, "Output type must be one of: #{inspect(valid_types)}"
      end
    end

    :ok
  end

  defp infer_output_type([]), do: :any
  defp infer_output_type(operations) do
    # Get the result type of the last operation
    case List.last(operations) do
      %{result_type: type} -> type
      _ -> :any
    end
  end
end
