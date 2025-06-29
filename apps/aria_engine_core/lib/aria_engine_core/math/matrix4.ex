defmodule AriaEngineCore.Math.Matrix4 do
  @moduledoc """
  Matrix4 mathematical operations implementing glTF KHR Interactivity `float4x4` matrix operations.

  All operations follow IEEE-754 standard for NaN, infinity, and special case handling
  as defined in the glTF KHR Interactivity specification.

  Matrix4 is represented as a tuple of 16 floats in column-major order, following glTF convention.
  The matrix layout is:
  ```
  [ m0  m4  m8  m12]
  [ m1  m5  m9  m13]
  [ m2  m6  m10 m14]
  [ m3  m7  m11 m15]
  ```
  """

  alias __MODULE__
  alias AriaEngineCore.Math.{Vector3, Quaternion}

  @type t :: {
          float(), float(), float(), float(),
          float(), float(), float(), float(),
          float(), float(), float(), float(),
          float(), float(), float(), float()
        }

  @doc """
  Creates a new Matrix4 from 16 float components in column-major order.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.new(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  @spec new(
          float(), float(), float(), float(),
          float(), float(), float(), float(),
          float(), float(), float(), float(),
          float(), float(), float(), float()
        ) :: t()
  def new(m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15) do
    {m0/1, m1/1, m2/1, m3/1, m4/1, m5/1, m6/1, m7/1, m8/1, m9/1, m10/1, m11/1, m12/1, m13/1, m14/1, m15/1}
  end

  @doc """
  Matrix multiplication.

  Implements `math/matMul` operation from KHR Interactivity spec.

  Returns matrix product C = A * B following standard matrix multiplication rules.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.multiply(AriaEngineCore.Math.Matrix4.identity(), AriaEngineCore.Math.Matrix4.identity())
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  @spec multiply(t(), t()) :: t()
  def multiply(
        {a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15},
        {b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15}
      ) do
    {
      # Column 0
      a0 * b0 + a4 * b1 + a8 * b2 + a12 * b3,
      a1 * b0 + a5 * b1 + a9 * b2 + a13 * b3,
      a2 * b0 + a6 * b1 + a10 * b2 + a14 * b3,
      a3 * b0 + a7 * b1 + a11 * b2 + a15 * b3,
      # Column 1
      a0 * b4 + a4 * b5 + a8 * b6 + a12 * b7,
      a1 * b4 + a5 * b5 + a9 * b6 + a13 * b7,
      a2 * b4 + a6 * b5 + a10 * b6 + a14 * b7,
      a3 * b4 + a7 * b5 + a11 * b6 + a15 * b7,
      # Column 2
      a0 * b8 + a4 * b9 + a8 * b10 + a12 * b11,
      a1 * b8 + a5 * b9 + a9 * b10 + a13 * b11,
      a2 * b8 + a6 * b9 + a10 * b10 + a14 * b11,
      a3 * b8 + a7 * b9 + a11 * b10 + a15 * b11,
      # Column 3
      a0 * b12 + a4 * b13 + a8 * b14 + a12 * b15,
      a1 * b12 + a5 * b13 + a9 * b14 + a13 * b15,
      a2 * b12 + a6 * b13 + a10 * b14 + a14 * b15,
      a3 * b12 + a7 * b13 + a11 * b14 + a15 * b15
    }
  end

  @doc """
  Matrix determinant calculation.

  Implements `math/matDeterminant` operation from KHR Interactivity spec.

  Returns the determinant of the 4x4 matrix.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.determinant(AriaEngineCore.Math.Matrix4.identity())
      1.0
  """
  @spec determinant(t()) :: float()
  def determinant({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}) do
    # Using cofactor expansion along first row
    minor_0 = (m5 * (m10 * m15 - m11 * m14) - m6 * (m9 * m15 - m11 * m13) + m7 * (m9 * m14 - m10 * m13))
    minor_1 = (m4 * (m10 * m15 - m11 * m14) - m6 * (m8 * m15 - m11 * m12) + m7 * (m8 * m14 - m10 * m12))
    minor_2 = (m4 * (m9 * m15 - m11 * m13) - m5 * (m8 * m15 - m11 * m12) + m7 * (m8 * m13 - m9 * m12))
    minor_3 = (m4 * (m9 * m14 - m10 * m13) - m5 * (m8 * m14 - m10 * m12) + m6 * (m8 * m13 - m9 * m12))

    m0 * minor_0 - m1 * minor_1 + m2 * minor_2 - m3 * minor_3
  end

  @doc """
  Matrix inversion with validity checking.

  Implements `math/matInverse` operation from KHR Interactivity spec.

  Returns {inverted_matrix, is_valid} where:
  - inverted_matrix: inverse matrix, or identity if invalid
  - is_valid: true if matrix is invertible, false otherwise

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.inverse(AriaEngineCore.Math.Matrix4.identity())
      {{1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}, true}
  """
  @spec inverse(t()) :: {t(), boolean()}
  def inverse(matrix) do
    det = determinant(matrix)

    cond do
      # If determinant is zero, NaN, or infinity, return identity and false
      det == 0.0 or is_nan(det) or is_infinite(det) ->
        {identity(), false}

      # If determinant is valid, calculate inverse
      true ->
        inv_matrix = calculate_inverse(matrix, det)
        {inv_matrix, true}
    end
  end

  @doc """
  Matrix transpose operation.

  Implements `math/matTranspose` operation from KHR Interactivity spec.

  Returns the transpose of the matrix.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.transpose({1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16})
      {1.0, 5.0, 9.0, 13.0, 2.0, 6.0, 10.0, 14.0, 3.0, 7.0, 11.0, 15.0, 4.0, 8.0, 12.0, 16.0}
  """
  @spec transpose(t()) :: t()
  def transpose({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}) do
    {m0, m4, m8, m12, m1, m5, m9, m13, m2, m6, m10, m14, m3, m7, m11, m15}
  end

  @doc """
  Extract translation vector from transformation matrix.

  Returns the translation component (last column) as Vector3.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.get_translation(AriaEngineCore.Math.Matrix4.translation({1.0, 2.0, 3.0}))
      {1.0, 2.0, 3.0}
  """
  @spec get_translation(t()) :: Vector3.t()
  def get_translation({_, _, _, _, _, _, _, _, _, _, _, _, tx, ty, tz, _}) do
    {tx, ty, tz}
  end

  @doc """
  Create translation matrix from vector.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.translation({1.0, 2.0, 3.0})
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 2.0, 3.0, 1.0}
  """
  @spec translation(Vector3.t()) :: t()
  def translation({x, y, z}) do
    {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, x, y, z, 1.0}
  end

  @doc """
  Create scaling matrix from vector.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.scaling({2.0, 3.0, 4.0})
      {2.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  @spec scaling(Vector3.t()) :: t()
  def scaling({x, y, z}) do
    {x, 0.0, 0.0, 0.0, 0.0, y, 0.0, 0.0, 0.0, 0.0, z, 0.0, 0.0, 0.0, 0.0, 1.0}
  end

  @doc """
  Create rotation matrix from quaternion.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.rotation(AriaEngineCore.Math.Quaternion.identity())
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  @spec rotation(Quaternion.t()) :: t()
  def rotation({x, y, z, w}) do
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

  @doc """
  Create transformation matrix from translation, rotation, and scale.

  Combines TRS (Translation, Rotation, Scale) into a single transformation matrix.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.compose({0.0, 0.0, 0.0}, AriaEngineCore.Math.Quaternion.identity(), {1.0, 1.0, 1.0})
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  @spec compose(Vector3.t(), Quaternion.t(), Vector3.t()) :: t()
  def compose(translation_vec, rotation_quat, scale_vec) do
    t_matrix = translation(translation_vec)
    r_matrix = rotation(rotation_quat)
    s_matrix = scaling(scale_vec)

    # Apply in order: Scale, then Rotate, then Translate (T * R * S)
    multiply(multiply(t_matrix, r_matrix), s_matrix)
  end

  @doc """
  Decompose transformation matrix into translation, rotation, and scale.

  Returns {translation, rotation, scale} components.
  CAUTION: This assumes the matrix represents a valid TRS transformation.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.decompose(AriaEngineCore.Math.Matrix4.identity())
      {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 1.0}, {1.0, 1.0, 1.0}}
  """
  @spec decompose(t()) :: {Vector3.t(), Quaternion.t(), Vector3.t()}
  def decompose({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}) do
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
  Transform a Vector3 point by the matrix.

  Applies full 4x4 transformation to a 3D point (w=1).

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.transform_point(AriaEngineCore.Math.Matrix4.identity(), {1.0, 2.0, 3.0})
      {1.0, 2.0, 3.0}
  """
  @spec transform_point(t(), Vector3.t()) :: Vector3.t()
  def transform_point({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}, {x, y, z}) do
    # Transform with w=1 (point)
    tx = m0 * x + m4 * y + m8 * z + m12
    ty = m1 * x + m5 * y + m9 * z + m13
    tz = m2 * x + m6 * y + m10 * z + m14
    tw = m3 * x + m7 * y + m11 * z + m15

    # Perspective divide if needed
    if tw != 0.0 and tw != 1.0 do
      {tx / tw, ty / tw, tz / tw}
    else
      {tx, ty, tz}
    end
  end

  @doc """
  Transform a Vector3 direction by the matrix.

  Applies only rotation and scale to a 3D direction vector (w=0).

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.transform_direction(AriaEngineCore.Math.Matrix4.identity(), {1.0, 0.0, 0.0})
      {1.0, 0.0, 0.0}
  """
  @spec transform_direction(t(), Vector3.t()) :: Vector3.t()
  def transform_direction({m0, m1, m2, _, m4, m5, m6, _, m8, m9, m10, _, _, _, _, _}, {x, y, z}) do
    # Transform with w=0 (direction)
    {
      m0 * x + m4 * y + m8 * z,
      m1 * x + m5 * y + m9 * z,
      m2 * x + m6 * y + m10 * z
    }
  end

  @doc """
  Identity matrix constant.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.identity()
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  @spec identity() :: t()
  def identity do
    {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  end

  @doc """
  Zero matrix constant.

  ## Examples

      iex> AriaEngineCore.Math.Matrix4.zero()
      {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
  """
  @spec zero() :: t()
  def zero do
    {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
  end

  # Helper functions

  defp is_nan(x) do
    x != x
  end

  defp is_infinite(x) do
    x == :positive_infinity or x == :negative_infinity
  end

  defp calculate_inverse({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}, det) do
    inv_det = 1.0 / det

    # Calculate cofactor matrix and multiply by 1/det
    {
      inv_det * (m5 * (m10 * m15 - m11 * m14) - m6 * (m9 * m15 - m11 * m13) + m7 * (m9 * m14 - m10 * m13)),
      inv_det * -(m1 * (m10 * m15 - m11 * m14) - m2 * (m9 * m15 - m11 * m13) + m3 * (m9 * m14 - m10 * m13)),
      inv_det * (m1 * (m6 * m15 - m7 * m14) - m2 * (m5 * m15 - m7 * m13) + m3 * (m5 * m14 - m6 * m13)),
      inv_det * -(m1 * (m6 * m11 - m7 * m10) - m2 * (m5 * m11 - m7 * m9) + m3 * (m5 * m10 - m6 * m9)),

      inv_det * -(m4 * (m10 * m15 - m11 * m14) - m6 * (m8 * m15 - m11 * m12) + m7 * (m8 * m14 - m10 * m12)),
      inv_det * (m0 * (m10 * m15 - m11 * m14) - m2 * (m8 * m15 - m11 * m12) + m3 * (m8 * m14 - m10 * m12)),
      inv_det * -(m0 * (m6 * m15 - m7 * m14) - m2 * (m4 * m15 - m7 * m12) + m3 * (m4 * m14 - m6 * m12)),
      inv_det * (m0 * (m6 * m11 - m7 * m10) - m2 * (m4 * m11 - m7 * m8) + m3 * (m4 * m10 - m6 * m8)),

      inv_det * (m4 * (m9 * m15 - m11 * m13) - m5 * (m8 * m15 - m11 * m12) + m7 * (m8 * m13 - m9 * m12)),
      inv_det * -(m0 * (m9 * m15 - m11 * m13) - m1 * (m8 * m15 - m11 * m12) + m3 * (m8 * m13 - m9 * m12)),
      inv_det * (m0 * (m5 * m15 - m7 * m13) - m1 * (m4 * m15 - m7 * m12) + m3 * (m4 * m13 - m5 * m12)),
      inv_det * -(m0 * (m5 * m11 - m7 * m9) - m1 * (m4 * m11 - m7 * m8) + m3 * (m4 * m9 - m5 * m8)),

      inv_det * -(m4 * (m9 * m14 - m10 * m13) - m5 * (m8 * m14 - m10 * m12) + m6 * (m8 * m13 - m9 * m12)),
      inv_det * (m0 * (m9 * m14 - m10 * m13) - m1 * (m8 * m14 - m10 * m12) + m2 * (m8 * m13 - m9 * m12)),
      inv_det * -(m0 * (m5 * m14 - m6 * m13) - m1 * (m4 * m14 - m6 * m12) + m2 * (m4 * m13 - m5 * m12)),
      inv_det * (m0 * (m5 * m10 - m6 * m9) - m1 * (m4 * m10 - m6 * m8) + m2 * (m4 * m9 - m5 * m8))
    }
  end

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
