# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf.Validation.SchemaValidator do
  @moduledoc """
  JSON schema validation for glTF 2.0 documents.

  This module validates glTF documents against the official glTF 2.0 JSON schema
  to ensure structural compliance with the specification.
  """

  alias AriaGltf.Document
  alias AriaGltf.Validation.{Context}

  @doc """
  Validates a document against the glTF 2.0 JSON schema.
  """
  @spec validate(Context.t()) :: Context.t()
  def validate(%Context{document: document} = context) do
    # Convert document to JSON for schema validation
    json = Document.to_json(document)

    # Validate against schema
    case validate_json_schema(json) do
      :ok -> context
      {:error, errors} -> add_schema_errors(context, errors)
    end
  end

  # Schema validation implementation
  defp validate_json_schema(json) when is_map(json) do
    # TODO: Implement actual JSON schema validation
    # This would use a JSON schema library to validate against the official glTF 2.0 schema
    # For now, we'll do basic structural validation

    errors = []

    # Check required top-level fields
    errors = check_required_field(errors, json, "asset", "Root asset field is required")

    # Check asset structure
    if asset = json["asset"] do
      errors = check_required_field(errors, asset, "version", "Asset version is required")
      ^errors = check_field_type(errors, asset, "version", "string", "Asset version must be a string")
    end

    # Check array fields are actually arrays
    array_fields = ["scenes", "nodes", "meshes", "materials", "textures", "images",
                   "samplers", "accessors", "bufferViews", "buffers", "cameras",
                   "skins", "animations"]

    errors = Enum.reduce(array_fields, errors, fn field, acc ->
      if _value = json[field] do
        check_field_type(acc, json, field, "array", "#{field} must be an array")
      else
        acc
      end
    end)

    # Check scene index is valid
    if scene_index = json["scene"] do
      scenes = json["scenes"] || []
      if not is_integer(scene_index) or scene_index < 0 or scene_index >= length(scenes) do
        ^errors = ["Invalid scene index: #{scene_index}" | errors]
      end
    end

    case errors do
      [] -> :ok
      _ -> {:error, Enum.reverse(errors)}
    end
  end

  defp check_required_field(errors, map, field, message) do
    if Map.has_key?(map, field) do
      errors
    else
      [message | errors]
    end
  end

  defp check_field_type(errors, map, field, expected_type, message) do
    case {Map.get(map, field), expected_type} do
      {nil, _} -> errors
      {value, "string"} when is_binary(value) -> errors
      {value, "array"} when is_list(value) -> errors
      {value, "object"} when is_map(value) -> errors
      {value, "number"} when is_number(value) -> errors
      {value, "integer"} when is_integer(value) -> errors
      {value, "boolean"} when is_boolean(value) -> errors
      _ -> [message | errors]
    end
  end

  defp add_schema_errors(context, errors) do
    Enum.reduce(errors, context, fn error_msg, ctx ->
      Context.add_error(ctx, :schema, error_msg)
    end)
  end

  @doc """
  Validates specific glTF data types and constraints.
  """
  @spec validate_data_types(Context.t()) :: Context.t()
  def validate_data_types(%Context{} = context) do
    # TODO: Implement comprehensive data type validation
    # This would include:
    # - Numeric ranges (e.g., accessor component types)
    # - String enums (e.g., filter modes, wrap modes)
    # - URI validation for external references
    # - Base64 validation for data URIs
    context
  end

  @doc """
  Validates glTF extension usage and requirements.
  """
  @spec validate_extensions(Context.t()) :: Context.t()
  def validate_extensions(%Context{document: document} = context) do
    used = document.extensions_used || []
    required = document.extensions_required || []

    # All required extensions must be in used extensions
    missing = required -- used

    Enum.reduce(missing, context, fn ext, ctx ->
      Context.add_error(ctx, :extensions,
        "Required extension '#{ext}' not declared in extensionsUsed")
    end)
  end

  @doc """
  Validates accessor and buffer view relationships.
  """
  @spec validate_data_access(Context.t()) :: Context.t()
  def validate_data_access(%Context{document: document} = context) do
    accessors = document.accessors || []
    buffer_views = document.buffer_views || []
    buffers = document.buffers || []

    # Validate accessor -> buffer view -> buffer chain
    Enum.with_index(accessors)
    |> Enum.reduce(context, fn {accessor, index}, ctx ->
      validate_accessor_chain(ctx, accessor, index, buffer_views, buffers)
    end)
  end

  defp validate_accessor_chain(context, accessor, accessor_index, buffer_views, buffers) do
    case accessor do
      %{buffer_view: bv_index} when is_integer(bv_index) ->
        if bv_index >= 0 and bv_index < length(buffer_views) do
          buffer_view = Enum.at(buffer_views, bv_index)
          validate_buffer_view_chain(context, buffer_view, bv_index, buffers, accessor_index)
        else
          Context.add_error(context, {:accessor, accessor_index},
            "Invalid bufferView index: #{bv_index}")
        end
      _ -> context  # No buffer view reference is valid for some accessors
    end
  end

  defp validate_buffer_view_chain(context, buffer_view, bv_index, buffers, accessor_index) do
    case buffer_view do
      %{buffer: buffer_index} when is_integer(buffer_index) ->
        if buffer_index >= 0 and buffer_index < length(buffers) do
          context
        else
          Context.add_error(context, {:buffer_view, bv_index},
            "Invalid buffer index: #{buffer_index} (referenced by accessor #{accessor_index})")
        end
      _ ->
        Context.add_error(context, {:buffer_view, bv_index},
          "Buffer index is required for bufferView")
    end
  end
end
