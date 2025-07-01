# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Primitives do
  @moduledoc """
  Geometric primitive generation for basic 3D shapes.

  This module provides functions to generate common 3D geometric primitives
  like boxes, spheres, cylinders, planes, and triangles with vertex data,
  indices, normals, and UV coordinates.
  """

  alias AriaMath.{Vector3, Matrix4}

  @type primitive :: %{
    vertices: [Vector3.t()],
    indices: [non_neg_integer()],
    normals: [Vector3.t()],
    uvs: [{float(), float()}]
  }

  @doc """
  Create a box primitive with default size (1, 1, 1).
  """
  @spec box() :: primitive()
  def box(), do: box({1.0, 1.0, 1.0})

  @doc """
  Create a box primitive with specified size.
  """
  @spec box({float(), float(), float()}) :: primitive()
  def box({width, height, depth}) do
    half_w = width / 2.0
    half_h = height / 2.0
    half_d = depth / 2.0

    vertices = [
      # Front face
      {-half_w, -half_h, half_d},   # 0
      {half_w, -half_h, half_d},    # 1
      {half_w, half_h, half_d},     # 2
      {-half_w, half_h, half_d},    # 3
      # Back face
      {-half_w, -half_h, -half_d},  # 4
      {half_w, -half_h, -half_d},   # 5
      {half_w, half_h, -half_d},    # 6
      {-half_w, half_h, -half_d}    # 7
    ]

    indices = [
      # Front face
      0, 1, 2, 0, 2, 3,
      # Back face
      4, 6, 5, 4, 7, 6,
      # Left face
      4, 0, 3, 4, 3, 7,
      # Right face
      1, 5, 6, 1, 6, 2,
      # Top face
      3, 2, 6, 3, 6, 7,
      # Bottom face
      4, 5, 1, 4, 1, 0
    ]

    normals = [
      # Front
      {0.0, 0.0, 1.0}, {0.0, 0.0, 1.0}, {0.0, 0.0, 1.0}, {0.0, 0.0, 1.0},
      # Back
      {0.0, 0.0, -1.0}, {0.0, 0.0, -1.0}, {0.0, 0.0, -1.0}, {0.0, 0.0, -1.0}
    ]

    uvs = [
      {0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}, {0.0, 1.0},
      {1.0, 0.0}, {0.0, 0.0}, {0.0, 1.0}, {1.0, 1.0}
    ]

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  @doc """
  Create a sphere primitive with default radius 1.0 and 2 subdivisions.
  """
  @spec sphere() :: primitive()
  def sphere(), do: sphere(1.0, 2)

  @doc """
  Create a sphere primitive with specified radius and default 2 subdivisions.
  """
  @spec sphere(float()) :: primitive()
  def sphere(radius), do: sphere(radius, 2)

  @doc """
  Create a sphere primitive with specified radius and subdivisions.
  Uses icosphere generation for better topology.
  """
  @spec sphere(float(), non_neg_integer()) :: primitive()
  def sphere(radius, subdivisions) do
    # Start with icosahedron
    {vertices, indices} = generate_icosahedron(radius)

    # Subdivide the specified number of times
    {final_vertices, final_indices} =
      Enum.reduce(0..(subdivisions-1), {vertices, indices}, fn _, {v, i} ->
        subdivide_sphere(v, i, radius)
      end)

    # Generate normals (for sphere, normal = normalized position)
    normals = Enum.map(final_vertices, fn vertex ->
      {normal, _} = Vector3.normalize(vertex)
      normal
    end)

    # Generate UV coordinates
    uvs = Enum.map(final_vertices, fn {x, y, z} ->
      u = 0.5 + :math.atan2(z, x) / (2 * :math.pi())
      v = 0.5 - :math.asin(y / radius) / :math.pi()
      {u, v}
    end)

    %{vertices: final_vertices, indices: final_indices, normals: normals, uvs: uvs}
  end

  @doc """
  Create a cylinder primitive with default parameters (radius 1.0, height 2.0, 8 segments).
  """
  @spec cylinder() :: primitive()
  def cylinder(), do: cylinder(1.0, 2.0, 8)

  @doc """
  Create a cylinder primitive with specified parameters.
  """
  @spec cylinder(float(), float(), non_neg_integer()) :: primitive()
  def cylinder(radius, height, segments) do
    half_height = height / 2.0
    angle_step = 2 * :math.pi() / segments

    # Generate vertices
    vertices = []
    # Bottom center
    vertices = [{0.0, -half_height, 0.0} | vertices]
    # Top center
    vertices = [{0.0, half_height, 0.0} | vertices]

    # Bottom circle
    bottom_vertices = for i <- 0..(segments-1) do
      angle = i * angle_step
      x = radius * :math.cos(angle)
      z = radius * :math.sin(angle)
      {x, -half_height, z}
    end

    # Top circle
    top_vertices = for i <- 0..(segments-1) do
      angle = i * angle_step
      x = radius * :math.cos(angle)
      z = radius * :math.sin(angle)
      {x, half_height, z}
    end

    vertices = vertices ++ bottom_vertices ++ top_vertices

    # Bottom cap
    bottom_indices = for i <- 0..(segments-1) do
      next_i = rem(i + 1, segments)
      [0, 2 + next_i, 2 + i]
    end |> List.flatten()

    # Top cap
    top_indices = for i <- 0..(segments-1) do
      next_i = rem(i + 1, segments)
      [1, 2 + segments + i, 2 + segments + next_i]
    end |> List.flatten()

    # Side faces
    side_indices = for i <- 0..(segments-1) do
      next_i = rem(i + 1, segments)
      bottom_i = 2 + i
      bottom_next = 2 + next_i
      top_i = 2 + segments + i
      top_next = 2 + segments + next_i
      [bottom_i, top_i, top_next, bottom_i, top_next, bottom_next]
    end |> List.flatten()

    indices = bottom_indices ++ top_indices ++ side_indices

    # Generate normals
    normals = []
    # Bottom center normal
    normals = [{0.0, -1.0, 0.0} | normals]
    # Top center normal
    normals = [{0.0, 1.0, 0.0} | normals]

    # Bottom circle normals
    bottom_normals = List.duplicate({0.0, -1.0, 0.0}, segments)

    # Top circle normals
    top_normals = List.duplicate({0.0, 1.0, 0.0}, segments)

    normals = normals ++ bottom_normals ++ top_normals

    # Generate UVs
    uvs = List.duplicate({0.5, 0.5}, length(vertices))

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  @doc """
  Create a plane primitive with default size (1.0, 1.0).
  """
  @spec plane() :: primitive()
  def plane(), do: plane({1.0, 1.0})

  @doc """
  Create a plane primitive with specified size lying on XZ plane.
  """
  @spec plane({float(), float()}) :: primitive()
  def plane({width, depth}) do
    half_w = width / 2.0
    half_d = depth / 2.0

    vertices = [
      {-half_w, 0.0, -half_d},  # 0
      {half_w, 0.0, -half_d},   # 1
      {half_w, 0.0, half_d},    # 2
      {-half_w, 0.0, half_d}    # 3
    ]

    indices = [0, 1, 2, 0, 2, 3]

    normals = List.duplicate({0.0, 1.0, 0.0}, 4)

    uvs = [{0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}, {0.0, 1.0}]

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  @doc """
  Create a triangle primitive with default vertices.
  """
  @spec triangle() :: primitive()
  def triangle() do
    triangle([{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}])
  end

  @doc """
  Create a triangle primitive with specified vertices.
  """
  @spec triangle([Vector3.t()]) :: primitive()
  def triangle(vertices) when length(vertices) == 3 do
    [v1, v2, v3] = vertices

    # Calculate normal using cross product
    edge1 = Vector3.sub(v2, v1)
    edge2 = Vector3.sub(v3, v1)
    {normal, _} = Vector3.normalize(Vector3.cross(edge1, edge2))

    indices = [0, 1, 2]
    normals = [normal, normal, normal]
    uvs = [{0.0, 0.0}, {1.0, 0.0}, {0.5, 1.0}]

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  @doc """
  Apply a transformation matrix to a primitive.
  """
  @spec transform(primitive(), Matrix4.t()) :: primitive()
  def transform(primitive, matrix) do
    # Transform vertices
    transformed_vertices = Enum.map(primitive.vertices, fn vertex ->
      Matrix4.transform_point(matrix, vertex)
    end)

    # Transform normals (use inverse transpose for proper normal transformation)
    {inverse_matrix, _} = Matrix4.inverse(matrix)
    transpose_inverse = Matrix4.transpose(inverse_matrix)

    transformed_normals = Enum.map(primitive.normals, fn normal ->
      transformed = Matrix4.transform_vector(transpose_inverse, normal)
      {normalized, _} = Vector3.normalize(transformed)
      normalized
    end)

    %{primitive |
      vertices: transformed_vertices,
      normals: transformed_normals
    }
  end

  @doc """
  Merge two primitives into a single primitive.
  """
  @spec merge(primitive(), primitive()) :: primitive()
  def merge(prim1, prim2) do
    vertex_offset = length(prim1.vertices)

    # Combine vertices
    vertices = prim1.vertices ++ prim2.vertices

    # Combine indices with offset for second primitive
    offset_indices = Enum.map(prim2.indices, fn idx -> idx + vertex_offset end)
    indices = prim1.indices ++ offset_indices

    # Combine normals and UVs
    normals = prim1.normals ++ prim2.normals
    uvs = prim1.uvs ++ prim2.uvs

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  # Helper functions for sphere generation

  @spec generate_icosahedron(float()) :: {[Vector3.t()], [non_neg_integer()]}
  defp generate_icosahedron(radius) do
    # Golden ratio
    phi = (1.0 + :math.sqrt(5.0)) / 2.0

    # Icosahedron vertices
    vertices = [
      {-1.0, phi, 0.0}, {1.0, phi, 0.0}, {-1.0, -phi, 0.0}, {1.0, -phi, 0.0},
      {0.0, -1.0, phi}, {0.0, 1.0, phi}, {0.0, -1.0, -phi}, {0.0, 1.0, -phi},
      {phi, 0.0, -1.0}, {phi, 0.0, 1.0}, {-phi, 0.0, -1.0}, {-phi, 0.0, 1.0}
    ]

    # Normalize and scale to radius
    scaled_vertices = Enum.map(vertices, fn vertex ->
      {normalized, _} = Vector3.normalize(vertex)
      Vector3.scale(normalized, radius)
    end)

    # Icosahedron faces
    indices = [
      0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
      1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
      3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
      4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1
    ]

    {scaled_vertices, indices}
  end

  @spec subdivide_sphere([Vector3.t()], [non_neg_integer()], float()) :: {[Vector3.t()], [non_neg_integer()]}
  defp subdivide_sphere(vertices, indices, _radius) do
    # This is a simplified subdivision - a full implementation would be more complex
    # For now, just return the original sphere
    {vertices, indices}
  end

  # Mathematical utility functions

  @doc """
  Check if two floating-point numbers are approximately equal within default tolerance.
  """
  @spec approximately_equal(float(), float()) :: boolean()
  def approximately_equal(a, b) do
    approximately_equal(a, b, 1.0e-6)
  end

  @doc """
  Check if two floating-point numbers are approximately equal within specified tolerance.
  """
  @spec approximately_equal(float(), float(), float()) :: boolean()
  def approximately_equal(a, b, tolerance) when is_number(a) and is_number(b) and is_number(tolerance) do
    abs(a - b) <= tolerance
  end

  @doc """
  Clamp a value between minimum and maximum bounds.
  """
  @spec clamp(number(), number(), number()) :: number()
  def clamp(value, min_val, max_val) when is_number(value) and is_number(min_val) and is_number(max_val) do
    cond do
      value < min_val -> min_val
      value > max_val -> max_val
      true -> value
    end
  end

  @doc """
  Linear interpolation between two values.
  """
  @spec lerp(float(), float(), float()) :: float()
  def lerp(a, b, t) when is_number(a) and is_number(b) and is_number(t) do
    a + (b - a) * t
  end

  @doc """
  Convert degrees to radians.
  """
  @spec deg_to_rad(float()) :: float()
  def deg_to_rad(degrees) when is_number(degrees) do
    degrees * :math.pi() / 180.0
  end

  @doc """
  Convert radians to degrees.
  """
  @spec rad_to_deg(float()) :: float()
  def rad_to_deg(radians) when is_number(radians) do
    radians * 180.0 / :math.pi()
  end

  @doc """
  IEEE-754 positive infinity constant.
  """
  @spec inf() :: float()
  def inf do
    try do
      1.0 / 0.0
    rescue
      ArithmeticError -> :positive_infinity
    end
  end

  @doc """
  Check if a float value is infinite (positive or negative).
  """
  @spec isinf_float(float()) :: boolean()
  def isinf_float(value) when is_number(value) do
    value == :positive_infinity or value == :negative_infinity or
    value == 1.0 / 0.0 or value == -1.0 / 0.0
  rescue
    ArithmeticError -> false
  end
end
