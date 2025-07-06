# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaGltf.HelpersTest do
  use ExUnit.Case, async: true
  doctest AriaGltf.Helpers

  alias AriaGltf.Helpers
  alias AriaGltf.{Document, Scene, Node, Mesh, Material, Animation, Buffer, BufferView, Accessor}

  describe "create_minimal_document/1" do
    test "creates minimal document with defaults" do
      doc = Helpers.create_minimal_document()

      assert %Document{} = doc
      assert doc.asset.version == "2.0"
      assert doc.asset.generator == "AriaGltf"
      assert doc.asset.copyright == nil
      assert length(doc.scenes) == 1
      assert doc.scene == 0
      assert doc.nodes == []
      assert doc.meshes == []
    end

    test "creates minimal document with custom options" do
      doc = Helpers.create_minimal_document(
        generator: "TestApp",
        copyright: "2025 Test Company"
      )

      assert doc.asset.generator == "TestApp"
      assert doc.asset.copyright == "2025 Test Company"
      assert doc.asset.version == "2.0"
    end

    test "creates minimal document with custom version" do
      doc = Helpers.create_minimal_document(version: "2.1")

      assert doc.asset.version == "2.1"
    end
  end

  describe "create_simple_scene/1" do
    test "creates scene with defaults" do
      scene = Helpers.create_simple_scene()

      assert %Scene{} = scene
      assert scene.name == nil
      assert scene.nodes == [0]
    end

    test "creates scene with custom name" do
      scene = Helpers.create_simple_scene(name: "Main Scene")

      assert scene.name == "Main Scene"
      assert scene.nodes == [0]
    end
  end

  describe "create_node/1" do
    test "creates node with defaults" do
      node = Helpers.create_node()

      assert %Node{} = node
      assert node.name == nil
      assert node.translation == nil
      assert node.rotation == nil
      assert node.scale == nil
      assert node.mesh == nil
      assert node.children == nil
    end

    test "creates node with transform properties" do
      node = Helpers.create_node(
        name: "Transform Node",
        translation: [1, 2, 3],
        rotation: [0, 0, 0, 1],
        scale: [2, 2, 2],
        mesh: 0
      )

      assert node.name == "Transform Node"
      assert node.translation == [1, 2, 3]
      assert node.rotation == [0, 0, 0, 1]
      assert node.scale == [2, 2, 2]
      assert node.mesh == 0
    end

    test "creates node with children" do
      node = Helpers.create_node(children: [1, 2, 3])

      assert node.children == [1, 2, 3]
    end
  end

  describe "create_simple_mesh/1" do
    test "creates mesh with position and indices" do
      mesh = Helpers.create_simple_mesh(
        name: "Test Mesh",
        position_accessor: 0,
        indices_accessor: 1
      )

      assert %Mesh{} = mesh
      assert mesh.name == "Test Mesh"
      assert length(mesh.primitives) == 1

      primitive = List.first(mesh.primitives)
      assert primitive.mode == 4  # TRIANGLES
      assert primitive.attributes["POSITION"] == 0
      assert primitive.indices == 1
    end

    test "creates mesh with all attributes" do
      mesh = Helpers.create_simple_mesh(
        name: "Full Mesh",
        position_accessor: 0,
        normal_accessor: 1,
        texcoord_accessor: 2,
        indices_accessor: 3,
        material: 0
      )

      primitive = List.first(mesh.primitives)
      assert primitive.attributes["POSITION"] == 0
      assert primitive.attributes["NORMAL"] == 1
      assert primitive.attributes["TEXCOORD_0"] == 2
      assert primitive.indices == 3
      assert primitive.material == 0
    end

    test "creates mesh with custom mode" do
      mesh = Helpers.create_simple_mesh(
        mode: 1,  # LINES
        position_accessor: 0
      )

      primitive = List.first(mesh.primitives)
      assert primitive.mode == 1
    end
  end

  describe "create_pbr_material/1" do
    test "creates material with defaults" do
      material = Helpers.create_pbr_material()

      assert %Material{} = material
      assert material.name == nil
      assert material.pbr_metallic_roughness.base_color_factor == [1, 1, 1, 1]
      assert material.pbr_metallic_roughness.metallic_factor == 1.0
      assert material.pbr_metallic_roughness.roughness_factor == 1.0
    end

    test "creates material with custom properties" do
      material = Helpers.create_pbr_material(
        name: "Blue Metal",
        base_color_factor: [0, 0, 1, 1],
        metallic_factor: 0.8,
        roughness_factor: 0.2,
        double_sided: true
      )

      assert material.name == "Blue Metal"
      assert material.pbr_metallic_roughness.base_color_factor == [0, 0, 1, 1]
      assert material.pbr_metallic_roughness.metallic_factor == 0.8
      assert material.pbr_metallic_roughness.roughness_factor == 0.2
      assert material.double_sided == true
    end

    test "creates material with textures" do
      material = Helpers.create_pbr_material(
        base_color_texture: 0,
        metallic_roughness_texture: 1,
        normal_texture: 2
      )

      assert material.pbr_metallic_roughness.base_color_texture.index == 0
      assert material.pbr_metallic_roughness.metallic_roughness_texture.index == 1
      assert material.normal_texture.index == 2
    end

    test "creates material with alpha properties" do
      material = Helpers.create_pbr_material(
        alpha_mode: "MASK",
        alpha_cutoff: 0.5,
        emissive_factor: [1, 0, 0]
      )

      assert material.alpha_mode == "MASK"
      assert material.alpha_cutoff == 0.5
      assert material.emissive_factor == [1, 0, 0]
    end
  end

  describe "create_simple_animation/1" do
    test "creates animation with required properties" do
      animation = Helpers.create_simple_animation(
        name: "Rotate",
        target_node: 0,
        path: "rotation",
        input_accessor: 0,
        output_accessor: 1
      )

      assert %Animation{} = animation
      assert animation.name == "Rotate"
      assert length(animation.channels) == 1
      assert length(animation.samplers) == 1

      channel = List.first(animation.channels)
      assert channel.sampler == 0
      assert channel.target.node == 0
      assert channel.target.path == "rotation"

      sampler = List.first(animation.samplers)
      assert sampler.input == 0
      assert sampler.output == 1
      assert sampler.interpolation == "LINEAR"
    end

    test "creates animation with custom interpolation" do
      animation = Helpers.create_simple_animation(
        target_node: 0,
        path: "translation",
        input_accessor: 0,
        output_accessor: 1,
        interpolation: "STEP"
      )

      sampler = List.first(animation.samplers)
      assert sampler.interpolation == "STEP"
    end
  end

  describe "create_buffer/1" do
    test "creates buffer with required byte_length" do
      buffer = Helpers.create_buffer(byte_length: 1024)

      assert %Buffer{} = buffer
      assert buffer.byte_length == 1024
      assert buffer.uri == nil
      assert buffer.name == nil
    end

    test "creates buffer with all properties" do
      buffer = Helpers.create_buffer(
        byte_length: 2048,
        uri: "data.bin",
        name: "Mesh Buffer"
      )

      assert buffer.byte_length == 2048
      assert buffer.uri == "data.bin"
      assert buffer.name == "Mesh Buffer"
    end

    test "raises when byte_length is missing" do
      assert_raise KeyError, fn ->
        Helpers.create_buffer()
      end
    end
  end

  describe "create_buffer_view/1" do
    test "creates buffer view with required properties" do
      buffer_view = Helpers.create_buffer_view(
        buffer: 0,
        byte_length: 512
      )

      assert %BufferView{} = buffer_view
      assert buffer_view.buffer == 0
      assert buffer_view.byte_offset == 0
      assert buffer_view.byte_length == 512
      assert buffer_view.byte_stride == nil
      assert buffer_view.target == nil
    end

    test "creates buffer view with all properties" do
      buffer_view = Helpers.create_buffer_view(
        buffer: 1,
        byte_offset: 100,
        byte_length: 300,
        byte_stride: 12,
        target: 34962,
        name: "Vertices"
      )

      assert buffer_view.buffer == 1
      assert buffer_view.byte_offset == 100
      assert buffer_view.byte_length == 300
      assert buffer_view.byte_stride == 12
      assert buffer_view.target == 34962
      assert buffer_view.name == "Vertices"
    end

    test "raises when required properties are missing" do
      assert_raise KeyError, fn ->
        Helpers.create_buffer_view()
      end

      assert_raise KeyError, fn ->
        Helpers.create_buffer_view(buffer: 0)
      end
    end
  end

  describe "create_accessor/1" do
    test "creates accessor with required properties" do
      accessor = Helpers.create_accessor(
        buffer_view: 0,
        component_type: 5126,
        count: 24,
        type: "VEC3"
      )

      assert %Accessor{} = accessor
      assert accessor.buffer_view == 0
      assert accessor.component_type == 5126
      assert accessor.count == 24
      assert accessor.type == "VEC3"
      assert accessor.byte_offset == 0
      assert accessor.normalized == nil
    end

    test "creates accessor with all properties" do
      accessor = Helpers.create_accessor(
        buffer_view: 1,
        component_type: 5123,
        count: 36,
        type: "SCALAR",
        byte_offset: 12,
        normalized: true,
        max: [255],
        min: [0],
        name: "Indices"
      )

      assert accessor.buffer_view == 1
      assert accessor.component_type == 5123
      assert accessor.count == 36
      assert accessor.type == "SCALAR"
      assert accessor.byte_offset == 12
      assert accessor.normalized == true
      assert accessor.max == [255]
      assert accessor.min == [0]
      assert accessor.name == "Indices"
    end

    test "raises when required properties are missing" do
      assert_raise KeyError, fn ->
        Helpers.create_accessor()
      end

      assert_raise KeyError, fn ->
        Helpers.create_accessor(buffer_view: 0)
      end
    end
  end

  describe "create_cube_mesh/1" do
    test "creates complete cube mesh data" do
      cube_data = Helpers.create_cube_mesh()

      assert %{
        mesh: mesh,
        buffers: buffers,
        buffer_views: buffer_views,
        accessors: accessors
      } = cube_data

      # Verify mesh
      assert %Mesh{} = mesh
      assert mesh.name == "Cube"
      assert length(mesh.primitives) == 1

      primitive = List.first(mesh.primitives)
      assert primitive.mode == 4  # TRIANGLES
      assert primitive.attributes["POSITION"] == 0
      assert primitive.attributes["NORMAL"] == 1
      assert primitive.attributes["TEXCOORD_0"] == 2
      assert primitive.indices == 3

      # Verify buffers
      assert length(buffers) == 1
      buffer = List.first(buffers)
      assert buffer.byte_length == 328  # 256 + 72
      assert buffer.name == "Cube Data"

      # Verify buffer views
      assert length(buffer_views) == 2
      [vertex_view, index_view] = buffer_views

      assert vertex_view.buffer == 0
      assert vertex_view.byte_offset == 0
      assert vertex_view.byte_length == 256
      assert vertex_view.byte_stride == 32
      assert vertex_view.target == 34962  # ARRAY_BUFFER

      assert index_view.buffer == 0
      assert index_view.byte_offset == 256
      assert index_view.byte_length == 72
      assert index_view.target == 34963  # ELEMENT_ARRAY_BUFFER

      # Verify accessors
      assert length(accessors) == 4
      [position_acc, normal_acc, texcoord_acc, index_acc] = accessors

      assert position_acc.buffer_view == 0
      assert position_acc.component_type == 5126  # FLOAT
      assert position_acc.count == 8
      assert position_acc.type == "VEC3"
      assert position_acc.byte_offset == 0
      assert position_acc.min == [-0.5, -0.5, -0.5]
      assert position_acc.max == [0.5, 0.5, 0.5]

      assert normal_acc.buffer_view == 0
      assert normal_acc.component_type == 5126  # FLOAT
      assert normal_acc.count == 8
      assert normal_acc.type == "VEC3"
      assert normal_acc.byte_offset == 12

      assert texcoord_acc.buffer_view == 0
      assert texcoord_acc.component_type == 5126  # FLOAT
      assert texcoord_acc.count == 8
      assert texcoord_acc.type == "VEC2"
      assert texcoord_acc.byte_offset == 24

      assert index_acc.buffer_view == 1
      assert index_acc.component_type == 5123  # UNSIGNED_SHORT
      assert index_acc.count == 36
      assert index_acc.type == "SCALAR"
    end

    test "creates cube mesh with custom name and material" do
      cube_data = Helpers.create_cube_mesh(
        name: "My Cube",
        material: 0
      )

      assert cube_data.mesh.name == "My Cube"

      primitive = List.first(cube_data.mesh.primitives)
      assert primitive.material == 0

      # Buffer and accessor names should reflect custom name
      buffer = List.first(cube_data.buffers)
      assert buffer.name == "My Cube Data"

      [vertex_view, index_view] = cube_data.buffer_views
      assert vertex_view.name == "My Cube Vertices"
      assert index_view.name == "My Cube Indices"
    end
  end
end
