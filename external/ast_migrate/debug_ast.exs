# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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

Logger.debug("=== Full AST ===")
IO.inspect(ast, pretty: true, limit: :infinity)

Logger.debug("\n=== Walking through AST nodes ===")
defmodule ASTWalker do
  def walk(ast) do
    case ast do
      {:defmodule, _, [{:__aliases__, _, [:AriaEngine, :Membrane | rest]}, _]} = node ->
        Logger.debug("Found defmodule: #{inspect(node)}")
        Logger.debug("  - Rest: #{inspect(rest)}")

      {:alias, _, [{:__aliases__, _, [:AriaEngine, :Membrane | rest]} | _]} = node ->
        Logger.debug("Found alias: #{inspect(node)}")
        Logger.debug("  - Rest: #{inspect(rest)}")

      {{:., _, [{:__aliases__, _, [:AriaEngine, :Membrane | rest]}, func]}, _, args} = node ->
        Logger.debug("Found function call: #{inspect(node)}")
        Logger.debug("  - Rest: #{inspect(rest)}")
        Logger.debug("  - Function: #{inspect(func)}")

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

Logger.debug("\n=== Done ===")
