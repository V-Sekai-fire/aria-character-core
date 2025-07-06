# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath do
  @moduledoc """
  Mathematical operations for 3D graphics and spatial calculations.

  This module provides the external API for the AriaMath application, delegating
  to specialized API modules for different mathematical domains:

  - Vector3 operations via `AriaMath.API.Vector3`
  - Quaternion operations via `AriaMath.API.Quaternion`
  - Matrix4 operations via `AriaMath.API.Matrix4`
  - Primitive operations via `AriaMath.API.Primitives`

  ## Vector3 Operations

  Basic 3D vector mathematics including addition, subtraction, dot and cross products,
  normalization, and distance calculations.

  ## Quaternion Operations

  Quaternion mathematics for 3D rotations including creation from axis-angle and Euler
  angles, multiplication, normalization, and vector rotation.

  ## Matrix4 Operations

  4x4 matrix operations for 3D transformations including identity, translation, scaling,
  rotation, multiplication, inversion, and decomposition.

  ## Primitive Operations

  Basic mathematical utilities including clamping, interpolation, angle conversion,
  and floating-point comparisons.
  """

  # Vector3 operations
  defdelegate vector3(x, y, z), to: AriaMath.API.Vector3
  defdelegate add_vectors(v1, v2), to: AriaMath.API.Vector3
  defdelegate subtract_vectors(v1, v2), to: AriaMath.API.Vector3
  defdelegate scale_vector(vector, scalar), to: AriaMath.API.Vector3
  defdelegate dot_product(v1, v2), to: AriaMath.API.Vector3
  defdelegate cross_product(v1, v2), to: AriaMath.API.Vector3
  defdelegate vector_length(vector), to: AriaMath.API.Vector3
  defdelegate normalize_vector(vector), to: AriaMath.API.Vector3
  defdelegate distance(point1, point2), to: AriaMath.API.Vector3
  defdelegate lerp(v1, v2, t), to: AriaMath.API.Vector3

  # Quaternion operations
  defdelegate quaternion(x, y, z, w), to: AriaMath.API.Quaternion
  defdelegate identity_quaternion(), to: AriaMath.API.Quaternion
  defdelegate quaternion_from_axis_angle(axis, angle), to: AriaMath.API.Quaternion
  defdelegate quaternion_from_euler(yaw, pitch, roll), to: AriaMath.API.Quaternion
  defdelegate quaternion_multiply(q1, q2), to: AriaMath.API.Quaternion
  defdelegate multiply_quaternions(q1, q2), to: AriaMath.API.Quaternion
  defdelegate quaternion_normalize(quaternion), to: AriaMath.API.Quaternion
  defdelegate normalize_quaternion(quaternion), to: AriaMath.API.Quaternion
  defdelegate quaternion_rotate(quaternion, vector), to: AriaMath.API.Quaternion
  defdelegate quaternion_conjugate(quaternion), to: AriaMath.API.Quaternion
  defdelegate quaternion_slerp(q1, q2, t), to: AriaMath.API.Quaternion

  # Matrix4 operations
  defdelegate matrix4_identity(), to: AriaMath.API.Matrix4
  defdelegate identity_matrix(), to: AriaMath.API.Matrix4
  defdelegate matrix4_translation(translation), to: AriaMath.API.Matrix4
  defdelegate translation_matrix(translation), to: AriaMath.API.Matrix4
  defdelegate matrix4_scaling(scale), to: AriaMath.API.Matrix4
  defdelegate scaling_matrix(scale), to: AriaMath.API.Matrix4
  defdelegate matrix4_rotation(quaternion), to: AriaMath.API.Matrix4
  defdelegate rotation_matrix(quaternion), to: AriaMath.API.Matrix4
  defdelegate matrix4_multiply(m1, m2), to: AriaMath.API.Matrix4
  defdelegate multiply_matrices(m1, m2), to: AriaMath.API.Matrix4
  defdelegate matrix4_transform_point(matrix, point), to: AriaMath.API.Matrix4
  defdelegate transform_point(matrix, point), to: AriaMath.API.Matrix4
  defdelegate matrix4_transform_direction(matrix, vector), to: AriaMath.API.Matrix4
  defdelegate matrix4_inverse(matrix), to: AriaMath.API.Matrix4
  defdelegate matrix4_transpose(matrix), to: AriaMath.API.Matrix4
  defdelegate matrix4_decompose(matrix), to: AriaMath.API.Matrix4
  defdelegate matrix4_compose(translation, rotation, scale), to: AriaMath.API.Matrix4
  defdelegate matrix_determinant(matrix), to: AriaMath.API.Matrix4

  # Primitive operations
  defdelegate abs_float(x), to: AriaMath.API.Primitives
  defdelegate clamp_float(value, min_val, max_val), to: AriaMath.API.Primitives
  defdelegate approximately_equal(a, b), to: AriaMath.API.Primitives
  defdelegate approximately_equal(a, b, tolerance), to: AriaMath.API.Primitives
  defdelegate clamp(value, min, max), to: AriaMath.API.Primitives
  defdelegate lerp_scalar(a, b, t), to: AriaMath.API.Primitives
  defdelegate deg_to_rad(degrees), to: AriaMath.API.Primitives
  defdelegate rad_to_deg(radians), to: AriaMath.API.Primitives
  defdelegate create_joint(opts), to: AriaMath.API.Primitives
end
