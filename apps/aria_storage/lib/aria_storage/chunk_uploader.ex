# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.ChunkUploader do
  @moduledoc """
  Waffle uploader for desync/casync chunks.
  
  This module defines how chunks are stored using Waffle's flexible storage
  backends. Chunks are stored with their SHA512/256 hash as the filename
  and can be stored locally, on S3, or any other Waffle-supported backend.
  """

  use Waffle.Definition
  
  alias AriaStorage.Chunks
  
  # Accept chunk data and compressed data
  @versions [:original, :compressed]
  
  def __storage, do: Waffle.Storage.Local  # Default to local, can be overridden
  
  # Generate chunk filename based on SHA512/256 hash
  def filename(_version, {%Chunks{id: chunk_id}, _scope}) do
    chunk_id
    |> Base.encode16(case: :lower)
    |> add_chunk_extension()
  end
  
  def filename(_version, {_file, %{chunk_id: chunk_id}}) when is_binary(chunk_id) do
    chunk_id
    |> Base.encode16(case: :lower)
    |> add_chunk_extension()
  end
  
  # Handle file storage path - organize chunks in subdirectories
  def storage_dir(_version, {%Chunks{id: chunk_id}, _scope}) do
    chunk_id
    |> Base.encode16(case: :lower)
    |> organize_chunk_path()
  end
  
  def storage_dir(_version, {_file, %{chunk_id: chunk_id}}) when is_binary(chunk_id) do
    chunk_id
    |> Base.encode16(case: :lower)
    |> organize_chunk_path()
  end
  
  # Transform chunks for storage
  def transform(:original, {%Chunks{data: data}, _scope}) do
    {:ok, create_temp_file(data)}
  end
  
  def transform(:compressed, {%Chunks{compressed: compressed}, _scope}) when not is_nil(compressed) do
    {:ok, create_temp_file(compressed)}
  end
  
  def transform(:compressed, {%Chunks{data: data}, _scope}) do
    # Compress on-the-fly if not already compressed
    case Chunks.compress_chunk(data, :zstd) do
      {:ok, compressed} -> {:ok, create_temp_file(compressed)}
      compressed when is_binary(compressed) -> {:ok, create_temp_file(compressed)}
      {:error, _} -> {:ok, create_temp_file(data)}  # Fallback to uncompressed
    end
  end
  
  # Validate chunk integrity
  def validate({%Chunks{} = chunk, _scope}) do
    case validate_chunk_integrity(chunk) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Default ACL for chunk storage
  def default_acl, do: :private
  
  # S3 object metadata for chunks
  def s3_object_headers(_version, {%Chunks{} = chunk, _scope}) do
    %{
      "content-type" => "application/octet-stream",
      "cache-control" => "public, max-age=31536000",  # Cache for 1 year
      "x-chunk-size" => to_string(chunk.size),
      "x-chunk-algorithm" => "sha512-256",
      "x-desync-version" => "1.0"
    }
  end
  
  # Private functions
  
  defp add_chunk_extension(filename) do
    filename <> ".cacnk"
  end
  
  defp organize_chunk_path(chunk_id_hex) do
    # Organize chunks in subdirectories using first 4 chars
    # e.g., abcd1234... -> chunks/ab/cd/abcd1234...
    case String.length(chunk_id_hex) do
      len when len >= 4 ->
        <<a::binary-size(2), b::binary-size(2), _rest::binary>> = chunk_id_hex
        "chunks/#{a}/#{b}"
      _ ->
        "chunks/misc"
    end
  end
  
  defp create_temp_file(data) do
    # Create a temporary file for Waffle to process
    temp_path = System.tmp_dir!() |> Path.join("chunk_#{System.unique_integer([:positive])}")
    :ok = File.write!(temp_path, data)
    %Plug.Upload{
      path: temp_path,
      content_type: "application/octet-stream",
      filename: Path.basename(temp_path)
    }
  end
  
  defp validate_chunk_integrity(%Chunks{data: data, id: expected_id, checksum: checksum}) do
    # Validate SHA512/256 hash
    calculated_id = Chunks.calculate_chunk_id(data)
    if calculated_id == expected_id do
      # Validate additional checksum if present
      if checksum do
        calculated_checksum = :crypto.hash(:sha256, data)
        if calculated_checksum == checksum do
          :ok
        else
          {:error, :checksum_mismatch}
        end
      else
        :ok
      end
    else
      {:error, :chunk_id_mismatch}
    end
  end
end
