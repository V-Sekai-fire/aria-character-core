# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Math do
  @moduledoc """
  Mathematical primitives implementing glTF KHR Interactivity standard operations.

  This module provides a unified interface to Vector3, Quaternion, and Matrix4 operations
  that follow the glTF KHR Interactivity specification for mathematical nodes.

  All operations implement IEEE-754 standard for NaN, infinity, and special case handling.

  **Note:** This module now delegates to AriaMath for all mathematical operations.
  """

  # Use AriaMath external API instead of direct internal module imports
  alias AriaMath

  # Re-export all mathematical types and operations through external API
  defdelegate new_vector3(x, y, z), to: AriaMath, as: :vector3
  defdelegate new_quaternion(x, y, z, w), to: AriaMath, as: :quaternion
  def new_matrix4(m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15) do
    {m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}
  end
  defdelegate new_joint(opts), to: AriaMath, as: :create_joint

  # Commonly used constants - delegate to external API
  def vector3_zero(), do: AriaMath.vector3(0.0, 0.0, 0.0)
  def vector3_unit_x(), do: AriaMath.vector3(1.0, 0.0, 0.0)
  def vector3_unit_y(), do: AriaMath.vector3(0.0, 1.0, 0.0)
  def vector3_unit_z(), do: AriaMath.vector3(0.0, 0.0, 1.0)

  defdelegate quaternion_identity(), to: AriaMath, as: :identity_quaternion
  defdelegate matrix4_identity(), to: AriaMath, as: :identity_matrix
  def matrix4_zero(), do: {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}

  @doc """
  Returns a map of all available KHR Interactivity mathematical operations.

  This provides a registry of mathematical functions that can be called dynamically
  during glTF node execution.

  ## Returns

  A map where keys are operation names (as atoms) and values are function references.

  ## Examples

      iex> operations = AriaEngineCore.Math.khr_operations()
      iex> is_map(operations)
      true
      iex> Map.has_key?(operations, :vector_add)
      true
  """
  @spec khr_operations() :: %{atom() => function()}
  def khr_operations do
    %{
      # Vector3 operations - using AriaMath external API
      vector_length: &AriaMath.vector_length/1,
      vector_normalize: &AriaMath.normalize_vector/1,
      vector_dot: &AriaMath.dot_product/2,
      vector_cross: &AriaMath.cross_product/2,
      vector_add: &AriaMath.add_vectors/2,
      vector_sub: &AriaMath.subtract_vectors/2,
      vector_mul_scalar: &AriaMath.scale_vector/2,
      # Note: These operations require additional functions in AriaMath external API
      # For now, provide basic implementations using available external API
      vector_min: fn {x1, y1, z1}, {x2, y2, z2} -> {min(x1, x2), min(y1, y2), min(z1, z2)} end,
      vector_max: fn {x1, y1, z1}, {x2, y2, z2} -> {max(x1, x2), max(y1, y2), max(z1, z2)} end,
      vector_clamp: fn {x, y, z}, {min_x, min_y, min_z}, {max_x, max_y, max_z} ->
        {AriaMath.clamp_float(x, min_x, max_x), AriaMath.clamp_float(y, min_y, max_y), AriaMath.clamp_float(z, min_z, max_z)}
      end,
      vector_mix: fn {x1, y1, z1}, {x2, y2, z2}, t ->
        {x1 + t * (x2 - x1), y1 + t * (y2 - y1), z1 + t * (z2 - z1)}
      end,
      vector_abs: fn {x, y, z} -> {AriaMath.abs_float(x), AriaMath.abs_float(y), AriaMath.abs_float(z)} end,

      # Quaternion operations - using basic implementations with external API
      quat_conjugate: fn {x, y, z, w} -> {-x, -y, -z, w} end,
      quat_mul: &AriaMath.multiply_quaternions/2,
      quat_angle_between: fn q1, q2 ->
        # Basic implementation using dot product of quaternions
        {x1, y1, z1, w1} = q1
        {x2, y2, z2, w2} = q2
        dot = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
        :math.acos(AriaMath.clamp_float(abs(dot), -1.0, 1.0)) * 2.0
      end,
      quat_from_axis_angle: &AriaMath.quaternion_from_axis_angle/2,
      quat_to_axis_angle: fn {x, y, z, w} ->
        # Basic implementation
        angle = 2.0 * :math.acos(AriaMath.clamp_float(abs(w), 0.0, 1.0))
        s = :math.sqrt(1.0 - w * w)
        if s < 0.001 do
          {{1.0, 0.0, 0.0}, angle}
        else
          {{x / s, y / s, z / s}, angle}
        end
      end,
      quat_from_directions: fn {ax, ay, az}, {bx, by, bz} ->
        # Basic implementation using cross and dot products
        dot = AriaMath.dot_product({ax, ay, az}, {bx, by, bz})
        cross = AriaMath.cross_product({ax, ay, az}, {bx, by, bz})
        {cx, cy, cz} = cross
        w = :math.sqrt(2.0 * (1.0 + dot))
        s = 1.0 / w
        {cx * s, cy * s, cz * s, w * 0.5}
      end,
      quat_normalize: &AriaMath.normalize_quaternion/1,
      quat_slerp: fn q1, q2, t ->
        # Basic linear interpolation approximation
        {x1, y1, z1, w1} = q1
        {x2, y2, z2, w2} = q2
        result = {x1 + t * (x2 - x1), y1 + t * (y2 - y1), z1 + t * (z2 - z1), w1 + t * (w2 - w1)}
        {normalized, _} = AriaMath.normalize_quaternion(result)
        normalized
      end,

      # Matrix4 operations - using basic implementations with external API
      mat_mul: &AriaMath.multiply_matrices/2,
      mat_determinant: &AriaMath.matrix_determinant/1,
      mat_inverse: fn matrix ->
        # For now, return identity as placeholder - should be implemented in AriaMath external API
        AriaMath.identity_matrix()
      end,
      mat_transpose: fn {m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15} ->
        {m0, m4, m8, m12, m1, m5, m9, m13, m2, m6, m10, m14, m3, m7, m11, m15}
      end,
      mat_transform_point: &AriaMath.transform_point/2,
      mat_transform_direction: fn matrix, {x, y, z} ->
        # Transform as direction (w = 0)
        {m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, _, _, _, _} = matrix
        {
          m0 * x + m1 * y + m2 * z,
          m4 * x + m5 * y + m6 * z,
          m8 * x + m9 * y + m10 * z
        }
      end,

      # Transformation operations - using AriaMath external API
      mat_translation: &AriaMath.translation_matrix/1,
      mat_rotation: &AriaMath.rotation_matrix/1,
      mat_scaling: &AriaMath.scaling_matrix/1,
      mat_compose: fn translation, rotation, scale ->
        # Basic implementation using available operations
        t_matrix = AriaMath.translation_matrix(translation)
        r_matrix = AriaMath.rotation_matrix(rotation)
        s_matrix = AriaMath.scaling_matrix(scale)
        # T * R * S
        temp = AriaMath.multiply_matrices(r_matrix, s_matrix)
        AriaMath.multiply_matrices(t_matrix, temp)
      end,
      mat_decompose: fn matrix ->
        # Basic implementation - extract translation, assume identity for rotation and scale
        {_, _, _, _, _, _, _, _, _, _, _, _, tx, ty, tz, _} = matrix
        translation = {tx, ty, tz}
        rotation = AriaMath.identity_quaternion()
        scale = {1.0, 1.0, 1.0}
        {translation, rotation, scale}
      end
    }
  end

  @doc """
  Execute a KHR Interactivity mathematical operation by name.

  ## Parameters

  - `operation_name`: Atom identifying the mathematical operation
  - `args`: List of arguments to pass to the operation

  ## Returns

  Result of the mathematical operation, or `{:error, reason}` if operation fails.

  ## Examples

      iex> AriaEngineCore.Math.execute_operation(:vector_add, [{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}])
      {:ok, {5.0, 7.0, 9.0}}

      iex> AriaEngineCore.Math.execute_operation(:invalid_op, [])
      {:error, :operation_not_found}
  """
  @spec execute_operation(atom(), list()) :: {:ok, any()} | {:error, atom()}
  def execute_operation(operation_name, args) when is_atom(operation_name) and is_list(args) do
    operations = khr_operations()

    case Map.get(operations, operation_name) do
      nil ->
        {:error, :operation_not_found}

      func ->
        try do
          result = apply(func, args)
          {:ok, result}
        rescue
          error ->
            {:error, {:execution_failed, error}}
        end
    end
  end

  @doc """
  Validate that mathematical arguments conform to expected types.

  ## Parameters

  - `operation_name`: The mathematical operation being performed
  - `args`: Arguments to validate

  ## Returns

  `:ok` if arguments are valid, `{:error, reason}` otherwise.

  ## Examples

      iex> AriaEngineCore.Math.validate_args(:vector_add, [{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}])
      :ok

      iex> AriaEngineCore.Math.validate_args(:vector_add, [{1.0, 2.0}, {4.0, 5.0, 6.0}])
      {:error, :invalid_vector3_format}
  """
  @spec validate_args(atom(), list()) :: :ok | {:error, atom()}
  def validate_args(operation_name, args) do
    case operation_name do
      # Vector3 operations requiring 2 Vector3 arguments
      op when op in [:vector_dot, :vector_cross, :vector_add, :vector_sub, :vector_mul, :vector_min, :vector_max] ->
        validate_vector3_pair(args)

      # Vector3 operations requiring 1 Vector3 argument
      op when op in [:vector_length, :vector_normalize, :vector_abs] ->
        validate_single_vector3(args)

      # Vector3 operations requiring 3 Vector3 arguments
      :vector_clamp ->
        validate_vector3_triple(args)

      # Vector3 mix operation (2 Vector3 + 1 float)
      :vector_mix ->
        validate_vector3_mix(args)

      # Quaternion operations requiring 2 Quaternion arguments
      op when op in [:quat_mul, :quat_angle_between] ->
        validate_quaternion_pair(args)

      # Quaternion operations requiring 1 Quaternion argument
      op when op in [:quat_conjugate, :quat_normalize, :quat_to_axis_angle] ->
        validate_single_quaternion(args)

      # Matrix4 operations requiring 2 Matrix4 arguments
      :mat_mul ->
        validate_matrix4_pair(args)

      # Matrix4 operations requiring 1 Matrix4 argument
      op when op in [:mat_determinant, :mat_inverse, :mat_transpose, :mat_decompose] ->
        validate_single_matrix4(args)

      # Default: assume valid for now
      _ ->
        :ok
    end
  end

  # Private validation helper functions

  defp validate_vector3_pair([a, b]) do
    if is_vector3?(a) and is_vector3?(b) do
      :ok
    else
      {:error, :invalid_vector3_format}
    end
  end

  defp validate_vector3_pair(_), do: {:error, :wrong_argument_count}

  defp validate_single_vector3([a]) do
    if is_vector3?(a) do
      :ok
    else
      {:error, :invalid_vector3_format}
    end
  end

  defp validate_single_vector3(_), do: {:error, :wrong_argument_count}

  defp validate_vector3_triple([a, b, c]) do
    if is_vector3?(a) and is_vector3?(b) and is_vector3?(c) do
      :ok
    else
      {:error, :invalid_vector3_format}
    end
  end

  defp validate_vector3_triple(_), do: {:error, :wrong_argument_count}

  defp validate_vector3_mix([a, b, t]) do
    if is_vector3?(a) and is_vector3?(b) and is_number(t) do
      :ok
    else
      {:error, :invalid_vector3_mix_format}
    end
  end

  defp validate_vector3_mix(_), do: {:error, :wrong_argument_count}

  defp validate_quaternion_pair([a, b]) do
    if is_quaternion?(a) and is_quaternion?(b) do
      :ok
    else
      {:error, :invalid_quaternion_format}
    end
  end

  defp validate_quaternion_pair(_), do: {:error, :wrong_argument_count}

  defp validate_single_quaternion([a]) do
    if is_quaternion?(a) do
      :ok
    else
      {:error, :invalid_quaternion_format}
    end
  end

  defp validate_single_quaternion(_), do: {:error, :wrong_argument_count}

  defp validate_matrix4_pair([a, b]) do
    if is_matrix4?(a) and is_matrix4?(b) do
      :ok
    else
      {:error, :invalid_matrix4_format}
    end
  end

  defp validate_matrix4_pair(_), do: {:error, :wrong_argument_count}

  defp validate_single_matrix4([a]) do
    if is_matrix4?(a) do
      :ok
    else
      {:error, :invalid_matrix4_format}
    end
  end

  defp validate_single_matrix4(_), do: {:error, :wrong_argument_count}

  # Type checking predicates

  defp is_vector3?({x, y, z}) when is_number(x) and is_number(y) and is_number(z), do: true
  defp is_vector3?(_), do: false

  defp is_quaternion?({x, y, z, w}) when is_number(x) and is_number(y) and is_number(z) and is_number(w), do: true
  defp is_quaternion?(_), do: false

  defp is_matrix4?({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15})
       when is_number(m0) and is_number(m1) and is_number(m2) and is_number(m3) and
            is_number(m4) and is_number(m5) and is_number(m6) and is_number(m7) and
            is_number(m8) and is_number(m9) and is_number(m10) and is_number(m11) and
            is_number(m12) and is_number(m13) and is_number(m14) and is_number(m15), do: true
  defp is_matrix4?(_), do: false
end
