# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Primitives.Tensor do
  @moduledoc """
  Nx tensor-based geometric primitive generation.

  This module provides the same API as Primitives core module but uses Nx tensors
  for optimized numerical computing and batch operations on vertex data.

  Primitives are represented as maps with Nx tensors:
  - vertices: Nx.tensor with shape [num_vertices, 3]
  - normals: Nx.tensor with shape [num_vertices, 3]
  - indices: Nx.tensor with shape [num_triangles * 3] (u32)
  - uvs: Nx.tensor with shape [num_vertices, 2]
  """

  alias AriaMath.Vector3
  alias AriaMath.Matrix4

  @type primitive_tensor :: %{
    vertices: Nx.Tensor.t(),
    indices: Nx.Tensor.t(),
    normals: Nx.Tensor.t(),
    uvs: Nx.Tensor.t()
  }

  @doc """
  Convert a tuple-based primitive to tensor format.

  ## Examples

      iex> tuple_prim = AriaMath.Primitives.box()
      iex> tensor_prim = AriaMath.Primitives.Tensor.from_tuple_primitive(tuple_prim)
      iex> Nx.shape(tensor_prim.vertices)
      {8, 3}
  """
  @spec from_tuple_primitive(AriaMath.Primitives.primitive()) :: primitive_tensor()
  def from_tuple_primitive(primitive) do
    vertices_tensor = primitive.vertices
                      |> Enum.map(&Tuple.to_list/1)
                      |> Nx.tensor(type: :f32)

    normals_tensor = primitive.normals
                     |> Enum.map(&Tuple.to_list/1)
                     |> Nx.tensor(type: :f32)

    indices_tensor = Nx.tensor(primitive.indices, type: :u32)

    uvs_tensor = primitive.uvs
                 |> Enum.map(&Tuple.to_list/1)
                 |> Nx.tensor(type: :f32)

    %{
      vertices: vertices_tensor,
      indices: indices_tensor,
      normals: normals_tensor,
      uvs: uvs_tensor
    }
  end

  @doc """
  Convert a tensor-based primitive back to tuple format.

  ## Examples

      iex> tensor_prim = AriaMath.Primitives.Tensor.box_nx()
      iex> tuple_prim = AriaMath.Primitives.Tensor.to_tuple_primitive(tensor_prim)
      iex> length(tuple_prim.vertices)
      8
  """
  @spec to_tuple_primitive(primitive_tensor()) :: AriaMath.Primitives.primitive()
  def to_tuple_primitive(tensor_primitive) do
    vertices = tensor_primitive.vertices
               |> Nx.to_list()
               |> Enum.map(&List.to_tuple/1)

    normals = tensor_primitive.normals
              |> Nx.to_list()
              |> Enum.map(&List.to_tuple/1)

    indices = Nx.to_list(tensor_primitive.indices)

    uvs = tensor_primitive.uvs
          |> Nx.to_list()
          |> Enum.map(&List.to_tuple/1)

    %{
      vertices: vertices,
      indices: indices,
      normals: normals,
      uvs: uvs
    }
  end

  @doc """
  Create a box primitive using Nx tensors with default size (1, 1, 1).

  ## Examples

      iex> box = AriaMath.Primitives.Tensor.box_nx()
      iex> Nx.shape(box.vertices)
      {8, 3}
  """
  @spec box_nx() :: primitive_tensor()
  def box_nx(), do: box_nx({1.0, 1.0, 1.0})

  @doc """
  Create a box primitive using Nx tensors with specified size.

  ## Examples

      iex> box = AriaMath.Primitives.Tensor.box_nx({2.0, 2.0, 2.0})
      iex> Nx.shape(box.vertices)
      {8, 3}
  """
  @spec box_nx({float(), float(), float()}) :: primitive_tensor()
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

      iex> sphere = AriaMath.Primitives.Tensor.sphere_nx()
      iex> {num_vertices, 3} = Nx.shape(sphere.vertices)
      iex> num_vertices > 12  # More than icosahedron
      true
  """
  @spec sphere_nx() :: primitive_tensor()
  def sphere_nx(), do: sphere_nx(1.0, 2)

  @doc """
  Create a sphere primitive using Nx tensors with specified radius and default 2 subdivisions.

  ## Examples

      iex> sphere = AriaMath.Primitives.Tensor.sphere_nx(2.0)
      iex> {num_vertices, 3} = Nx.shape(sphere.vertices)
      iex> num_vertices > 12
      true
  """
  @spec sphere_nx(float()) :: primitive_tensor()
  def sphere_nx(radius), do: sphere_nx(radius, 2)

  @doc """
  Create a sphere primitive using Nx tensors with specified radius and subdivisions.

  ## Examples

      iex> sphere = AriaMath.Primitives.Tensor.sphere_nx(1.0, 1)
      iex> Nx.shape(sphere.vertices)
      {42, 3}  # After 1 subdivision
  """
  @spec sphere_nx(float(), non_neg_integer()) :: primitive_tensor()
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

      iex> plane = AriaMath.Primitives.Tensor.plane_nx()
      iex> Nx.shape(plane.vertices)
      {4, 3}
  """
  @spec plane_nx() :: primitive_tensor()
  def plane_nx(), do: plane_nx({1.0, 1.0})

  @doc """
  Create a plane primitive using Nx tensors with specified size lying on XZ plane.

  ## Examples

      iex> plane = AriaMath.Primitives.Tensor.plane_nx({2.0, 3.0})
      iex> Nx.shape(plane.vertices)
      {4, 3}
  """
  @spec plane_nx({float(), float()}) :: primitive_tensor()
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

  @doc """
  Apply a transformation matrix to a primitive using batch operations.

  ## Examples

      iex> prim = AriaMath.Primitives.Tensor.box_nx()
      iex> transform = Matrix4.translation_nx({1.0, 2.0, 3.0})
      iex> transformed = AriaMath.Primitives.Tensor.transform_nx(prim, transform)
      iex> Nx.shape(transformed.vertices)
      {8, 3}
  """
  @spec transform_nx(primitive_tensor(), Nx.Tensor.t()) :: primitive_tensor()
  def transform_nx(primitive, matrix) do
    # Transform vertices using batch matrix operations
    transformed_vertices = Matrix4.transform_points_batch(matrix, primitive.vertices)

    # Transform normals (use inverse transpose for proper normal transformation)
    inverse_matrix = Matrix4.inverse_nx(matrix)
    transpose_inverse = Matrix4.transpose_nx(inverse_matrix)

    transformed_normals = Matrix4.transform_vectors_batch(transpose_inverse, primitive.normals)
    normalized_normals = Vector3.normalize_batch(transformed_normals)

    %{primitive |
      vertices: transformed_vertices,
      normals: normalized_normals
    }
  end

  @doc """
  Merge two tensor primitives into a single primitive using efficient tensor operations.

  ## Examples

      iex> prim1 = AriaMath.Primitives.Tensor.box_nx()
      iex> prim2 = AriaMath.Primitives.Tensor.plane_nx()
      iex> merged = AriaMath.Primitives.Tensor.merge_nx(prim1, prim2)
      iex> Nx.shape(merged.vertices)
      {12, 3}  # 8 + 4 vertices
  """
  @spec merge_nx(primitive_tensor(), primitive_tensor()) :: primitive_tensor()
  def merge_nx(prim1, prim2) do
    vertex_offset = Nx.axis_size(prim1.vertices, 0)

    # Combine vertices using concatenation
    vertices = Nx.concatenate([prim1.vertices, prim2.vertices], axis: 0)

    # Combine indices with offset for second primitive
    offset_indices = Nx.add(prim2.indices, vertex_offset)
    indices = Nx.concatenate([prim1.indices, offset_indices])

    # Combine normals and UVs
    normals = Nx.concatenate([prim1.normals, prim2.normals], axis: 0)
    uvs = Nx.concatenate([prim1.uvs, prim2.uvs], axis: 0)

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  @doc """
  Calculate bounding box of a primitive using Nx reduction operations.

  ## Examples

      iex> prim = AriaMath.Primitives.Tensor.box_nx()
      iex> {min_coords, max_coords} = AriaMath.Primitives.Tensor.bounding_box_nx(prim)
      iex> Nx.shape(min_coords)
      {3}
  """
  @spec bounding_box_nx(primitive_tensor()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  def bounding_box_nx(primitive) do
    min_coords = Nx.reduce_min(primitive.vertices, axes: [0])
    max_coords = Nx.reduce_max(primitive.vertices, axes: [0])
    {min_coords, max_coords}
  end

  @doc """
  Scale a primitive by a factor using tensor operations.

  ## Examples

      iex> prim = AriaMath.Primitives.Tensor.box_nx()
      iex> scaled = AriaMath.Primitives.Tensor.scale_nx(prim, 2.0)
      iex> Nx.shape(scaled.vertices)
      {8, 3}
  """
  @spec scale_nx(primitive_tensor(), float()) :: primitive_tensor()
  def scale_nx(primitive, factor) when is_number(factor) do
    scaled_vertices = Nx.multiply(primitive.vertices, factor)
    %{primitive | vertices: scaled_vertices}
  end

  @doc """
  Translate a primitive by an offset using tensor operations.

  ## Examples

      iex> prim = AriaMath.Primitives.Tensor.box_nx()
      iex> translated = AriaMath.Primitives.Tensor.translate_nx(prim, {1.0, 2.0, 3.0})
      iex> Nx.shape(translated.vertices)
      {8, 3}
  """
  @spec translate_nx(primitive_tensor(), {float(), float(), float()}) :: primitive_tensor()
  def translate_nx(primitive, {x, y, z}) do
    offset = Nx.tensor([x, y, z], type: :f32)
    translated_vertices = Nx.add(primitive.vertices, offset)
    %{primitive | vertices: translated_vertices}
  end

  # Helper functions for sphere generation using Nx operations

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
