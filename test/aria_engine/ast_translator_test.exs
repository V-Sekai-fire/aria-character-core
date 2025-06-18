defmodule AriaEngine.ASTTranslatorTest do
  use ExUnit.Case, async: true

  alias AriaEngine.ASTTranslator
  alias AriaEngine.ASTTranslator.{
    NodeManager,
    PatternMatcher,
    OperationRegistry,
    DataFlow,
    MultiCategoryExtractor,
    CodeGenerator
  }
  alias StateV2Mock

  doctest AriaEngine.ASTTranslator

  describe "complete translation pipeline" do
    test "translates simple arithmetic function" do
      # Original function: def add(x, y), do: x + y
      func_body = quote do: x + y
      func_params = [:x, :y]

      # Full translation pipeline
      {result_func, annotation} = ASTTranslator.translate_function("add", func_params, func_body)

      # Test the generated function
      initial_state = StateV2Mock.new()
      {result, _final_state} = result_func.(initial_state, [10, 5])

      assert result == 15
      assert annotation.input == [:x, :y]
      assert annotation.output == :number
    end

    test "translates function with variable assignment" do
      # def calculate(x, y) do
      #   temp = x + y
      #   temp * 2
      # end
      func_body = quote do
        temp = x + y
        temp * 2
      end
      func_params = [:x, :y]

      {result_func, _annotation} = ASTTranslator.translate_function("calculate", func_params, func_body)

      initial_state = StateV2Mock.new()
      {result, _final_state} = result_func.(initial_state, [3, 7])

      assert result == 20  # (3 + 7) * 2
    end

    test "translates function with math functions" do
      # def distance(x, y), do: abs(x - y)
      func_body = quote do
        abs(x - y)
      end
      func_params = [:x, :y]

      {result_func, _annotation} = ASTTranslator.translate_function("distance", func_params, func_body)

      initial_state = StateV2Mock.new()
      
      # Test positive difference
      {result1, _state1} = result_func.(initial_state, [10, 3])
      assert result1 == 7

      # Test negative difference
      {result2, _state2} = result_func.(initial_state, [3, 10])
      assert result2 == 7
    end

    test "translates function with multiple operations" do
      # def complex_calc(a, b, c) do
      #   step1 = a + b
      #   step2 = step1 * c
      #   step3 = abs(step2)
      #   min(step3, 100)
      # end
      func_body = quote do
        step1 = a + b
        step2 = step1 * c
        step3 = abs(step2)
        min(step3, 100)
      end
      func_params = [:a, :b, :c]

      {result_func, _annotation} = ASTTranslator.translate_function("complex_calc", func_params, func_body)

      initial_state = StateV2Mock.new()
      {result, _final_state} = result_func.(initial_state, [5, 3, -2])

      # (5 + 3) * -2 = -16, abs(-16) = 16, min(16, 100) = 16
      assert result == 16
    end

    test "handles comparison operations" do
      # def is_greater(x, y), do: x > y
      func_body = quote do: x > y
      func_params = [:x, :y]

      {result_func, annotation} = ASTTranslator.translate_function("is_greater", func_params, func_body)

      initial_state = StateV2Mock.new()
      
      {result1, _state1} = result_func.(initial_state, [10, 5])
      assert result1 == true

      {result2, _state2} = result_func.(initial_state, [3, 8])
      assert result2 == false

      assert annotation.output == :boolean
    end
  end

  describe "NodeManager" do
    test "manages node ID assignment" do
      manager = NodeManager.new([:x, :y])
      
      assert manager.next_node_id == 1
      assert manager.parameter_names == [:x, :y]

      {node_id1, manager2} = NodeManager.assign_node_id(manager)
      assert node_id1 == 1
      assert manager2.next_node_id == 2

      {node_id2, manager3} = NodeManager.assign_node_id(manager2, :temp)
      assert node_id2 == 2
      assert manager3.variable_map["temp"] == 2
    end

    test "tracks variable assignments" do
      manager = NodeManager.new([:x])
      {_node_id, manager2} = NodeManager.assign_node_id(manager, :result)

      assert NodeManager.get_variable_node_id(manager2, :result) == {:ok, 1}
      assert NodeManager.get_variable_node_id(manager2, :unknown) == :error
    end
  end

  describe "PatternMatcher" do
    test "recognizes binary math operations" do
      ast = {:+, [], [1, 2]}
      pattern = PatternMatcher.recognize_pattern(ast)

      assert pattern == {:binary_math, :+, [1, 2]}
    end

    test "recognizes variable assignments" do
      ast = {:=, [], [{:x, [], nil}, 5]}
      pattern = PatternMatcher.recognize_pattern(ast)

      assert pattern == {:variable_assignment, :x, 5}
    end

    test "recognizes function calls" do
      ast = {{:., [], [nil, :abs]}, [], [5]}
      pattern = PatternMatcher.recognize_pattern(ast)

      assert pattern == {:function_call, :abs, [5]}
    end

    test "extracts variable references" do
      ast = {:+, [], [{:x, [], nil}, {:y, [], nil}]}
      variables = PatternMatcher.extract_variable_references(ast)

      assert Enum.sort(variables) == [:x, :y]
    end

    test "calculates complexity scores" do
      simple_ast = 42
      complex_ast = {:+, [], [{:*, [], [{:x, [], nil}, 2]}, {:y, [], nil}]}

      assert PatternMatcher.complexity_score(simple_ast) == 0
      assert PatternMatcher.complexity_score(complex_ast) > 3
    end
  end

  describe "OperationRegistry" do
    test "maps basic operations" do
      assert OperationRegistry.get_khr_action(:+) == {:ok, :khr_math_add}
      assert OperationRegistry.get_khr_action(:-) == {:ok, :khr_math_sub}
      assert OperationRegistry.get_khr_action(:*) == {:ok, :khr_math_mul}
    end

    test "maps function operations" do
      assert OperationRegistry.get_khr_action({:abs, 1}) == {:ok, :khr_math_abs}
      assert OperationRegistry.get_khr_action({:min, 2}) == {:ok, :khr_math_min}
      assert OperationRegistry.get_khr_action({:max, 2}) == {:ok, :khr_math_max}
    end

    test "checks operation support" do
      assert OperationRegistry.supported_operation?(:+) == true
      assert OperationRegistry.supported_operation?({:abs, 1}) == true
      assert OperationRegistry.supported_operation?(:unsupported) == false
    end

    test "provides operation categories" do
      categories = OperationRegistry.available_categories()
      
      assert :math_arithmetic in categories
      assert :math_comparison in categories
      assert :math_special in categories
    end

    test "validates input types" do
      assert OperationRegistry.validate_input_types(:+, [:number, :number]) == :ok
      assert OperationRegistry.validate_input_types(:+, [:number]) == {:error, "Expected 2 inputs, got 1"}
    end
  end

  describe "DataFlow" do
    test "resolves function parameters" do
      manager = NodeManager.new([:x, :y])
      operand = {:x, [], nil}

      {resolved, _manager} = DataFlow.resolve_operand(operand, manager, [:x, :y])

      assert resolved == {:function_param, :x}
    end

    test "resolves literals" do
      manager = NodeManager.new([])
      operand = 42

      {resolved, _manager} = DataFlow.resolve_operand(operand, manager, [])

      assert resolved == {:literal, 42}
    end

    test "builds execution sequences" do
      operations = [
        %{node_id: 1, op: :+, inputs: [{:function_param, :x}, {:function_param, :y}]},
        %{node_id: 2, op: :abs, inputs: [{:node_reference, 1}]}
      ]
      manager = NodeManager.new([:x, :y])

      sequence = DataFlow.build_execution_sequence(operations, manager)

      assert length(sequence) == 2
      assert {action1, [1 | _args1]} = Enum.at(sequence, 0)
      assert action1 == :khr_math_add
      
      assert {action2, [2 | _args2]} = Enum.at(sequence, 1)
      assert action2 == :khr_math_abs
    end

    test "validates execution dependencies" do
      good_sequence = [
        {:khr_math_add, [1, {:param_value, :x}, {:param_value, :y}]},
        {:khr_math_abs, [2, {:node_result, 1}]}
      ]

      bad_sequence = [
        {:khr_math_add, [1, {:param_value, :x}, {:node_result, 2}]},  # References future node
        {:khr_math_abs, [2, {:param_value, :y}]}
      ]

      assert DataFlow.validate_execution_dependencies(good_sequence, [:x, :y]) == :ok
      assert {:error, _errors} = DataFlow.validate_execution_dependencies(bad_sequence, [:x, :y])
    end
  end

  describe "MultiCategoryExtractor" do
    test "extracts math operations" do
      ast = {:+, [], [{:x, [], nil}, {:y, [], nil}]}
      manager = NodeManager.new([:x, :y])

      {operations, _final_manager} = MultiCategoryExtractor.extract_operations(ast, manager)

      assert length(operations) == 1
      operation = hd(operations)
      assert operation.op == :+
      assert operation.node_id == 1
    end

    test "extracts variable assignments" do
      ast = {:=, [], [{:temp, [], nil}, {:+, [], [{:x, [], nil}, {:y, [], nil}]}]}
      manager = NodeManager.new([:x, :y])

      {operations, final_manager} = MultiCategoryExtractor.extract_operations(ast, manager)

      assert length(operations) == 1
      operation = hd(operations)
      assert operation.variable_name == "temp"
      assert final_manager.variable_map["temp"] == operation.node_id
    end

    test "extracts function calls" do
      ast = {{:., [], [nil, :abs]}, [], [{:x, [], nil}]}
      manager = NodeManager.new([:x])

      {operations, _final_manager} = MultiCategoryExtractor.extract_operations(ast, manager)

      assert length(operations) == 1
      operation = hd(operations)
      assert operation.op == :khr_math_abs
    end

    test "extracts sequence blocks" do
      ast = {:__block__, [], [
        {:=, [], [{:step1, [], nil}, {:+, [], [{:x, [], nil}, {:y, [], nil}]}]},
        {:*, [], [{:step1, [], nil}, 2]}
      ]}
      manager = NodeManager.new([:x, :y])

      {operations, _final_manager} = MultiCategoryExtractor.extract_operations(ast, manager)

      assert length(operations) == 2
      assert Enum.at(operations, 0).op == :+
      assert Enum.at(operations, 1).op == :*
    end
  end

  describe "CodeGenerator" do
    test "generates executable functions" do
      execution_sequence = [
        {:khr_math_add, [1, {:param_value, :x}, {:param_value, :y}]}
      ]
      annotation = %{input: [:x, :y], output: :number, name: "add"}

      func = CodeGenerator.generate_executable_function(
        "add", [:x, :y], execution_sequence, annotation
      )

      assert is_function(func, 2)

      # Test execution
      state = StateV2Mock.new()
      {result, _final_state} = func.(state, [10, 5])
      assert result == 15
    end

    test "generates module code" do
      execution_sequence = [
        {:khr_math_add, [1, {:param_value, :x}, {:param_value, :y}]}
      ]
      annotation = %{input: [:x, :y], output: :number, name: "add"}

      module_code = CodeGenerator.generate_module_code(
        TestModule, "add", [:x, :y], execution_sequence, annotation
      )

      assert is_binary(module_code)
      assert String.contains?(module_code, "defmodule TestModule")
      assert String.contains?(module_code, "def ast_add")
    end

    test "validates generated functions" do
      execution_sequence = [
        {:khr_math_add, [1, {:param_value, :x}, {:param_value, :y}]}
      ]
      annotation = %{input: [:x, :y], output: :number, name: "add"}

      func = CodeGenerator.generate_executable_function(
        "add", [:x, :y], execution_sequence, annotation
      )

      test_cases = [
        {[1, 2], 3},
        {[10, -5], 5},
        {[0, 0], 0}
      ]

      state = StateV2.new()
      result = CodeGenerator.validate_generated_function(func, test_cases, state)

      assert result == :ok
    end

    test "generates optimization hints" do
      # Sequence with all literal operations
      constant_sequence = [
        {:khr_math_add, [1, {:literal_value, 5}, {:literal_value, 3}]}
      ]

      hints = CodeGenerator.generate_optimization_hints(constant_sequence)
      assert "Consider constant folding for literal-only operations" in hints
    end
  end

  describe "error handling" do
    test "handles unsupported operations gracefully" do
      ast = {:unsupported_op, [], [1, 2]}
      manager = NodeManager.new([])

      assert_raise ArgumentError, ~r/Unsupported AST pattern/, fn ->
        MultiCategoryExtractor.extract_operations(ast, manager)
      end
    end

    test "handles invalid variable references" do
      ast = {:+, [], [{:unknown_var, [], nil}, 5]}
      manager = NodeManager.new([:x])

      assert_raise ArgumentError, ~r/Unknown variable reference/, fn ->
        DataFlow.resolve_operand({:unknown_var, [], nil}, manager, [:x])
      end
    end
  end

  describe "integration scenarios" do
    test "handles nested expressions" do
      # def calc(x), do: abs(x + (x * 2))
      func_body = quote do
        abs(x + (x * 2))
      end
      func_params = [:x]

      {result_func, _annotation} = ASTTranslator.translate_function("calc", func_params, func_body)

      state = StateV2.new()
      {result, _final_state} = result_func.(state, [-3])

      # -3 + (-3 * 2) = -3 + (-6) = -9, abs(-9) = 9
      assert result == 9
    end

    test "handles multiple variable assignments" do
      func_body = quote do
        a = x + 1
        b = y + 2
        c = a + b
        c * 3
      end
      func_params = [:x, :y]

      {result_func, _annotation} = ASTTranslator.translate_function("multi_assign", func_params, func_body)

      state = StateV2.new()
      {result, _final_state} = result_func.(state, [5, 10])

      # a = 6, b = 12, c = 18, result = 54
      assert result == 54
    end
  end
end
