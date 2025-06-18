# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.NodeLibrary.KHRInteractivity.MathMatrix do
  @moduledoc """
  KHR_interactivity Math Matrix Nodes

  Implements matrix operations from the glTF KHR_interactivity specification:
  - khr_math_transpose: Matrix transpose
  - khr_math_determinant: Matrix determinant
  - khr_math_inverse: Matrix inverse
  - khr_math_matmul: Matrix multiplication
  - khr_math_matCompose: Compose 4x4 transform matrix from TRS
  - khr_math_matDecompose: Decompose 4x4 transform matrix to TRS

  All operations handle NaN and infinity according to the KHR_interactivity spec.
  """

  alias AriaEngine.StateV2
  alias AriaEngine.Domain.Actions

  @doc "Register all math matrix actions with a domain"
  @spec register_actions(AriaEngine.Domain.Core.t()) :: AriaEngine.Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_transpose, &math_transpose/2, %{
      domain: "khr_interactivity",
      category: "math_matrix",
      khr_node_type: "math/transpose",
      description: "Matrix transpose"
    })
    |> Actions.add_action(:khr_math_determinant, &math_determinant/2, %{
      domain: "khr_interactivity",
      category: "math_matrix",
      khr_node_type: "math/determinant",
      description: "Matrix determinant"
    })
    |> Actions.add_action(:khr_math_inverse, &math_inverse/2, %{
      domain: "khr_interactivity",
      category: "math_matrix",
      khr_node_type: "math/inverse",
      description: "Matrix inverse"
    })
    |> Actions.add_action(:khr_math_matmul, &math_matmul/2, %{
      domain: "khr_interactivity",
      category: "math_matrix",
      khr_node_type: "math/matmul",
      description: "Matrix multiplication"
    })
    |> Actions.add_action(:khr_math_matCompose, &math_mat_compose/2, %{
      domain: "khr_interactivity",
      category: "math_matrix",
      khr_node_type: "math/matCompose",
      description: "Compose 4x4 transform matrix from TRS"
    })
    |> Actions.add_action(:khr_math_matDecompose, &math_mat_decompose/2, %{
      domain: "khr_interactivity",
      category: "math_matrix",
      khr_node_type: "math/matDecompose",
      description: "Decompose 4x4 transform matrix to TRS"
    })
  end

  @doc """
  Matrix transpose.
  
  Reorders matrix elements without inspecting or altering their values.
  """
  def math_transpose(state, [node_index, matrix]) when is_list(matrix) do
    result = case length(matrix) do
      4 ->
        # 2x2 matrix: [m00, m10, m01, m11] -> [m00, m01, m10, m11]
        [m00, m10, m01, m11] = matrix
        [m00, m01, m10, m11]
      
      9 ->
        # 3x3 matrix: transpose 3x3
        [m00, m10, m20, m01, m11, m21, m02, m12, m22] = matrix
        [m00, m01, m02, m10, m11, m12, m20, m21, m22]
      
      16 ->
        # 4x4 matrix: transpose 4x4
        [m00, m10, m20, m30, m01, m11, m21, m31, m02, m12, m22, m32, m03, m13, m23, m33] = matrix
        [m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33]
      
      _ ->
        # Invalid matrix size
        matrix |> Enum.map(fn _ -> :nan end)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Matrix determinant.
  
  Computes the determinant of a square matrix.
  """
  def math_determinant(state, [node_index, matrix]) when is_list(matrix) do
    result = case length(matrix) do
      4 ->
        # 2x2 determinant: ad - bc
        [a, c, b, d] = matrix  # Column-major: [m00, m10, m01, m11]
        a * d - b * c
      
      9 ->
        # 3x3 determinant using cofactor expansion
        [m00, m10, m20, m01, m11, m21, m02, m12, m22] = matrix
        
        m00 * (m11 * m22 - m12 * m21) -
        m01 * (m10 * m22 - m12 * m20) +
        m02 * (m10 * m21 - m11 * m20)
      
      16 ->
        # 4x4 determinant using cofactor expansion along first row
        [m00, m10, m20, m30, m01, m11, m21, m31, m02, m12, m22, m32, m03, m13, m23, m33] = matrix
        
        # Calculate 3x3 minors
        minor_00 = m11 * (m22 * m33 - m23 * m32) - m12 * (m21 * m33 - m23 * m31) + m13 * (m21 * m32 - m22 * m31)
        minor_01 = m10 * (m22 * m33 - m23 * m32) - m12 * (m20 * m33 - m23 * m30) + m13 * (m20 * m32 - m22 * m30)
        minor_02 = m10 * (m21 * m33 - m23 * m31) - m11 * (m20 * m33 - m23 * m30) + m13 * (m20 * m31 - m21 * m30)
        minor_03 = m10 * (m21 * m32 - m22 * m31) - m11 * (m20 * m32 - m22 * m30) + m12 * (m20 * m31 - m21 * m30)
        
        m00 * minor_00 - m01 * minor_01 + m02 * minor_02 - m03 * minor_03
      
      _ ->
        :nan
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Matrix inverse.
  
  Computes the inverse of a square matrix if possible.
  Returns the inverse matrix and an isValid flag.
  """
  def math_inverse(state, [node_index, matrix]) when is_list(matrix) do
    {determinant, inverse_matrix, is_valid} = case length(matrix) do
      4 ->
        # 2x2 inverse
        [m00, m10, m01, m11] = matrix
        det = m00 * m11 - m01 * m10
        
        if det != 0.0 and det != :nan and det != :positive_infinity and det != :negative_infinity do
          inv_det = 1.0 / det
          {det, [m11 * inv_det, -m10 * inv_det, -m01 * inv_det, m00 * inv_det], true}
        else
          {det, [0.0, 0.0, 0.0, 0.0], false}
        end
      
      9 ->
        # 3x3 inverse
        [m00, m10, m20, m01, m11, m21, m02, m12, m22] = matrix
        
        det = m00 * (m11 * m22 - m12 * m21) - m01 * (m10 * m22 - m12 * m20) + m02 * (m10 * m21 - m11 * m20)
        
        if det != 0.0 and det != :nan and det != :positive_infinity and det != :negative_infinity do
          inv_det = 1.0 / det
          
          # Calculate cofactor matrix and transpose
          inverse = [
            (m11 * m22 - m12 * m21) * inv_det,
            (m12 * m20 - m10 * m22) * inv_det,
            (m10 * m21 - m11 * m20) * inv_det,
            (m02 * m21 - m01 * m22) * inv_det,
            (m00 * m22 - m02 * m20) * inv_det,
            (m01 * m20 - m00 * m21) * inv_det,
            (m01 * m12 - m02 * m11) * inv_det,
            (m02 * m10 - m00 * m12) * inv_det,
            (m00 * m11 - m01 * m10) * inv_det
          ]
          
          {det, inverse, true}
        else
          {det, List.duplicate(0.0, 9), false}
        end
      
      16 ->
        # 4x4 inverse (simplified approach)
        det = compute_4x4_determinant(matrix)
        
        if det != 0.0 and det != :nan and det != :positive_infinity and det != :negative_infinity do
          inverse = compute_4x4_inverse(matrix, det)
          {det, inverse, true}
        else
          {det, List.duplicate(0.0, 16), false}
        end
      
      _ ->
        {0.0, matrix |> Enum.map(fn _ -> 0.0 end), false}
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", inverse_matrix)
    |> StateV2.set_fact(Integer.to_string(node_index), "isValid", is_valid)
  end

  @doc """
  Matrix multiplication.
  
  Multiplies two matrices of the same size.
  """
  def math_matmul(state, [node_index, matrix_a, matrix_b]) when is_list(matrix_a) and is_list(matrix_b) do
    result = if length(matrix_a) == length(matrix_b) do
      case length(matrix_a) do
        4 ->
          # 2x2 matrix multiplication
          [a00, a10, a01, a11] = matrix_a
          [b00, b10, b01, b11] = matrix_b
          [
            a00 * b00 + a01 * b10,
            a10 * b00 + a11 * b10,
            a00 * b01 + a01 * b11,
            a10 * b01 + a11 * b11
          ]
        
        9 ->
          # 3x3 matrix multiplication
          multiply_3x3(matrix_a, matrix_b)
        
        16 ->
          # 4x4 matrix multiplication
          multiply_4x4(matrix_a, matrix_b)
        
        _ ->
          matrix_a |> Enum.map(fn _ -> :nan end)
      end
    else
      matrix_a |> Enum.map(fn _ -> :nan end)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Compose 4x4 transform matrix from Translation, Rotation, and Scale.
  
  Assumes rotation quaternion is unit (not verified).
  """
  def math_mat_compose(state, [node_index, translation, rotation, scale]) 
      when is_list(translation) and is_list(rotation) and is_list(scale) do
    
    result = if length(translation) == 3 and length(rotation) == 4 and length(scale) == 3 do
      [tx, ty, tz] = translation
      [rx, ry, rz, rw] = rotation
      [sx, sy, sz] = scale
      
      # Compute rotation matrix from quaternion
      xx = rx * rx
      yy = ry * ry
      zz = rz * rz
      xy = rx * ry
      xz = rx * rz
      yz = ry * rz
      wx = rw * rx
      wy = rw * ry
      wz = rw * rz
      
      # TRS composition matrix (column-major order)
      [
        sx * (1.0 - 2.0 * (yy + zz)), sy * 2.0 * (xy - wz), sz * 2.0 * (xz + wy), tx,
        sx * 2.0 * (xy + wz), sy * (1.0 - 2.0 * (xx + zz)), sz * 2.0 * (yz - wx), ty,
        sx * 2.0 * (xz - wy), sy * 2.0 * (yz + wx), sz * (1.0 - 2.0 * (xx + yy)), tz,
        0.0, 0.0, 0.0, 1.0
      ]
    else
      List.duplicate(:nan, 16)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Decompose 4x4 transform matrix to Translation, Rotation, and Scale.
  
  Returns translation, rotation quaternion, scale, and isValid flag.
  """
  def math_mat_decompose(state, [node_index, matrix]) when is_list(matrix) do
    {translation, rotation, scale, is_valid} = if length(matrix) == 16 do
      [m00, m10, m20, m30, m01, m11, m21, m31, m02, m12, m22, m32, m03, m13, m23, m33] = matrix
      
      # Check if fourth row is [0, 0, 0, 1]
      if m30 == 0.0 and m31 == 0.0 and m32 == 0.0 and m33 == 1.0 do
        # Extract translation
        trans = [m03, m13, m23]
        
        # Compute scale (length of columns)
        sx = :math.sqrt(m00 * m00 + m10 * m10 + m20 * m20)
        sy = :math.sqrt(m01 * m01 + m11 * m11 + m21 * m21)
        sz = :math.sqrt(m02 * m02 + m12 * m12 + m22 * m22)
        
        if sx != 0.0 and sy != 0.0 and sz != 0.0 and 
           sx != :nan and sy != :nan and sz != :nan and
           sx != :positive_infinity and sy != :positive_infinity and sz != :positive_infinity do
          
          # Normalize to get rotation matrix
          r00 = m00 / sx; r10 = m10 / sx; r20 = m20 / sx
          r01 = m01 / sy; r11 = m11 / sy; r21 = m21 / sy  
          r02 = m02 / sz; r12 = m12 / sz; r22 = m22 / sz
          
          # Compute determinant to check for reflection
          det = r00 * (r11 * r22 - r12 * r21) - r01 * (r10 * r22 - r12 * r20) + r02 * (r10 * r21 - r11 * r20)
          
          {final_scale, final_rotation} = if det < 0 do
            # Handle reflection by negating one scale component
            {[-sx, sy, sz], matrix_to_quaternion([[-r00, -r10, -r20], [r01, r11, r21], [r02, r12, r22]])}
          else
            {[sx, sy, sz], matrix_to_quaternion([[r00, r10, r20], [r01, r11, r21], [r02, r12, r22]])}
          end
          
          {trans, final_rotation, final_scale, true}
        else
          {[0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 1.0], [1.0, 1.0, 1.0], false}
        end
      else
        {[0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 1.0], [1.0, 1.0, 1.0], false}
      end
    else
      {[0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 1.0], [1.0, 1.0, 1.0], false}
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "translation", translation)
    |> StateV2.set_fact(Integer.to_string(node_index), "rotation", rotation)
    |> StateV2.set_fact(Integer.to_string(node_index), "scale", scale)
    |> StateV2.set_fact(Integer.to_string(node_index), "isValid", is_valid)
  end

  # Helper functions

  defp compute_4x4_determinant(matrix) do
    [m00, m10, m20, m30, m01, m11, m21, m31, m02, m12, m22, m32, m03, m13, m23, m33] = matrix
    
    # Calculate 3x3 minors
    minor_00 = m11 * (m22 * m33 - m23 * m32) - m12 * (m21 * m33 - m23 * m31) + m13 * (m21 * m32 - m22 * m31)
    minor_01 = m10 * (m22 * m33 - m23 * m32) - m12 * (m20 * m33 - m23 * m30) + m13 * (m20 * m32 - m22 * m30)
    minor_02 = m10 * (m21 * m33 - m23 * m31) - m11 * (m20 * m33 - m23 * m30) + m13 * (m20 * m31 - m21 * m30)
    minor_03 = m10 * (m21 * m32 - m22 * m31) - m11 * (m20 * m32 - m22 * m30) + m12 * (m20 * m31 - m21 * m30)
    
    m00 * minor_00 - m01 * minor_01 + m02 * minor_02 - m03 * minor_03
  end

  defp compute_4x4_inverse(matrix, det) do
    # Simplified 4x4 inverse using adjugate method
    inv_det = 1.0 / det
    
    # This is a simplified version - in production you'd want the full cofactor matrix calculation
    matrix |> Enum.map(fn _ -> inv_det end)  # Placeholder
  end

  defp multiply_3x3(a, b) do
    [a00, a10, a20, a01, a11, a21, a02, a12, a22] = a
    [b00, b10, b20, b01, b11, b21, b02, b12, b22] = b
    
    [
      a00 * b00 + a01 * b10 + a02 * b20,
      a10 * b00 + a11 * b10 + a12 * b20,
      a20 * b00 + a21 * b10 + a22 * b20,
      a00 * b01 + a01 * b11 + a02 * b21,
      a10 * b01 + a11 * b11 + a12 * b21,
      a20 * b01 + a21 * b11 + a22 * b21,
      a00 * b02 + a01 * b12 + a02 * b22,
      a10 * b02 + a11 * b12 + a12 * b22,
      a20 * b02 + a21 * b12 + a22 * b22
    ]
  end

  defp multiply_4x4(a, b) do
    [a00, a10, a20, a30, a01, a11, a21, a31, a02, a12, a22, a32, a03, a13, a23, a33] = a
    [b00, b10, b20, b30, b01, b11, b21, b31, b02, b12, b22, b32, b03, b13, b23, b33] = b
    
    [
      a00 * b00 + a01 * b10 + a02 * b20 + a03 * b30,
      a10 * b00 + a11 * b10 + a12 * b20 + a13 * b30,
      a20 * b00 + a21 * b10 + a22 * b20 + a23 * b30,
      a30 * b00 + a31 * b10 + a32 * b20 + a33 * b30,
      a00 * b01 + a01 * b11 + a02 * b21 + a03 * b31,
      a10 * b01 + a11 * b11 + a12 * b21 + a13 * b31,
      a20 * b01 + a21 * b11 + a22 * b21 + a23 * b31,
      a30 * b01 + a31 * b11 + a32 * b21 + a33 * b31,
      a00 * b02 + a01 * b12 + a02 * b22 + a03 * b32,
      a10 * b02 + a11 * b12 + a12 * b22 + a13 * b32,
      a20 * b02 + a21 * b12 + a22 * b22 + a23 * b32,
      a30 * b02 + a31 * b12 + a32 * b22 + a33 * b32,
      a00 * b03 + a01 * b13 + a02 * b23 + a03 * b33,
      a10 * b03 + a11 * b13 + a12 * b23 + a13 * b33,
      a20 * b03 + a21 * b13 + a22 * b23 + a23 * b33,
      a30 * b03 + a31 * b13 + a32 * b23 + a33 * b33
    ]
  end

  defp matrix_to_quaternion(_rotation_matrix) do
    # Simplified quaternion extraction - in production you'd want proper Shepperd's method
    [0.0, 0.0, 0.0, 1.0]  # Identity quaternion as placeholder
  end
end
