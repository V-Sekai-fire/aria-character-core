# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.API.Matrix4 do
  @moduledoc """
  Matrix4 operations for the AriaMath external API.

  This module contains all Matrix4-related delegations and operations
  for the AriaMath external API, keeping the main API module focused.
  """

  alias AriaMath.Matrix4

  @doc """
  Create a 4x4 identity matrix.

  ## Examples

      iex> AriaMath.API.Matrix4.matrix4_identity()
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate matrix4_identity(), to: Matrix4, as: :identity

  @doc """
  Create a 4x4 identity matrix (alias for matrix4_identity/0).

  ## Examples

      iex> AriaMath.API.Matrix4.identity_matrix()
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate identity_matrix(), to: Matrix4, as: :identity

  @doc """
  Create a translation matrix.

  ## Examples

      iex> AriaMath.API.Matrix4.matrix4_translation({1.0, 2.0, 3.0})
      {1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate matrix4_translation(translation), to: Matrix4, as: :translation

  @doc """
  Create a translation matrix (alias for matrix4_translation/1).

  ## Examples

      iex> AriaMath.API.Matrix4.translation_matrix({1.0, 2.0, 3.0})
      {1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate translation_matrix(translation), to: Matrix4, as: :translation

  @doc """
  Create a scaling matrix.

  ## Examples

      iex> AriaMath.API.Matrix4.matrix4_scaling({2.0, 3.0, 4.0})
      {2.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate matrix4_scaling(scale), to: Matrix4, as: :scaling

  @doc """
  Create a scaling matrix (alias for matrix4_scaling/1).

  ## Examples

      iex> AriaMath.API.Matrix4.scaling_matrix({2.0, 3.0, 4.0})
      {2.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  defdelegate scaling_matrix(scale), to: Matrix4, as: :scaling

  @doc """
  Create a rotation matrix from a quaternion.

  ## Examples

      q = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      matrix = AriaMath.API.Matrix4.matrix4_rotation(q)
  """
  defdelegate matrix4_rotation(quaternion), to: Matrix4, as: :rotation

  @doc """
  Create a rotation matrix from a quaternion (alias for matrix4_rotation/1).

  ## Examples

      q = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      matrix = AriaMath.API.Matrix4.rotation_matrix(q)
  """
  defdelegate rotation_matrix(quaternion), to: Matrix4, as: :rotation

  @doc """
  Multiply two 4x4 matrices.

  ## Examples

      m1 = AriaMath.API.Matrix4.matrix4_translation({1.0, 0.0, 0.0})
      m2 = AriaMath.API.Matrix4.matrix4_scaling({2.0, 2.0, 2.0})
      result = AriaMath.API.Matrix4.matrix4_multiply(m1, m2)
  """
  defdelegate matrix4_multiply(m1, m2), to: Matrix4, as: :multiply

  @doc """
  Multiply two 4x4 matrices (alias for matrix4_multiply/2).

  ## Examples

      m1 = AriaMath.API.Matrix4.matrix4_translation({1.0, 0.0, 0.0})
      m2 = AriaMath.API.Matrix4.matrix4_scaling({2.0, 2.0, 2.0})
      result = AriaMath.API.Matrix4.multiply_matrices(m1, m2)
  """
  defdelegate multiply_matrices(m1, m2), to: Matrix4, as: :multiply

  @doc """
  Transform a 3D point by a 4x4 matrix.

  ## Examples

      matrix = AriaMath.API.Matrix4.matrix4_translation({1.0, 2.0, 3.0})
      transformed = AriaMath.API.Matrix4.matrix4_transform_point(matrix, {0.0, 0.0, 0.0})
  """
  defdelegate matrix4_transform_point(matrix, point), to: Matrix4, as: :transform_point

  @doc """
  Transform a 3D point by a 4x4 matrix (alias for matrix4_transform_point/2).

  ## Examples

      matrix = AriaMath.API.Matrix4.matrix4_translation({1.0, 2.0, 3.0})
      transformed = AriaMath.API.Matrix4.transform_point(matrix, {0.0, 0.0, 0.0})
  """
  defdelegate transform_point(matrix, point), to: Matrix4, as: :transform_point

  @doc """
  Transform a 3D direction by a 4x4 matrix (ignores translation).

  ## Examples

      matrix = AriaMath.API.Matrix4.matrix4_scaling({2.0, 2.0, 2.0})
      transformed = AriaMath.API.Matrix4.matrix4_transform_direction(matrix, {1.0, 1.0, 1.0})
  """
  defdelegate matrix4_transform_direction(matrix, vector), to: Matrix4, as: :transform_direction

  @doc """
  Compute the inverse of a 4x4 matrix.

  ## Examples

      matrix = AriaMath.API.Matrix4.matrix4_translation({1.0, 2.0, 3.0})
      {inverse, valid} = AriaMath.API.Matrix4.matrix4_inverse(matrix)
  """
  defdelegate matrix4_inverse(matrix), to: Matrix4, as: :inverse

  @doc """
  Compute the transpose of a 4x4 matrix.

  ## Examples

      matrix = AriaMath.API.Matrix4.matrix4_translation({1.0, 2.0, 3.0})
      transposed = AriaMath.API.Matrix4.matrix4_transpose(matrix)
  """
  defdelegate matrix4_transpose(matrix), to: Matrix4, as: :transpose

  @doc """
  Decompose a 4x4 transformation matrix into translation, rotation, and scale.

  ## Examples

      matrix = AriaMath.API.Matrix4.matrix4_translation({1.0, 2.0, 3.0})
      {translation, rotation, scale} = AriaMath.API.Matrix4.matrix4_decompose(matrix)
  """
  defdelegate matrix4_decompose(matrix), to: Matrix4, as: :decompose

  @doc """
  Compose a 4x4 transformation matrix from translation, rotation, and scale.

  ## Examples

      translation = {1.0, 2.0, 3.0}
      rotation = AriaMath.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      scale = {2.0, 2.0, 2.0}
      matrix = AriaMath.API.Matrix4.matrix4_compose(translation, rotation, scale)
  """
  defdelegate matrix4_compose(translation, rotation, scale), to: Matrix4, as: :compose

  @doc """
  Compute the determinant of a 4x4 matrix.

  ## Examples

      matrix = AriaMath.API.Matrix4.matrix4_identity()
      det = AriaMath.API.Matrix4.matrix_determinant(matrix)
  """
  defdelegate matrix_determinant(matrix), to: Matrix4, as: :determinant
end
