# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf do
  @moduledoc """
  External API for AriaGltf - glTF 2.0 file format support.

  This module provides the public interface for AriaGltf functionality, including:
  - glTF document parsing and generation
  - Asset, scene, and node management
  - Mesh, material, and texture handling
  - Animation and skinning support
  - Buffer and accessor management
  - I/O operations for glTF files

  All cross-app communication should use this external API rather than importing
  internal AriaGltf modules directly.

  ## Document Management

      # Parse glTF from JSON
      {:ok, document} = AriaGltf.parse_document(json_data)

      # Create new document
      asset = AriaGltf.create_asset("2.0", "AriaEngine")
      document = AriaGltf.new_document(asset)

      # Convert to JSON
      json = AriaGltf.document_to_json(document)

  ## Asset Management

      # Create asset metadata
      asset = AriaGltf.create_asset("2.0", "MyGenerator", %{copyright: "2025 Me"})

  ## Scene and Node Management

      # Create scenes and nodes
      scene = AriaGltf.create_scene("Main Scene", [0, 1])
      node = AriaGltf.create_node("RootNode", %{mesh: 0})

  ## Mesh and Material Management

      # Create meshes and materials
      mesh = AriaGltf.create_mesh("MyMesh", primitives)
      material = AriaGltf.create_material("MyMaterial", %{albedo: [1.0, 0.0, 0.0, 1.0]})

  ## I/O Operations

      # Load from file
      {:ok, document} = AriaGltf.load_file("model.gltf")

      # Save to file
      :ok = AriaGltf.save_file(document, "output.gltf")
  """

  # Document Management API
  defdelegate new_document(asset), to: AriaGltf.Document, as: :new
  defdelegate parse_document(json), to: AriaGltf.Document, as: :from_json
  defdelegate document_to_json(document), to: AriaGltf.Document, as: :to_json

  # Asset Management API
  defdelegate create_asset(version, generator, options \\ %{}), to: AriaGltf.Asset, as: :new
  defdelegate parse_asset(json), to: AriaGltf.Asset, as: :from_json
  defdelegate asset_to_json(asset), to: AriaGltf.Asset, as: :to_json

  # Scene Management API
  defdelegate create_scene(name, node_indices, options \\ %{}), to: AriaGltf.Scene, as: :new
  defdelegate parse_scene(json), to: AriaGltf.Scene, as: :from_json
  defdelegate scene_to_json(scene), to: AriaGltf.Scene, as: :to_json

  # Node Management API
  defdelegate create_node(name, options \\ %{}), to: AriaGltf.Node, as: :new
  defdelegate parse_node(json), to: AriaGltf.Node, as: :from_json
  defdelegate node_to_json(node), to: AriaGltf.Node, as: :to_json

  # Mesh Management API
  defdelegate create_mesh(primitives, options \\ []), to: AriaGltf.Mesh, as: :new
  defdelegate parse_mesh(json), to: AriaGltf.Mesh, as: :from_json
  defdelegate mesh_to_json(mesh), to: AriaGltf.Mesh, as: :to_json

  # Material Management API
  defdelegate create_material(name, properties, options \\ %{}), to: AriaGltf.Material, as: :new
  defdelegate parse_material(json), to: AriaGltf.Material, as: :from_json
  defdelegate material_to_json(material), to: AriaGltf.Material, as: :to_json

  # Texture Management API
  defdelegate create_texture(source, sampler, options \\ %{}), to: AriaGltf.Texture, as: :new
  defdelegate parse_texture(json), to: AriaGltf.Texture, as: :from_json
  defdelegate texture_to_json(texture), to: AriaGltf.Texture, as: :to_json

  # Image Management API
  defdelegate create_image(uri_or_buffer, options \\ %{}), to: AriaGltf.Image, as: :new
  defdelegate parse_image(json), to: AriaGltf.Image, as: :from_json
  defdelegate image_to_json(image), to: AriaGltf.Image, as: :to_json

  # Sampler Management API
  defdelegate create_sampler(options \\ %{}), to: AriaGltf.Sampler, as: :new
  defdelegate parse_sampler(json), to: AriaGltf.Sampler, as: :from_json
  defdelegate sampler_to_json(sampler), to: AriaGltf.Sampler, as: :to_json

  # Accessor Management API
  defdelegate create_accessor(buffer_view, type, component_type, count, options \\ %{}), to: AriaGltf.Accessor, as: :new
  defdelegate parse_accessor(json), to: AriaGltf.Accessor, as: :from_json
  defdelegate accessor_to_json(accessor), to: AriaGltf.Accessor, as: :to_json

  # BufferView Management API
  defdelegate create_buffer_view(buffer, byte_length, options \\ %{}), to: AriaGltf.BufferView, as: :new
  defdelegate parse_buffer_view(json), to: AriaGltf.BufferView, as: :from_json
  defdelegate buffer_view_to_json(buffer_view), to: AriaGltf.BufferView, as: :to_json

  # Buffer Management API
  defdelegate create_buffer(byte_length, uri, options \\ %{}), to: AriaGltf.Buffer, as: :new
  defdelegate parse_buffer(json), to: AriaGltf.Buffer, as: :from_json
  defdelegate buffer_to_json(buffer), to: AriaGltf.Buffer, as: :to_json

  # Camera Management API
  defdelegate create_camera(type, properties, options \\ %{}), to: AriaGltf.Camera, as: :new
  defdelegate parse_camera(json), to: AriaGltf.Camera, as: :from_json
  defdelegate camera_to_json(camera), to: AriaGltf.Camera, as: :to_json

  # Skin Management API
  defdelegate create_skin(joints, options \\ %{}), to: AriaGltf.Skin, as: :new
  defdelegate parse_skin(json), to: AriaGltf.Skin, as: :from_json
  defdelegate skin_to_json(skin), to: AriaGltf.Skin, as: :to_json

  # Animation Management API
  defdelegate create_animation(channels, samplers, options \\ %{}), to: AriaGltf.Animation, as: :new
  defdelegate parse_animation(json), to: AriaGltf.Animation, as: :from_json
  defdelegate animation_to_json(animation), to: AriaGltf.Animation, as: :to_json

  # I/O Operations API
  defdelegate load_file(file_path), to: AriaGltf.IO
  defdelegate save_file(document, file_path), to: AriaGltf.IO
  defdelegate load_binary(file_path), to: AriaGltf.IO
  defdelegate save_binary(document, file_path), to: AriaGltf.IO

  @doc """
  Creates a complete glTF document with minimal required elements.

  This convenience function creates a basic glTF document with asset information
  and an empty scene.

  ## Parameters

  - `generator`: Generator name for asset metadata
  - `options`: Configuration options
    - `:version`: glTF version (default: "2.0")
    - `:copyright`: Copyright information
    - `:scene_name`: Name for default scene (default: "Scene")

  ## Examples

      iex> document = AriaGltf.create_minimal_document("AriaEngine")
      iex> document.asset.generator
      "AriaEngine"
  """
  def create_minimal_document(generator, options \\ []) do
    version = Keyword.get(options, :version, "2.0")
    copyright = Keyword.get(options, :copyright)
    scene_name = Keyword.get(options, :scene_name, "Scene")

    asset_options = if copyright, do: %{copyright: copyright}, else: %{}
    asset = create_asset(version, generator, asset_options)

    scene = create_scene(scene_name, [])

    %AriaGltf.Document{
      asset: asset,
      scenes: [scene],
      scene: 0
    }
  end

  @doc """
  Validates a glTF document for completeness and correctness.

  This function checks that the document follows glTF 2.0 specification
  requirements and has consistent internal references.

  ## Parameters

  - `document`: glTF document to validate
  - `options`: Validation options
    - `:strict`: Enable strict validation (default: false)
    - `:check_references`: Validate internal references (default: true)

  ## Examples

      iex> result = AriaGltf.validate_document(document)
      iex> {:ok, :valid} = result

      iex> result = AriaGltf.validate_document(invalid_document)
      iex> {:error, {:validation_failed, errors}} = result
  """
  def validate_document(document, options \\ []) do
    strict = Keyword.get(options, :strict, false)
    check_references = Keyword.get(options, :check_references, true)

    errors = []

    # Basic asset validation
    errors = if document.asset do
      errors
    else
      [{:missing_asset, "Document must have asset information"} | errors]
    end

    # Reference validation
    errors = if check_references do
      validate_internal_references(document, errors)
    else
      errors
    end

    # Strict validation checks
    errors = if strict do
      validate_strict_requirements(document, errors)
    else
      errors
    end

    case errors do
      [] -> {:ok, :valid}
      _ -> {:error, {:validation_failed, Enum.reverse(errors)}}
    end
  end

  @doc """
  Extracts all textures and images from a glTF document.

  This convenience function collects all texture and image resources
  from the document for processing or optimization.

  ## Examples

      iex> resources = AriaGltf.extract_textures(document)
      iex> %{textures: textures, images: images} = resources
  """
  def extract_textures(document) do
    textures = document.textures || []
    images = document.images || []

    %{
      textures: textures,
      images: images,
      texture_count: length(textures),
      image_count: length(images)
    }
  end

  @doc """
  Hello world.

  ## Examples

      iex> AriaGltf.hello()
      :world

  """
  def hello do
    :world
  end

  # Private helper functions

  defp validate_internal_references(document, errors) do
    # Scene references
    errors = case document.scene do
      nil -> errors
      scene_index ->
        scene_count = length(document.scenes || [])
        if scene_index >= 0 and scene_index < scene_count do
          errors
        else
          [{:invalid_scene_reference, "Scene index #{scene_index} out of range"} | errors]
        end
    end

    # Node reference validation would go here
    errors
  end

  defp validate_strict_requirements(document, errors) do
    # Strict validation rules would be implemented here
    # For now, just basic checks
    errors = if document.scenes && length(document.scenes) == 0 do
      [{:empty_scenes, "Document should have at least one scene"} | errors]
    else
      errors
    end

    errors
  end
end
