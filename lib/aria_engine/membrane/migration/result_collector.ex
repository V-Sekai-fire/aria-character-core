# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.ResultCollector do
  @moduledoc """
  Membrane filter that collects transformation results and aggregates statistics.

  This filter processes files through applicable rules and collects metrics
  about transformations performed.
  """

  use Membrane.Filter

  alias AriaEngine.Membrane.Migration.{Format.FileData, Registry}

  def_input_pad :input, accepted_format: FileData, flow_control: :auto
  def_output_pad :output, accepted_format: FileData, flow_control: :auto

  def_options dry_run: [
                spec: boolean(),
                default: false,
                description: "Whether this is a dry run"
              ]

  @impl true
  def handle_init(_ctx, options) do
    state = %{
      dry_run: options.dry_run,
      files_processed: 0,
      files_changed: 0,
      total_transformations: 0
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Membrane.Buffer{payload: file_data}, _ctx, state) do
    # Apply all applicable rules to this file
    transformed_file_data = apply_rules_to_file(file_data)

    # Update statistics
    new_state = update_statistics(state, transformed_file_data)

    output_buffer = %Membrane.Buffer{payload: transformed_file_data}
    {[buffer: {:output, output_buffer}], new_state}
  end

  @impl true
  def handle_end_of_stream(:input, _ctx, state) do
    # Send summary statistics when stream ends
    summary = %{
      total_files: state.files_processed,
      changed_files: state.files_changed,
      unchanged_files: state.files_processed - state.files_changed,
      skipped_files: 0,
      total_transformations: state.total_transformations
    }

    send(self(), {:pipeline_complete, summary})

    {[end_of_stream: :output], state}
  end

  # Private functions

  defp apply_rules_to_file(file_data) do
    # Apply each applicable rule in sequence
    Enum.reduce(file_data.applicable_rules, file_data, fn rule_name, acc_file_data ->
      apply_single_rule(acc_file_data, rule_name)
    end)
  end

  defp apply_single_rule(file_data, rule_name) do
    case Registry.get_rule(rule_name) do
      %{bin_module: _bin_module} ->
        # For now, we'll simulate rule application
        # In a full implementation, this would route through the actual bin
        simulate_rule_application(file_data, rule_name)

      nil ->
        file_data
    end
  end

  defp simulate_rule_application(file_data, rule_name) do
    # This is a simplified simulation - in the full implementation,
    # files would be routed through the actual rule bins
    case rule_name do
      :datetime_string_fix ->
        apply_datetime_string_fix(file_data)

      _ ->
        # For other rules, just pass through for now
        file_data
    end
  end

  defp apply_datetime_string_fix(file_data) do
    if String.contains?(file_data.content, "DateTime.to_iso8601(") do
      # Simple regex-based transformation for demonstration
      new_content = String.replace(file_data.content, ~r/DateTime\.to_iso8601\((\w+_dt|\w+_time)\)/, "\\1")

      if new_content != file_data.content do
        transformation = %{
          rule: :datetime_string_fix,
          original: "DateTime.to_iso8601(...)",
          replacement: "variable",
          line: 0
        }

        %{file_data |
          content: new_content,
          transformations: file_data.transformations ++ [transformation]
        }
      else
        file_data
      end
    else
      file_data
    end
  end

  defp update_statistics(state, file_data) do
    files_processed = state.files_processed + 1
    transformation_count = length(file_data.transformations)
    files_changed = if transformation_count > 0, do: state.files_changed + 1, else: state.files_changed

    %{state |
      files_processed: files_processed,
      files_changed: files_changed,
      total_transformations: state.total_transformations + transformation_count
    }
  end
end
