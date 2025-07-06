# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Matrix4.Tensor do
  @moduledoc """
  Nx tensor-based Matrix4 operations.

  This module provides a unified API for Matrix4 operations by delegating
  to specialized modules for different operation types:

  - `AriaMath.Matrix4.Core` - Basic matrix operations
  - `AriaMath.Matrix4.Batch` - Batch processing operations
  - `AriaMath.Matrix4.Memory` - Memory-optimized operations
  - `AriaMath.Matrix4.Transformations` - Transformation matrices

  Includes memory-optimized operations that prevent CUDA out-of-memory errors
  through intelligent chunking and automatic CPU fallback mechanisms.
  """

  alias AriaMath.Matrix4.{Core, Batch, Memory, Transformations}

  @type matrix4_tensor :: Nx.Tensor.t()
  @type matrix4_tuple :: {
    float(), float(), float(), float(),
    float(), float(), float(), float(),
    float(), float(), float(), float(),
    float(), float(), float(), float()
  }

  # Core Operations - delegate to Core module
  defdelegate new(m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33), to: Core
  defdelegate from_tuple(tuple), to: Core
  defdelegate to_tuple(tensor), to: Core
  defdelegate identity(), to: Core
  defdelegate multiply(a, b), to: Core
  defdelegate transpose(matrix), to: Core
  defdelegate determinant(matrix), to: Core
  defdelegate invert(matrix), to: Core
  defdelegate equal?(a, b, tolerance \\ 1.0e-6), to: Core
  defdelegate transpose_nx(matrix), to: Core
  defdelegate inverse_nx(matrix), to: Core
  defdelegate to_tuple_list(matrix), to: Core
  defdelegate from_tuple_list(tuple_list), to: Core

  # Batch Operations - delegate to Batch module
  defdelegate multiply_batch(a_matrices, b_matrices), to: Batch
  defdelegate transpose_batch(matrices), to: Batch
  defdelegate determinant_batch(matrices), to: Batch
  defdelegate invert_batch(matrices), to: Batch
  defdelegate equal_batch?(m1_batch, m2_batch, tolerance \\ 1.0e-6), to: Batch
  defdelegate inverse_batch(matrices), to: Batch
  defdelegate scaling_batch(scale_vectors), to: Batch
  defdelegate lerp_batch(m1_batch, m2_batch, t_batch), to: Batch
  defdelegate extract_translations_batch(matrices), to: Batch
  defdelegate extract_rotations_batch(matrices), to: Batch

  # Memory-Optimized Operations - delegate to Memory module
  defdelegate multiply_batch_safe(matrices_a, matrices_b), to: Memory
  defdelegate transform_points_batch_multi_safe(transforms, points), to: Memory
  defdelegate transform_points_batch_multi(matrices, points), to: Memory
  defdelegate transform_points_batch_safe(matrices, points), to: Memory
  defdelegate invert_batch_safe(matrices), to: Memory
  defdelegate scaling_batch_safe(scale_vectors), to: Memory
  defdelegate lerp_batch_safe(m1_batch, m2_batch, t_batch), to: Memory
  defdelegate with_memory_monitoring(operation_fn), to: Memory
  defdelegate optimal_batch_size(tensor_shape), to: Memory
  defdelegate with_cpu_backend(operation_fn), to: Memory

  # Transformation Operations - delegate to Transformations module
  defdelegate translation(translation_vector), to: Transformations
  defdelegate translation_xyz(x, y, z), to: Transformations, as: :translation_xyz
  defdelegate scaling(scale_vector), to: Transformations
  defdelegate uniform_scaling(scale), to: Transformations
  defdelegate rotation_from_quaternion(quaternion), to: Transformations
  defdelegate rotation_x(angle_radians), to: Transformations
  defdelegate rotation_y(angle_radians), to: Transformations
  defdelegate rotation_z(angle_radians), to: Transformations
  defdelegate perspective(fov_y_degrees, aspect_ratio, near_plane, far_plane), to: Transformations
  defdelegate orthographic(left, right, bottom, top, near_plane, far_plane), to: Transformations
  defdelegate look_at(eye, target, up), to: Transformations
  defdelegate compose_trs(translation, rotation, scale), to: Transformations
  defdelegate decompose_trs(matrix), to: Transformations
  defdelegate transform_point(matrix, point), to: Transformations
  defdelegate transform_direction(matrix, direction), to: Transformations

  # Legacy API compatibility functions
  @doc """
  Transform a Vector3 by this matrix (treating vector as homogeneous coordinate with w=1).

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.identity()
      iex> vector = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> result = AriaMath.Matrix4.Tensor.transform_vector3(matrix, vector)
      iex> AriaMath.Vector3.Tensor.to_tuple(result)
      {1.0, 2.0, 3.0}
  """
  @spec transform_vector3(matrix4_tensor(), AriaMath.Vector3.Tensor.vector3_tensor()) :: AriaMath.Vector3.Tensor.vector3_tensor()
  def transform_vector3(matrix, vector) do
    Transformations.transform_point(matrix, vector)
  end

  @doc """
  Batch transform multiple Vector3s by multiple matrices.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> vectors = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
      iex> results = AriaMath.Matrix4.Tensor.transform_vector3_batch(matrices, vectors)
      iex> Nx.to_list(results)
      [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
  """
  @spec transform_vector3_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_vector3_batch(matrices, vectors) do
    # Add homogeneous coordinate (w=1) to all vectors
    ones = Nx.broadcast(1.0, {Nx.axis_size(vectors, 0), 1})
    homogeneous = Nx.concatenate([vectors, ones], axis: 1)

    # Transform by matrices (batch matrix-vector multiplication)
    transformed = Nx.dot(matrices, Nx.new_axis(homogeneous, -1))

    # Remove the last axis and extract x, y, z components
    squeezed = Nx.squeeze(transformed, axes: [-1])
    Nx.slice_along_axis(squeezed, 0, 3, axis: 1)
  end

  @doc """
  Creates a uniform scale matrix.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.scale(2.0)
      iex> # Check diagonal elements
      iex> diag = Nx.take_diagonal(matrix) |> Nx.to_list()
      iex> diag
      [2.0, 2.0, 2.0, 1.0]
  """
  @spec scale(float()) :: matrix4_tensor()
  def scale(factor) when is_number(factor) do
    Transformations.uniform_scaling(factor)
  end

  @doc """
  Creates a non-uniform scale matrix from a Vector3.

  ## Examples

      iex> scale_vec = AriaMath.Vector3.Tensor.new(2.0, 3.0, 4.0)
      iex> matrix = AriaMath.Matrix4.Tensor.scale_vector3(scale_vec)
      iex> diag = Nx.take_diagonal(matrix) |> Nx.to_list()
      iex> diag
      [2.0, 3.0, 4.0, 1.0]
  """
  @spec scale_vector3(AriaMath.Vector3.Tensor.vector3_tensor()) :: matrix4_tensor()
  def scale_vector3(vector) do
    Transformations.scaling(vector)
  end

  @doc """
  Create a translation matrix using Nx operations.

  ## Examples

      iex> trans = AriaMath.Matrix4.Tensor.translation_nx({1.0, 2.0, 3.0})
      iex> Nx.shape(trans)
      {4, 4}
  """
  @spec translation_nx({float(), float(), float()}) :: Nx.Tensor.t()
  def translation_nx({x, y, z}) do
    Transformations.translation_xyz(x, y, z)
  end

  @doc """
  Transform multiple points using a matrix with batch operations.

  Points are assumed to be homogeneous (w = 1.0) for transformation.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.translation_nx({1.0, 2.0, 3.0})
      iex> points = Nx.tensor([[0.0, 0.0, 0.0], [1.0, 1.0, 1.0]], type: :f32)
      iex> transformed = AriaMath.Matrix4.Tensor.transform_points_batch(matrix, points)
      iex> Nx.shape(transformed)
      {2, 3}
  """
  @spec transform_points_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_points_batch(matrix, points) do
    # Convert points to homogeneous coordinates by adding w = 1.0
    num_points = Nx.axis_size(points, 0)
    ones = Nx.broadcast(1.0, {num_points, 1})
    homogeneous_points = Nx.concatenate([points, ones], axis: 1)

    # Transform homogeneous points: matrix * points^T, then transpose back
    transformed_homo = Nx.dot(homogeneous_points, [1], matrix, [0])

    # Extract x, y, z components (drop w component)
    Nx.slice_along_axis(transformed_homo, 0, 3, axis: 1)
  end

  @doc """
  Transform multiple vectors using a matrix with batch operations.

  Vectors are assumed to be directions (w = 0.0) for transformation.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.identity()
      iex> vectors = Nx.tensor([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0]], type: :f32)
      iex> transformed = AriaMath.Matrix4.Tensor.transform_vectors_batch(matrix, vectors)
      iex> Nx.shape(transformed)
      {2, 3}
  """
  @spec transform_vectors_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_vectors_batch(matrix, vectors) do
    # Convert vectors to homogeneous coordinates by adding w = 0.0
    num_vectors = Nx.axis_size(vectors, 0)
    zeros = Nx.broadcast(0.0, {num_vectors, 1})
    homogeneous_vectors = Nx.concatenate([vectors, zeros], axis: 1)

    # Transform homogeneous vectors: matrix * vectors^T, then transpose back
    transformed_homo = Nx.dot(homogeneous_vectors, [1], matrix, [0])

    # Extract x, y, z components (drop w component)
    Nx.slice_along_axis(transformed_homo, 0, 3, axis: 1)
  end

  @doc """
  Create a scaling matrix using Nx operations.

  ## Examples

      iex> scale = AriaMath.Matrix4.Tensor.scaling_nx({2.0, 3.0, 4.0})
      iex> Nx.shape(scale)
      {4, 4}
  """
  @spec scaling_nx({float(), float(), float()}) :: Nx.Tensor.t()
  def scaling_nx({x, y, z}) do
    Transformations.scaling(AriaMath.Vector3.Tensor.new(x, y, z))
  end

  @doc """
  Create a rotation matrix around Y-axis using Nx operations.

  ## Examples

      iex> rot = AriaMath.Matrix4.Tensor.rotation_y_nx(:math.pi() / 2)
      iex> Nx.shape(rot)
      {4, 4}
  """
  @spec rotation_y_nx(float()) :: Nx.Tensor.t()
  def rotation_y_nx(angle) when is_number(angle) do
    Transformations.rotation_y(angle)
  end

  @doc """
  Create a rotation matrix around Z-axis using Nx operations.

  ## Examples

      iex> rot = AriaMath.Matrix4.Tensor.rotation_z_nx(:math.pi() / 2)
      iex> Nx.shape(rot)
      {4, 4}
  """
  @spec rotation_z_nx(float()) :: Nx.Tensor.t()
  def rotation_z_nx(angle) when is_number(angle) do
    Transformations.rotation_z(angle)
  end
end
