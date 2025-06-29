defmodule AriaEngineCore.Math do
  @moduledoc """
  Mathematical primitives implementing glTF KHR Interactivity standard operations.

  This module provides a unified interface to Vector3, Quaternion, and Matrix4 operations
  that follow the glTF KHR Interactivity specification for mathematical nodes.

  All operations implement IEEE-754 standard for NaN, infinity, and special case handling.
  """

  # Re-export all mathematical types and operations
  defdelegate new_vector3(x, y, z), to: AriaEngineCore.Math.Vector3, as: :new
  defdelegate new_quaternion(x, y, z, w), to: AriaEngineCore.Math.Quaternion, as: :new
  defdelegate new_matrix4(m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15), to: AriaEngineCore.Math.Matrix4, as: :new
  defdelegate new_ik_node_3d(opts), to: AriaEngineCore.Math.IKNode3D, as: :new

  # Commonly used constants
  defdelegate vector3_zero(), to: AriaEngineCore.Math.Vector3, as: :zero
  defdelegate vector3_unit_x(), to: AriaEngineCore.Math.Vector3, as: :unit_x
  defdelegate vector3_unit_y(), to: AriaEngineCore.Math.Vector3, as: :unit_y
  defdelegate vector3_unit_z(), to: AriaEngineCore.Math.Vector3, as: :unit_z

  defdelegate quaternion_identity(), to: AriaEngineCore.Math.Quaternion, as: :identity
  defdelegate matrix4_identity(), to: AriaEngineCore.Math.Matrix4, as: :identity
  defdelegate matrix4_zero(), to: AriaEngineCore.Math.Matrix4, as: :zero

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
      # Vector3 operations
      vector_length: &AriaEngineCore.Math.Vector3.length/1,
      vector_normalize: &AriaEngineCore.Math.Vector3.normalize/1,
      vector_dot: &AriaEngineCore.Math.Vector3.dot/2,
      vector_cross: &AriaEngineCore.Math.Vector3.cross/2,
      vector_add: &AriaEngineCore.Math.Vector3.add/2,
      vector_sub: &AriaEngineCore.Math.Vector3.sub/2,
      vector_mul: &AriaEngineCore.Math.Vector3.mul/2,
      vector_min: &AriaEngineCore.Math.Vector3.min/2,
      vector_max: &AriaEngineCore.Math.Vector3.max/2,
      vector_clamp: &AriaEngineCore.Math.Vector3.clamp/3,
      vector_mix: &AriaEngineCore.Math.Vector3.mix/3,
      vector_abs: &AriaEngineCore.Math.Vector3.abs/1,

      # Quaternion operations
      quat_conjugate: &AriaEngineCore.Math.Quaternion.conjugate/1,
      quat_mul: &AriaEngineCore.Math.Quaternion.multiply/2,
      quat_angle_between: &AriaEngineCore.Math.Quaternion.angle_between/2,
      quat_from_axis_angle: &AriaEngineCore.Math.Quaternion.from_axis_angle/2,
      quat_to_axis_angle: &AriaEngineCore.Math.Quaternion.to_axis_angle/1,
      quat_from_directions: &AriaEngineCore.Math.Quaternion.from_directions/2,
      quat_normalize: &AriaEngineCore.Math.Quaternion.normalize/1,
      quat_slerp: &AriaEngineCore.Math.Quaternion.slerp/3,

      # Matrix4 operations
      mat_mul: &AriaEngineCore.Math.Matrix4.multiply/2,
      mat_determinant: &AriaEngineCore.Math.Matrix4.determinant/1,
      mat_inverse: &AriaEngineCore.Math.Matrix4.inverse/1,
      mat_transpose: &AriaEngineCore.Math.Matrix4.transpose/1,
      mat_transform_point: &AriaEngineCore.Math.Matrix4.transform_point/2,
      mat_transform_direction: &AriaEngineCore.Math.Matrix4.transform_direction/2,

      # Transformation operations
      mat_translation: &AriaEngineCore.Math.Matrix4.translation/1,
      mat_rotation: &AriaEngineCore.Math.Matrix4.rotation/1,
      mat_scaling: &AriaEngineCore.Math.Matrix4.scaling/1,
      mat_compose: &AriaEngineCore.Math.Matrix4.compose/3,
      mat_decompose: &AriaEngineCore.Math.Matrix4.decompose/1
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
