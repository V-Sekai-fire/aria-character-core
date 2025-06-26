# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSolver.Executor do
  @moduledoc """
  Pure MiniZinc execution infrastructure for AriaSolver.

  This module provides the foundation layer for all MiniZinc-based
  constraint solving, handling template rendering, process execution,
  and result parsing without any domain-specific logic. Migrated from
  `aria_minizinc_executor` as part of ADR-193 layered architecture consolidation.

  ## Main Components

  - Core MiniZinc execution with Porcelain
  - EEx template processing
  - Result parsing and error handling

  ## Usage

      # Execute a template with variables
      {:ok, result} = AriaSolver.Executor.exec("path/to/template.mzn.eex",
        %{input_value: 5, multiplier: 3})

      # Execute raw MiniZinc content
      {:ok, result} = AriaSolver.Executor.exec_raw(minizinc_content)

      # Check MiniZinc availability
      {:ok, version} = AriaSolver.Executor.check_availability()

      # Render template without execution
      {:ok, content} = AriaSolver.Executor.render_template("template.mzn.eex", vars)
  """

  require Logger

  @type template_vars :: map()
  @type execution_options :: keyword()
  @type execution_result :: map()
  @type error_reason :: atom() | String.t()

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
  @spec exec(String.t(), template_vars(), execution_options()) ::
          {:ok, execution_result()} | {:error, error_reason()}
  def exec(template_path, template_vars, options \\ []) do
    with {:ok, content} <- render_template(template_path, template_vars),
         {:ok, result} <- exec_raw(content, options) do
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
  @spec exec_raw(String.t(), execution_options()) ::
          {:ok, execution_result()} | {:error, error_reason()}
  def exec_raw(minizinc_content, options \\ []) do
    timeout = Keyword.get(options, :timeout, 30_000)
    
    case check_availability() do
      {:ok, _version} ->
        execute_minizinc(minizinc_content, timeout)
      {:error, reason} ->
        {:error, "MiniZinc not available: #{reason}"}
    end
  end

  @doc """
  Check if MiniZinc is available on the system.

  ## Returns
  - `{:ok, version}` - MiniZinc is available with version info
  - `{:error, reason}` - MiniZinc is not available or accessible
  """
  @spec check_availability() :: {:ok, String.t()} | {:error, error_reason()}
  def check_availability do
    case System.cmd("minizinc", ["--version"], stderr_to_stdout: true) do
      {output, 0} ->
        version = String.trim(output)
        {:ok, version}
      {_output, _exit_code} ->
        {:error, :minizinc_not_found}
    rescue
      _error ->
        {:error, :minizinc_not_found}
    end
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
  @spec render_template(String.t(), template_vars()) :: {:ok, String.t()} | {:error, error_reason()}
  def render_template(template_path, template_vars) do
    case File.read(template_path) do
      {:ok, template_content} ->
        try do
          rendered = EEx.eval_string(template_content, assigns: template_vars)
          {:ok, rendered}
        rescue
          error ->
            {:error, "Template rendering failed: #{Exception.message(error)}"}
        end
      {:error, reason} ->
        {:error, "Failed to read template: #{reason}"}
    end
  end

  # Private helper functions

  defp execute_minizinc(content, timeout) do
    # Create temporary file for MiniZinc input
    temp_file = System.tmp_dir!() |> Path.join("minizinc_#{:rand.uniform(1000000)}.mzn")
    
    try do
      File.write!(temp_file, content)
      
      case System.cmd("minizinc", ["--output-mode", "json", temp_file], 
                      stderr_to_stdout: true, timeout: timeout) do
        {output, 0} ->
          parse_minizinc_output(output)
        {output, exit_code} ->
          {:error, "MiniZinc execution failed (exit code #{exit_code}): #{output}"}
      end
    rescue
      error ->
        {:error, "MiniZinc execution error: #{Exception.message(error)}"}
    after
      File.rm(temp_file)
    end
  end

  defp parse_minizinc_output(output) do
    # Try to parse as JSON first
    case Jason.decode(output) do
      {:ok, parsed} ->
        {:ok, parsed}
      {:error, _} ->
        # If JSON parsing fails, return raw output
        {:ok, %{"raw_output" => output, "status" => "UNKNOWN"}}
    end
  end
end
