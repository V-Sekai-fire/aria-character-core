# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives.Operations do
  @moduledoc """
  Operations for transforming and manipulating geometric primitives.

  This module provides functions for applying transformations, merging primitives,
  and helper functions for complex geometric operations like sphere subdivision.
  """

  alias AriaMath.{Vector3, Matrix4}

  @type primitive :: %{
    vertices: [Vector3.t()],
    indices: [non_neg_integer()],
    normals: [Vector3.t()],
    uvs: [{float(), float()}]
  }

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

  @doc """
  Generate an icosahedron with the specified radius.
  """
  @spec generate_icosahedron(float()) :: {[Vector3.t()], [non_neg_integer()]}
  def generate_icosahedron(radius) do
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

  @doc """
  Subdivide a sphere by splitting each triangle into 4 triangles.
  """
  @spec subdivide_sphere([Vector3.t()], [non_neg_integer()], float()) :: {[Vector3.t()], [non_neg_integer()]}
  def subdivide_sphere(vertices, indices, radius) do
    # Basic subdivision algorithm: split each triangle into 4 triangles
    # by adding midpoints and projecting them to sphere surface

    # Process triangles in groups of 3 indices
    {new_vertices, new_indices} =
      indices
      |> Enum.chunk_every(3)
      |> Enum.reduce({vertices, []}, fn [i1, i2, i3], {v_list, acc_indices} ->
        # Get triangle vertices
        v1 = Enum.at(v_list, i1)
        v2 = Enum.at(v_list, i2)
        v3 = Enum.at(v_list, i3)

        # Calculate midpoints
        mid12 = midpoint_on_sphere(v1, v2, radius)
        mid23 = midpoint_on_sphere(v2, v3, radius)
        mid31 = midpoint_on_sphere(v3, v1, radius)

        # Add new vertices and get their indices
        current_count = length(v_list)
        updated_vertices = v_list ++ [mid12, mid23, mid31]
        idx12 = current_count
        idx23 = current_count + 1
        idx31 = current_count + 2

        # Create 4 new triangles from original triangle
        new_triangle_indices = [
          # Center triangle
          idx12, idx23, idx31,
          # Corner triangles
          i1, idx12, idx31,
          i2, idx23, idx12,
          i3, idx31, idx23
        ]

        {updated_vertices, acc_indices ++ new_triangle_indices}
      end)

    {new_vertices, new_indices}
  end

  @doc """
  Calculate midpoint between two vertices and project to sphere surface.
  """
  @spec midpoint_on_sphere(Vector3.t(), Vector3.t(), float()) :: Vector3.t()
  def midpoint_on_sphere({x1, y1, z1}, {x2, y2, z2}, radius) do
    # Calculate midpoint
    mid_x = (x1 + x2) / 2.0
    mid_y = (y1 + y2) / 2.0
    mid_z = (z1 + z2) / 2.0

    # Normalize and scale to radius
    {normalized, _} = Vector3.normalize({mid_x, mid_y, mid_z})
    Vector3.scale(normalized, radius)
  end
end
