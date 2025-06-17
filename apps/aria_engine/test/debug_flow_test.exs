# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DebugFlowTest do
  @moduledoc """
  Debug test to understand Flow backflow processing behavior.
  """

  @tag :skip
  use ExUnit.Case, async: false

  describe "Debug Flow Processing" do
    test "simple flow processing without backflow" do
      # Simple test data
      actions = [
        %{id: 1, action: :move_to},
        %{id: 2, action: :attack}
      ]

      # Process with simple Flow
      results = actions
      # |> Flow.from_enumerable(stages: 1)
      |> Enum.map(fn item -> 
        IO.puts("Processing item: #{inspect(item)}")
        %{id: item.id, processed: true}
      end)
      # |> Enum.to_list()

      IO.puts("Final results: #{inspect(results)}")
      IO.puts("Results count: #{length(results)}")

      assert length(results) == 2
    end

    test "flow with chunking" do
      actions = [
        %{id: 1, action: :move_to},
        %{id: 2, action: :attack}, 
        %{id: 3, action: :skill_cast},
        %{id: 4, action: :interact}
      ]

      chunk_size = 4  # Process all in one chunk
      IO.puts("Chunk size: #{chunk_size}")

      results = actions
      |> Enum.chunk_every(chunk_size)
      # |> Flow.from_enumerable(stages: 2)
      |> Enum.map(fn chunk ->
        IO.puts("Processing chunk: #{inspect(chunk)}")
        processed_chunk = Enum.map(chunk, fn item ->
          %{id: item.id, processed: true}
        end)
        IO.puts("Processed chunk: #{inspect(processed_chunk)}")
        processed_chunk
      end)
      # |> Flow.flat_map(fn chunk_result ->
      #   IO.puts("Flattening: #{inspect(chunk_result)}")
      #   chunk_result
      # end)
      |> List.flatten()
      # |> Enum.to_list()

      IO.puts("Final results: #{inspect(results)}")
      IO.puts("Results count: #{length(results)}")

      assert length(results) == 4
    end
  end
end
