# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincExecutor.TemplateRenderer do
  @moduledoc """
  EEx template rendering for MiniZinc models.

  Handles rendering of .mzn.eex template files with variable substitution,
  providing clean separation between template processing and execution.
  """

  @type template_vars :: map()
  @type error_reason :: String.t()

  @doc """
  Render a MiniZinc template with the given variables.

  ## Parameters
  - `template_path` - Path to .mzn.eex template file
  - `template_vars` - Map of variables for template rendering

  ## Returns
  - `{:ok, content}` - Successfully rendered template content
  - `{:error, reason}` - Failed to render template

  ## Examples

      vars = %{num_activities: 3, durations: [10, 20, 15]}
      {:ok, content} = TemplateRenderer.render("stn_temporal.mzn.eex", vars)
  """
  @spec render(String.t(), template_vars()) :: {:ok, String.t()} | {:error, error_reason()}
  def render(template_path, template_vars) do
    if File.exists?(template_path) do
      render_existing_file(template_path, template_vars)
    else
      {:error, "Template not found: #{template_path}"}
    end
  end

  @doc """
  Render a template from a string with the given variables.

  ## Parameters
  - `template_content` - Raw EEx template content as string
  - `template_vars` - Map of variables for template rendering

  ## Returns
  - `{:ok, content}` - Successfully rendered template content
  - `{:error, reason}` - Failed to render template
  """
  @spec render_string(String.t(), template_vars()) :: {:ok, String.t()} | {:error, error_reason()}
  def render_string(template_content, template_vars) do
    try do
      template_vars = prepare_eex_vars(template_vars)
      rendered_content = EEx.eval_string(template_content, assigns: template_vars)
      {:ok, rendered_content}
    rescue
      error -> {:error, "Template rendering failed: #{Exception.message(error)}"}
    end
  end

  defp render_existing_file(template_path, template_vars) do
    try do
      template_content = File.read!(template_path)
      template_vars = prepare_eex_vars(template_vars)
      rendered_content = EEx.eval_string(template_content, assigns: template_vars)
      {:ok, rendered_content}
    rescue
      error -> {:error, "Template rendering failed: #{Exception.message(error)}"}
    end
  end

  defp prepare_eex_vars(vars) do
    vars |> convert_keys_to_atoms()
  end

  defp convert_keys_to_atoms(data) when is_map(data) do
    data
    |> Enum.map(fn {k, v} -> {String.to_atom(to_string(k)), convert_keys_to_atoms(v)} end)
    |> Map.new()
  end

  defp convert_keys_to_atoms(data) when is_list(data) do
    Enum.map(data, &convert_keys_to_atoms/1)
  end

  defp convert_keys_to_atoms(data) do
    data
  end
end
