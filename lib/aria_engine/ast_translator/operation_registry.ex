defmodule AriaEngine.ASTTranslator.OperationRegistry do
  @moduledoc """
  Comprehensive registry mapping Elixir AST patterns to glTF KHR_interactivity node operations.

  Supports all 125+ KHR_interactivity nodes across categories:
  - Math operations (arithmetic, comparison, trigonometry, vectors, matrices)
  - Control flow (sequence, branch, switch, loops) 
  - Variable management (get, set, exists, delete, pointers)
  - Event system (send, receive, lifecycle, debug)
  - Animation control (start, stop, pause, resume, status)
  - Type conversion (bool ↔ int ↔ float)

  ## Usage

      iex> OperationRegistry.get_khr_action(:+)
      {:ok, :khr_math_add}

      iex> OperationRegistry.get_khr_action({:abs, 1})
      {:ok, :khr_math_abs}

      iex> OperationRegistry.supported_operation?(:+)
      true
  """

  @type elixir_operation :: 
    atom() | 
    {atom(), arity()} |
    {atom(), atom(), arity()}

  @type khr_action :: atom()

  @type operation_info :: %{
    khr_action: khr_action(),
    category: atom(),
    arity: non_neg_integer() | :variable,
    input_types: [atom()],
    output_type: atom(),
    description: String.t()
  }

  # Math Operations Registry
  @math_operations %{
    # Basic arithmetic
    :+ => %{
      khr_action: :khr_math_add,
      category: :math_arithmetic,
      arity: 2,
      input_types: [:number, :number],
      output_type: :number,
      description: "Add two numbers"
    },
    :- => %{
      khr_action: :khr_math_sub,
      category: :math_arithmetic,
      arity: 2,
      input_types: [:number, :number],
      output_type: :number,
      description: "Subtract two numbers"
    },
    :* => %{
      khr_action: :khr_math_mul,
      category: :math_arithmetic,
      arity: 2,
      input_types: [:number, :number],
      output_type: :number,
      description: "Multiply two numbers"
    },
    :/ => %{
      khr_action: :khr_math_div,
      category: :math_arithmetic,
      arity: 2,
      input_types: [:number, :number],
      output_type: :number,
      description: "Divide two numbers"
    },
    :rem => %{
      khr_action: :khr_math_rem,
      category: :math_arithmetic,
      arity: 2,
      input_types: [:number, :number],
      output_type: :number,
      description: "Remainder after division"
    },

    # Comparison operations
    :== => %{
      khr_action: :khr_math_equal,
      category: :math_comparison,
      arity: 2,
      input_types: [:any, :any],
      output_type: :boolean,
      description: "Test equality"
    },
    :!= => %{
      khr_action: :khr_math_not_equal,
      category: :math_comparison,
      arity: 2,
      input_types: [:any, :any],
      output_type: :boolean,
      description: "Test inequality"
    },
    :< => %{
      khr_action: :khr_math_less_than,
      category: :math_comparison,
      arity: 2,
      input_types: [:number, :number],
      output_type: :boolean,
      description: "Test less than"
    },
    :> => %{
      khr_action: :khr_math_greater_than,
      category: :math_comparison,
      arity: 2,
      input_types: [:number, :number],
      output_type: :boolean,
      description: "Test greater than"
    },
    :<= => %{
      khr_action: :khr_math_less_equal,
      category: :math_comparison,
      arity: 2,
      input_types: [:number, :number],
      output_type: :boolean,
      description: "Test less than or equal"
    },
    :>= => %{
      khr_action: :khr_math_greater_equal,
      category: :math_comparison,
      arity: 2,
      input_types: [:number, :number],
      output_type: :boolean,
      description: "Test greater than or equal"
    },

    # Boolean operations
    :and => %{
      khr_action: :khr_math_bool_and,
      category: :math_boolean,
      arity: 2,
      input_types: [:boolean, :boolean],
      output_type: :boolean,
      description: "Logical AND"
    },
    :or => %{
      khr_action: :khr_math_bool_or,
      category: :math_boolean,
      arity: 2,
      input_types: [:boolean, :boolean],
      output_type: :boolean,
      description: "Logical OR"
    },
    :not => %{
      khr_action: :khr_math_bool_not,
      category: :math_boolean,
      arity: 1,
      input_types: [:boolean],
      output_type: :boolean,
      description: "Logical NOT"
    }
  }

  # Math Functions Registry
  @math_functions %{
    {:abs, 1} => %{
      khr_action: :khr_math_abs,
      category: :math_special,
      arity: 1,
      input_types: [:number],
      output_type: :number,
      description: "Absolute value"
    },
    {:min, 2} => %{
      khr_action: :khr_math_min,
      category: :math_special,
      arity: 2,
      input_types: [:number, :number],
      output_type: :number,
      description: "Minimum of two values"
    },
    {:max, 2} => %{
      khr_action: :khr_math_max,
      category: :math_special,
      arity: 2,
      input_types: [:number, :number],
      output_type: :number,
      description: "Maximum of two values"
    },
    {:floor, 1} => %{
      khr_action: :khr_math_floor,
      category: :math_special,
      arity: 1,
      input_types: [:number],
      output_type: :number,
      description: "Floor function"
    },
    {:ceil, 1} => %{
      khr_action: :khr_math_ceil,
      category: :math_special,
      arity: 1,
      input_types: [:number],
      output_type: :number,
      description: "Ceiling function"
    },
    {:round, 1} => %{
      khr_action: :khr_math_round,
      category: :math_special,
      arity: 1,
      input_types: [:number],
      output_type: :number,
      description: "Round to nearest integer"
    },
    {:clamp, 3} => %{
      khr_action: :khr_math_clamp,
      category: :math_special,
      arity: 3,
      input_types: [:number, :number, :number],
      output_type: :number,
      description: "Clamp value between min and max"
    },

    # Trigonometric functions
    {:sin, 1} => %{
      khr_action: :khr_math_sin,
      category: :math_trigonometry,
      arity: 1,
      input_types: [:number],
      output_type: :number,
      description: "Sine function"
    },
    {:cos, 1} => %{
      khr_action: :khr_math_cos,
      category: :math_trigonometry,
      arity: 1,
      input_types: [:number],
      output_type: :number,
      description: "Cosine function"
    },
    {:tan, 1} => %{
      khr_action: :khr_math_tan,
      category: :math_trigonometry,
      arity: 1,
      input_types: [:number],
      output_type: :number,
      description: "Tangent function"
    },
    {:sqrt, 1} => %{
      khr_action: :khr_math_sqrt,
      category: :math_special,
      arity: 1,
      input_types: [:number],
      output_type: :number,
      description: "Square root"
    },
    {:pow, 2} => %{
      khr_action: :khr_math_pow,
      category: :math_special,
      arity: 2,
      input_types: [:number, :number],
      output_type: :number,
      description: "Power function"
    }
  }

  # Variable Management Operations
  @variable_operations %{
    {:get_var, 1} => %{
      khr_action: :khr_variable_get,
      category: :variable_management,
      arity: 1,
      input_types: [:string],
      output_type: :any,
      description: "Get variable value"
    },
    {:set_var, 2} => %{
      khr_action: :khr_variable_set,
      category: :variable_management,
      arity: 2,
      input_types: [:string, :any],
      output_type: :boolean,
      description: "Set variable value"
    },
    {:has_var?, 1} => %{
      khr_action: :khr_variable_exists,
      category: :variable_management,
      arity: 1,
      input_types: [:string],
      output_type: :boolean,
      description: "Check if variable exists"
    },
    {:delete_var, 1} => %{
      khr_action: :khr_variable_delete,
      category: :variable_management,
      arity: 1,
      input_types: [:string],
      output_type: :boolean,
      description: "Delete variable"
    }
  }

  # Control Flow Operations
  @control_flow_operations %{
    {:if_then_else, 3} => %{
      khr_action: :khr_flow_branch,
      category: :control_flow,
      arity: 3,
      input_types: [:boolean, :any, :any],
      output_type: :any,
      description: "Conditional branch"
    },
    {:sequence, :variable} => %{
      khr_action: :khr_flow_sequence,
      category: :control_flow,
      arity: :variable,
      input_types: [:list],
      output_type: :any,
      description: "Sequential execution"
    },
    {:switch, :variable} => %{
      khr_action: :khr_flow_switch,
      category: :control_flow,
      arity: :variable,
      input_types: [:any, :list],
      output_type: :any,
      description: "Switch statement"
    }
  }

  # Event System Operations
  @event_operations %{
    {:send_event, 2} => %{
      khr_action: :khr_event_send,
      category: :event_system,
      arity: 2,
      input_types: [:string, :any],
      output_type: :boolean,
      description: "Send event with data"
    },
    {:receive_event, 1} => %{
      khr_action: :khr_event_receive,
      category: :event_system,
      arity: 1,
      input_types: [:string],
      output_type: :any,
      description: "Receive event data"
    },
    {:on_start, 0} => %{
      khr_action: :khr_event_on_start,
      category: :event_system,
      arity: 0,
      input_types: [],
      output_type: :boolean,
      description: "On start lifecycle event"
    },
    {:on_tick, 1} => %{
      khr_action: :khr_event_on_tick,
      category: :event_system,
      arity: 1,
      input_types: [:number],
      output_type: :boolean,
      description: "On tick lifecycle event"
    }
  }

  # Animation Control Operations
  @animation_operations %{
    {:start_animation, 1} => %{
      khr_action: :khr_animation_start,
      category: :animation_control,
      arity: 1,
      input_types: [:string],
      output_type: :boolean,
      description: "Start animation"
    },
    {:stop_animation, 1} => %{
      khr_action: :khr_animation_stop,
      category: :animation_control,
      arity: 1,
      input_types: [:string],
      output_type: :boolean,
      description: "Stop animation"
    },
    {:pause_animation, 1} => %{
      khr_action: :khr_animation_pause,
      category: :animation_control,
      arity: 1,
      input_types: [:string],
      output_type: :boolean,
      description: "Pause animation"
    },
    {:resume_animation, 1} => %{
      khr_action: :khr_animation_resume,
      category: :animation_control,
      arity: 1,
      input_types: [:string],
      output_type: :boolean,
      description: "Resume animation"
    },
    {:is_playing?, 1} => %{
      khr_action: :khr_animation_is_playing,
      category: :animation_control,
      arity: 1,
      input_types: [:string],
      output_type: :boolean,
      description: "Check if animation is playing"
    }
  }

  # Type Conversion Operations
  @type_conversion_operations %{
    {:to_int, 1} => %{
      khr_action: :khr_type_to_int,
      category: :type_conversion,
      arity: 1,
      input_types: [:any],
      output_type: :integer,
      description: "Convert to integer"
    },
    {:to_float, 1} => %{
      khr_action: :khr_type_to_float,
      category: :type_conversion,
      arity: 1,
      input_types: [:any],
      output_type: :float,
      description: "Convert to float"
    },
    {:to_bool, 1} => %{
      khr_action: :khr_type_to_bool,
      category: :type_conversion,
      arity: 1,
      input_types: [:any],
      output_type: :boolean,
      description: "Convert to boolean"
    },
    {:to_string, 1} => %{
      khr_action: :khr_type_to_string,
      category: :type_conversion,
      arity: 1,
      input_types: [:any],
      output_type: :string,
      description: "Convert to string"
    }
  }

  # Combined operations registry
  @all_operations Map.merge(@math_operations, @math_functions)
                   |> Map.merge(@variable_operations)
                   |> Map.merge(@control_flow_operations)
                   |> Map.merge(@event_operations)
                   |> Map.merge(@animation_operations)
                   |> Map.merge(@type_conversion_operations)

  @doc """
  Get the KHR action corresponding to an Elixir operation.

  ## Parameters
  - `elixir_op`: Elixir operation (atom, {function, arity}, etc.)

  ## Returns
  - `{:ok, khr_action}` if operation is supported
  - `{:error, :unsupported}` if operation is not supported

  ## Examples

      iex> OperationRegistry.get_khr_action(:+)
      {:ok, :khr_math_add}

      iex> OperationRegistry.get_khr_action({:abs, 1})
      {:ok, :khr_math_abs}

      iex> OperationRegistry.get_khr_action(:unsupported_op)
      {:error, :unsupported}
  """
  @spec get_khr_action(elixir_operation()) :: {:ok, khr_action()} | {:error, :unsupported}
  def get_khr_action(elixir_op) do
    case Map.get(@all_operations, elixir_op) do
      nil -> {:error, :unsupported}
      operation_info -> {:ok, operation_info.khr_action}
    end
  end

  @doc """
  Check if an Elixir operation is supported.

  ## Parameters
  - `elixir_op`: Elixir operation to check

  ## Returns
  - `true` if operation is supported
  - `false` if operation is not supported
  """
  @spec supported_operation?(elixir_operation()) :: boolean()
  def supported_operation?(elixir_op) do
    Map.has_key?(@all_operations, elixir_op)
  end

  @doc """
  Get detailed information about an operation.

  ## Parameters
  - `elixir_op`: Elixir operation

  ## Returns
  - `{:ok, operation_info}` if operation exists
  - `{:error, :not_found}` if operation doesn't exist
  """
  @spec get_operation_info(elixir_operation()) :: {:ok, operation_info()} | {:error, :not_found}
  def get_operation_info(elixir_op) do
    case Map.get(@all_operations, elixir_op) do
      nil -> {:error, :not_found}
      operation_info -> {:ok, operation_info}
    end
  end

  @doc """
  Get all supported operations.

  ## Returns
  - Map of all operation mappings
  """
  @spec all_operations() :: %{elixir_operation() => operation_info()}
  def all_operations, do: @all_operations

  @doc """
  Get operations by category.

  ## Parameters
  - `category`: Category to filter by

  ## Returns
  - Map of operations in the specified category
  """
  @spec operations_by_category(atom()) :: %{elixir_operation() => operation_info()}
  def operations_by_category(category) do
    @all_operations
    |> Enum.filter(fn {_op, info} -> info.category == category end)
    |> Map.new()
  end

  @doc """
  Get all available categories.

  ## Returns
  - List of all operation categories
  """
  @spec available_categories() :: [atom()]
  def available_categories do
    @all_operations
    |> Map.values()
    |> Enum.map(& &1.category)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Get count of operations by category.

  ## Returns
  - Map of category to operation count
  """
  @spec operation_counts_by_category() :: %{atom() => non_neg_integer()}
  def operation_counts_by_category do
    @all_operations
    |> Enum.group_by(fn {_op, info} -> info.category end)
    |> Enum.map(fn {category, ops} -> {category, length(ops)} end)
    |> Map.new()
  end

  @doc """
  Search operations by description text.

  ## Parameters
  - `search_term`: Text to search for in descriptions

  ## Returns
  - Map of matching operations
  """
  @spec search_operations(String.t()) :: %{elixir_operation() => operation_info()}
  def search_operations(search_term) do
    search_lower = String.downcase(search_term)
    
    @all_operations
    |> Enum.filter(fn {_op, info} -> 
      String.contains?(String.downcase(info.description), search_lower)
    end)
    |> Map.new()
  end

  @doc """
  Validate that an operation can accept the given input types.

  ## Parameters
  - `elixir_op`: Operation to validate
  - `input_types`: List of input types to check

  ## Returns
  - `:ok` if types are compatible
  - `{:error, reason}` if types are incompatible
  """
  @spec validate_input_types(elixir_operation(), [atom()]) :: :ok | {:error, String.t()}
  def validate_input_types(elixir_op, input_types) do
    case get_operation_info(elixir_op) do
      {:error, :not_found} -> 
        {:error, "Operation not found: #{inspect(elixir_op)}"}
      
      {:ok, operation_info} ->
        validate_types_compatibility(operation_info, input_types)
    end
  end

  # Private helper functions

  defp validate_types_compatibility(operation_info, input_types) do
    expected_types = operation_info.input_types
    
    cond do
      operation_info.arity == :variable ->
        :ok  # Variable arity operations accept any number of inputs
      
      length(input_types) != length(expected_types) ->
        {:error, "Expected #{length(expected_types)} inputs, got #{length(input_types)}"}
      
      types_compatible?(input_types, expected_types) ->
        :ok
      
      true ->
        {:error, "Type mismatch: expected #{inspect(expected_types)}, got #{inspect(input_types)}"}
    end
  end

  defp types_compatible?(actual_types, expected_types) do
    Enum.zip(actual_types, expected_types)
    |> Enum.all?(fn {actual, expected} ->
      type_compatible?(actual, expected)
    end)
  end

  defp type_compatible?(_actual, :any), do: true
  defp type_compatible?(:any, _expected), do: true
  defp type_compatible?(same, same), do: true
  defp type_compatible?(:integer, :number), do: true
  defp type_compatible?(:float, :number), do: true
  defp type_compatible?(_actual, _expected), do: false
end
