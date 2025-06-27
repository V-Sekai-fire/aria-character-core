# Debug script to examine AST structure using built-in Code module
test_code = """
defmodule AriaEngine.Membrane.Format.TestModule do
  alias AriaEngine.Membrane.Format.PlanningResult

  def test_function do
    AriaEngine.Membrane.Format.PlanningResult.success(%{}, "test", %{}, %{})
  end
end
"""

{:ok, ast} = Code.string_to_quoted(test_code)

IO.puts("=== Full AST ===")
IO.inspect(ast, pretty: true, limit: :infinity)

IO.puts("\n=== Walking through AST nodes ===")
defmodule ASTWalker do
  def walk(ast) do
    case ast do
      {:defmodule, _, [{:__aliases__, _, [:AriaEngine, :Membrane | rest]}, _]} = node ->
        IO.puts("Found defmodule: #{inspect(node)}")
        IO.puts("  - Rest: #{inspect(rest)}")

      {:alias, _, [{:__aliases__, _, [:AriaEngine, :Membrane | rest]} | _]} = node ->
        IO.puts("Found alias: #{inspect(node)}")
        IO.puts("  - Rest: #{inspect(rest)}")

      {{:., _, [{:__aliases__, _, [:AriaEngine, :Membrane | rest]}, func]}, _, args} = node ->
        IO.puts("Found function call: #{inspect(node)}")
        IO.puts("  - Rest: #{inspect(rest)}")
        IO.puts("  - Function: #{inspect(func)}")

      {_tag, _, children} when is_list(children) ->
        Enum.each(children, &walk/1)

      {_tag, _, child} ->
        walk(child)

      list when is_list(list) ->
        Enum.each(list, &walk/1)

      _ ->
        :ok
    end
  end
end

ASTWalker.walk(ast)

IO.puts("\n=== Done ===")
