# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf.Validation do
  @moduledoc """
  Comprehensive validation framework for glTF 2.0 specification compliance.

  This module provides validation functions for glTF documents, ensuring they
  conform to the glTF 2.0 specification and reporting detailed errors and warnings.
  """

  alias AriaGltf.{Document, Asset, Scene, Node, Mesh, Material, Texture, Image, Sampler, Accessor, BufferView, Buffer, Camera, Skin, Animation}
  alias AriaGltf.Validation.{Report, Context, SchemaValidator}

  @type validation_result :: {:ok, Document.t()} | {:error, Report.t()}
  @type validation_mode :: :strict | :permissive | :warning_only

  @doc """
  Validates a glTF document comprehensively.

  ## Options

  - `:mode` - Validation mode `:strict` (default), `:permissive`, or `:warning_only`
  - `:check_indices` - Whether to validate index references (default: true)
  - `:check_extensions` - Whether to validate extensions (default: true)
  - `:check_schema` - Whether to validate against JSON schema (default: true)

  ## Examples

      iex> AriaGltf.Validation.validate(document)
      {:ok, document}

      iex> AriaGltf.Validation.validate(invalid_document)
      {:error, %AriaGltf.Validation.Report{errors: [...]}}
  """
  @spec validate(Document.t(), keyword()) :: validation_result()
  def validate(%Document{} = document, opts \\ []) do
    mode = Keyword.get(opts, :mode, :strict)
    check_indices = Keyword.get(opts, :check_indices, true)
    check_extensions = Keyword.get(opts, :check_extensions, true)
    check_schema = Keyword.get(opts, :check_schema, true)

    context = Context.new(document, mode)

    context
    |> validate_asset()
    |> validate_scene_references()
    |> then(fn ctx -> if check_indices, do: validate_index_references(ctx), else: ctx end)
    |> then(fn ctx -> if check_extensions, do: validate_extensions(ctx), else: ctx end)
    |> then(fn ctx -> if check_schema, do: validate_schema(ctx), else: ctx end)
    |> validate_arrays()
    |> validate_required_fields()
    |> validate_data_types()
    |> finalize_validation()
  end

  @doc """
  Validates just the basic structure without deep validation.
  Useful for quick checks during parsing.
  """
  @spec validate_basic(Document.t()) :: validation_result()
  def validate_basic(%Document{} = document) do
    context = Context.new(document, :warning_only)

    context
    |> validate_asset()
    |> validate_required_fields()
    |> finalize_validation()
  end

  # Asset validation
  defp validate_asset(%Context{document: %{asset: asset}} = context) do
    case validate_asset_version(asset) do
      :ok -> context
      {:error, error} -> Context.add_error(context, :asset, error)
    end
  end

  defp validate_asset_version(%Asset{version: version}) when is_binary(version) do
    case version do
      "2.0" -> :ok
      _ -> {:error, "Invalid glTF version: #{version}. Only version 2.0 is supported"}
    end
  end
  defp validate_asset_version(_), do: {:error, "Asset version is required and must be a string"}

  # Scene reference validation
  defp validate_scene_references(%Context{document: document} = context) do
    case document.scene do
      nil -> context
      scene_index when is_integer(scene_index) ->
        if scene_index >= 0 and scene_index < length(document.scenes || []) do
          context
        else
          Context.add_error(context, :scene, "Scene index #{scene_index} is out of bounds")
        end
      _ -> Context.add_error(context, :scene, "Scene index must be a non-negative integer")
    end
  end

  # Index reference validation
  defp validate_index_references(%Context{document: document} = context) do
    context
    |> validate_node_indices(document.nodes || [])
    |> validate_mesh_indices(document.meshes || [])
    |> validate_material_indices(document.materials || [])
    |> validate_texture_indices(document.textures || [])
    |> validate_accessor_indices(document.accessors || [])
    |> validate_buffer_view_indices(document.buffer_views || [])
    |> validate_buffer_indices(document.buffers || [])
  end

  defp validate_node_indices(context, nodes) do
    Enum.with_index(nodes)
    |> Enum.reduce(context, fn {node, index}, ctx ->
      ctx
      |> validate_node_children(node, index, length(nodes))
      |> validate_node_mesh_reference(node, index, context.document.meshes)
      |> validate_node_camera_reference(node, index, context.document.cameras)
      |> validate_node_skin_reference(node, index, context.document.skins)
    end)
  end

  defp validate_node_children(context, %{children: children}, node_index, total_nodes) when is_list(children) do
    Enum.reduce(children, context, fn child_index, ctx ->
      if is_integer(child_index) and child_index >= 0 and child_index < total_nodes do
        ctx
      else
        Context.add_error(ctx, {:node, node_index}, "Invalid child node index: #{child_index}")
      end
    end)
  end
  defp validate_node_children(context, _, _, _), do: context

  defp validate_node_mesh_reference(context, %{mesh: mesh_index}, node_index, meshes) when is_integer(mesh_index) do
    if mesh_index >= 0 and mesh_index < length(meshes || []) do
      context
    else
      Context.add_error(context, {:node, node_index}, "Invalid mesh index: #{mesh_index}")
    end
  end
  defp validate_node_mesh_reference(context, _, _, _), do: context

  defp validate_node_camera_reference(context, %{camera: camera_index}, node_index, cameras) when is_integer(camera_index) do
    if camera_index >= 0 and camera_index < length(cameras || []) do
      context
    else
      Context.add_error(context, {:node, node_index}, "Invalid camera index: #{camera_index}")
    end
  end
  defp validate_node_camera_reference(context, _, _, _), do: context

  defp validate_node_skin_reference(context, %{skin: skin_index}, node_index, skins) when is_integer(skin_index) do
    if skin_index >= 0 and skin_index < length(skins || []) do
      context
    else
      Context.add_error(context, {:node, node_index}, "Invalid skin index: #{skin_index}")
    end
  end
  defp validate_node_skin_reference(context, _, _, _), do: context

  defp validate_mesh_indices(context, _meshes), do: context  # TODO: Implement mesh validation
  defp validate_material_indices(context, _materials), do: context  # TODO: Implement material validation
  defp validate_texture_indices(context, _textures), do: context  # TODO: Implement texture validation
  defp validate_accessor_indices(context, _accessors), do: context  # TODO: Implement accessor validation
  defp validate_buffer_view_indices(context, _buffer_views), do: context  # TODO: Implement buffer view validation
  defp validate_buffer_indices(context, _buffers), do: context  # TODO: Implement buffer validation

  # Extension validation
  defp validate_extensions(%Context{document: document} = context) do
    used_extensions = document.extensions_used || []
    required_extensions = document.extensions_required || []

    # Check that all required extensions are in used extensions
    missing_required = required_extensions -- used_extensions

    context =
      Enum.reduce(missing_required, context, fn ext, ctx ->
        Context.add_error(ctx, :extensions, "Required extension '#{ext}' not listed in extensionsUsed")
      end)

    # Validate known extensions
    validate_known_extensions(context, used_extensions)
  end

  defp validate_known_extensions(context, extensions) do
    # List of known glTF extensions
    known_extensions = [
      "KHR_draco_mesh_compression",
      "KHR_lights_punctual",
      "KHR_materials_clearcoat",
      "KHR_materials_ior",
      "KHR_materials_transmission",
      "KHR_materials_unlit",
      "KHR_mesh_quantization",
      "KHR_texture_transform",
      "EXT_mesh_gpu_instancing",
      "EXT_texture_webp"
    ]

    Enum.reduce(extensions, context, fn ext, ctx ->
      if ext in known_extensions or String.starts_with?(ext, ["KHR_", "EXT_"]) do
        ctx
      else
        Context.add_warning(ctx, :extensions, "Unknown extension: #{ext}")
      end
    end)
  end

  # Schema validation
  defp validate_schema(%Context{} = context) do
    # TODO: Implement JSON schema validation
    # This would validate against the official glTF 2.0 JSON schema
    context
  end

  # Array validation
  defp validate_arrays(%Context{document: document} = context) do
    context
    |> validate_array_bounds(:scenes, document.scenes)
    |> validate_array_bounds(:nodes, document.nodes)
    |> validate_array_bounds(:meshes, document.meshes)
    |> validate_array_bounds(:materials, document.materials)
    |> validate_array_bounds(:textures, document.textures)
    |> validate_array_bounds(:images, document.images)
    |> validate_array_bounds(:samplers, document.samplers)
    |> validate_array_bounds(:accessors, document.accessors)
    |> validate_array_bounds(:buffer_views, document.buffer_views)
    |> validate_array_bounds(:buffers, document.buffers)
    |> validate_array_bounds(:cameras, document.cameras)
    |> validate_array_bounds(:skins, document.skins)
    |> validate_array_bounds(:animations, document.animations)
  end

  defp validate_array_bounds(context, _field, nil), do: context
  defp validate_array_bounds(context, _field, []), do: context
  defp validate_array_bounds(context, field, array) when is_list(array) do
    if length(array) > 0 do
      context
    else
      Context.add_warning(context, field, "Empty array - consider omitting field")
    end
  end
  defp validate_array_bounds(context, field, _), do: Context.add_error(context, field, "Must be an array")

  # Required fields validation
  defp validate_required_fields(%Context{document: document} = context) do
    if is_nil(document.asset) do
      Context.add_error(context, :asset, "Asset field is required")
    else
      context
    end
  end

  # Data type validation
  defp validate_data_types(%Context{} = context) do
    # TODO: Implement comprehensive data type validation
    context
  end

  # Finalize validation and return result
  defp finalize_validation(%Context{mode: mode} = context) do
    case {mode, Context.has_errors?(context)} do
      {:strict, true} -> {:error, Context.to_report(context)}
      {:permissive, _} -> handle_permissive_result(context)
      {:warning_only, _} -> {:ok, context.document}
    end
  end

  defp handle_permissive_result(%Context{} = context) do
    if Context.has_critical_errors?(context) do
      {:error, Context.to_report(context)}
    else
      {:ok, context.document}
    end
  end
end
