# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives.Sphere do
  @moduledoc """
  Sphere generation using icosphere algorithm with subdivision.

  This module provides optimized sphere generation with proper topology
  using icosahedron base and subdivision for smooth surfaces.
  """

  alias AriaMath.Vector3

  @type primitive :: %{
    vertices: [Vector3.t()],
    indices: [non_neg_integer()],
    normals: [Vector3.t()],
    uvs: [{float(), float()}]
  }

  @doc """
  Create a sphere primitive with default radius 1.0 and 2 subdivisions.
  """
  @spec generate() :: primitive()
  def generate(), do: generate(1.0, 2)

  @doc """
  Create a sphere primitive with specified radius and default 2 subdivisions.
  """
  @spec generate(float()) :: primitive()
  def generate(radius), do: generate(radius, 2)

  @doc """
  Create a sphere primitive with specified radius and subdivisions.
  Uses icosphere generation for better topology.
  """
  @spec generate(float(), non_neg_integer()) :: primitive()
  def generate(radius, subdivisions) do
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
  defp subdivide_sphere(vertices, indices, radius) do
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

  # Helper function to calculate midpoint and project to sphere surface
  defp midpoint_on_sphere({x1, y1, z1}, {x2, y2, z2}, radius) do
    # Calculate midpoint
    mid_x = (x1 + x2) / 2.0
    mid_y = (y1 + y2) / 2.0
    mid_z = (z1 + z2) / 2.0

    # Normalize and scale to radius
    {normalized, _} = Vector3.normalize({mid_x, mid_y, mid_z})
    Vector3.scale(normalized, radius)
  end
end
