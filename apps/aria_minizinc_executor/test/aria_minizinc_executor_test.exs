# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincExecutorTest do
  use ExUnit.Case
  import Mox

  alias AriaMinizincExecutor.TemplateRenderer

  setup :verify_on_exit!

  describe "TemplateRenderer.render/2" do
    test "renders template with variables successfully" do
      template_path = "test_render.mzn.eex"
      template_vars = %{num: 42}
      template_content = "int: value = <%= @num %>; solve satisfy; output [\"value: \\(value)\"];"

      File.write!(template_path, template_content)

      result = TemplateRenderer.render(template_path, template_vars)

      assert {:ok, rendered} = result
      assert String.contains?(rendered, "int: value = 42;")

      # Cleanup
      File.rm(template_path)
    end

    test "returns error when template file not found" do
      result = TemplateRenderer.render("nonexistent.mzn.eex", %{})
      assert {:error, _reason} = result
    end
  end

  describe "TemplateRenderer.render_string/2" do
    test "renders template string with variables successfully" do
      template_content = "int: x = <%= @x %>; int: y = <%= @y %>; solve satisfy; output [\"result: \\(x + y)\"];"
      template_vars = %{x: 5, y: 10}

      result = TemplateRenderer.render_string(template_content, template_vars)

      assert {:ok, rendered} = result
      assert String.contains?(rendered, "int: x = 5;")
      assert String.contains?(rendered, "int: y = 10;")
    end

    test "handles nested data structures" do
      template_content = "array[1..<%= length(@items) %>] of int: items = <%= inspect(@items) %>;"
      template_vars = %{items: [1, 2, 3]}

      result = TemplateRenderer.render_string(template_content, template_vars)

      assert {:ok, rendered} = result
      assert String.contains?(rendered, "array[1..3] of int:")
    end
  end
end
