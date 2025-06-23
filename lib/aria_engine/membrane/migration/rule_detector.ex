# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.RuleDetector do
  @moduledoc """
  Membrane filter that detects which rules apply to each file.

  This filter analyzes file content and tags files with applicable transformation rules.
  """

  use Membrane.Filter

  alias AriaEngine.Membrane.Migration.{Format.FileData, Registry}

  def_input_pad :input, accepted_format: FileData, flow_control: :auto
  def_output_pad :output, accepted_format: FileData, flow_control: :auto

  def_options available_rules: [
                spec: [atom()],
                description: "List of available rule names to check"
              ]

  @impl true
  def handle_init(_ctx, options) do
    state = %{
      available_rules: options.available_rules
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Membrane.Buffer{payload: file_data}, _ctx, state) do
    # Detect applicable rules for this file
    applicable_rules = detect_applicable_rules(file_data, state.available_rules)

    # Update file data with applicable rules
    updated_file_data = %{file_data | applicable_rules: applicable_rules}

    output_buffer = %Membrane.Buffer{payload: updated_file_data}
    {[buffer: {:output, output_buffer}], state}
  end

  # Private functions

  defp detect_applicable_rules(file_data, available_rules) do
    available_rules
    |> Enum.filter(fn rule_name ->
      case Registry.get_rule(rule_name) do
        %{detection_fn: detection_fn} -> detection_fn.(file_data.content)
        nil -> false
      end
    end)
  end
end
