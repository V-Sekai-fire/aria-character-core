# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.RuleRouter do
  @moduledoc """
  Membrane filter that routes files to appropriate rule bins for processing.

  This filter acts as a pass-through for now, but could be extended to route
  files to specific rule bins based on their applicable rules.
  """

  use Membrane.Filter

  alias AriaEngine.Membrane.Migration.Format.FileData

  def_input_pad :input, accepted_format: FileData, flow_control: :auto
  def_output_pad :output, accepted_format: FileData, flow_control: :auto

  def_options rules: [
                spec: [atom()],
                description: "List of rule names to route to"
              ]

  @impl true
  def handle_init(_ctx, options) do
    state = %{
      rules: options.rules
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Membrane.Buffer{payload: file_data}, _ctx, state) do
    # For now, just pass through all files
    # In a more complex implementation, this could route files to specific rule bins
    output_buffer = %Membrane.Buffer{payload: file_data}
    {[buffer: {:output, output_buffer}], state}
  end
end
