defmodule AriaBmeshDomain.Primitives do
  @moduledoc """
  Composite task methods for generating geometric primitives using atomic BMesh actions.

  This module provides task decomposition methods that break down complex geometric
  primitive generation into sequences of atomic BMesh operations (add_vertex, add_face, etc.).
  All mesh data is stored in AriaState rather than external systems.

  ## Supported Primitives as Task Methods

  Complete set of industry-standard geometric primitives implemented as composite tasks:

  - **Cubic Strokes**: Volumetric brush-like meshes
  - **Cylinders**: Circular cross-section extrusions
  - **Cones**: Tapered circular meshes
  - **Cuboids**: Rectangular box primitives
  - **Ellipsoids**: Stretched spherical meshes
  - **Triangular Prisms**: Triangular cross-section extrusions
  - **Donuts (Tori)**: Ring-shaped meshes with holes
  - **Biscuits**: Rounded cylindrical shapes
  - **Markoids**: Super ellipsoids with variable power for x,y,z axes
  - **Pyramids**: Pointed apex meshes

  ## Usage

      iex> {:ok, actions} = AriaBmeshDomain.Primitives.create_cuboid_task(state, ["mesh1", %{width: 2.0}])
      iex> # Returns sequence of atomic BMesh actions to execute

  """

  use AriaCore

  @type primitive_params :: map()

  @doc """
  Create cone primitive using atomic BMesh actions.
  Tapered circular meshes with configurable resolution.
  """
  @task_method true
  def create_cone_task(state, [mesh_id, params]) do
    radius = Map.get(params, :radius, 1.0)
    height = Map.get(params, :height, 2.0)
    radial_segments = Map.get(params, :radial_segments, 8)

    # Calculate half height for centering
    hh = height / 2.0

    # Generate vertices for bottom circle and apex
    vertices = []

    # Bottom circle vertices
    bottom_vertices = for i <- 0..(radial_segments - 1) do
      angle = 2 * :math.pi() * i / radial_segments
      x = radius * :math.cos(angle)
      z = radius * :math.sin(angle)
      {"v_bottom_#{i}", {x, -hh, z}}
    end

    # Center vertex for bottom cap and apex
    center_vertices = [
      {"v_center_bottom", {0.0, -hh, 0.0}},
      {"v_apex", {0.0, hh, 0.0}}
    ]

    all_vertices = bottom_vertices ++ center_vertices

    # Generate faces
    faces = []

    # Bottom cap faces (triangular faces from center to edge)
    bottom_faces = for i <- 0..(radial_segments - 1) do
      next_i = rem(i + 1, radial_segments)
      {"f_bottom_#{i}", ["v_center_bottom", "v_bottom_#{next_i}", "v_bottom_#{i}"]}
    end

    # Side faces (triangular faces from bottom edge to apex)
    side_faces = for i <- 0..(radial_segments - 1) do
      next_i = rem(i + 1, radial_segments)
      {"f_side_#{i}", ["v_bottom_#{i}", "v_bottom_#{next_i}", "v_apex"]}
    end

    all_faces = bottom_faces ++ side_faces

    # Generate action sequence
    actions = [
      {:create_bmesh, [mesh_id]}
    ] ++
    Enum.map(all_vertices, fn {vertex_id, position} ->
      {:add_vertex, [mesh_id, vertex_id, position]}
    end) ++
    Enum.map(all_faces, fn {face_id, vertex_list} ->
      {:add_face, [mesh_id, face_id, vertex_list]}
    end)

    {:ok, actions}
  end

  @doc """
  Create ellipsoid primitive using atomic BMesh actions.
  Stretched spherical meshes with configurable radii.
  """
  @task_method true
  def create_ellipsoid_task(state, [mesh_id, params]) do
    radius_x = Map.get(params, :radius_x, 1.0)
    radius_y = Map.get(params, :radius_y, 1.0)
    radius_z = Map.get(params, :radius_z, 1.0)
    u_segments = Map.get(params, :u_segments, 8)
    v_segments = Map.get(params, :v_segments, 6)

    # Generate vertices using spherical coordinates
    vertices = []

    # Generate vertices for each ring
    ring_vertices = for v <- 0..v_segments do
      phi = :math.pi() * v / v_segments
      y = radius_y * :math.cos(phi)
      ring_radius = :math.sin(phi)

      for u <- 0..(u_segments - 1) do
        theta = 2 * :math.pi() * u / u_segments
        x = radius_x * ring_radius * :math.cos(theta)
        z = radius_z * ring_radius * :math.sin(theta)
        {"v_#{v}_#{u}", {x, y, z}}
      end
    end

    all_vertices = List.flatten(ring_vertices)

    # Generate faces
    faces = []

    # Generate faces between rings
    ring_faces = for v <- 0..(v_segments - 1) do
      for u <- 0..(u_segments - 1) do
        next_u = rem(u + 1, u_segments)
        next_v = v + 1

        # Create quad face (split into two triangles if needed)
        {"f_#{v}_#{u}", ["v_#{v}_#{u}", "v_#{v}_#{next_u}", "v_#{next_v}_#{next_u}", "v_#{next_v}_#{u}"]}
      end
    end

    all_faces = List.flatten(ring_faces)

    # Generate action sequence
    actions = [
      {:create_bmesh, [mesh_id]}
    ] ++
    Enum.map(all_vertices, fn {vertex_id, position} ->
      {:add_vertex, [mesh_id, vertex_id, position]}
    end) ++
    Enum.map(all_faces, fn {face_id, vertex_list} ->
      {:add_face, [mesh_id, face_id, vertex_list]}
    end)

    {:ok, actions}
  end

  @doc """
  Create donut (torus) primitive using atomic BMesh actions.
  Ring-shaped meshes with holes.
  """
  @task_method true
  def create_donut_task(state, [mesh_id, params]) do
    major_radius = Map.get(params, :major_radius, 2.0)
    minor_radius = Map.get(params, :minor_radius, 0.5)
    major_segments = Map.get(params, :major_segments, 12)
    minor_segments = Map.get(params, :minor_segments, 8)

    # Generate vertices using torus parametric equations
    vertices = []

    ring_vertices = for i <- 0..(major_segments - 1) do
      theta = 2 * :math.pi() * i / major_segments

      for j <- 0..(minor_segments - 1) do
        phi = 2 * :math.pi() * j / minor_segments

        x = (major_radius + minor_radius * :math.cos(phi)) * :math.cos(theta)
        y = minor_radius * :math.sin(phi)
        z = (major_radius + minor_radius * :math.cos(phi)) * :math.sin(theta)

        {"v_#{i}_#{j}", {x, y, z}}
      end
    end

    all_vertices = List.flatten(ring_vertices)

    # Generate faces
    faces = []

    ring_faces = for i <- 0..(major_segments - 1) do
      next_i = rem(i + 1, major_segments)

      for j <- 0..(minor_segments - 1) do
        next_j = rem(j + 1, minor_segments)

        # Create quad face
        {"f_#{i}_#{j}", ["v_#{i}_#{j}", "v_#{next_i}_#{j}", "v_#{next_i}_#{next_j}", "v_#{i}_#{next_j}"]}
      end
    end

    all_faces = List.flatten(ring_faces)

    # Generate action sequence
    actions = [
      {:create_bmesh, [mesh_id]}
    ] ++
    Enum.map(all_vertices, fn {vertex_id, position} ->
      {:add_vertex, [mesh_id, vertex_id, position]}
    end) ++
    Enum.map(all_faces, fn {face_id, vertex_list} ->
      {:add_face, [mesh_id, face_id, vertex_list]}
    end)

    {:ok, actions}
  end

  @doc """
  Create pyramid primitive using atomic BMesh actions.
  Pointed apex meshes with square base.
  """
  @task_method true
  def create_pyramid_task(state, [mesh_id, params]) do
    base_width = Map.get(params, :base_width, 2.0)
    height = Map.get(params, :height, 2.0)

    # Calculate half dimensions for centering
    hw = base_width / 2.0
    hh = height / 2.0

    # Define 5 vertices of a pyramid (4 base + 1 apex)
    vertices = [
      # Base vertices
      {"v1", {-hw, -hh, -hw}},  # Bottom left
      {"v2", {hw, -hh, -hw}},   # Bottom right
      {"v3", {hw, -hh, hw}},    # Top right
      {"v4", {-hw, -hh, hw}},   # Top left
      # Apex vertex
      {"v5", {0.0, hh, 0.0}}    # Apex
    ]

    # Define 5 faces (1 base + 4 triangular sides)
    faces = [
      {"f1", ["v1", "v4", "v3", "v2"]},  # Base face (square)
      {"f2", ["v1", "v2", "v5"]},        # Front triangle
      {"f3", ["v2", "v3", "v5"]},        # Right triangle
      {"f4", ["v3", "v4", "v5"]},        # Back triangle
      {"f5", ["v4", "v1", "v5"]}         # Left triangle
    ]

    # Generate action sequence
    actions = [
      {:create_bmesh, [mesh_id]}
    ] ++
    Enum.map(vertices, fn {vertex_id, position} ->
      {:add_vertex, [mesh_id, vertex_id, position]}
    end) ++
    Enum.map(faces, fn {face_id, vertex_list} ->
      {:add_face, [mesh_id, face_id, vertex_list]}
    end)

    {:ok, actions}
  end

  @doc """
  Create cylinder primitive using atomic BMesh actions.
  Circular cross-section extrusions with configurable resolution.
  """
  @task_method true
  def create_cylinder_task(state, [mesh_id, params]) do
    radius = Map.get(params, :radius, 1.0)
    height = Map.get(params, :height, 2.0)
    radial_segments = Map.get(params, :radial_segments, 8)

    # Calculate half height for centering
    hh = height / 2.0

    # Generate vertices for bottom and top circles
    vertices = []

    # Bottom circle vertices
    bottom_vertices = for i <- 0..(radial_segments - 1) do
      angle = 2 * :math.pi() * i / radial_segments
      x = radius * :math.cos(angle)
      z = radius * :math.sin(angle)
      {"v_bottom_#{i}", {x, -hh, z}}
    end

    # Top circle vertices
    top_vertices = for i <- 0..(radial_segments - 1) do
      angle = 2 * :math.pi() * i / radial_segments
      x = radius * :math.cos(angle)
      z = radius * :math.sin(angle)
      {"v_top_#{i}", {x, hh, z}}
    end

    # Center vertices for caps
    center_vertices = [
      {"v_center_bottom", {0.0, -hh, 0.0}},
      {"v_center_top", {0.0, hh, 0.0}}
    ]

    all_vertices = bottom_vertices ++ top_vertices ++ center_vertices

    # Generate faces
    faces = []

    # Bottom cap faces (triangular faces from center to edge)
    bottom_faces = for i <- 0..(radial_segments - 1) do
      next_i = rem(i + 1, radial_segments)
      {"f_bottom_#{i}", ["v_center_bottom", "v_bottom_#{next_i}", "v_bottom_#{i}"]}
    end

    # Top cap faces (triangular faces from center to edge)
    top_faces = for i <- 0..(radial_segments - 1) do
      next_i = rem(i + 1, radial_segments)
      {"f_top_#{i}", ["v_center_top", "v_top_#{i}", "v_top_#{next_i}"]}
    end

    # Side faces (rectangular faces connecting bottom and top)
    side_faces = for i <- 0..(radial_segments - 1) do
      next_i = rem(i + 1, radial_segments)
      {"f_side_#{i}", ["v_bottom_#{i}", "v_bottom_#{next_i}", "v_top_#{next_i}", "v_top_#{i}"]}
    end

    all_faces = bottom_faces ++ top_faces ++ side_faces

    # Generate action sequence
    actions = [
      {:create_bmesh, [mesh_id]}
    ] ++
    Enum.map(all_vertices, fn {vertex_id, position} ->
      {:add_vertex, [mesh_id, vertex_id, position]}
    end) ++
    Enum.map(all_faces, fn {face_id, vertex_list} ->
      {:add_face, [mesh_id, face_id, vertex_list]}
    end)

    {:ok, actions}
  end


  @doc """
  Create cuboid primitive using atomic BMesh actions.
  Rectangular box primitives with configurable dimensions.
  """
  @task_method true
  def create_cuboid_task(state, [mesh_id, params]) do
    width = Map.get(params, :width, 2.0)
    height = Map.get(params, :height, 2.0)
    depth = Map.get(params, :depth, 2.0)

    # Calculate half dimensions for centering
    hw = width / 2.0
    hh = height / 2.0
    hd = depth / 2.0

    # Define 8 vertices of a cuboid
    vertices = [
      {"v1", {-hw, -hh, -hd}},  # Bottom face
      {"v2", {hw, -hh, -hd}},
      {"v3", {hw, hh, -hd}},
      {"v4", {-hw, hh, -hd}},
      {"v5", {-hw, -hh, hd}},   # Top face
      {"v6", {hw, -hh, hd}},
      {"v7", {hw, hh, hd}},
      {"v8", {-hw, hh, hd}}
    ]

    # Define 6 faces (each face defined by 4 vertices in counter-clockwise order)
    faces = [
      {"f1", ["v1", "v2", "v3", "v4"]},  # Bottom face
      {"f2", ["v5", "v8", "v7", "v6"]},  # Top face
      {"f3", ["v1", "v5", "v6", "v2"]},  # Front face
      {"f4", ["v3", "v7", "v8", "v4"]},  # Back face
      {"f5", ["v1", "v4", "v8", "v5"]},  # Left face
      {"f6", ["v2", "v6", "v7", "v3"]}   # Right face
    ]

    # Generate action sequence
    actions = [
      {:create_bmesh, [mesh_id]}
    ] ++
    Enum.map(vertices, fn {vertex_id, position} ->
      {:add_vertex, [mesh_id, vertex_id, position]}
    end) ++
    Enum.map(faces, fn {face_id, vertex_list} ->
      {:add_face, [mesh_id, face_id, vertex_list]}
    end)

    {:ok, actions}
  end


  @doc """
  Create triangular prism primitive using atomic BMesh actions.
  Triangular cross-section extrusions.
  """
  @task_method true
  def create_triangular_prism_task(state, [mesh_id, params]) do
    base_width = Map.get(params, :base_width, 2.0)
    height = Map.get(params, :height, 2.0)
    depth = Map.get(params, :depth, 1.0)

    # Calculate half dimensions for centering
    hw = base_width / 2.0
    hh = height / 2.0
    hd = depth / 2.0

    # Define 6 vertices of a triangular prism
    vertices = [
      # Bottom triangle
      {"v1", {-hw, -hh, -hd}},  # Left bottom front
      {"v2", {hw, -hh, -hd}},   # Right bottom front
      {"v3", {0.0, hh, -hd}},   # Top front
      # Top triangle
      {"v4", {-hw, -hh, hd}},   # Left bottom back
      {"v5", {hw, -hh, hd}},    # Right bottom back
      {"v6", {0.0, hh, hd}}     # Top back
    ]

    # Define 8 faces (2 triangular faces + 3 rectangular faces)
    faces = [
      {"f1", ["v1", "v2", "v3"]},        # Front triangle
      {"f2", ["v4", "v6", "v5"]},        # Back triangle
      {"f3", ["v1", "v4", "v5", "v2"]},  # Bottom rectangle
      {"f4", ["v2", "v5", "v6", "v3"]},  # Right rectangle
      {"f5", ["v3", "v6", "v4", "v1"]}   # Left rectangle
    ]

    # Generate action sequence
    actions = [
      {:create_bmesh, [mesh_id]}
    ] ++
    Enum.map(vertices, fn {vertex_id, position} ->
      {:add_vertex, [mesh_id, vertex_id, position]}
    end) ++
    Enum.map(faces, fn {face_id, vertex_list} ->
      {:add_face, [mesh_id, face_id, vertex_list]}
    end)

    {:ok, actions}
  end

  @doc """
  Get all available task methods for primitive generation.
  """
  @spec available_task_methods() :: [atom()]
  def available_task_methods do
    [
      :create_cuboid_task,
      :create_cylinder_task,
      :create_triangular_prism_task,
      :create_cone_task,
      :create_ellipsoid_task,
      :create_donut_task,
      :create_pyramid_task
    ]
  end

  @doc """
  Get complexity category for implemented task methods.
  """
  @spec task_complexity(atom()) :: :low | :medium | :high
  def task_complexity(task_method) do
    case task_method do
      :create_cuboid_task -> :low
      :create_triangular_prism_task -> :low
      :create_pyramid_task -> :low
      :create_cylinder_task -> :medium
      :create_cone_task -> :medium
      :create_ellipsoid_task -> :high
      :create_donut_task -> :high
      _ -> :medium
    end
  end
end
