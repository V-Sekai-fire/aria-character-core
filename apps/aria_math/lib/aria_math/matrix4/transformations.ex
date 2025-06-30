# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Matrix4.Transformations do
  @moduledoc """
  Transformation operations for Matrix4.

  Contains TRS (Translation, Rotation, Scale) operations including
  composition, decomposition, and individual transformation matrices.
  """

  alias AriaMath.{Matrix4, Vector3, Quaternion}

  @doc """
  Extract translation vector from transformation matrix.
  """
  @spec get_translation(Matrix4.t()) :: Vector3.t()
  def get_translation({_, _, _, _, _, _, _, _, _, _, _, _, tx, ty, tz, _}) do
    {tx, ty, tz}
  end

  @doc """
  Create translation matrix from vector.
  """
  @spec translation(Vector3.t()) :: Matrix4.t()
  def translation({x, y, z}) do
    {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, x, y, z, 1.0}
  end

  @doc """
  Create scaling matrix from vector.
  """
  @spec scaling(Vector3.t()) :: Matrix4.t()
  def scaling({x, y, z}) do
    {x, 0.0, 0.0, 0.0, 0.0, y, 0.0, 0.0, 0.0, 0.0, z, 0.0, 0.0, 0.0, 0.0, 1.0}
  end

  @doc """
  Create rotation matrix from quaternion or extract rotation from matrix.
  """
  @spec rotation(Quaternion.t() | Matrix4.t()) :: Matrix4.t()
  def rotation({x, y, z, w}) when is_float(x) and is_float(y) and is_float(z) and is_float(w) do
    # Convert unit quaternion to rotation matrix
    xx = x * x
    yy = y * y
    zz = z * z
    xy = x * y
    xz = x * z
    yz = y * z
    wx = w * x
    wy = w * y
    wz = w * z

    {
      1.0 - 2.0 * (yy + zz), 2.0 * (xy + wz), 2.0 * (xz - wy), 0.0,
      2.0 * (xy - wz), 1.0 - 2.0 * (xx + zz), 2.0 * (yz + wx), 0.0,
      2.0 * (xz + wy), 2.0 * (yz - wx), 1.0 - 2.0 * (xx + yy), 0.0,
      0.0, 0.0, 0.0, 1.0
    }
  end

  def rotation({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}) do
    # Extract rotation component from 4x4 matrix (remove translation and normalize)
    rotation_3x3 = extract_basis({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15})
    orthogonalize(rotation_3x3)
  end

  @doc """
  Create transformation matrix from translation, rotation, and scale.
  """
  @spec compose(Vector3.t(), Quaternion.t(), Vector3.t()) :: Matrix4.t()
  def compose(translation_vec, rotation_quat, scale_vec) do
    t_matrix = translation(translation_vec)
    r_matrix = rotation(rotation_quat)
    s_matrix = scaling(scale_vec)

    # Apply in order: Scale, then Rotate, then Translate (T * R * S)
    Matrix4.Core.multiply(Matrix4.Core.multiply(t_matrix, r_matrix), s_matrix)
  end

  @doc """
  Decompose transformation matrix into translation, rotation, and scale.
  """
  @spec decompose(Matrix4.t()) :: {Vector3.t(), Quaternion.t(), Vector3.t()}
  def decompose({m0, m1, m2, _m3, m4, m5, m6, _m7, m8, m9, m10, _m11, m12, m13, m14, _m15}) do
    # Extract translation (last column)
    translation = {m12, m13, m14}

    # Extract scale (length of each column vector)
    scale_x = :math.sqrt(m0 * m0 + m1 * m1 + m2 * m2)
    scale_y = :math.sqrt(m4 * m4 + m5 * m5 + m6 * m6)
    scale_z = :math.sqrt(m8 * m8 + m9 * m9 + m10 * m10)

    scale = {scale_x, scale_y, scale_z}

    # Remove scale from rotation matrix
    rotation_matrix = {
      m0 / scale_x, m1 / scale_x, m2 / scale_x, 0.0,
      m4 / scale_y, m5 / scale_y, m6 / scale_y, 0.0,
      m8 / scale_z, m9 / scale_z, m10 / scale_z, 0.0,
      0.0, 0.0, 0.0, 1.0
    }

    # Convert rotation matrix to quaternion
    rotation = matrix_to_quaternion(rotation_matrix)

    {translation, rotation, scale}
  end

  @doc """
  Extract the 3x3 basis (rotation + scale) matrix from a 4x4 transformation matrix.
  """
  @spec extract_basis(Matrix4.t()) :: Matrix4.t()
  def extract_basis({m0, m1, m2, _, m4, m5, m6, _, m8, m9, m10, _, _, _, _, _}) do
    {m0, m1, m2, 0.0, m4, m5, m6, 0.0, m8, m9, m10, 0.0, 0.0, 0.0, 0.0, 1.0}
  end

  @doc """
  Orthogonalize a matrix by removing scaling effects while preserving rotation.
  """
  @spec orthogonalize(Matrix4.t()) :: Matrix4.t()
  def orthogonalize({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}) do
    # Extract the 3x3 rotation part
    col0 = {m0, m1, m2}
    col1 = {m4, m5, m6}
    col2 = {m8, m9, m10}

    # Gram-Schmidt orthogonalization
    # First column - normalize
    col0_len = Vector3.length(col0)
    norm_col0 = if col0_len > 1.0e-6 do
      Vector3.div_scalar(col0, col0_len)
    else
      {1.0, 0.0, 0.0}
    end

    # Second column - remove component along first, then normalize
    proj1 = Vector3.mul_scalar(norm_col0, Vector3.dot(col1, norm_col0))
    orth_col1 = Vector3.sub(col1, proj1)
    col1_len = Vector3.length(orth_col1)
    norm_col1 = if col1_len > 1.0e-6 do
      Vector3.div_scalar(orth_col1, col1_len)
    else
      {0.0, 1.0, 0.0}
    end

    # Third column - remove components along first two, then normalize
    proj2_0 = Vector3.mul_scalar(norm_col0, Vector3.dot(col2, norm_col0))
    proj2_1 = Vector3.mul_scalar(norm_col1, Vector3.dot(col2, norm_col1))
    orth_col2 = col2 |> Vector3.sub(proj2_0) |> Vector3.sub(proj2_1)
    col2_len = Vector3.length(orth_col2)
    norm_col2 = if col2_len > 1.0e-6 do
      Vector3.div_scalar(orth_col2, col2_len)
    else
      Vector3.cross(norm_col0, norm_col1)
    end

    # Reconstruct matrix with orthonormal basis
    {nx0, nx1, nx2} = norm_col0
    {ny0, ny1, ny2} = norm_col1
    {nz0, nz1, nz2} = norm_col2

    {nx0, nx1, nx2, m3, ny0, ny1, ny2, m7, nz0, nz1, nz2, m11, m12, m13, m14, m15}
  end

  # Helper function for matrix to quaternion conversion
  defp matrix_to_quaternion({m0, m1, m2, _, m4, m5, m6, _, m8, m9, m10, _, _, _, _, _}) do
    # Convert 3x3 rotation matrix to quaternion using Shepperd's method
    trace = m0 + m5 + m10

    cond do
      trace > 0.0 ->
        s = :math.sqrt(trace + 1.0) * 2.0  # s = 4 * qw
        w = 0.25 * s
        x = (m6 - m9) / s
        y = (m8 - m2) / s
        z = (m1 - m4) / s
        {x, y, z, w}

      m0 > m5 and m0 > m10 ->
        s = :math.sqrt(1.0 + m0 - m5 - m10) * 2.0  # s = 4 * qx
        w = (m6 - m9) / s
        x = 0.25 * s
        y = (m4 + m1) / s
        z = (m8 + m2) / s
        {x, y, z, w}

      m5 > m10 ->
        s = :math.sqrt(1.0 + m5 - m0 - m10) * 2.0  # s = 4 * qy
        w = (m8 - m2) / s
        x = (m4 + m1) / s
        y = 0.25 * s
        z = (m9 + m6) / s
        {x, y, z, w}

      true ->
        s = :math.sqrt(1.0 + m10 - m0 - m5) * 2.0  # s = 4 * qz
        w = (m1 - m4) / s
        x = (m8 + m2) / s
        y = (m9 + m6) / s
        z = 0.25 * s
        {x, y, z, w}
    end
  end
end
