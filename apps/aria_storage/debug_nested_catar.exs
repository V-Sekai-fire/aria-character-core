#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

Mix.install([])

defmodule Debug do
  @testdata_path "apps/aria_storage/test/support/testdata"

  def debug_nested_catar do
    file_path = Path.join(@testdata_path, "nested.catar")

    case File.read(file_path) do
      {:ok, data} ->
        IO.puts("File size: #{byte_size(data)} bytes")
        IO.puts("First 32 bytes:")
        IO.inspect(binary_part(data, 0, 32))

        # Try to parse with current parser
        case AriaStorage.Parsers.CasyncFormat.parse_archive(data) do
          {:ok, result} ->
            IO.puts("\nParsing successful!")
            IO.puts("Format: #{result.format}")
            IO.puts("Number of entries: #{length(result.entries)}")
            IO.puts("Entries:")
            for {entry, idx} <- Enum.with_index(result.entries) do
              IO.puts("  Entry #{idx + 1}: #{inspect(entry)}")
            end
          {:error, reason} ->
            IO.puts("Parsing failed: #{inspect(reason)}")
        end

      {:error, reason} ->
        IO.puts("Failed to read file: #{inspect(reason)}")
    end
  end
end

Debug.debug_nested_catar()
