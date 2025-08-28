defmodule AriaBmeshDomain do
  @moduledoc """
  Procedural mesh generation domain for AriaHybridPlanner.

  This module implements a planning domain that treats procedural mesh generation
  as a first-class planning concern, enabling spatial and geometric reasoning
  within the temporal planning framework.

  Provides a flexible boundary representation mesh system with runtime
  procedural generation capabilities for game development and 3D content creation.

  ## Core Capabilities

  - **Mesh Generation Planning**: Durative actions for complex mesh operations
  - **Spatial Reasoning**: Topology and geometry as planning predicates
  - **Procedural Content Creation**: Integrated with temporal planning constraints
  - **Runtime Mesh Modification**: Based on planning decisions and goals
  - **Attribute-driven Planning**: Using mesh properties as planning state

  ## Planning Actions

  - `create_mesh/2` - Generate new mesh with specified parameters
  - `modify_topology/2` - Add/remove vertices, edges, faces
  - `setup_mesh_scenario/2` - Initialize mesh generation entities

  ## Goal Achievement

  - `achieve_mesh_existence/2` - Ensure mesh creation goals
  - `achieve_vertex_count/2` - Achieve target vertex count goals

  ## Task Decomposition

  - `generate_procedural_mesh/2` - Decompose complex mesh generation workflows

  ## Usage

      iex> domain = AriaBmeshDomain.create()
      iex> state = AriaState.new()
      iex> {:ok, new_state} = AriaBmeshDomain.setup_mesh_scenario(state, [])
      iex> {:ok, mesh_state} = AriaBmeshDomain.create_mesh(new_state, ["mesh1", %{vertex_count: 100}])

  ## References

  - R25W1398085: Unified durative action specification and planner standardization
  - R25W10069A4: Align unigoal method registration with GTpyhop design
  """
  use AriaCore.ActionAttributes

  @type mesh_id :: String.t()
  @type vertex_count :: non_neg_integer()
  @type mesh_params :: map()

  # Entity setup
  @action duration: "PT0S"
  @spec setup_mesh_scenario(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def setup_mesh_scenario(state, []) do
    state = state
    |> register_entity(["mesh_generator", "generator", [:mesh_creation, :topology_modification]])
    |> register_entity(["spatial_analyzer", "analyzer", [:geometry_analysis, :constraint_checking]])
    |> register_entity(["mesh_optimizer", "optimizer", [:mesh_simplification, :quality_improvement]])

    {:ok, state}
  end

  # Atomic BMesh primitive actions (based on TestBMesh.cs)

  @action duration: "PT0.1S"
  @spec add_vertex(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def add_vertex(state, [mesh_id, vertex_id, position]) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists != true do
      {:error, :mesh_not_found}
    else
      vertex_exists = AriaState.get_fact(state, {mesh_id, vertex_id}, "vertex_exists")

      if vertex_exists == true do
        {:error, :vertex_already_exists}
      else
        current_count = AriaState.get_fact(state, mesh_id, "vertex_count") || 0

        new_state = state
        |> AriaState.set_fact({mesh_id, vertex_id}, "vertex_exists", true)
        |> AriaState.set_fact({mesh_id, vertex_id}, "position", position)
        |> AriaState.set_fact(mesh_id, "vertex_count", current_count + 1)

        {:ok, new_state}
      end
    end
  end

  @action duration: "PT0.2S"
  @spec add_face(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def add_face(state, [mesh_id, face_id, vertex_ids]) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists != true do
      {:error, :mesh_not_found}
    else
      # Check all vertices exist
      vertices_exist = Enum.all?(vertex_ids, fn vertex_id ->
        AriaState.get_fact(state, {mesh_id, vertex_id}, "vertex_exists") == true
      end)

      if not vertices_exist do
        {:error, :vertices_not_found}
      else
        face_exists = AriaState.get_fact(state, {mesh_id, face_id}, "face_exists")

        if face_exists == true do
          {:error, :face_already_exists}
        else
          current_count = AriaState.get_fact(state, mesh_id, "face_count") || 0
          edge_count = AriaState.get_fact(state, mesh_id, "edge_count") || 0

          new_state = state
          |> AriaState.set_fact({mesh_id, face_id}, "face_exists", true)
          |> AriaState.set_fact({mesh_id, face_id}, "vertices", vertex_ids)
          |> AriaState.set_fact(mesh_id, "face_count", current_count + 1)
          |> AriaState.set_fact(mesh_id, "edge_count", edge_count + length(vertex_ids))

          {:ok, new_state}
        end
      end
    end
  end

  @action duration: "PT0.1S"
  @spec remove_edge(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def remove_edge(state, [mesh_id, edge_id]) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists != true do
      {:error, :mesh_not_found}
    else
      edge_exists = AriaState.get_fact(state, {mesh_id, edge_id}, "edge_exists")

      if edge_exists != true do
        {:error, :edge_not_found}
      else
        # Removing edge removes associated faces (BMesh behavior)
        new_state = state
        |> AriaState.set_fact({mesh_id, edge_id}, "edge_exists", false)
        |> AriaState.set_fact(mesh_id, "face_count", 0)
        |> AriaState.set_fact(mesh_id, "loop_count", 0)

        {:ok, new_state}
      end
    end
  end

  @action duration: "PT0.05S"
  @spec add_vertex_attribute(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def add_vertex_attribute(state, [mesh_id, attr_name, attr_type, dimensions]) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists != true do
      {:error, :mesh_not_found}
    else
      new_state = AriaState.set_fact(state, {mesh_id, "vertex_attr", attr_name}, %{
        type: attr_type,
        dimensions: dimensions
      })

      {:ok, new_state}
    end
  end

  @action duration: "PT0.05S"
  @spec add_edge_attribute(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def add_edge_attribute(state, [mesh_id, attr_name, attr_type, dimensions]) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists != true do
      {:error, :mesh_not_found}
    else
      new_state = AriaState.set_fact(state, {mesh_id, "edge_attr", attr_name}, %{
        type: attr_type,
        dimensions: dimensions
      })

      {:ok, new_state}
    end
  end

  @action duration: "PT0.05S"
  @spec add_face_attribute(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def add_face_attribute(state, [mesh_id, attr_name, attr_type, dimensions]) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists != true do
      {:error, :mesh_not_found}
    else
      new_state = AriaState.set_fact(state, {mesh_id, "face_attr", attr_name}, %{
        type: attr_type,
        dimensions: dimensions
      })

      {:ok, new_state}
    end
  end

  @action duration: "PT0.01S"
  @spec create_bmesh(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def create_bmesh(state, [mesh_id]) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists == true do
      {:error, :mesh_already_exists}
    else
      new_state = state
      |> AriaState.set_fact(mesh_id, "mesh_exists", true)
      |> AriaState.set_fact(mesh_id, "vertex_count", 0)
      |> AriaState.set_fact(mesh_id, "edge_count", 0)
      |> AriaState.set_fact(mesh_id, "face_count", 0)
      |> AriaState.set_fact(mesh_id, "loop_count", 0)

      {:ok, new_state}
    end
  end

  # High-level mesh creation action
  @action duration: "PT1S"
  @spec create_mesh(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def create_mesh(state, [mesh_id, params]) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists == true do
      {:error, :mesh_already_exists}
    else
      # Create mesh with specified parameters
      vertex_count = Map.get(params, :vertex_count, 0)
      face_count = Map.get(params, :face_count, 0)

      new_state = state
      |> AriaState.set_fact(mesh_id, "mesh_exists", true)
      |> AriaState.set_fact(mesh_id, "vertex_count", vertex_count)
      |> AriaState.set_fact(mesh_id, "face_count", face_count)
      |> AriaState.set_fact(mesh_id, "edge_count", 0)
      |> AriaState.set_fact(mesh_id, "loop_count", 0)

      {:ok, new_state}
    end
  end

  @action duration: "PT2S"
  @spec modify_topology(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def modify_topology(state, [mesh_id, operations]) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists != true do
      {:error, :mesh_not_found}
    else
      # Apply topology modifications
      current_vertices = AriaState.get_fact(state, mesh_id, "vertex_count") || 0
      current_faces = AriaState.get_fact(state, mesh_id, "face_count") || 0

      new_vertices = current_vertices + Map.get(operations, :add_vertices, 0) - Map.get(operations, :remove_vertices, 0)
      new_faces = current_faces + Map.get(operations, :add_faces, 0) - Map.get(operations, :remove_faces, 0)

      new_state = state
      |> AriaState.set_fact(mesh_id, "vertex_count", max(0, new_vertices))
      |> AriaState.set_fact(mesh_id, "face_count", max(0, new_faces))

      {:ok, new_state}
    end
  end

  # Spatial reasoning unigoal methods
  @unigoal_method predicate: "mesh_exists"
  @spec achieve_mesh_existence(AriaState.t(), {String.t(), boolean()}) :: {:ok, [tuple()]} | {:error, atom()}
  def achieve_mesh_existence(state, {mesh_id, true}) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")

    if mesh_exists == true do
      {:ok, []}  # Already exists
    else
      # Generate action to create mesh
      {:ok, [{:create_bmesh, [mesh_id]}]}
    end
  end

  @unigoal_method predicate: "vertex_count"
  @spec achieve_vertex_count(AriaState.t(), {String.t(), non_neg_integer()}) :: {:ok, [tuple()]} | {:error, atom()}
  def achieve_vertex_count(state, {mesh_id, target_count}) do
    current_count = AriaState.get_fact(state, mesh_id, "vertex_count") || 0

    if current_count == target_count do
      {:ok, []}  # Already at target
    else
      # Generate topology modification to reach target
      vertex_diff = target_count - current_count
      operations = if vertex_diff > 0 do
        %{add_vertices: vertex_diff}
      else
        %{remove_vertices: abs(vertex_diff)}
      end

      {:ok, [{:modify_topology, [mesh_id, operations]}]}
    end
  end

  # Task decomposition methods - delegate to primitives
  @task_method
  def create_cuboid_task(state, [mesh_id, params]) do
    AriaBmeshDomain.Primitives.create_cuboid_task(state, [mesh_id, params])
  end

  @task_method
  def create_cylinder_task(state, [mesh_id, params]) do
    AriaBmeshDomain.Primitives.create_cylinder_task(state, [mesh_id, params])
  end

  @task_method
  def create_cone_task(state, [mesh_id, params]) do
    AriaBmeshDomain.Primitives.create_cone_task(state, [mesh_id, params])
  end

  @task_method
  def create_ellipsoid_task(state, [mesh_id, params]) do
    AriaBmeshDomain.Primitives.create_ellipsoid_task(state, [mesh_id, params])
  end

  @task_method
  def create_donut_task(state, [mesh_id, params]) do
    AriaBmeshDomain.Primitives.create_donut_task(state, [mesh_id, params])
  end

  @task_method
  def create_pyramid_task(state, [mesh_id, params]) do
    AriaBmeshDomain.Primitives.create_pyramid_task(state, [mesh_id, params])
  end

  @task_method
  def create_triangular_prism_task(state, [mesh_id, params]) do
    AriaBmeshDomain.Primitives.create_triangular_prism_task(state, [mesh_id, params])
  end

  @task_method
  @spec generate_procedural_mesh(AriaState.t(), [any()]) :: {:ok, [tuple()]} | {:error, atom()}
  def generate_procedural_mesh(state, [mesh_id, complexity, style]) do
    # Decompose complex mesh generation into primitive task methods
    case style do
      :cuboid -> create_cuboid_task(state, [mesh_id, %{width: 2.0, height: 2.0, depth: 2.0}])
      :cylinder -> create_cylinder_task(state, [mesh_id, %{radius: 1.0, height: 2.0, radial_segments: 8}])
      :cone -> create_cone_task(state, [mesh_id, %{radius: 1.0, height: 2.0, radial_segments: 8}])
      :ellipsoid -> create_ellipsoid_task(state, [mesh_id, %{radius_x: 1.0, radius_y: 1.0, radius_z: 1.0}])
      :donut -> create_donut_task(state, [mesh_id, %{major_radius: 2.0, minor_radius: 0.5}])
      :pyramid -> create_pyramid_task(state, [mesh_id, %{base_width: 2.0, height: 2.0}])
      :triangular_prism -> create_triangular_prism_task(state, [mesh_id, %{base_width: 2.0, height: 2.0, depth: 1.0}])
      _ -> create_cuboid_task(state, [mesh_id, %{width: 2.0, height: 2.0, depth: 2.0}])
    end
  end

  # Domain creation
  @spec create() :: AriaCore.Domain.t()
  def create() do
    domain = AriaCore.new_domain(:bmesh_world)
    domain = AriaCore.register_attribute_specs(domain, __MODULE__)
    domain
  end

  # Helper functions
  defp register_entity(state, [entity_id, type, capabilities]) do
    state
    |> AriaState.set_fact(entity_id, "type", type)
    |> AriaState.set_fact(entity_id, "capabilities", capabilities)
    |> AriaState.set_fact(entity_id, "status", "available")
  end
end
