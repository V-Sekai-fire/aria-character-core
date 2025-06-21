# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Chunks.Compression do
  @moduledoc """
  Chunk compression and decompression utilities.
  
  Provides compression functionality for chunks using various algorithms,
  with zstd as the primary compression method.
  """

  @type compression_algorithm :: :zstd | :none
  @type compression_result :: {:ok, binary()} | {:error, atom() | {atom(), any()}}

  @doc """
  Compresses chunk data using the specified compression algorithm.

  Supports zstd compression (default) and no compression. The compressed
  data format includes a small header indicating the compression algorithm used.

  ## Parameters
    - data: Binary data to compress
    - algorithm: Compression algorithm to use (:zstd, :none)

  ## Returns
    - {:ok, binary} - Successfully compressed data with header
    - {:error, :compression_not_available} - Compression algorithm not available
  """
  @spec compress_chunk(binary(), compression_algorithm()) :: compression_result()
  def compress_chunk(data, algorithm \\ :zstd) do
    case algorithm do
      :zstd ->
        try do
          # Use Erlang module directly with compression level 1
          compressed = :ezstd.compress(data, 1)
          {:ok, compressed}
        rescue
          UndefinedFunctionError ->
            {:error, :compression_not_available}
        catch
          :error, reason ->
            {:error, {:compression_failed, reason}}
        end

      :none ->
        {:ok, data}

      _ ->
        {:error, {:unsupported_compression, algorithm}}
    end
  end

  @doc """
  Decompresses chunk data that was previously compressed with compress_chunk/2.

  ## Parameters
    - compressed_data: Binary data to decompress
    - algorithm: Compression algorithm used (:zstd, :none)

  ## Returns
    - {:ok, binary} - Successfully decompressed data
    - {:error, :compression_not_available} - Decompression algorithm not available
    - {:error, {:decompression_failed, reason}} - Decompression failed
  """
  @spec decompress_chunk(binary(), compression_algorithm()) :: compression_result()
  def decompress_chunk(compressed_data, algorithm \\ :zstd) do
    case algorithm do
      :zstd ->
        try do
          # Use Erlang module directly
          decompressed = :ezstd.decompress(compressed_data)
          {:ok, decompressed}
        rescue
          UndefinedFunctionError ->
            {:error, :compression_not_available}
        catch
          :error, reason ->
            {:error, {:decompression_failed, reason}}
        end

      :none ->
        {:ok, compressed_data}

      _ ->
        {:error, {:unsupported_compression, algorithm}}
    end
  end

  @doc """
  Check if a compression algorithm is available.
  """
  @spec compression_available?(compression_algorithm()) :: boolean()
  def compression_available?(:zstd) do
    try do
      # Test if ezstd is available
      :ezstd.compress("test", 1)
      true
    rescue
      UndefinedFunctionError -> false
    catch
      :error, _ -> false
    end
  end

  def compression_available?(:none), do: true
  def compression_available?(_), do: false

  @doc """
  Get the best available compression algorithm.
  """
  @spec best_available_compression() :: compression_algorithm()
  def best_available_compression do
    if compression_available?(:zstd) do
      :zstd
    else
      :none
    end
  end

  @doc """
  Calculate compression ratio for given data and algorithm.
  """
  @spec compression_ratio(binary(), compression_algorithm()) :: {:ok, float()} | {:error, any()}
  def compression_ratio(data, algorithm) do
    original_size = byte_size(data)

    case compress_chunk(data, algorithm) do
      {:ok, compressed} ->
        compressed_size = byte_size(compressed)
        ratio = compressed_size / original_size
        {:ok, ratio}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
