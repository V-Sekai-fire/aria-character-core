# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf.Import.Parser do
  @moduledoc """
  JSON parsing and document conversion for glTF content.

  This module handles the conversion from raw JSON data to structured Document types.
  """

  alias AriaGltf.{Document, Asset, Scene, Node, Mesh, Material, Texture, TextureInfo, Image, Sampler, Accessor, BufferView, Buffer, Camera, Skin, Animation}

  @type parse_result :: {:ok, term()} | {:error, term()}
  @type document_result :: {:ok, Document.t()} | {:error, term()}

  @doc """
  Parses JSON content into Elixir data structures.

  ## Examples

      iex> AriaGltf.Import.Parser.parse_json(~s({"asset": {"version": "2.0"}}))
      {:ok, %{"asset" => %{"version" => "2.0"}}}
  """
  @spec parse_json(String.t()) :: parse_result()
  def parse_json(json_content) when is_binary(json_content) do
    case Jason.decode(json_content) do
      {:ok, parsed} -> {:ok, parsed}
      {:error, error} -> {:error, "JSON parsing failed: #{inspect(error)}"}
    end
  end

  @doc """
  Converts parsed JSON data to a Document struct.

  ## Examples

      iex> json_data = %{"asset" => %{"version" => "2.0"}}
      iex> AriaGltf.Import.Parser.json_to_document(json_data, [])
      {:ok, %AriaGltf.Document{...}}
  """
  @spec json_to_document(map(), keyword()) :: document_result()
  def json_to_document(json_data, _opts \\ []) when is_map(json_data) do
    try do
      document = %Document{
        asset: parse_asset(json_data["asset"]),
        scene: json_data["scene"],
        scenes: parse_scenes(json_data["scenes"]),
        nodes: parse_nodes(json_data["nodes"]),
        meshes: parse_meshes(json_data["meshes"]),
        materials: parse_materials(json_data["materials"]),
        textures: parse_textures(json_data["textures"]),
        images: parse_images(json_data["images"]),
        samplers: parse_samplers(json_data["samplers"]),
        accessors: parse_accessors(json_data["accessors"]),
        buffer_views: parse_buffer_views(json_data["bufferViews"]),
        buffers: parse_buffers(json_data["buffers"]),
        cameras: parse_cameras(json_data["cameras"]),
        skins: parse_skins(json_data["skins"]),
        animations: parse_animations(json_data["animations"]),
        extensions_used: json_data["extensionsUsed"],
        extensions_required: json_data["extensionsRequired"],
        extensions: json_data["extensions"],
        extras: json_data["extras"]
      }

      {:ok, document}
    rescue
      error -> {:error, "Document conversion failed: #{inspect(error)}"}
    end
  end

  # Asset parsing
  defp parse_asset(nil), do: nil
  defp parse_asset(asset_data) when is_map(asset_data) do
    %Asset{
      copyright: asset_data["copyright"],
      generator: asset_data["generator"],
      version: asset_data["version"],
      min_version: asset_data["minVersion"],
      extensions: asset_data["extensions"],
      extras: asset_data["extras"]
    }
  end

  # Scenes parsing
  defp parse_scenes(nil), do: []
  defp parse_scenes(scenes_data) when is_list(scenes_data) do
    Enum.map(scenes_data, &parse_scene/1)
  end

  defp parse_scene(scene_data) when is_map(scene_data) do
    %Scene{
      name: scene_data["name"],
      nodes: scene_data["nodes"] || [],
      extensions: scene_data["extensions"],
      extras: scene_data["extras"]
    }
  end

  # Nodes parsing
  defp parse_nodes(nil), do: []
  defp parse_nodes(nodes_data) when is_list(nodes_data) do
    Enum.map(nodes_data, &parse_node/1)
  end

  defp parse_node(node_data) when is_map(node_data) do
    %Node{
      name: node_data["name"],
      camera: node_data["camera"],
      children: node_data["children"] || [],
      skin: node_data["skin"],
      matrix: parse_matrix(node_data["matrix"]),
      mesh: node_data["mesh"],
      rotation: parse_quaternion(node_data["rotation"]),
      scale: parse_vec3(node_data["scale"]),
      translation: parse_vec3(node_data["translation"]),
      weights: node_data["weights"],
      extensions: node_data["extensions"],
      extras: node_data["extras"]
    }
  end

  # Meshes parsing
  defp parse_meshes(nil), do: []
  defp parse_meshes(meshes_data) when is_list(meshes_data) do
    Enum.map(meshes_data, &parse_mesh/1)
  end

  defp parse_mesh(mesh_data) when is_map(mesh_data) do
    %Mesh{
      name: mesh_data["name"],
      primitives: parse_primitives(mesh_data["primitives"]),
      weights: mesh_data["weights"],
      extensions: mesh_data["extensions"],
      extras: mesh_data["extras"]
    }
  end

  defp parse_primitives(nil), do: []
  defp parse_primitives(primitives_data) when is_list(primitives_data) do
    Enum.map(primitives_data, &parse_primitive/1)
  end

  defp parse_primitive(primitive_data) when is_map(primitive_data) do
    %Mesh.Primitive{
      attributes: primitive_data["attributes"] || %{},
      indices: primitive_data["indices"],
      material: primitive_data["material"],
      mode: primitive_data["mode"] || 4,  # TRIANGLES
      targets: parse_morph_targets(primitive_data["targets"]),
      extensions: primitive_data["extensions"],
      extras: primitive_data["extras"]
    }
  end

  defp parse_morph_targets(nil), do: []
  defp parse_morph_targets(targets_data) when is_list(targets_data) do
    targets_data
  end

  # Materials parsing
  defp parse_materials(nil), do: []
  defp parse_materials(materials_data) when is_list(materials_data) do
    Enum.map(materials_data, &parse_material/1)
  end

  defp parse_material(material_data) when is_map(material_data) do
    %Material{
      name: material_data["name"],
      pbr_metallic_roughness: parse_pbr_metallic_roughness(material_data["pbrMetallicRoughness"]),
      normal_texture: parse_normal_texture_info(material_data["normalTexture"]),
      occlusion_texture: parse_occlusion_texture_info(material_data["occlusionTexture"]),
      emissive_texture: parse_texture_info(material_data["emissiveTexture"]),
      emissive_factor: parse_vec3(material_data["emissiveFactor"]) || [0.0, 0.0, 0.0],
      alpha_mode: material_data["alphaMode"] || "OPAQUE",
      alpha_cutoff: material_data["alphaCutoff"] || 0.5,
      double_sided: material_data["doubleSided"] || false,
      extensions: material_data["extensions"],
      extras: material_data["extras"]
    }
  end

  defp parse_pbr_metallic_roughness(nil), do: nil
  defp parse_pbr_metallic_roughness(pbr_data) when is_map(pbr_data) do
    %Material.PbrMetallicRoughness{
      base_color_factor: parse_vec4(pbr_data["baseColorFactor"]) || [1.0, 1.0, 1.0, 1.0],
      base_color_texture: parse_texture_info(pbr_data["baseColorTexture"]),
      metallic_factor: pbr_data["metallicFactor"] || 1.0,
      roughness_factor: pbr_data["roughnessFactor"] || 1.0,
      metallic_roughness_texture: parse_texture_info(pbr_data["metallicRoughnessTexture"]),
      extensions: pbr_data["extensions"],
      extras: pbr_data["extras"]
    }
  end

  defp parse_texture_info(nil), do: nil
  defp parse_texture_info(texture_info) when is_map(texture_info) do
    %TextureInfo{
      index: texture_info["index"],
      tex_coord: texture_info["texCoord"] || 0,
      extensions: texture_info["extensions"],
      extras: texture_info["extras"]
    }
  end

  defp parse_normal_texture_info(nil), do: nil
  defp parse_normal_texture_info(texture_info) when is_map(texture_info) do
    %Material.NormalTextureInfo{
      index: texture_info["index"],
      tex_coord: texture_info["texCoord"] || 0,
      scale: texture_info["scale"] || 1.0,
      extensions: texture_info["extensions"],
      extras: texture_info["extras"]
    }
  end

  defp parse_occlusion_texture_info(nil), do: nil
  defp parse_occlusion_texture_info(texture_info) when is_map(texture_info) do
    %Material.OcclusionTextureInfo{
      index: texture_info["index"],
      tex_coord: texture_info["texCoord"] || 0,
      strength: texture_info["strength"] || 1.0,
      extensions: texture_info["extensions"],
      extras: texture_info["extras"]
    }
  end

  # Textures parsing
  defp parse_textures(nil), do: []
  defp parse_textures(textures_data) when is_list(textures_data) do
    Enum.map(textures_data, &parse_texture/1)
  end

  defp parse_texture(texture_data) when is_map(texture_data) do
    %Texture{
      name: texture_data["name"],
      sampler: texture_data["sampler"],
      source: texture_data["source"],
      extensions: texture_data["extensions"],
      extras: texture_data["extras"]
    }
  end

  # Images parsing
  defp parse_images(nil), do: []
  defp parse_images(images_data) when is_list(images_data) do
    Enum.map(images_data, &parse_image/1)
  end

  defp parse_image(image_data) when is_map(image_data) do
    %Image{
      name: image_data["name"],
      uri: image_data["uri"],
      mime_type: image_data["mimeType"],
      buffer_view: image_data["bufferView"],
      extensions: image_data["extensions"],
      extras: image_data["extras"]
    }
  end

  # Samplers parsing
  defp parse_samplers(nil), do: []
  defp parse_samplers(samplers_data) when is_list(samplers_data) do
    Enum.map(samplers_data, &parse_sampler/1)
  end

  defp parse_sampler(sampler_data) when is_map(sampler_data) do
    %Sampler{
      name: sampler_data["name"],
      mag_filter: sampler_data["magFilter"],
      min_filter: sampler_data["minFilter"],
      wrap_s: sampler_data["wrapS"] || 10497,  # REPEAT
      wrap_t: sampler_data["wrapT"] || 10497,  # REPEAT
      extensions: sampler_data["extensions"],
      extras: sampler_data["extras"]
    }
  end

  # Accessors parsing
  defp parse_accessors(nil), do: []
  defp parse_accessors(accessors_data) when is_list(accessors_data) do
    Enum.map(accessors_data, &parse_accessor/1)
  end

  defp parse_accessor(accessor_data) when is_map(accessor_data) do
    %Accessor{
      name: accessor_data["name"],
      buffer_view: accessor_data["bufferView"],
      byte_offset: accessor_data["byteOffset"] || 0,
      component_type: accessor_data["componentType"],
      normalized: accessor_data["normalized"] || false,
      count: accessor_data["count"],
      type: accessor_data["type"],
      max: accessor_data["max"],
      min: accessor_data["min"],
      sparse: parse_sparse(accessor_data["sparse"]),
      extensions: accessor_data["extensions"],
      extras: accessor_data["extras"]
    }
  end

  defp parse_sparse(nil), do: nil
  defp parse_sparse(sparse_data) when is_map(sparse_data) do
    %Accessor.Sparse{
      count: sparse_data["count"],
      indices: parse_sparse_indices(sparse_data["indices"]),
      values: parse_sparse_values(sparse_data["values"]),
      extensions: sparse_data["extensions"],
      extras: sparse_data["extras"]
    }
  end

  defp parse_sparse_indices(nil), do: nil
  defp parse_sparse_indices(indices_data) when is_map(indices_data) do
    %Accessor.Sparse.Indices{
      buffer_view: indices_data["bufferView"],
      byte_offset: indices_data["byteOffset"] || 0,
      component_type: indices_data["componentType"],
      extensions: indices_data["extensions"],
      extras: indices_data["extras"]
    }
  end

  defp parse_sparse_values(nil), do: nil
  defp parse_sparse_values(values_data) when is_map(values_data) do
    %Accessor.Sparse.Values{
      buffer_view: values_data["bufferView"],
      byte_offset: values_data["byteOffset"] || 0,
      extensions: values_data["extensions"],
      extras: values_data["extras"]
    }
  end

  # BufferViews parsing
  defp parse_buffer_views(nil), do: []
  defp parse_buffer_views(buffer_views_data) when is_list(buffer_views_data) do
    Enum.map(buffer_views_data, &parse_buffer_view/1)
  end

  defp parse_buffer_view(buffer_view_data) when is_map(buffer_view_data) do
    %BufferView{
      name: buffer_view_data["name"],
      buffer: buffer_view_data["buffer"],
      byte_offset: buffer_view_data["byteOffset"] || 0,
      byte_length: buffer_view_data["byteLength"],
      byte_stride: buffer_view_data["byteStride"],
      target: buffer_view_data["target"],
      extensions: buffer_view_data["extensions"],
      extras: buffer_view_data["extras"]
    }
  end

  # Buffers parsing
  defp parse_buffers(nil), do: []
  defp parse_buffers(buffers_data) when is_list(buffers_data) do
    Enum.map(buffers_data, &parse_buffer/1)
  end

  defp parse_buffer(buffer_data) when is_map(buffer_data) do
    %Buffer{
      name: buffer_data["name"],
      uri: buffer_data["uri"],
      byte_length: buffer_data["byteLength"],
      extensions: buffer_data["extensions"],
      extras: buffer_data["extras"]
    }
  end

  # Cameras parsing
  defp parse_cameras(nil), do: []
  defp parse_cameras(cameras_data) when is_list(cameras_data) do
    Enum.map(cameras_data, &parse_camera/1)
  end

  defp parse_camera(camera_data) when is_map(camera_data) do
    %Camera{
      name: camera_data["name"],
      type: camera_data["type"],
      orthographic: parse_orthographic(camera_data["orthographic"]),
      perspective: parse_perspective(camera_data["perspective"]),
      extensions: camera_data["extensions"],
      extras: camera_data["extras"]
    }
  end

  defp parse_orthographic(nil), do: nil
  defp parse_orthographic(ortho_data) when is_map(ortho_data) do
    %Camera.Orthographic{
      xmag: ortho_data["xmag"],
      ymag: ortho_data["ymag"],
      zfar: ortho_data["zfar"],
      znear: ortho_data["znear"],
      extensions: ortho_data["extensions"],
      extras: ortho_data["extras"]
    }
  end

  defp parse_perspective(nil), do: nil
  defp parse_perspective(persp_data) when is_map(persp_data) do
    %Camera.Perspective{
      aspect_ratio: persp_data["aspectRatio"],
      yfov: persp_data["yfov"],
      zfar: persp_data["zfar"],
      znear: persp_data["znear"],
      extensions: persp_data["extensions"],
      extras: persp_data["extras"]
    }
  end

  # Skins parsing
  defp parse_skins(nil), do: []
  defp parse_skins(skins_data) when is_list(skins_data) do
    Enum.map(skins_data, &parse_skin/1)
  end

  defp parse_skin(skin_data) when is_map(skin_data) do
    %Skin{
      name: skin_data["name"],
      inverse_bind_matrices: skin_data["inverseBindMatrices"],
      skeleton: skin_data["skeleton"],
      joints: skin_data["joints"] || [],
      extensions: skin_data["extensions"],
      extras: skin_data["extras"]
    }
  end

  # Animations parsing
  defp parse_animations(nil), do: []
  defp parse_animations(animations_data) when is_list(animations_data) do
    Enum.map(animations_data, &parse_animation/1)
  end

  defp parse_animation(animation_data) when is_map(animation_data) do
    %Animation{
      name: animation_data["name"],
      channels: parse_animation_channels(animation_data["channels"]),
      samplers: parse_animation_samplers(animation_data["samplers"]),
      extensions: animation_data["extensions"],
      extras: animation_data["extras"]
    }
  end

  defp parse_animation_channels(nil), do: []
  defp parse_animation_channels(channels_data) when is_list(channels_data) do
    Enum.map(channels_data, &parse_animation_channel/1)
  end

  defp parse_animation_channel(channel_data) when is_map(channel_data) do
    %Animation.Channel{
      sampler: channel_data["sampler"],
      target: parse_animation_target(channel_data["target"]),
      extensions: channel_data["extensions"],
      extras: channel_data["extras"]
    }
  end

  defp parse_animation_target(nil), do: nil
  defp parse_animation_target(target_data) when is_map(target_data) do
    %Animation.Channel.Target{
      node: target_data["node"],
      path: target_data["path"],
      extensions: target_data["extensions"],
      extras: target_data["extras"]
    }
  end

  defp parse_animation_samplers(nil), do: []
  defp parse_animation_samplers(samplers_data) when is_list(samplers_data) do
    Enum.map(samplers_data, &parse_animation_sampler/1)
  end

  defp parse_animation_sampler(sampler_data) when is_map(sampler_data) do
    %Animation.Sampler{
      input: sampler_data["input"],
      interpolation: sampler_data["interpolation"] || "LINEAR",
      output: sampler_data["output"],
      extensions: sampler_data["extensions"],
      extras: sampler_data["extras"]
    }
  end

  # Utility parsers for common data types
  defp parse_matrix(nil), do: nil
  defp parse_matrix(matrix) when is_list(matrix) and length(matrix) == 16 do
    matrix
  end

  defp parse_quaternion(nil), do: nil
  defp parse_quaternion(quat) when is_list(quat) and length(quat) == 4 do
    quat
  end

  defp parse_vec3(nil), do: nil
  defp parse_vec3(vec) when is_list(vec) and length(vec) == 3 do
    vec
  end

  defp parse_vec4(nil), do: nil
  defp parse_vec4(vec) when is_list(vec) and length(vec) == 4 do
    vec
  end
end
