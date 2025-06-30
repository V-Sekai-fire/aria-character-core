# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath do
  @moduledoc """
  AriaMath provides mathematical operations and data structures for the Aria project.

  This module serves as the main entry point for mathematical functionality, including:

  - Vector and quaternion operations (`AriaMath.Vector3`, `AriaMath.Quaternion`)
  - Matrix operations (`AriaMath.Matrix4`)
  - Mathematical primitives following KHR Interactivity spec (`AriaMath.Primitives`)
  - Transform hierarchy management (`AriaMath.Joint`)
  - Optimal superposition calculations (`AriaMath.QCP`)

  ## External API Functions

  This module provides a clean external API for common mathematical operations while
  delegating to internal modules for implementation details.

  ## Examples

      # Vector operations
      v1 = {1.0, 0.0, 0.0}
      v2 = {0.0, 1.0, 0.0}
      result = AriaMath.cross_product(v1, v2)

      # Matrix operations
      matrix = AriaMath.identity_matrix()
      transformed = AriaMath.multiply_matrices(matrix, matrix)

      # Quaternion operations
      q = AriaMath.identity_quaternion()
      normalized = AriaMath.normalize_quaternion(q)

  """

  alias AriaMath.{Vector3, Quaternion, Matrix4, Primitives, Joint, QCP}

  ## Vector Operations

  @doc """
  Create a new 3D vector.

  ## Examples

      iex> AriaMath.vector3(1.0, 2.0, 3.0)
      {1.0, 2.0, 3.0}
  """
  @spec vector3(float(), float(), float()) :: Vector3.t()
  def vector3(x, y, z), do: Vector3.new(x, y, z)

  @doc """
  Calculate vector cross product.

  ## Examples

      iex> AriaMath.cross_product({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 1.0}
  """
  @spec cross_product(Vector3.t(), Vector3.t()) :: Vector3.t()
  def cross_product(v1, v2), do: Vector3.cross(v1, v2)

  @doc """
  Calculate vector dot product.

  ## Examples

      iex> AriaMath.dot_product({1.0, 0.0, 0.0}, {1.0, 0.0, 0.0})
      1.0
  """
  @spec dot_product(Vector3.t(), Vector3.t()) :: float()
  def dot_product(v1, v2), do: Vector3.dot(v1, v2)

  @doc """
  Calculate vector length.

  ## Examples

      iex> AriaMath.vector_length({3.0, 4.0, 0.0})
      5.0
  """
  @spec vector_length(Vector3.t()) :: float()
  def vector_length(v), do: Vector3.length(v)

  @doc """
  Normalize a vector.

  ## Examples

      iex> {normalized, true} = AriaMath.normalize_vector({3.0, 4.0, 0.0})
      iex> AriaMath.vector_length(normalized)
      1.0
  """
  @spec normalize_vector(Vector3.t()) :: {Vector3.t(), boolean()}
  def normalize_vector(v), do: Vector3.normalize(v)

  @doc """
  Add two vectors.

  ## Examples

      iex> AriaMath.add_vectors({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {5.0, 7.0, 9.0}
  """
  @spec add_vectors(Vector3.t(), Vector3.t()) :: Vector3.t()
  def add_vectors(v1, v2), do: Vector3.add(v1, v2)

  @doc """
  Subtract two vectors.

  ## Examples

      iex> AriaMath.subtract_vectors({4.0, 5.0, 6.0}, {1.0, 2.0, 3.0})
      {3.0, 3.0, 3.0}
  """
  @spec subtract_vectors(Vector3.t(), Vector3.t()) :: Vector3.t()
  def subtract_vectors(v1, v2), do: Vector3.sub(v1, v2)

  @doc """
  Scale a vector by a scalar.

  ## Examples

      iex> AriaMath.scale_vector({1.0, 2.0, 3.0}, 2.0)
      {2.0, 4.0, 6.0}
  """
  @spec scale_vector(Vector3.t(), float()) :: Vector3.t()
  def scale_vector(v, scalar), do: Vector3.mul_scalar(v, scalar)

  ## Quaternion Operations

  @doc """
  Create a new quaternion.

  ## Examples

      iex> AriaMath.quaternion(0.0, 0.0, 0.0, 1.0)
      {0.0, 0.0, 0.0, 1.0}
  """
  @spec quaternion(float(), float(), float(), float()) :: Quaternion.t()
  def quaternion(x, y, z, w), do: Quaternion.new(x, y, z, w)

  @doc """
  Create identity quaternion.

  ## Examples

      iex> AriaMath.identity_quaternion()
      {0.0, 0.0, 0.0, 1.0}
  """
  @spec identity_quaternion() :: Quaternion.t()
  def identity_quaternion(), do: Quaternion.identity()

  @doc """
  Normalize a quaternion.

  ## Examples

      iex> {normalized, true} = AriaMath.normalize_quaternion({0.0, 0.0, 0.0, 2.0})
      iex> {_, _, _, w} = normalized
      iex> abs(w - 1.0) < 1.0e-10
      true
  """
  @spec normalize_quaternion(Quaternion.t()) :: {Quaternion.t(), boolean()}
  def normalize_quaternion(q), do: Quaternion.normalize(q)

  @doc """
  Multiply two quaternions.

  ## Examples

      iex> q1 = AriaMath.identity_quaternion()
      iex> q2 = AriaMath.identity_quaternion()
      iex> AriaMath.multiply_quaternions(q1, q2)
      {0.0, 0.0, 0.0, 1.0}
  """
  @spec multiply_quaternions(Quaternion.t(), Quaternion.t()) :: Quaternion.t()
  def multiply_quaternions(q1, q2), do: Quaternion.multiply(q1, q2)

  @doc """
  Create quaternion from axis and angle.

  ## Examples

      iex> axis = {0.0, 0.0, 1.0}
      iex> angle = :math.pi() / 2.0
      iex> q = AriaMath.quaternion_from_axis_angle(axis, angle)
      iex> {_, _, z, w} = q
      iex> abs(z - :math.sin(:math.pi() / 4.0)) < 1.0e-10
      true
  """
  @spec quaternion_from_axis_angle(Vector3.t(), float()) :: Quaternion.t()
  def quaternion_from_axis_angle(axis, angle), do: Quaternion.from_axis_angle(axis, angle)

  @doc """
  Rotate a vector by a quaternion.

  ## Examples

      iex> vector = {1.0, 0.0, 0.0}
      iex> rotation = AriaMath.identity_quaternion()
      iex> AriaMath.rotate_vector(rotation, vector)
      {1.0, 0.0, 0.0}
  """
  @spec rotate_vector(Quaternion.t(), Vector3.t()) :: Vector3.t()
  def rotate_vector(q, v), do: Quaternion.rotate_vector(q, v)

  ## Matrix Operations

  @doc """
  Create identity matrix.

  ## Examples

      iex> matrix = AriaMath.identity_matrix()
      iex> {m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15} = matrix
      iex> m0 == 1.0 and m5 == 1.0 and m10 == 1.0 and m15 == 1.0
      true
  """
  @spec identity_matrix() :: Matrix4.t()
  def identity_matrix(), do: Matrix4.identity()

  @doc """
  Multiply two matrices.

  ## Examples

      iex> m1 = AriaMath.identity_matrix()
      iex> m2 = AriaMath.identity_matrix()
      iex> AriaMath.multiply_matrices(m1, m2)
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  @spec multiply_matrices(Matrix4.t(), Matrix4.t()) :: Matrix4.t()
  def multiply_matrices(m1, m2), do: Matrix4.multiply(m1, m2)

  @doc """
  Create translation matrix.

  ## Examples

      iex> translation = {1.0, 2.0, 3.0}
      iex> matrix = AriaMath.translation_matrix(translation)
      iex> {_, _, _, _, _, _, _, _, _, _, _, _, tx, ty, tz, _} = matrix
      iex> {tx, ty, tz} == translation
      true
  """
  @spec translation_matrix(Vector3.t()) :: Matrix4.t()
  def translation_matrix(translation), do: Matrix4.translation(translation)

  @doc """
  Create scaling matrix.

  ## Examples

      iex> scale = {2.0, 3.0, 4.0}
      iex> matrix = AriaMath.scaling_matrix(scale)
      iex> {sx, _, _, _, _, sy, _, _, _, _, sz, _, _, _, _, _} = matrix
      iex> {sx, sy, sz} == scale
      true
  """
  @spec scaling_matrix(Vector3.t()) :: Matrix4.t()
  def scaling_matrix(scale), do: Matrix4.scaling(scale)

  @doc """
  Create rotation matrix from quaternion.

  ## Examples

      iex> q = AriaMath.identity_quaternion()
      iex> matrix = AriaMath.rotation_matrix(q)
      iex> matrix == AriaMath.identity_matrix()
      true
  """
  @spec rotation_matrix(Quaternion.t()) :: Matrix4.t()
  def rotation_matrix(q), do: Matrix4.rotation(q)

  @doc """
  Transform a point with a matrix.

  ## Examples

      iex> point = {1.0, 2.0, 3.0}
      iex> matrix = AriaMath.identity_matrix()
      iex> AriaMath.transform_point(matrix, point)
      {1.0, 2.0, 3.0}
  """
  @spec transform_point(Matrix4.t(), Vector3.t()) :: Vector3.t()
  def transform_point(matrix, point), do: Matrix4.transform_point(matrix, point)

  @doc """
  Calculate matrix determinant.

  ## Examples

      iex> matrix = AriaMath.identity_matrix()
      iex> AriaMath.matrix_determinant(matrix)
      1.0
  """
  @spec matrix_determinant(Matrix4.t()) :: float()
  def matrix_determinant(matrix), do: Matrix4.determinant(matrix)

  ## Mathematical Primitives

  @doc """
  Calculate absolute value of a float.

  ## Examples

      iex> AriaMath.abs_float(-5.5)
      5.5
  """
  @spec abs_float(float()) :: float()
  def abs_float(x), do: Primitives.abs_float(x)

  @doc """
  Calculate sine of an angle in radians.

  ## Examples

      iex> result = AriaMath.sin_float(:math.pi() / 2.0)
      iex> abs(result - 1.0) < 1.0e-10
      true
  """
  @spec sin_float(float()) :: float()
  def sin_float(x), do: Primitives.sin_float(x)

  @doc """
  Calculate cosine of an angle in radians.

  ## Examples

      iex> result = AriaMath.cos_float(0.0)
      iex> abs(result - 1.0) < 1.0e-10
      true
  """
  @spec cos_float(float()) :: float()
  def cos_float(x), do: Primitives.cos_float(x)

  @doc """
  Calculate square root.

  ## Examples

      iex> AriaMath.sqrt_float(4.0)
      2.0
  """
  @spec sqrt_float(float()) :: float()
  def sqrt_float(x), do: Primitives.sqrt_float(x)

  @doc """
  Clamp a value between minimum and maximum.

  ## Examples

      iex> AriaMath.clamp_float(5.0, 0.0, 3.0)
      3.0
  """
  @spec clamp_float(float(), float(), float()) :: float()
  def clamp_float(value, min_val, max_val), do: Primitives.clamp_float(value, min_val, max_val)

  ## Transform Hierarchy (Joint Operations)

  @doc """
  Create a new joint for transform hierarchy.

  ## Examples

      iex> {:ok, joint} = AriaMath.create_joint()
      iex> is_map(joint)
      true
  """
  @spec create_joint(keyword()) :: {:ok, Joint.t()} | {:error, term()}
  def create_joint(opts \\ []), do: Joint.new(opts)

  @doc """
  Set transform of a joint.

  ## Examples

      iex> {:ok, joint} = AriaMath.create_joint()
      iex> transform = AriaMath.identity_matrix()
      iex> updated_joint = AriaMath.set_joint_transform(joint, transform)
      iex> is_map(updated_joint)
      true
  """
  @spec set_joint_transform(Joint.t(), Matrix4.t()) :: Joint.t() | {:error, term()}
  def set_joint_transform(joint, transform), do: Joint.set_transform(joint, transform)

  @doc """
  Get global transform of a joint.

  ## Examples

      iex> {:ok, joint} = AriaMath.create_joint()
      iex> transform = AriaMath.get_joint_global_transform(joint)
      iex> transform == AriaMath.identity_matrix()
      true
  """
  @spec get_joint_global_transform(Joint.t()) :: Matrix4.t()
  def get_joint_global_transform(joint), do: Joint.get_global_transform(joint)

  ## Optimal Superposition (QCP Operations)

  @doc """
  Calculate optimal rotation and translation to align two point sets.

  ## Examples

      iex> moved = [{1.0, 0.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}]
      iex> {:ok, {rotation, translation}} = AriaMath.superpose_points(moved, target)
      iex> is_tuple(rotation) and is_tuple(translation)
      true
  """
  @spec superpose_points([Vector3.t()], [Vector3.t()], [float()], boolean()) ::
          {:ok, {Quaternion.t(), Vector3.t()}} | {:error, term()}
  def superpose_points(moved, target, weights \\ [], translate \\ true) do
    QCP.weighted_superpose(moved, target, weights, translate)
  end

  ## Constants

  @doc """
  Mathematical constant π (pi).

  ## Examples

      iex> pi = AriaMath.pi()
      iex> abs(pi - 3.141592653589793) < 1.0e-10
      true
  """
  @spec pi() :: float()
  def pi(), do: Primitives.pi()

  @doc """
  Mathematical constant e (Euler's number).

  ## Examples

      iex> e = AriaMath.e()
      iex> abs(e - 2.718281828459045) < 1.0e-10
      true
  """
  @spec e() :: float()
  def e(), do: Primitives.e()

  ## Utility Functions

  @doc """
  Check if two vectors are approximately equal within tolerance.

  ## Examples

      iex> v1 = {1.0, 2.0, 3.0}
      iex> v2 = {1.0000001, 2.0000001, 3.0000001}
      iex> AriaMath.vectors_equal?(v1, v2, 1.0e-5)
      true
  """
  @spec vectors_equal?(Vector3.t(), Vector3.t(), float()) :: boolean()
  def vectors_equal?(v1, v2, tolerance \\ 1.0e-6), do: Vector3.equal?(v1, v2, tolerance)

  @doc """
  Check if two quaternions are approximately equal within tolerance.

  ## Examples

      iex> q1 = {0.0, 0.0, 0.0, 1.0}
      iex> q2 = {0.0000001, 0.0000001, 0.0000001, 1.0000001}
      iex> AriaMath.quaternions_equal?(q1, q2, 1.0e-5)
      true
  """
  @spec quaternions_equal?(Quaternion.t(), Quaternion.t(), float()) :: boolean()
  def quaternions_equal?(q1, q2, tolerance \\ 1.0e-6), do: Quaternion.equal?(q1, q2, tolerance)

  @doc """
  Check if two matrices are approximately equal within tolerance.

  ## Examples

      iex> m1 = AriaMath.identity_matrix()
      iex> m2 = AriaMath.identity_matrix()
      iex> AriaMath.matrices_equal?(m1, m2)
      true
  """
  @spec matrices_equal?(Matrix4.t(), Matrix4.t()) :: boolean()
  def matrices_equal?(m1, m2), do: Matrix4.equal?(m1, m2)
end
