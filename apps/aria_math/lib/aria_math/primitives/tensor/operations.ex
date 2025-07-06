# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives.Tensor.Operations do
  @moduledoc """
  Transformation and manipulation operations for tensor-based primitives.

  This module provides functions to transform, merge, scale, and translate
  geometric primitives using efficient Nx tensor operations.
  """

  alias AriaMath.Vector3
  alias AriaMath.Matrix4
  alias AriaMath.Primitives.Tensor.Core

  @doc """
  Apply a transformation matrix to a primitive using batch operations.

  ## Examples

      iex> prim = AriaMath.Primitives.Tensor.Shapes.box_nx()
      iex> transform = Matrix4.translation_nx({1.0, 2.0, 3.0})
      iex> transformed = AriaMath.Primitives.Tensor.Operations.transform_nx(prim, transform)
      iex> Nx.shape(transformed.vertices)
      {8, 3}
  """
  @spec transform_nx(Core.primitive_tensor(), Nx.Tensor.t()) :: Core.primitive_tensor()
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

      iex> prim1 = AriaMath.Primitives.Tensor.Shapes.box_nx()
      iex> prim2 = AriaMath.Primitives.Tensor.Shapes.plane_nx()
      iex> merged = AriaMath.Primitives.Tensor.Operations.merge_nx(prim1, prim2)
      iex> Nx.shape(merged.vertices)
      {12, 3}  # 8 + 4 vertices
  """
  @spec merge_nx(Core.primitive_tensor(), Core.primitive_tensor()) :: Core.primitive_tensor()
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
  Scale a primitive by a factor using tensor operations.

  ## Examples

      iex> prim = AriaMath.Primitives.Tensor.Shapes.box_nx()
      iex> scaled = AriaMath.Primitives.Tensor.Operations.scale_nx(prim, 2.0)
      iex> Nx.shape(scaled.vertices)
      {8, 3}
  """
  @spec scale_nx(Core.primitive_tensor(), float()) :: Core.primitive_tensor()
  def scale_nx(primitive, factor) when is_number(factor) do
    scaled_vertices = Nx.multiply(primitive.vertices, factor)
    %{primitive | vertices: scaled_vertices}
  end

  @doc """
  Translate a primitive by an offset using tensor operations.

  ## Examples

      iex> prim = AriaMath.Primitives.Tensor.Shapes.box_nx()
      iex> translated = AriaMath.Primitives.Tensor.Operations.translate_nx(prim, {1.0, 2.0, 3.0})
      iex> Nx.shape(translated.vertices)
      {8, 3}
  """
  @spec translate_nx(Core.primitive_tensor(), {float(), float(), float()}) :: Core.primitive_tensor()
  def translate_nx(primitive, {x, y, z}) do
    offset = Nx.tensor([x, y, z], type: :f32)
    translated_vertices = Nx.add(primitive.vertices, offset)
    %{primitive | vertices: translated_vertices}
  end
end
