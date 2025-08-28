defmodule AriaBmeshDomainTest do
  use ExUnit.Case
  doctest AriaBmeshDomain

  alias AriaBmeshDomain.Primitives

  setup do
    state = AriaState.new()
    {:ok, state: state}
  end

  describe "domain creation" do
    test "creates procedural mesh domain successfully" do
      domain = AriaBmeshDomain.create()
      assert domain != nil
      assert domain.name == :bmesh_world
    end
  end

  describe "entity setup" do
    test "setup_mesh_scenario initializes entities", %{state: state} do
      {:ok, new_state} = AriaBmeshDomain.setup_mesh_scenario(state, [])

      # Verify mesh generator entity
      assert AriaState.get_fact(new_state, "mesh_generator", "type") == "generator"
      assert AriaState.get_fact(new_state, "mesh_generator", "status") == "available"

      # Verify spatial analyzer entity
      assert AriaState.get_fact(new_state, "spatial_analyzer", "type") == "analyzer"
      assert AriaState.get_fact(new_state, "spatial_analyzer", "status") == "available"

      # Verify mesh optimizer entity
      assert AriaState.get_fact(new_state, "mesh_optimizer", "type") == "optimizer"
      assert AriaState.get_fact(new_state, "mesh_optimizer", "status") == "available"
    end
  end

  describe "geometric primitives - cubic strokes" do
    test "creates cubic stroke mesh", %{state: state} do
      params = Primitives.cubic_stroke_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["cubic_stroke_1", params])

      assert AriaState.get_fact(new_state, "cubic_stroke_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "cubic_stroke_1", "vertex_count") == 64
      assert AriaState.get_fact(new_state, "cubic_stroke_1", "face_count") == 48
    end

    test "cubic stroke with custom parameters", %{state: state} do
      params = Primitives.cubic_stroke_params(vertex_count: 128, segments: 16)
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["custom_stroke", params])

      assert AriaState.get_fact(new_state, "custom_stroke", "vertex_count") == 128
    end
  end

  describe "geometric primitives - cylinders" do
    test "creates cylinder mesh", %{state: state} do
      params = Primitives.cylinder_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["cylinder_1", params])

      assert AriaState.get_fact(new_state, "cylinder_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "cylinder_1", "vertex_count") == 48
      assert AriaState.get_fact(new_state, "cylinder_1", "face_count") == 32
    end

    test "cylinder with high resolution", %{state: state} do
      params = Primitives.cylinder_params(radial_segments: 32, vertex_count: 96)
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["hires_cylinder", params])

      assert AriaState.get_fact(new_state, "hires_cylinder", "vertex_count") == 96
    end
  end

  describe "geometric primitives - cones" do
    test "creates cone mesh", %{state: state} do
      params = Primitives.cone_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["cone_1", params])

      assert AriaState.get_fact(new_state, "cone_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "cone_1", "vertex_count") == 33
      assert AriaState.get_fact(new_state, "cone_1", "face_count") == 32
    end
  end

  describe "geometric primitives - cuboids" do
    test "creates cuboid mesh", %{state: state} do
      params = Primitives.cuboid_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["cuboid_1", params])

      assert AriaState.get_fact(new_state, "cuboid_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "cuboid_1", "vertex_count") == 8
      assert AriaState.get_fact(new_state, "cuboid_1", "face_count") == 6
    end

    test "cuboid with custom dimensions", %{state: state} do
      params = Primitives.cuboid_params(width: 4.0, height: 2.0, depth: 1.0)
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["custom_cuboid", params])

      assert AriaState.get_fact(new_state, "custom_cuboid", "mesh_exists") == true
    end
  end

  describe "geometric primitives - ellipsoids" do
    test "creates ellipsoid mesh", %{state: state} do
      params = Primitives.ellipsoid_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["ellipsoid_1", params])

      assert AriaState.get_fact(new_state, "ellipsoid_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "ellipsoid_1", "vertex_count") == 482
      assert AriaState.get_fact(new_state, "ellipsoid_1", "face_count") == 960
    end

    test "ellipsoid with different radii", %{state: state} do
      params = Primitives.ellipsoid_params(radius_x: 2.0, radius_y: 1.0, radius_z: 0.5)
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["stretched_ellipsoid", params])

      assert AriaState.get_fact(new_state, "stretched_ellipsoid", "mesh_exists") == true
    end
  end

  describe "geometric primitives - triangular prisms" do
    test "creates triangular prism mesh", %{state: state} do
      params = Primitives.triangular_prism_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["tri_prism_1", params])

      assert AriaState.get_fact(new_state, "tri_prism_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "tri_prism_1", "vertex_count") == 6
      assert AriaState.get_fact(new_state, "tri_prism_1", "face_count") == 8
    end
  end

  describe "geometric primitives - donuts (tori)" do
    test "creates donut mesh", %{state: state} do
      params = Primitives.donut_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["donut_1", params])

      assert AriaState.get_fact(new_state, "donut_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "donut_1", "vertex_count") == 256
      assert AriaState.get_fact(new_state, "donut_1", "face_count") == 256
    end

    test "donut with custom radii", %{state: state} do
      params = Primitives.donut_params(major_radius: 3.0, minor_radius: 0.8)
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["large_donut", params])

      assert AriaState.get_fact(new_state, "large_donut", "mesh_exists") == true
    end
  end

  describe "geometric primitives - biscuits" do
    test "creates biscuit mesh", %{state: state} do
      params = Primitives.biscuit_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["biscuit_1", params])

      assert AriaState.get_fact(new_state, "biscuit_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "biscuit_1", "vertex_count") == 96
      assert AriaState.get_fact(new_state, "biscuit_1", "face_count") == 80
    end

    test "biscuit with chamfer", %{state: state} do
      params = Primitives.biscuit_params(chamfer_radius: 0.2, height: 1.0)
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["chamfered_biscuit", params])

      assert AriaState.get_fact(new_state, "chamfered_biscuit", "mesh_exists") == true
    end
  end

  describe "geometric primitives - markoids" do
    test "creates markoid mesh", %{state: state} do
      params = Primitives.markoid_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["markoid_1", params])

      assert AriaState.get_fact(new_state, "markoid_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "markoid_1", "vertex_count") == 642
      assert AriaState.get_fact(new_state, "markoid_1", "face_count") == 1280
    end

    test "markoid with custom powers", %{state: state} do
      params = Primitives.markoid_params(power_x: 4.0, power_y: 2.0, power_z: 1.5)
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["custom_markoid", params])

      assert AriaState.get_fact(new_state, "custom_markoid", "mesh_exists") == true
    end
  end

  describe "geometric primitives - pyramids" do
    test "creates pyramid mesh", %{state: state} do
      params = Primitives.pyramid_params()
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["pyramid_1", params])

      assert AriaState.get_fact(new_state, "pyramid_1", "mesh_exists") == true
      assert AriaState.get_fact(new_state, "pyramid_1", "vertex_count") == 5
      assert AriaState.get_fact(new_state, "pyramid_1", "face_count") == 5
    end

    test "triangular pyramid", %{state: state} do
      params = Primitives.pyramid_params(base_type: :triangle)
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["tri_pyramid", params])

      assert AriaState.get_fact(new_state, "tri_pyramid", "vertex_count") == 4
      assert AriaState.get_fact(new_state, "tri_pyramid", "face_count") == 4
    end

    test "hexagonal pyramid", %{state: state} do
      params = Primitives.pyramid_params(base_type: :hexagon)
      {:ok, new_state} = AriaBmeshDomain.create_mesh(state, ["hex_pyramid", params])

      assert AriaState.get_fact(new_state, "hex_pyramid", "vertex_count") == 7
      assert AriaState.get_fact(new_state, "hex_pyramid", "face_count") == 7
    end
  end

  describe "primitive complexity categories" do
    test "low complexity primitives" do
      assert Primitives.primitive_complexity(:cuboid) == :low
      assert Primitives.primitive_complexity(:triangular_prism) == :low
      assert Primitives.primitive_complexity(:pyramid) == :low
    end

    test "medium complexity primitives" do
      assert Primitives.primitive_complexity(:cylinder) == :medium
      assert Primitives.primitive_complexity(:cone) == :medium
      assert Primitives.primitive_complexity(:cubic_stroke) == :medium
      assert Primitives.primitive_complexity(:biscuit) == :medium
    end

    test "high complexity primitives" do
      assert Primitives.primitive_complexity(:ellipsoid) == :high
      assert Primitives.primitive_complexity(:donut) == :high
      assert Primitives.primitive_complexity(:markoid) == :high
    end
  end

  describe "primitive parameter generation" do
    test "generates parameters for all primitive types" do
      for primitive_type <- Primitives.all_primitive_types() do
        params = Primitives.primitive_params(primitive_type)
        assert params.primitive_type == primitive_type
        assert is_integer(params.vertex_count)
        assert is_integer(params.face_count)
        assert is_binary(params.shape)
      end
    end
  end

  describe "mesh actions" do
    test "prevents duplicate mesh creation", %{state: state} do
      params = Primitives.cuboid_params()
      {:ok, state_with_mesh} = AriaBmeshDomain.create_mesh(state, ["test_mesh", params])

      # Try to create same mesh again
      {:error, reason} = AriaBmeshDomain.create_mesh(state_with_mesh, ["test_mesh", params])
      assert reason == :mesh_already_exists
    end

    test "modifies mesh topology", %{state: state} do
      params = Primitives.cuboid_params()
      {:ok, state_with_mesh} = AriaBmeshDomain.create_mesh(state, ["test_mesh", params])

      operations = %{add_vertices: 4, add_faces: 2}
      {:ok, modified_state} = AriaBmeshDomain.modify_topology(state_with_mesh, ["test_mesh", operations])

      assert AriaState.get_fact(modified_state, "test_mesh", "vertex_count") == 12
      assert AriaState.get_fact(modified_state, "test_mesh", "face_count") == 8
    end

    test "fails to modify non-existent mesh", %{state: state} do
      operations = %{add_vertices: 4}
      {:error, reason} = AriaBmeshDomain.modify_topology(state, ["nonexistent", operations])
      assert reason == :mesh_not_found
    end
  end

  describe "goal achievement" do
    test "achieves mesh existence goal", %{state: state} do
      {:ok, actions} = AriaBmeshDomain.achieve_mesh_existence(state, {"test_mesh", true})
      assert length(actions) == 1
      assert {:create_mesh, ["test_mesh", %{vertex_count: 4, face_count: 1}]} in actions
    end

    test "mesh existence already satisfied", %{state: state} do
      params = Primitives.cuboid_params()
      {:ok, state_with_mesh} = AriaBmeshDomain.create_mesh(state, ["test_mesh", params])

      {:ok, actions} = AriaBmeshDomain.achieve_mesh_existence(state_with_mesh, {"test_mesh", true})
      assert actions == []
    end

    test "achieves vertex count goal", %{state: state} do
      params = Primitives.cuboid_params()
      {:ok, state_with_mesh} = AriaBmeshDomain.create_mesh(state, ["test_mesh", params])

      {:ok, actions} = AriaBmeshDomain.achieve_vertex_count(state_with_mesh, {"test_mesh", 12})
      assert length(actions) == 1
      assert {:modify_topology, ["test_mesh", %{add_vertices: 4}]} in actions
    end

    test "vertex count already satisfied", %{state: state} do
      params = Primitives.cuboid_params()
      {:ok, state_with_mesh} = AriaBmeshDomain.create_mesh(state, ["test_mesh", params])

      {:ok, actions} = AriaBmeshDomain.achieve_vertex_count(state_with_mesh, {"test_mesh", 8})
      assert actions == []
    end
  end

  describe "task decomposition" do
    test "generates procedural mesh with low complexity", %{state: state} do
      {:ok, actions} = AriaBmeshDomain.generate_procedural_mesh(state, ["test_mesh", :low, :cube])

      assert length(actions) == 2
      assert {:create_mesh, ["test_mesh", %{vertex_count: 100, face_count: 50, shape: "cube"}]} in actions
      assert {"mesh_quality", "test_mesh", :good} in actions
    end

    test "generates procedural mesh with high complexity", %{state: state} do
      {:ok, actions} = AriaBmeshDomain.generate_procedural_mesh(state, ["complex_mesh", :high, :sphere])

      assert length(actions) == 2
      assert {:create_mesh, ["complex_mesh", %{vertex_count: 2000, face_count: 1000, shape: "sphere", subdivisions: 3}]} in actions
    end
  end
end
