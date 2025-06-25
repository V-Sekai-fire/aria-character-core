# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMinizincExecutor do
  @moduledoc """
  Pure MiniZinc execution infrastructure via Porcelain.

  This application provides the foundation layer for all MiniZinc-based
  constraint solving, handling template rendering, process execution,
  and result parsing without any domain-specific logic.

  ## Main Components

  - `AriaMinizincExecutor.Executor` - Core MiniZinc execution with Porcelain
  - `AriaMinizincExecutor.ExecutorBehaviour` - Behavior for testing and mocking
  - `AriaMinizincExecutor.TemplateRenderer` - EEx template processing

  ## Usage

      # Execute a template with variables
      {:ok, result} = AriaMinizincExecutor.exec("path/to/template.mzn.eex",
        %{input_value: 5, multiplier: 3})

      # Execute raw MiniZinc content
      {:ok, result} = AriaMinizincExecutor.exec_raw(minizinc_content)

      # Check MiniZinc availability
      {:ok, version} = AriaMinizincExecutor.check_availability()

      # Render template without execution
      {:ok, content} = AriaMinizincExecutor.render_template("template.mzn.eex", vars)
  """

  alias AriaMinizincExecutor.{Executor, TemplateRenderer}

  @doc """
  Execute a MiniZinc template with the given variables.

  ## Parameters
  - `template_path` - Path to .mzn.eex template file
  - `template_vars` - Map of variables for template rendering
  - `options` - Execution options including timeout

  ## Returns
  - `{:ok, result}` - Successfully executed with solution
  - `{:error, reason}` - Failed to execute or solve
  """
  def exec(template_path, template_vars, options \\ []) do
    with {:ok, content} <- TemplateRenderer.render(template_path, template_vars),
         {:ok, result} <- Executor.exec_raw(content, options) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Execute raw MiniZinc content directly.

  ## Parameters
  - `minizinc_content` - Raw MiniZinc model content
  - `options` - Execution options including timeout

  ## Returns
  - `{:ok, result}` - Successfully executed with solution
  - `{:error, reason}` - Failed to execute or solve
  """
  def exec_raw(minizinc_content, options \\ []) do
    Executor.exec_raw(minizinc_content, options)
  end

  @doc """
  Check if MiniZinc is available on the system.

  ## Returns
  - `{:ok, version}` - MiniZinc is available with version info
  - `{:error, reason}` - MiniZinc is not available or accessible
  """
  def check_availability do
    Executor.check_availability()
  end

  @doc """
  Render a template with variables without executing.

  ## Parameters
  - `template_path` - Path to .mzn.eex template file
  - `template_vars` - Map of variables for template rendering

  ## Returns
  - `{:ok, content}` - Successfully rendered template content
  - `{:error, reason}` - Failed to render template
  """
  def render_template(template_path, template_vars) do
    TemplateRenderer.render(template_path, template_vars)
  end
end
