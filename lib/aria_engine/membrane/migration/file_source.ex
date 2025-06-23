# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.FileSource do
  @moduledoc """
  Membrane source that reads files from directories and emits FileData structures.

  This source can handle both individual files and directories, recursively
  finding all .ex files and emitting them as FileData structures for processing.
  """

  use Membrane.Source

  alias AriaEngine.Membrane.Migration.Format.FileData

  def_output_pad :output, accepted_format: FileData, flow_control: :manual

  def_options location: [
                spec: String.t(),
                description: "File or directory path to read from"
              ]

  @impl true
  def handle_init(_ctx, options) do
    files = discover_files(options.location)

    state = %{
      files: files,
      current_index: 0,
      total_files: length(files)
    }

    {[], state}
  end

  @impl true
  def handle_demand(:output, size, _unit, _ctx, state) do
    # Send stream format first if not already sent
    stream_format_action = if state.current_index == 0 do
      [stream_format: {:output, %FileData{}}]
    else
      []
    end

    {buffers, new_state} = emit_files(state, size)

    actions = if new_state.current_index >= new_state.total_files do
      stream_format_action ++ buffers ++ [end_of_stream: :output]
    else
      stream_format_action ++ buffers
    end

    {actions, new_state}
  end

  # Private functions

  defp discover_files(location) do
    cond do
      File.regular?(location) and String.ends_with?(location, ".ex") ->
        [location]

      File.dir?(location) ->
        find_elixir_files(location)

      true ->
        []
    end
  end

  defp find_elixir_files(directory) do
    directory
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
  end

  defp emit_files(state, demand) do
    files_to_emit = min(demand, state.total_files - state.current_index)

    {buffers, new_index} =
      state.files
      |> Enum.slice(state.current_index, files_to_emit)
      |> Enum.with_index(state.current_index)
      |> Enum.map(fn {file_path, index} ->
        file_data = read_file_data(file_path)
        buffer = %Membrane.Buffer{payload: file_data}
        {[buffer: {:output, buffer}], index + 1}
      end)
      |> Enum.reduce({[], state.current_index}, fn {buffer_action, _}, {acc_buffers, _} ->
        {acc_buffers ++ buffer_action, files_to_emit + state.current_index}
      end)

    new_state = %{state | current_index: new_index}
    {buffers, new_state}
  end

  defp read_file_data(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        %FileData{
          file_path: file_path,
          content: content,
          original_content: content,
          transformations: [],
          applicable_rules: [],
          timestamp: DateTime.utc_now(),
          error: nil
        }

      {:error, reason} ->
        require Logger
        Logger.warning("Failed to read file #{file_path}: #{reason}")

        %FileData{
          file_path: file_path,
          content: "",
          original_content: "",
          transformations: [],
          applicable_rules: [],
          timestamp: DateTime.utc_now(),
          error: reason
        }
    end
  end
end
