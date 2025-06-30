# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath do
  @moduledoc """
  Mathematical operations and data structures for 3D graphics and spatial computing.

  AriaMath provides essential mathematical primitives for 3D graphics, spatial
  computing, and coordinate transformations. This library includes optimized
  implementations of vectors, quaternions, matrices, and geometric primitives.

  ## Core Components

  - **Vector3**: 3D vector operations (addition, scaling, cross/dot products)
  - **Quaternion**: Rotation representation with efficient composition
  - **Matrix4**: 4x4 transformation matrices for 3D graphics
  - **Primitives**: Basic geometric primitives and calculations

  ## Usage

      # Vector operations
      v1 = {1.0, 2.0, 3.0}
      v2 = {4.0, 5.0, 6.0}
      result = AriaMath.add(v1, v2)

      # Quaternion rotations
      q = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      rotated = AriaMath.quaternion_rotate(q, {1.0, 0.0, 0.0})

      # Matrix transformations
      matrix = AriaMath.matrix4_translation({1.0, 2.0, 3.0})
      point = AriaMath.matrix4_transform_point(matrix, {0.0, 0.0, 0.0})

  ## Design Principles

  - **Performance**: Optimized for real-time 3D graphics applications
  - **Precision**: Careful handling of floating-point precision issues
  - **Interoperability**: Standard tuple-based representations for compatibility
  - **Safety**: Input validation and robust error handling
  """

  # Vector3 operations
  alias AriaMath.Vector3

  @doc """
  Create a 3D vector from three components.

  ## Examples

      iex> AriaMath.vector3(1.0, 2.0, 3.0)
      {1.0, 2.0, 3.0}
  """
  def vector3(x, y, z), do: Vector3.new(x, y, z)

  @doc """
  Add two 3D vectors component-wise.

  ## Examples

      iex> AriaMath.add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {5.0, 7.0, 9.0}
  """
  defdelegate add(v1, v2), to: Vector3

  @doc """
  Add two 3D vectors component-wise (alias for add/2).

  ## Examples

      iex> AriaMath.add_vectors({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {5.0, 7.0, 9.0}
  """
  defdelegate add_vectors(v1, v2), to: Vector3, as: :add

  @doc """
  Subtract two 3D vectors component-wise.

  ## Examples

      iex> AriaMath.subtract({4.0, 5.0, 6.0}, {1.0, 2.0, 3.0})
      {3.0, 3.0, 3.0}
  """
  defdelegate subtract(v1, v2), to: Vector3, as: :sub

  @doc """
  Subtract two 3D vectors component-wise (alias for subtract/2).

  ## Examples

      iex> AriaMath.subtract_vectors({4.0, 5.0, 6.0}, {1.0, 2.0, 3.0})
      {3.0, 3.0, 3.0}
  """
  defdelegate subtract_vectors(v1, v2), to: Vector3, as: :sub

  @doc """
  Scale a 3D vector by a scalar value.

  ## Examples

      iex> AriaMath.scale({1.0, 2.0, 3.0}, 2.0)
      {2.0, 4.0, 6.0}
  """
  defdelegate scale(vector, scalar), to: Vector3

  @doc """
  Scale a 3D vector by a scalar value (alias for scale/2).

  ## Examples

      iex> AriaMath.scale_vector({1.0, 2.0, 3.0}, 2.0)
      {2.0, 4.0, 6.0}
  """
  defdelegate scale_vector(vector, scalar), to: Vector3, as: :scale

  @doc """
  Compute the dot product of two 3D vectors.

  ## Examples

      iex> AriaMath.dot({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      32.0
  """
  defdelegate dot(v1, v2), to: Vector3

  @doc """
  Compute the dot product of two 3D vectors (alias for dot/2).

  ## Examples

      iex> AriaMath.dot_product({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      32.0
  """
  defdelegate dot_product(v1, v2), to: Vector3, as: :dot

  @doc """
  Compute the cross product of two 3D vectors.

  ## Examples

      iex> AriaMath.cross({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 1.0}
  """
  defdelegate cross(v1, v2), to: Vector3

  @doc """
  Compute the cross product of two 3D vectors (alias for cross/2).

  ## Examples

      iex> AriaMath.cross_product({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 1.0}
  """
  defdelegate cross_product(v1, v2), to: Vector3, as: :cross

  @doc """
  Compute the length (magnitude) of a 3D vector.

  ## Examples

      iex> AriaMath.length({3.0, 4.0, 0.0})
      5.0
  """
  defdelegate length(vector), to: Vector3

  @doc """
  Compute the length (magnitude) of a 3D vector (alias for length/1).

  ## Examples

      iex> AriaMath.vector_length({3.0, 4.0, 0.0})
      5.0
  """
  defdelegate vector_length(vector), to: Vector3, as: :length

  @doc """
  Normalize a 3D vector to unit length.

  ## Examples

      iex> AriaMath.normalize({3.0, 4.0, 0.0})
      {{0.6, 0.8, 0.0}, true}
  """
  def normalize(vector) do
    {normalized, _valid} = Vector3.normalize(vector)
    normalized
  end

  @doc """
  Normalize a 3D vector to unit length (alias for normalize/1).

  ## Examples

      iex> AriaMath.normalize_vector({3.0, 4.0, 0.0})
      {{0.6, 0.8, 0.0}, true}
  """
  defdelegate normalize_vector(vector), to: Vector3, as: :normalize

  @doc """
  Compute distance between two 3D points.

  ## Examples

      iex> AriaMath.distance({0.0, 0.0, 0.0}, {3.0, 4.0, 0.0})
      5.0
  """
  defdelegate distance(point1, point2), to: Vector3

  @doc """
  Linear interpolation between two 3D vectors.

  ## Examples

      iex> AriaMath.lerp({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}, 0.5)
      {0.5, 0.5, 0.5}
  """
  defdelegate lerp(v1, v2, t), to: Vector3

  @doc """
  Compute the absolute value of a float.

  ## Examples

      iex> AriaMath.abs_float(-5.0)
      5.0
  """
  def abs_float(x) when is_number(x), do: abs(x)

  @doc """
  Clamp a float value between minimum and maximum bounds.

  ## Examples

      iex> AriaMath.clamp_float(5.0, 0.0, 10.0)
      5.0

      iex> AriaMath.clamp_float(-1.0, 0.0, 10.0)
      0.0

      iex> AriaMath.clamp_float(15.0, 0.0, 10.0)
      10.0
  """
  def clamp_float(value, min_val, max_val) when is_number(value) and is_number(min_val) and is_number(max_val) do
    cond do
      value < min_val -> min_val
      value > max_val -> max_val
      true -> value
    end
  end

  # Quaternion operations
  alias AriaMath.Quaternion

  @doc """
  Create a quaternion from four components.

  ## Examples

      iex> AriaMath.quaternion(0.0, 0.0, 0.0, 1.0)
      {0.0, 0.0, 0.0, 1.0}
  """
  def quaternion(x, y, z, w), do: {x / 1, y / 1, z / 1, w / 1}

  @doc """
  Create an identity quaternion.

  ## Examples

      iex> AriaMath.identity_quaternion()
      {0.0, 0.0, 0.0, 1.0}
  """
  def identity_quaternion(), do: {0.0, 0.0, 0.0, 1.0}

  @doc """
  Create a quaternion from axis-angle representation.

  ## Examples

      iex> AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      {0.0, 0.0, 0.7071067811865476, 0.7071067811865475}
  """
  defdelegate quaternion_from_axis_angle(axis, angle), to: Quaternion, as: :from_axis_angle

  @doc """
  Create a quaternion from Euler angles (yaw, pitch, roll).

  ## Examples

      iex> AriaMath.quaternion_from_euler(0.0, 0.0, :math.pi / 2)
      {0.0, 0.0, 0.7071067811865476, 0.7071067811865475}
  """
  defdelegate quaternion_from_euler(yaw, pitch, roll), to: Quaternion, as: :from_euler

  @doc """
  Multiply two quaternions (compose rotations).

  ## Examples

      q1 = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      q2 = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      result = AriaMath.quaternion_multiply(q1, q2)
  """
  defdelegate quaternion_multiply(q1, q2), to: Quaternion, as: :multiply

  @doc """
  Multiply two quaternions (alias for quaternion_multiply/2).

  ## Examples

      q1 = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      q2 = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      result = AriaMath.multiply_quaternions(q1, q2)
  """
  defdelegate multiply_quaternions(q1, q2), to: Quaternion, as: :multiply

  @doc """
  Normalize a quaternion to unit length.

  ## Examples

      q = {0.0, 0.0, 1.0, 1.0}
      normalized = AriaMath.quaternion_normalize(q)
  """
  def quaternion_normalize(quaternion) do
    {normalized, _valid} = Quaternion.normalize(quaternion)
    normalized
  end

  @doc """
  Normalize a quaternion to unit length (alias for quaternion_normalize/1).

  ## Examples

      q = {0.0, 0.0, 1.0, 1.0}
      normalized = AriaMath.normalize_quaternion(q)
  """
  defdelegate normalize_quaternion(quaternion), to: Quaternion, as: :normalize

  @doc """
  Rotate a 3D vector by a quaternion.

  ## Examples

      q = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      rotated = AriaMath.quaternion_rotate(q, {1.0, 0.0, 0.0})
  """
  defdelegate quaternion_rotate(quaternion, vector), to: Quaternion, as: :rotate

  @doc """
  Compute the conjugate of a quaternion.

  ## Examples

      q = {1.0, 2.0, 3.0, 4.0}
      conjugate = AriaMath.quaternion_conjugate(q)
  """
  defdelegate quaternion_conjugate(quaternion), to: Quaternion, as: :conjugate

  @doc """
  Spherical linear interpolation between two quaternions.

  ## Examples

      q1 = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, 0.0)
      q2 = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      result = AriaMath.quaternion_slerp(q1, q2, 0.5)
  """
  defdelegate quaternion_slerp(q1, q2, t), to: Quaternion, as: :slerp

  # Matrix4 operations
  alias AriaMath.Matrix4

  @doc """
  Create a 4x4 identity matrix.

  ## Examples

      iex> AriaMath.matrix4_identity()
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate matrix4_identity(), to: Matrix4, as: :identity

  @doc """
  Create a 4x4 identity matrix (alias for matrix4_identity/0).

  ## Examples

      iex> AriaMath.identity_matrix()
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate identity_matrix(), to: Matrix4, as: :identity

  @doc """
  Create a translation matrix.

  ## Examples

      iex> AriaMath.matrix4_translation({1.0, 2.0, 3.0})
      {1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate matrix4_translation(translation), to: Matrix4, as: :translation

  @doc """
  Create a translation matrix (alias for matrix4_translation/1).

  ## Examples

      iex> AriaMath.translation_matrix({1.0, 2.0, 3.0})
      {1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate translation_matrix(translation), to: Matrix4, as: :translation

  @doc """
  Create a scaling matrix.

  ## Examples

      iex> AriaMath.matrix4_scaling({2.0, 3.0, 4.0})
      {2.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate matrix4_scaling(scale), to: Matrix4, as: :scaling

  @doc """
  Create a scaling matrix (alias for matrix4_scaling/1).

  ## Examples

      iex> AriaMath.scaling_matrix({2.0, 3.0, 4.0})
      {2.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate scaling_matrix(scale), to: Matrix4, as: :scaling

  @doc """
  Create a rotation matrix from a quaternion.

  ## Examples

      q = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      matrix = AriaMath.matrix4_rotation(q)
  """
  defdelegate matrix4_rotation(quaternion), to: Matrix4, as: :rotation

  @doc """
  Create a rotation matrix from a quaternion (alias for matrix4_rotation/1).

  ## Examples

      q = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      matrix = AriaMath.rotation_matrix(q)
  """
  defdelegate rotation_matrix(quaternion), to: Matrix4, as: :rotation

  @doc """
  Multiply two 4x4 matrices.

  ## Examples

      m1 = AriaMath.matrix4_translation({1.0, 0.0, 0.0})
      m2 = AriaMath.matrix4_scaling({2.0, 2.0, 2.0})
      result = AriaMath.matrix4_multiply(m1, m2)
  """
  defdelegate matrix4_multiply(m1, m2), to: Matrix4, as: :multiply

  @doc """
  Multiply two 4x4 matrices (alias for matrix4_multiply/2).

  ## Examples

      m1 = AriaMath.matrix4_translation({1.0, 0.0, 0.0})
      m2 = AriaMath.matrix4_scaling({2.0, 2.0, 2.0})
      result = AriaMath.multiply_matrices(m1, m2)
  """
  defdelegate multiply_matrices(m1, m2), to: Matrix4, as: :multiply

  @doc """
  Transform a 3D point by a 4x4 matrix.

  ## Examples

      matrix = AriaMath.matrix4_translation({1.0, 2.0, 3.0})
      transformed = AriaMath.matrix4_transform_point(matrix, {0.0, 0.0, 0.0})
  """
  defdelegate matrix4_transform_point(matrix, point), to: Matrix4, as: :transform_point

  @doc """
  Transform a 3D point by a 4x4 matrix (alias for matrix4_transform_point/2).

  ## Examples

      matrix = AriaMath.matrix4_translation({1.0, 2.0, 3.0})
      transformed = AriaMath.transform_point(matrix, {0.0, 0.0, 0.0})
  """
  defdelegate transform_point(matrix, point), to: Matrix4, as: :transform_point

  @doc """
  Transform a 3D direction by a 4x4 matrix (ignores translation).

  ## Examples

      matrix = AriaMath.matrix4_scaling({2.0, 2.0, 2.0})
      transformed = AriaMath.matrix4_transform_direction(matrix, {1.0, 1.0, 1.0})
  """
  defdelegate matrix4_transform_direction(matrix, vector), to: Matrix4, as: :transform_direction

  @doc """
  Compute the inverse of a 4x4 matrix.

  ## Examples

      matrix = AriaMath.matrix4_translation({1.0, 2.0, 3.0})
      {inverse, valid} = AriaMath.matrix4_inverse(matrix)
  """
  defdelegate matrix4_inverse(matrix), to: Matrix4, as: :inverse

  @doc """
  Compute the transpose of a 4x4 matrix.

  ## Examples

      matrix = AriaMath.matrix4_translation({1.0, 2.0, 3.0})
      transposed = AriaMath.matrix4_transpose(matrix)
  """
  defdelegate matrix4_transpose(matrix), to: Matrix4, as: :transpose

  @doc """
  Decompose a 4x4 transformation matrix into translation, rotation, and scale.

  ## Examples

      matrix = AriaMath.matrix4_translation({1.0, 2.0, 3.0})
      {translation, rotation, scale} = AriaMath.matrix4_decompose(matrix)
  """
  defdelegate matrix4_decompose(matrix), to: Matrix4, as: :decompose

  @doc """
  Compose a 4x4 transformation matrix from translation, rotation, and scale.

  ## Examples

      translation = {1.0, 2.0, 3.0}
      rotation = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      scale = {2.0, 2.0, 2.0}
      matrix = AriaMath.matrix4_compose(translation, rotation, scale)
  """
  defdelegate matrix4_compose(translation, rotation, scale), to: Matrix4, as: :compose

  @doc """
  Compute the determinant of a 4x4 matrix.

  ## Examples

      matrix = AriaMath.matrix4_identity()
      det = AriaMath.matrix_determinant(matrix)
  """
  defdelegate matrix_determinant(matrix), to: Matrix4, as: :determinant

  @doc """
  Create a joint with the given options.

  ## Examples

      joint = AriaMath.create_joint(%{})
  """
  def create_joint(_opts) do
    # Basic joint implementation - should be moved to AriaJoint app
    %{
      id: make_ref(),
      transform: matrix4_identity(),
      parent: nil,
      children: []
    }
  end

  # Primitives operations
  alias AriaMath.Primitives

  @doc """
  Check if two floating-point numbers are approximately equal.

  ## Examples

      iex> AriaMath.approximately_equal(1.0, 1.0000001)
      true

      iex> AriaMath.approximately_equal(1.0, 1.1)
      false
  """
  defdelegate approximately_equal(a, b), to: Primitives

  @doc """
  Check if two floating-point numbers are approximately equal with custom tolerance.

  ## Examples

      iex> AriaMath.approximately_equal(1.0, 1.01, 0.1)
      true

      iex> AriaMath.approximately_equal(1.0, 1.01, 0.001)
      false
  """
  defdelegate approximately_equal(a, b, tolerance), to: Primitives

  @doc """
  Clamp a value between minimum and maximum bounds.

  ## Examples

      iex> AriaMath.clamp(5.0, 0.0, 10.0)
      5.0

      iex> AriaMath.clamp(-1.0, 0.0, 10.0)
      0.0

      iex> AriaMath.clamp(15.0, 0.0, 10.0)
      10.0
  """
  defdelegate clamp(value, min, max), to: Primitives

  @doc """
  Linear interpolation between two values.

  ## Examples

      iex> AriaMath.lerp_scalar(0.0, 10.0, 0.5)
      5.0

      iex> AriaMath.lerp_scalar(0.0, 10.0, 0.25)
      2.5
  """
  defdelegate lerp_scalar(a, b, t), to: Primitives, as: :lerp

  @doc """
  Convert degrees to radians.

  ## Examples

      iex> AriaMath.deg_to_rad(180.0)
      3.141592653589793

      iex> AriaMath.deg_to_rad(90.0)
      1.5707963267948966
  """
  defdelegate deg_to_rad(degrees), to: Primitives

  @doc """
  Convert radians to degrees.

  ## Examples

      iex> AriaMath.rad_to_deg(:math.pi)
      180.0

      iex> AriaMath.rad_to_deg(:math.pi / 2)
      90.0
  """
  defdelegate rad_to_deg(radians), to: Primitives
end
