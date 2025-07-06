# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives.Tensor.Shapes do
  @moduledoc """
  Basic geometric shape generation using Nx tensors.

  This module provides functions to create fundamental 3D shapes (box, sphere, plane)
  using Nx tensors for optimized numerical computing and batch operations.
  """

  alias AriaMath.Vector3
  alias AriaMath.Primitives.Tensor.Core

  @doc """
  Create a box primitive using Nx tensors with default size (1, 1, 1).

  ## Examples

      iex> box = AriaMath.Primitives.Tensor.Shapes.box_nx()
      iex> Nx.shape(box.vertices)
      {8, 3}
  """
  @spec box_nx() :: Core.primitive_tensor()
  def box_nx(), do: box_nx({1.0, 1.0, 1.0})

  @doc """
  Create a box primitive using Nx tensors with specified size.

  ## Examples

      iex> box = AriaMath.Primitives.Tensor.Shapes.box_nx({2.0, 2.0, 2.0})
      iex> Nx.shape(box.vertices)
      {8, 3}
  """
  @spec box_nx({float(), float(), float()}) :: Core.primitive_tensor()
  def box_nx({width, height, depth}) do
    half_w = width / 2.0
    half_h = height / 2.0
    half_d = depth / 2.0

    # Create vertices as Nx tensor [8, 3]
    vertices = Nx.tensor([
      # Front face
      [-half_w, -half_h, half_d],   # 0
      [half_w, -half_h, half_d],    # 1
      [half_w, half_h, half_d],     # 2
      [-half_w, half_h, half_d],    # 3
      # Back face
      [-half_w, -half_h, -half_d],  # 4
      [half_w, -half_h, -half_d],   # 5
      [half_w, half_h, -half_d],    # 6
      [-half_w, half_h, -half_d]    # 7
    ], type: :f32)

    # Indices for triangles
    indices = Nx.tensor([
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
    ], type: :u32)

    # Normals for each vertex
    normals = Nx.tensor([
      # Front
      [0.0, 0.0, 1.0], [0.0, 0.0, 1.0], [0.0, 0.0, 1.0], [0.0, 0.0, 1.0],
      # Back
      [0.0, 0.0, -1.0], [0.0, 0.0, -1.0], [0.0, 0.0, -1.0], [0.0, 0.0, -1.0]
    ], type: :f32)

    # UV coordinates
    uvs = Nx.tensor([
      [0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0],
      [1.0, 0.0], [0.0, 0.0], [0.0, 1.0], [1.0, 1.0]
    ], type: :f32)

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  @doc """
  Create a sphere primitive using Nx tensors with default radius 1.0 and 2 subdivisions.

  ## Examples

      iex> sphere = AriaMath.Primitives.Tensor.Shapes.sphere_nx()
      iex> {num_vertices, 3} = Nx.shape(sphere.vertices)
      iex> num_vertices > 12  # More than icosahedron
      true
  """
  @spec sphere_nx() :: Core.primitive_tensor()
  def sphere_nx(), do: sphere_nx(1.0, 2)

  @doc """
  Create a sphere primitive using Nx tensors with specified radius and default 2 subdivisions.

  ## Examples

      iex> sphere = AriaMath.Primitives.Tensor.Shapes.sphere_nx(2.0)
      iex> {num_vertices, 3} = Nx.shape(sphere.vertices)
      iex> num_vertices > 12
      true
  """
  @spec sphere_nx(float()) :: Core.primitive_tensor()
  def sphere_nx(radius), do: sphere_nx(radius, 2)

  @doc """
  Create a sphere primitive using Nx tensors with specified radius and subdivisions.

  ## Examples

      iex> sphere = AriaMath.Primitives.Tensor.Shapes.sphere_nx(1.0, 1)
      iex> Nx.shape(sphere.vertices)
      {42, 3}  # After 1 subdivision
  """
  @spec sphere_nx(float(), non_neg_integer()) :: Core.primitive_tensor()
  def sphere_nx(radius, subdivisions) do
    # Start with icosahedron
    {vertices, indices} = generate_icosahedron_nx(radius)

    # Subdivide the specified number of times
    {final_vertices, final_indices} =
      Enum.reduce(0..(subdivisions-1), {vertices, indices}, fn _, {v, i} ->
        subdivide_sphere_nx(v, i, radius)
      end)

    # Generate normals (for sphere, normal = normalized position)
    normals = Vector3.normalize_batch(final_vertices)

    # Generate UV coordinates using batch operations
    uvs = generate_sphere_uvs_nx(final_vertices, radius)

    %{vertices: final_vertices, indices: final_indices, normals: normals, uvs: uvs}
  end

  @doc """
  Create a plane primitive using Nx tensors with default size (1.0, 1.0).

  ## Examples

      iex> plane = AriaMath.Primitives.Tensor.Shapes.plane_nx()
      iex> Nx.shape(plane.vertices)
      {4, 3}
  """
  @spec plane_nx() :: Core.primitive_tensor()
  def plane_nx(), do: plane_nx({1.0, 1.0})

  @doc """
  Create a plane primitive using Nx tensors with specified size lying on XZ plane.

  ## Examples

      iex> plane = AriaMath.Primitives.Tensor.Shapes.plane_nx({2.0, 3.0})
      iex> Nx.shape(plane.vertices)
      {4, 3}
  """
  @spec plane_nx({float(), float()}) :: Core.primitive_tensor()
  def plane_nx({width, depth}) do
    half_w = width / 2.0
    half_d = depth / 2.0

    vertices = Nx.tensor([
      [-half_w, 0.0, -half_d],  # 0
      [half_w, 0.0, -half_d],   # 1
      [half_w, 0.0, half_d],    # 2
      [-half_w, 0.0, half_d]    # 3
    ], type: :f32)

    indices = Nx.tensor([0, 1, 2, 0, 2, 3], type: :u32)

    normals = Nx.tensor([
      [0.0, 1.0, 0.0], [0.0, 1.0, 0.0], [0.0, 1.0, 0.0], [0.0, 1.0, 0.0]
    ], type: :f32)

    uvs = Nx.tensor([
      [0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]
    ], type: :f32)

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  # Helper functions for sphere generation

  @spec generate_icosahedron_nx(float()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  defp generate_icosahedron_nx(radius) do
    # Golden ratio
    phi = (1.0 + :math.sqrt(5.0)) / 2.0

    # Icosahedron vertices as tensor
    vertices = Nx.tensor([
      [-1.0, phi, 0.0], [1.0, phi, 0.0], [-1.0, -phi, 0.0], [1.0, -phi, 0.0],
      [0.0, -1.0, phi], [0.0, 1.0, phi], [0.0, -1.0, -phi], [0.0, 1.0, -phi],
      [phi, 0.0, -1.0], [phi, 0.0, 1.0], [-phi, 0.0, -1.0], [-phi, 0.0, 1.0]
    ], type: :f32)

    # Normalize and scale to radius using batch operations
    normalized_vertices = Vector3.normalize_batch(vertices)
    scaled_vertices = Vector3.scale_batch(normalized_vertices, radius)

    # Icosahedron faces
    indices = Nx.tensor([
      0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
      1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
      3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
      4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1
    ], type: :u32)

    {scaled_vertices, indices}
  end

  @spec subdivide_sphere_nx(Nx.Tensor.t(), Nx.Tensor.t(), float()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  defp subdivide_sphere_nx(vertices, indices, radius) do
    # Convert to lists for subdivision algorithm, then back to tensors
    vertex_list = Nx.to_list(vertices) |> Enum.map(&List.to_tuple/1)
    index_list = Nx.to_list(indices)

    # Use existing subdivision logic
    {new_vertices, new_indices} = subdivide_sphere_list(vertex_list, index_list, radius)

    # Convert back to tensors
    vertices_tensor = new_vertices
                      |> Enum.map(&Tuple.to_list/1)
                      |> Nx.tensor(type: :f32)

    indices_tensor = Nx.tensor(new_indices, type: :u32)

    {vertices_tensor, indices_tensor}
  end

  @spec generate_sphere_uvs_nx(Nx.Tensor.t(), float()) :: Nx.Tensor.t()
  defp generate_sphere_uvs_nx(vertices, radius) do
    # Extract x, y, z components
    x = Nx.slice_along_axis(vertices, 0, 1, axis: 1) |> Nx.squeeze(axes: [1])
    y = Nx.slice_along_axis(vertices, 1, 1, axis: 1) |> Nx.squeeze(axes: [1])
    z = Nx.slice_along_axis(vertices, 2, 1, axis: 1) |> Nx.squeeze(axes: [1])

    # Calculate UV coordinates using Nx operations
    u = Nx.add(0.5, Nx.divide(Nx.atan2(z, x), 2 * :math.pi()))
    v = Nx.subtract(0.5, Nx.divide(Nx.asin(Nx.divide(y, radius)), :math.pi()))

    # Stack into [N, 2] tensor
    Nx.stack([u, v], axis: 1)
  end

  # Helper function for subdivision using existing logic
  defp subdivide_sphere_list(vertices, indices, radius) do
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
