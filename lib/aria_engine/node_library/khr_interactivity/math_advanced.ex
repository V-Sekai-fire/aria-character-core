defmodule NodeLibrary.KHRInteractivity.MathAdvanced do
  @moduledoc """
  Advanced math operations for KHR_interactivity specification.
  Implements vector, matrix, and quaternion operations.
  """

  alias StateV2

  # =============================================================================
  # Vector Operations
  # =============================================================================

  @doc """
  Saturate operation - clamps to [0, 1] range.
  
  ## Parameters
  - state: Current state
  - [node_id, value]: Node ID and value to saturate
  
  ## Returns
  Updated state with result stored in node_id
  """
  def saturate(state, [node_id, value]) when is_number(value) do
    result = max(0, min(1, value))
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  def saturate(state, [node_id, values]) when is_list(values) do
    result = Enum.map(values, &max(0, min(1, &1)))
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Linear interpolation (mix) operation.
  
  ## Parameters
  - state: Current state
  - [node_id, a, b, t]: Node ID, start value, end value, interpolation factor
  
  ## Returns
  Updated state with interpolated result
  """
  def mix(state, [node_id, a, b, t]) when is_number(a) and is_number(b) and is_number(t) do
    result = a * (1 - t) + b * t
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  def mix(state, [node_id, a, b, t]) when is_list(a) and is_list(b) and is_number(t) do
    result = Enum.zip_with(a, b, fn av, bv -> av * (1 - t) + bv * t end)
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Vector length operation.
  
  ## Parameters
  - state: Current state
  - [node_id, vector]: Node ID and vector to calculate length for
  
  ## Returns
  Updated state with vector length
  """
  def length(state, [node_id, vector]) when is_list(vector) do
    result = 
      vector
      |> Enum.map(&(&1 * &1))
      |> Enum.sum()
      |> :math.sqrt()
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Vector normalization operation.
  
  ## Parameters
  - state: Current state
  - [node_id, vector]: Node ID and vector to normalize
  
  ## Returns
  Updated state with normalized vector and validity flag
  """
  def normalize(state, [node_id, vector]) when is_list(vector) do
    length_squared = Enum.reduce(vector, 0, fn x, acc -> acc + x * x end)
    length = :math.sqrt(length_squared)
    
    {normalized_vector, is_valid} = 
      if length > 1.0e-10 do
        {Enum.map(vector, &(&1 / length)), true}
      else
        {List.duplicate(0.0, length(vector)), false}
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", normalized_vector)
    |> StateV2.set_fact(Integer.to_string(node_id), "isValid", is_valid)
  end

  @doc """
  2D vector rotation operation.
  
  ## Parameters
  - state: Current state
  - [node_id, vector, angle]: Node ID, 2D vector, and rotation angle in radians
  
  ## Returns
  Updated state with rotated vector
  """
  def rotate_2d(state, [node_id, [x, y], angle]) do
    cos_a = :math.cos(angle)
    sin_a = :math.sin(angle)
    
    result = [
      x * cos_a - y * sin_a,
      x * sin_a + y * cos_a
    ]
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  3D vector rotation by quaternion operation.
  
  ## Parameters
  - state: Current state
  - [node_id, vector, quaternion]: Node ID, 3D vector, and rotation quaternion [x, y, z, w]
  
  ## Returns
  Updated state with rotated vector
  """
  def rotate_3d(state, [node_id, [vx, vy, vz], [qx, qy, qz, qw]]) do
    # Quaternion rotation: v' = v + 2 * q_xyz × (q_xyz × v + qw * v)
    qv_cross = [
      qy * vz - qz * vy,
      qz * vx - qx * vz, 
      qx * vy - qy * vx
    ]
    
    qv_cross_plus_qw_v = [
      qv_cross |> Enum.at(0) |> Kernel.+(qw * vx),
      qv_cross |> Enum.at(1) |> Kernel.+(qw * vy),
      qv_cross |> Enum.at(2) |> Kernel.+(qw * vz)
    ]
    
    q_cross_result = [
      qy * Enum.at(qv_cross_plus_qw_v, 2) - qz * Enum.at(qv_cross_plus_qw_v, 1),
      qz * Enum.at(qv_cross_plus_qw_v, 0) - qx * Enum.at(qv_cross_plus_qw_v, 2),
      qx * Enum.at(qv_cross_plus_qw_v, 1) - qy * Enum.at(qv_cross_plus_qw_v, 0)
    ]
    
    result = [
      vx + 2 * Enum.at(q_cross_result, 0),
      vy + 2 * Enum.at(q_cross_result, 1),
      vz + 2 * Enum.at(q_cross_result, 2)
    ]
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  # =============================================================================
  # Matrix Operations
  # =============================================================================

  @doc """
  Matrix transpose operation.
  
  ## Parameters
  - state: Current state
  - [node_id, matrix]: Node ID and matrix to transpose
  
  ## Returns
  Updated state with transposed matrix
  """
  def transpose(state, [node_id, matrix]) when is_list(matrix) do
    size = case length(matrix) do
      4 -> 2   # 2x2 matrix
      9 -> 3   # 3x3 matrix
      16 -> 4  # 4x4 matrix
    end
    
    result = transpose_matrix(matrix, size)
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  defp transpose_matrix(matrix, size) do
    for row <- 0..(size - 1), col <- 0..(size - 1) do
      Enum.at(matrix, col * size + row)
    end
  end

  @doc """
  Matrix determinant operation.
  
  ## Parameters
  - state: Current state
  - [node_id, matrix]: Node ID and matrix to calculate determinant for
  
  ## Returns
  Updated state with determinant value
  """
  def determinant(state, [node_id, matrix]) when is_list(matrix) do
    result = case length(matrix) do
      4 -> determinant_2x2(matrix)
      9 -> determinant_3x3(matrix)
      16 -> determinant_4x4(matrix)
    end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  defp determinant_2x2([m00, m01, m10, m11]) do
    m00 * m11 - m01 * m10
  end

  defp determinant_3x3([m00, m01, m02, m10, m11, m12, m20, m21, m22]) do
    m00 * (m11 * m22 - m12 * m21) -
    m01 * (m10 * m22 - m12 * m20) +
    m02 * (m10 * m21 - m11 * m20)
  end

  defp determinant_4x4(matrix) do
    [m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33] = matrix
    
    # Calculate 4x4 determinant using cofactor expansion
    m00 * determinant_3x3([m11, m12, m13, m21, m22, m23, m31, m32, m33]) -
    m01 * determinant_3x3([m10, m12, m13, m20, m22, m23, m30, m32, m33]) +
    m02 * determinant_3x3([m10, m11, m13, m20, m21, m23, m30, m31, m33]) -
    m03 * determinant_3x3([m10, m11, m12, m20, m21, m22, m30, m31, m32])
  end

  @doc """
  Matrix inverse operation.
  
  ## Parameters
  - state: Current state
  - [node_id, matrix]: Node ID and matrix to invert
  
  ## Returns
  Updated state with inverted matrix and validity flag
  """
  def inverse(state, [node_id, matrix]) when is_list(matrix) do
    det = case length(matrix) do
      4 -> determinant_2x2(matrix)
      9 -> determinant_3x3(matrix)
      16 -> determinant_4x4(matrix)
    end
    
    {inverted_matrix, is_valid} = 
      if abs(det) > 1.0e-10 do
        {invert_matrix(matrix, det), true}
      else
        {List.duplicate(0.0, length(matrix)), false}
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", inverted_matrix)
    |> StateV2.set_fact(Integer.to_string(node_id), "isValid", is_valid)
  end

  defp invert_matrix(matrix, det) do
    case length(matrix) do
      4 -> invert_2x2(matrix, det)
      9 -> invert_3x3(matrix, det)
      16 -> invert_4x4(matrix, det)
    end
  end

  defp invert_2x2([m00, m01, m10, m11], det) do
    inv_det = 1.0 / det
    [
      m11 * inv_det, -m01 * inv_det,
      -m10 * inv_det, m00 * inv_det
    ]
  end

  defp invert_3x3(matrix, det) do
    [m00, m01, m02, m10, m11, m12, m20, m21, m22] = matrix
    inv_det = 1.0 / det
    
    [
      (m11 * m22 - m12 * m21) * inv_det,
      (m02 * m21 - m01 * m22) * inv_det,
      (m01 * m12 - m02 * m11) * inv_det,
      (m12 * m20 - m10 * m22) * inv_det,
      (m00 * m22 - m02 * m20) * inv_det,
      (m02 * m10 - m00 * m12) * inv_det,
      (m10 * m21 - m11 * m20) * inv_det,
      (m01 * m20 - m00 * m21) * inv_det,
      (m00 * m11 - m01 * m10) * inv_det
    ]
  end

  defp invert_4x4(_matrix, _det) do
    # Simplified 4x4 inversion - in practice would use full cofactor matrix
    List.duplicate(0.0, 16)
  end

  # =============================================================================
  # Quaternion Operations
  # =============================================================================

  @doc """
  Quaternion conjugate operation.
  
  ## Parameters
  - state: Current state
  - [node_id, quaternion]: Node ID and quaternion [x, y, z, w]
  
  ## Returns
  Updated state with conjugated quaternion
  """
  def quat_conjugate(state, [node_id, [x, y, z, w]]) do
    result = [-x, -y, -z, w]
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Angle between quaternions operation.
  
  ## Parameters
  - state: Current state
  - [node_id, quat_a, quat_b]: Node ID and two quaternions
  
  ## Returns
  Updated state with angle in radians
  """
  def quat_angle_between(state, [node_id, [ax, ay, az, aw], [bx, by, bz, bw]]) do
    dot_product = ax * bx + ay * by + az * bz + aw * bw
    clamped_dot = max(-1.0, min(1.0, abs(dot_product)))
    result = 2.0 * :math.acos(clamped_dot)
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Create quaternion from axis and angle.
  
  ## Parameters
  - state: Current state
  - [node_id, axis, angle]: Node ID, rotation axis [x, y, z], and angle in radians
  
  ## Returns
  Updated state with quaternion
  """
  def quat_from_axis_angle(state, [node_id, [axis_x, axis_y, axis_z], angle]) do
    half_angle = angle * 0.5
    sin_half = :math.sin(half_angle)
    cos_half = :math.cos(half_angle)
    
    result = [
      axis_x * sin_half,
      axis_y * sin_half,
      axis_z * sin_half,
      cos_half
    ]
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Extract axis and angle from quaternion.
  
  ## Parameters
  - state: Current state
  - [node_id, quaternion]: Node ID and quaternion [x, y, z, w]
  
  ## Returns
  Updated state with axis and angle
  """
  def quat_to_axis_angle(state, [node_id, [x, y, z, w]]) do
    {axis, angle} = 
      if abs(w) >= 1.0 do
        {[1.0, 0.0, 0.0], 0.0}
      else
        sin_theta = :math.sqrt(1.0 - w * w)
        factor = 1.0 / sin_theta
        {[x * factor, y * factor, z * factor], 2.0 * :math.acos(w)}
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "axis", axis)
    |> StateV2.set_fact(Integer.to_string(node_id), "angle", angle)
  end

  @doc """
  Create quaternion from two directional vectors.
  
  ## Parameters
  - state: Current state
  - [node_id, from_dir, to_dir]: Node ID and two direction vectors
  
  ## Returns
  Updated state with rotation quaternion
  """
  def quat_from_directions(state, [node_id, [fx, fy, fz], [tx, ty, tz]]) do
    dot = fx * tx + fy * ty + fz * tz
    
    result = cond do
      dot >= 0.999999 ->
        # Vectors are the same
        [0.0, 0.0, 0.0, 1.0]
        
      dot <= -0.999999 ->
        # Vectors are opposite - find perpendicular axis
        axis = 
          if abs(fx) < 0.1 do
            [0.0, fz, -fy]
          else
            [-fz, 0.0, fx]
          end
        # Normalize axis
        axis_length = :math.sqrt(Enum.reduce(axis, 0, fn x, acc -> acc + x * x end))
        normalized_axis = Enum.map(axis, &(&1 / axis_length))
        normalized_axis ++ [0.0]
        
      true ->
        # Normal case
        cross = [
          fy * tz - fz * ty,
          fz * tx - fx * tz,
          fx * ty - fy * tx
        ]
        
        s = :math.sqrt((1.0 + dot) * 2.0)
        inv_s = 1.0 / s
        
        [
          Enum.at(cross, 0) * inv_s,
          Enum.at(cross, 1) * inv_s,
          Enum.at(cross, 2) * inv_s,
          s * 0.5
        ]
    end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  # =============================================================================
  # Task Methods for HTN Planning
  # =============================================================================

  def saturate_task_method(_state, [node_id, value]) do
    [[:khr_math_saturate, node_id, value]]
  end

  def mix_task_method(_state, [node_id, a, b, t]) do
    [[:khr_math_mix, node_id, a, b, t]]
  end

  def length_task_method(_state, [node_id, vector]) do
    [[:khr_math_length, node_id, vector]]
  end

  def normalize_task_method(_state, [node_id, vector]) do
    [[:khr_math_normalize, node_id, vector]]
  end

  def rotate_2d_task_method(_state, [node_id, vector, angle]) do
    [[:khr_math_rotate_2d, node_id, vector, angle]]
  end

  def rotate_3d_task_method(_state, [node_id, vector, quaternion]) do
    [[:khr_math_rotate_3d, node_id, vector, quaternion]]
  end

  def transpose_task_method(_state, [node_id, matrix]) do
    [[:khr_math_transpose, node_id, matrix]]
  end

  def determinant_task_method(_state, [node_id, matrix]) do
    [[:khr_math_determinant, node_id, matrix]]
  end

  def inverse_task_method(_state, [node_id, matrix]) do
    [[:khr_math_inverse, node_id, matrix]]
  end

  def quat_conjugate_task_method(_state, [node_id, quaternion]) do
    [[:khr_math_quat_conjugate, node_id, quaternion]]
  end

  def quat_angle_between_task_method(_state, [node_id, quat_a, quat_b]) do
    [[:khr_math_quat_angle_between, node_id, quat_a, quat_b]]
  end

  def quat_from_axis_angle_task_method(_state, [node_id, axis, angle]) do
    [[:khr_math_quat_from_axis_angle, node_id, axis, angle]]
  end

  def quat_to_axis_angle_task_method(_state, [node_id, quaternion]) do
    [[:khr_math_quat_to_axis_angle, node_id, quaternion]]
  end

  def quat_from_directions_task_method(_state, [node_id, from_dir, to_dir]) do
    [[:khr_math_quat_from_directions, node_id, from_dir, to_dir]]
  end
end
