# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf.IO do
  @moduledoc """
  Input/Output functionality for glTF files.

  This module provides functions to export glTF documents to files on disk.
  It uses the existing Document serialization capabilities to create valid
  glTF JSON files.
  """

  alias AriaGltf.Document

  @doc """
  Exports a glTF document to a file.

  Takes a Document struct and writes it as a JSON glTF file to the specified path.
  The file will be created with proper glTF 2.0 formatting.

  ## Parameters

  - `document` - A valid AriaGltf.Document struct
  - `file_path` - The path where the glTF file should be written

  ## Returns

  - `{:ok, file_path}` - On successful export
  - `{:error, reason}` - On failure

  ## Examples

      iex> document = %AriaGltf.Document{asset: %AriaGltf.Asset{version: "2.0"}}
      iex> AriaGltf.IO.export_to_file(document, "/tmp/test.gltf")
      {:ok, "/tmp/test.gltf"}

  """
  @spec export_to_file(Document.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def export_to_file(%Document{} = document, file_path) when is_binary(file_path) do
    with :ok <- validate_document(document),
         :ok <- ensure_directory_exists(file_path),
         {:ok, json_content} <- serialize_document(document),
         :ok <- write_file(file_path, json_content) do
      {:ok, file_path}
    end
  end

  def export_to_file(_, _), do: {:error, :invalid_arguments}

  @doc """
  Validates that a document is suitable for export.
  """
  @spec validate_document(Document.t()) :: :ok | {:error, term()}
  def validate_document(%Document{asset: nil}), do: {:error, :missing_asset}
  def validate_document(%Document{asset: %{version: version}}) when version != "2.0" do
    {:error, {:unsupported_version, version}}
  end
  def validate_document(%Document{}), do: :ok

  @doc """
  Ensures the target directory exists, creating it if necessary.
  """
  @spec ensure_directory_exists(String.t()) :: :ok | {:error, term()}
  def ensure_directory_exists(file_path) do
    dir_path = Path.dirname(file_path)

    case File.mkdir_p(dir_path) do
      :ok -> :ok
      {:error, reason} -> {:error, {:directory_creation_failed, reason}}
    end
  end

  @doc """
  Serializes a document to JSON format.
  """
  @spec serialize_document(Document.t()) :: {:ok, String.t()} | {:error, term()}
  def serialize_document(%Document{} = document) do
    try do
      json_data = Document.to_json(document)
      json_string = Jason.encode!(json_data, pretty: true)
      {:ok, json_string}
    rescue
      error -> {:error, {:serialization_failed, error}}
    end
  end

  @doc """
  Writes content to a file with proper error handling.
  """
  @spec write_file(String.t(), String.t()) :: :ok | {:error, term()}
  def write_file(file_path, content) do
    case File.write(file_path, content) do
      :ok -> :ok
      {:error, reason} -> {:error, {:file_write_failed, reason}}
    end
  end

  @doc """
  Loads a glTF document from a file.
  """
  @spec load_file(String.t()) :: {:ok, Document.t()} | {:error, term()}
  def load_file(file_path) when is_binary(file_path) do
    with {:ok, content} <- File.read(file_path),
         {:ok, json_data} <- Jason.decode(content),
         {:ok, document} <- Document.from_json(json_data) do
      {:ok, document}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Saves a glTF document to a file.
  """
  @spec save_file(Document.t(), String.t()) :: :ok | {:error, term()}
  def save_file(document, file_path) do
    case export_to_file(document, file_path) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Loads a binary glTF (GLB) file.
  """
  @spec load_binary(String.t()) :: {:ok, Document.t()} | {:error, term()}
  def load_binary(file_path) when is_binary(file_path) do
    # For now, stub implementation - GLB parsing would be more complex
    {:error, :not_implemented}
  end

  @doc """
  Saves a glTF document as binary glTF (GLB) file.
  """
  @spec save_binary(Document.t(), String.t()) :: :ok | {:error, term()}
  def save_binary(_document, _file_path) do
    # For now, stub implementation - GLB creation would be more complex
    {:error, :not_implemented}
  end

  @doc """
  Creates a minimal valid glTF document for testing purposes.

  Returns a Document struct with the minimum required fields to create
  a valid glTF 2.0 file.
  """
  @spec create_minimal_document() :: Document.t()
  def create_minimal_document do
    %Document{
      asset: %AriaGltf.Asset{
        version: "2.0",
        generator: "aria_gltf"
      },
      scenes: [],
      nodes: [],
      meshes: [],
      materials: [],
      textures: [],
      images: [],
      samplers: [],
      buffers: [],
      buffer_views: [],
      accessors: [],
      animations: []
    }
  end
end
