# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf.Helpers do
  @moduledoc """
  Helper functions for common glTF patterns and utilities.

  This module provides convenient functions for creating common glTF structures,
  generating meshes, setting up materials, and configuring animations. These
  helpers simplify the process of creating glTF documents programmatically.
  """

  alias AriaGltf.{Document, Scene, Node, Mesh, Material, Animation, Asset, Buffer, BufferView, Accessor}

  @doc """
  Creates a minimal glTF document with basic structure.

  ## Options

  - `:generator` - Generator information (default: "AriaGltf")
  - `:version` - glTF version (default: "2.0")
  - `:copyright` - Copyright information

  ## Examples

      iex> doc = AriaGltf.Helpers.create_minimal_document()
      iex> doc.asset.version
      "2.0"
      iex> doc.asset.generator
      "AriaGltf"
      iex> doc.scene
      0

      iex> doc = AriaGltf.Helpers.create_minimal_document(generator: "MyApp", copyright: "2025 MyCompany")
      iex> doc.asset.generator
      "MyApp"
      iex> doc.asset.copyright
      "2025 MyCompany"
  """
  @spec create_minimal_document(keyword()) :: Document.t()
  def create_minimal_document(opts \\ []) do
    generator = Keyword.get(opts, :generator, "AriaGltf")
    version = Keyword.get(opts, :version, "2.0")
    copyright = Keyword.get(opts, :copyright)

    asset = %Asset{
      version: version,
      generator: generator,
      copyright: copyright
    }

    scene = %Scene{nodes: []}

    %Document{
      asset: asset,
      scenes: [scene],
      scene: 0,
      nodes: [],
      meshes: [],
      materials: [],
      textures: [],
      images: [],
      samplers: [],
      buffers: [],
      buffer_views: [],
      accessors: []
    }
  end

  @doc """
  Creates a simple scene with a single node.

  ## Options

  - `:name` - Scene name
  - `:node_name` - Node name
  - `:translation` - Node translation [x, y, z]
  - `:rotation` - Node rotation quaternion [x, y, z, w]
  - `:scale` - Node scale [x, y, z]

  ## Examples

      iex> AriaGltf.Helpers.create_simple_scene(name: "Main Scene", node_name: "Root")
      %AriaGltf.Scene{
        name: "Main Scene",
        nodes: [0]
      }
  """
  @spec create_simple_scene(keyword()) :: Scene.t()
  def create_simple_scene(opts \\ []) do
    name = Keyword.get(opts, :name)

    %Scene{
      name: name,
      nodes: [0]  # Reference to first node
    }
  end

  @doc """
  Creates a node with transform properties.

  ## Options

  - `:name` - Node name
  - `:translation` - Translation [x, y, z]
  - `:rotation` - Rotation quaternion [x, y, z, w]
  - `:scale` - Scale [x, y, z]
  - `:mesh` - Mesh index reference
  - `:children` - List of child node indices

  ## Examples

      iex> AriaGltf.Helpers.create_node(name: "Cube", translation: [0, 1, 0])
      %AriaGltf.Node{
        name: "Cube",
        translation: [0, 1, 0]
      }

      iex> AriaGltf.Helpers.create_node(
      ...>   name: "Transform",
      ...>   translation: [1, 2, 3],
      ...>   rotation: [0, 0, 0, 1],
      ...>   scale: [2, 2, 2],
      ...>   mesh: 0
      ...> )
      %AriaGltf.Node{
        name: "Transform",
        translation: [1, 2, 3],
        rotation: [0, 0, 0, 1],
        scale: [2, 2, 2],
        mesh: 0
      }
  """
  @spec create_node(keyword()) :: Node.t()
  def create_node(opts \\ []) do
    %Node{
      name: Keyword.get(opts, :name),
      translation: Keyword.get(opts, :translation),
      rotation: Keyword.get(opts, :rotation),
      scale: Keyword.get(opts, :scale),
      mesh: Keyword.get(opts, :mesh),
      children: Keyword.get(opts, :children)
    }
  end

  @doc """
  Creates a simple mesh with a single primitive.

  ## Options

  - `:name` - Mesh name
  - `:mode` - Primitive mode (default: 4 for TRIANGLES)
  - `:position_accessor` - Accessor index for positions
  - `:normal_accessor` - Accessor index for normals
  - `:texcoord_accessor` - Accessor index for texture coordinates
  - `:indices_accessor` - Accessor index for indices
  - `:material` - Material index

  ## Examples

      iex> AriaGltf.Helpers.create_simple_mesh(
      ...>   name: "Cube",
      ...>   position_accessor: 0,
      ...>   indices_accessor: 1
      ...> )
      %AriaGltf.Mesh{
        name: "Cube",
        primitives: [
          %AriaGltf.Mesh.Primitive{
            mode: 4,
            attributes: %{"POSITION" => 0},
            indices: 1
          }
        ]
      }
  """
  @spec create_simple_mesh(keyword()) :: Mesh.t()
  def create_simple_mesh(opts \\ []) do
    name = Keyword.get(opts, :name)
    mode = Keyword.get(opts, :mode, 4)  # TRIANGLES
    position_accessor = Keyword.get(opts, :position_accessor)
    normal_accessor = Keyword.get(opts, :normal_accessor)
    texcoord_accessor = Keyword.get(opts, :texcoord_accessor)
    indices_accessor = Keyword.get(opts, :indices_accessor)
    material = Keyword.get(opts, :material)

    # Build attributes map
    attributes = %{}
    attributes = if position_accessor, do: Map.put(attributes, "POSITION", position_accessor), else: attributes
    attributes = if normal_accessor, do: Map.put(attributes, "NORMAL", normal_accessor), else: attributes
    attributes = if texcoord_accessor, do: Map.put(attributes, "TEXCOORD_0", texcoord_accessor), else: attributes

    primitive = %Mesh.Primitive{
      mode: mode,
      attributes: attributes,
      indices: indices_accessor,
      material: material
    }

    %Mesh{
      name: name,
      primitives: [primitive]
    }
  end

  @doc """
  Creates a basic PBR material.

  ## Options

  - `:name` - Material name
  - `:base_color_factor` - Base color [r, g, b, a] (default: [1, 1, 1, 1])
  - `:metallic_factor` - Metallic factor (default: 1.0)
  - `:roughness_factor` - Roughness factor (default: 1.0)
  - `:base_color_texture` - Base color texture index
  - `:metallic_roughness_texture` - Metallic-roughness texture index
  - `:normal_texture` - Normal texture index
  - `:emissive_factor` - Emissive factor [r, g, b]
  - `:alpha_mode` - Alpha mode ("OPAQUE", "MASK", "BLEND")
  - `:alpha_cutoff` - Alpha cutoff value
  - `:double_sided` - Double-sided flag

  ## Examples

      iex> material = AriaGltf.Helpers.create_pbr_material(name: "Red Metal")
      iex> material.name
      "Red Metal"
      iex> material.pbr_metallic_roughness.metallic_factor
      1.0

      iex> material = AriaGltf.Helpers.create_pbr_material(
      ...>   name: "Blue Plastic",
      ...>   base_color_factor: [0, 0, 1, 1],
      ...>   metallic_factor: 0.0,
      ...>   roughness_factor: 0.8,
      ...>   double_sided: true
      ...> )
      iex> material.name
      "Blue Plastic"
      iex> material.double_sided
      true
      iex> material.pbr_metallic_roughness.base_color_factor
      [0, 0, 1, 1]
  """
  @spec create_pbr_material(keyword()) :: Material.t()
  def create_pbr_material(opts \\ []) do
    name = Keyword.get(opts, :name)
    base_color_factor = Keyword.get(opts, :base_color_factor, [1, 1, 1, 1])
    metallic_factor = Keyword.get(opts, :metallic_factor, 1.0)
    roughness_factor = Keyword.get(opts, :roughness_factor, 1.0)
    base_color_texture = Keyword.get(opts, :base_color_texture)
    metallic_roughness_texture = Keyword.get(opts, :metallic_roughness_texture)
    normal_texture = Keyword.get(opts, :normal_texture)
    emissive_factor = Keyword.get(opts, :emissive_factor)
    alpha_mode = Keyword.get(opts, :alpha_mode)
    alpha_cutoff = Keyword.get(opts, :alpha_cutoff)
    double_sided = Keyword.get(opts, :double_sided)

    pbr = %Material.PbrMetallicRoughness{
      base_color_factor: base_color_factor,
      metallic_factor: metallic_factor,
      roughness_factor: roughness_factor,
      base_color_texture: if(base_color_texture, do: %{index: base_color_texture}),
      metallic_roughness_texture: if(metallic_roughness_texture, do: %{index: metallic_roughness_texture})
    }

    %Material{
      name: name,
      pbr_metallic_roughness: pbr,
      normal_texture: if(normal_texture, do: %{index: normal_texture}),
      emissive_factor: emissive_factor,
      alpha_mode: alpha_mode,
      alpha_cutoff: alpha_cutoff,
      double_sided: double_sided
    }
  end

  @doc """
  Creates a simple animation with linear interpolation.

  ## Options

  - `:name` - Animation name
  - `:target_node` - Target node index
  - `:path` - Animation path ("translation", "rotation", "scale", "weights")
  - `:input_accessor` - Input (time) accessor index
  - `:output_accessor` - Output (values) accessor index
  - `:interpolation` - Interpolation method (default: "LINEAR")

  ## Examples

      iex> AriaGltf.Helpers.create_simple_animation(
      ...>   name: "Rotate Y",
      ...>   target_node: 0,
      ...>   path: "rotation",
      ...>   input_accessor: 0,
      ...>   output_accessor: 1
      ...> )
      %AriaGltf.Animation{
        name: "Rotate Y",
        channels: [
          %AriaGltf.Animation.Channel{
            sampler: 0,
            target: %AriaGltf.Animation.Channel.Target{
              node: 0,
              path: "rotation"
            }
          }
        ],
        samplers: [
          %AriaGltf.Animation.Sampler{
            input: 0,
            output: 1,
            interpolation: "LINEAR"
          }
        ]
      }
  """
  @spec create_simple_animation(keyword()) :: Animation.t()
  def create_simple_animation(opts \\ []) do
    name = Keyword.get(opts, :name)
    target_node = Keyword.get(opts, :target_node)
    path = Keyword.get(opts, :path)
    input_accessor = Keyword.get(opts, :input_accessor)
    output_accessor = Keyword.get(opts, :output_accessor)
    interpolation = Keyword.get(opts, :interpolation, "LINEAR")

    target = %Animation.Channel.Target{
      node: target_node,
      path: path
    }

    channel = %Animation.Channel{
      sampler: 0,
      target: target
    }

    sampler = %Animation.Sampler{
      input: input_accessor,
      output: output_accessor,
      interpolation: interpolation
    }

    %Animation{
      name: name,
      channels: [channel],
      samplers: [sampler]
    }
  end

  @doc """
  Creates a buffer with specified byte length.

  ## Options

  - `:byte_length` - Buffer size in bytes (required)
  - `:uri` - Buffer URI (external file or data URI)
  - `:name` - Buffer name

  ## Examples

      iex> AriaGltf.Helpers.create_buffer(byte_length: 1024)
      %AriaGltf.Buffer{byte_length: 1024}

      iex> AriaGltf.Helpers.create_buffer(
      ...>   byte_length: 2048,
      ...>   uri: "geometry.bin",
      ...>   name: "Mesh Data"
      ...> )
      %AriaGltf.Buffer{
        byte_length: 2048,
        uri: "geometry.bin",
        name: "Mesh Data"
      }
  """
  @spec create_buffer(keyword()) :: Buffer.t()
  def create_buffer(opts \\ []) do
    byte_length = Keyword.fetch!(opts, :byte_length)
    uri = Keyword.get(opts, :uri)
    name = Keyword.get(opts, :name)

    %Buffer{
      byte_length: byte_length,
      uri: uri,
      name: name
    }
  end

  @doc """
  Creates a buffer view with specified parameters.

  ## Options

  - `:buffer` - Buffer index (required)
  - `:byte_offset` - Byte offset (default: 0)
  - `:byte_length` - Byte length (required)
  - `:byte_stride` - Byte stride for interleaved data
  - `:target` - Buffer view target (34962 for ARRAY_BUFFER, 34963 for ELEMENT_ARRAY_BUFFER)
  - `:name` - Buffer view name

  ## Examples

      iex> AriaGltf.Helpers.create_buffer_view(buffer: 0, byte_length: 512)
      %AriaGltf.BufferView{
        buffer: 0,
        byte_offset: 0,
        byte_length: 512
      }

      iex> AriaGltf.Helpers.create_buffer_view(
      ...>   buffer: 0,
      ...>   byte_offset: 100,
      ...>   byte_length: 300,
      ...>   target: 34962,
      ...>   name: "Positions"
      ...> )
      %AriaGltf.BufferView{
        buffer: 0,
        byte_offset: 100,
        byte_length: 300,
        target: 34962,
        name: "Positions"
      }
  """
  @spec create_buffer_view(keyword()) :: BufferView.t()
  def create_buffer_view(opts \\ []) do
    buffer = Keyword.fetch!(opts, :buffer)
    byte_offset = Keyword.get(opts, :byte_offset, 0)
    byte_length = Keyword.fetch!(opts, :byte_length)
    byte_stride = Keyword.get(opts, :byte_stride)
    target = Keyword.get(opts, :target)
    name = Keyword.get(opts, :name)

    %BufferView{
      buffer: buffer,
      byte_offset: byte_offset,
      byte_length: byte_length,
      byte_stride: byte_stride,
      target: target,
      name: name
    }
  end

  @doc """
  Creates an accessor with specified parameters.

  ## Options

  - `:buffer_view` - Buffer view index (required)
  - `:component_type` - Component type (5126 for FLOAT, 5123 for UNSIGNED_SHORT, etc.)
  - `:count` - Number of elements (required)
  - `:type` - Data type ("SCALAR", "VEC2", "VEC3", "VEC4", "MAT2", "MAT3", "MAT4")
  - `:byte_offset` - Byte offset within buffer view (default: 0)
  - `:normalized` - Whether data is normalized
  - `:max` - Maximum values
  - `:min` - Minimum values
  - `:name` - Accessor name

  ## Examples

      iex> AriaGltf.Helpers.create_accessor(
      ...>   buffer_view: 0,
      ...>   component_type: 5126,
      ...>   count: 8,
      ...>   type: "VEC3"
      ...> )
      %AriaGltf.Accessor{
        buffer_view: 0,
        component_type: 5126,
        count: 8,
        type: "VEC3",
        byte_offset: 0
      }

      iex> AriaGltf.Helpers.create_accessor(
      ...>   buffer_view: 1,
      ...>   component_type: 5123,
      ...>   count: 36,
      ...>   type: "SCALAR",
      ...>   name: "Cube Indices"
      ...> )
      %AriaGltf.Accessor{
        buffer_view: 1,
        component_type: 5123,
        count: 36,
        type: "SCALAR",
        byte_offset: 0,
        name: "Cube Indices"
      }
  """
  @spec create_accessor(keyword()) :: Accessor.t()
  def create_accessor(opts \\ []) do
    buffer_view = Keyword.fetch!(opts, :buffer_view)
    component_type = Keyword.fetch!(opts, :component_type)
    count = Keyword.fetch!(opts, :count)
    type = Keyword.fetch!(opts, :type)
    byte_offset = Keyword.get(opts, :byte_offset, 0)
    normalized = Keyword.get(opts, :normalized)
    max = Keyword.get(opts, :max)
    min = Keyword.get(opts, :min)
    name = Keyword.get(opts, :name)

    %Accessor{
      buffer_view: buffer_view,
      component_type: component_type,
      count: count,
      type: type,
      byte_offset: byte_offset,
      normalized: normalized,
      max: max,
      min: min,
      name: name
    }
  end

  @doc """
  Creates a complete cube mesh with geometry data.

  This helper creates a unit cube centered at origin with positions, normals,
  texture coordinates, and indices. It creates all necessary buffers, buffer views,
  and accessors.

  ## Options

  - `:name` - Mesh name (default: "Cube")
  - `:material` - Material index to assign to the mesh

  ## Returns

  A map containing:
  - `:mesh` - The mesh structure
  - `:buffers` - List of buffers
  - `:buffer_views` - List of buffer views
  - `:accessors` - List of accessors

  ## Examples

      iex> cube_data = AriaGltf.Helpers.create_cube_mesh()
      iex> cube_data.mesh.name
      "Cube"
      iex> length(cube_data.accessors)
      4
  """
  @spec create_cube_mesh(keyword()) :: %{
    mesh: Mesh.t(),
    buffers: [Buffer.t()],
    buffer_views: [BufferView.t()],
    accessors: [Accessor.t()]
  }
  def create_cube_mesh(opts \\ []) do
    name = Keyword.get(opts, :name, "Cube")
    material = Keyword.get(opts, :material)

    # Cube vertices (8 vertices, each with position, normal, texcoord)
    # Each vertex: position (3 floats) + normal (3 floats) + texcoord (2 floats) = 8 floats = 32 bytes
    vertex_data_size = 8 * 8 * 4  # 8 vertices * 8 floats * 4 bytes = 256 bytes

    # Cube indices (12 triangles * 3 indices = 36 indices)
    # Each index: unsigned short = 2 bytes
    index_data_size = 36 * 2  # 36 indices * 2 bytes = 72 bytes

    total_buffer_size = vertex_data_size + index_data_size  # 328 bytes

    # Create buffer
    buffer = create_buffer(byte_length: total_buffer_size, name: "#{name} Data")

    # Create buffer views
    vertex_buffer_view = create_buffer_view(
      buffer: 0,
      byte_offset: 0,
      byte_length: vertex_data_size,
      byte_stride: 32,  # 8 floats * 4 bytes
      target: 34962,  # ARRAY_BUFFER
      name: "#{name} Vertices"
    )

    index_buffer_view = create_buffer_view(
      buffer: 0,
      byte_offset: vertex_data_size,
      byte_length: index_data_size,
      target: 34963,  # ELEMENT_ARRAY_BUFFER
      name: "#{name} Indices"
    )

    # Create accessors
    position_accessor = create_accessor(
      buffer_view: 0,
      component_type: 5126,  # FLOAT
      count: 8,
      type: "VEC3",
      byte_offset: 0,
      name: "#{name} Positions",
      min: [-0.5, -0.5, -0.5],
      max: [0.5, 0.5, 0.5]
    )

    normal_accessor = create_accessor(
      buffer_view: 0,
      component_type: 5126,  # FLOAT
      count: 8,
      type: "VEC3",
      byte_offset: 12,  # 3 floats * 4 bytes
      name: "#{name} Normals"
    )

    texcoord_accessor = create_accessor(
      buffer_view: 0,
      component_type: 5126,  # FLOAT
      count: 8,
      type: "VEC2",
      byte_offset: 24,  # 6 floats * 4 bytes
      name: "#{name} TexCoords"
    )

    index_accessor = create_accessor(
      buffer_view: 1,
      component_type: 5123,  # UNSIGNED_SHORT
      count: 36,
      type: "SCALAR",
      name: "#{name} Indices"
    )

    # Create mesh
    mesh = create_simple_mesh(
      name: name,
      position_accessor: 0,
      normal_accessor: 1,
      texcoord_accessor: 2,
      indices_accessor: 3,
      material: material
    )

    %{
      mesh: mesh,
      buffers: [buffer],
      buffer_views: [vertex_buffer_view, index_buffer_view],
      accessors: [position_accessor, normal_accessor, texcoord_accessor, index_accessor]
    }
  end
end
