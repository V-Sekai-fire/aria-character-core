# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.RuleRouter do
  @moduledoc """
  Membrane filter that applies transformation rules to files.

  This filter processes files through the specified transformation rules,
  applying each applicable rule to transform the file content.
  """

  use Membrane.Filter

  alias AriaEngine.Membrane.Migration.Format.FileData
  alias AriaEngine.Membrane.Migration.Registry

  def_input_pad :input, accepted_format: FileData, flow_control: :auto
  def_output_pad :output, accepted_format: FileData, flow_control: :auto

  def_options rules: [
                spec: [atom()],
                description: "List of rule names to apply"
              ]

  @impl true
  def handle_init(_ctx, options) do
    # Load rule modules for the specified rules
    rule_modules = Enum.map(options.rules, fn rule_name ->
      {rule_name, Registry.get_rule_module(rule_name)}
    end)

    state = %{
      rules: options.rules,
      rule_modules: rule_modules
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Membrane.Buffer{payload: file_data}, _ctx, state) do
    # Apply all applicable rules to the file
    transformed_data = apply_rules(file_data, state.rule_modules)

    output_buffer = %Membrane.Buffer{payload: transformed_data}
    {[buffer: {:output, output_buffer}], state}
  end

  # Private functions

  defp apply_rules(file_data, rule_modules) do
    Enum.reduce(rule_modules, file_data, fn {rule_name, rule_module}, acc_data ->
      if rule_module && applies_to_file?(acc_data, rule_module) do
        apply_rule_transformation(acc_data, rule_name, rule_module)
      else
        acc_data
      end
    end)
  end

  defp applies_to_file?(file_data, rule_module) do
    if function_exported?(rule_module, :applies_to_file?, 1) do
      rule_module.applies_to_file?(file_data)
    else
      # Default: apply to all .ex files
      String.ends_with?(file_data.file_path, ".ex")
    end
  end

  defp apply_rule_transformation(file_data, rule_name, rule_module) do
    if function_exported?(rule_module, :apply_transformation, 1) do
      rule_module.apply_transformation(file_data)
    else
      # If no transformation function, return unchanged
      file_data
    end
  rescue
    error ->
      # Log error and return original file data
      require Logger
      Logger.warning("Rule #{rule_name} failed for #{file_data.file_path}: #{inspect(error)}")
      file_data
  end
end
