# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSpatial.QCP.Rotation do
  @moduledoc false

  alias AriaMath.{Vector3, Quaternion}
  alias AriaSpatial.QCP.Validation

  @doc false
  @spec calculate(map()) :: {:ok, Quaternion.t()} | {:error, term()}
  def calculate(qcp_state) do
    %{moved: moved, target: target} = qcp_state

    cond do
      length(moved) == 1 ->
        calculate_single_point_rotation(hd(moved), hd(target))

      true ->
        calculate_multi_point_rotation(qcp_state)
    end
  end

  @doc false
  @spec calculate_single_point_rotation(Vector3.t(), Vector3.t()) :: {:ok, Quaternion.t()}
  def calculate_single_point_rotation(moved_point, target_point) do
    u_length = Vector3.length(moved_point)
    v_length = Vector3.length(target_point)
    norm_product = u_length * v_length

    if norm_product == 0.0 do
      {:ok, {0.0, 0.0, 0.0, 1.0}}
    else
      dot = Vector3.dot(moved_point, target_point)

      if dot < ((2.0e-15 - 1.0) * norm_product) do
        # Vectors are nearly opposite - return 180-degree rotation around perpendicular axis
        {normalized, _} = Vector3.normalize(moved_point)
        {nx, ny, nz} = normalized
        rotation = {nx, ny, nz, 0.0}
        {normalized_rotation, _} = Quaternion.normalize(rotation)
        {:ok, normalized_rotation}
      else
        # Standard quaternion calculation for rotation between vectors
        q0 = :math.sqrt(0.5 * (1.0 + dot / norm_product))
        coeff = 1.0 / (2.0 * q0 * norm_product)
        cross = Vector3.cross(target_point, moved_point)
        {cx, cy, cz} = cross
        rotation = {coeff * cx, coeff * cy, coeff * cz, q0}
        {normalized_rotation, _} = Quaternion.normalize(rotation)
        {:ok, normalized_rotation}
      end
    end
  end

  @doc false
  @spec calculate_multi_point_rotation(map()) :: {:ok, Quaternion.t()} | {:error, term()}
  def calculate_multi_point_rotation(qcp_state) do
    try do
      # Check for numerical stability before proceeding
      with :ok <- check_matrix_stability(qcp_state),
           {:ok, quaternion_components} <- calculate_quaternion_components(qcp_state),
           {:ok, normalized_quaternion} <- finalize_quaternion(quaternion_components, qcp_state.precision) do
        {:ok, normalized_quaternion}
      end
    rescue
      error -> {:error, {:quaternion_calculation_failed, error}}
    end
  end

  @doc false
  @spec check_matrix_stability(map()) :: :ok | {:error, term()}
  def check_matrix_stability(qcp_state) do
    %{max_eigenvalue: max_eigenvalue, precision: precision} = qcp_state

    # Check for reasonable eigenvalue magnitude
    cond do
      not Validation.is_finite_number?(max_eigenvalue) ->
        {:error, :infinite_eigenvalue}

      abs(max_eigenvalue) > 1.0e12 ->
        {:error, :eigenvalue_too_large}

      abs(max_eigenvalue) < precision * 1000 ->
        {:error, :eigenvalue_too_small}

      true ->
        :ok
    end
  end

  @doc false
  @spec calculate_quaternion_components(map()) :: {:ok, {float(), float(), float(), float()}} | {:error, term()}
  def calculate_quaternion_components(qcp_state) do
    %{
      sum_xz_minus_zx: sum_xz_minus_zx, sum_xy_minus_yx: sum_xy_minus_yx,
      sum_yz_minus_zy: sum_yz_minus_zy, sum_xx_minus_yy: sum_xx_minus_yy,
      sum_xy_plus_yx: sum_xy_plus_yx, sum_xz_plus_zx: sum_xz_plus_zx,
      sum_yy: sum_yy, sum_xx: sum_xx, sum_yz_plus_zy: sum_yz_plus_zy,
      sum_zz: sum_zz, sum_xx_plus_yy: sum_xx_plus_yy, max_eigenvalue: max_eigenvalue
    } = qcp_state

    # Build the 4x4 characteristic polynomial matrix elements
    a13 = -sum_xz_minus_zx
    a14 = sum_xy_minus_yx
    a21 = sum_yz_minus_zy
    a22 = sum_xx_minus_yy - sum_zz - max_eigenvalue
    a23 = sum_xy_plus_yx
    a24 = sum_xz_plus_zx
    a31 = a13
    a32 = a23
    a33 = sum_yy - sum_xx - sum_zz - max_eigenvalue
    a34 = sum_yz_plus_zy
    a41 = a14
    a42 = a24
    a43 = a34
    a44 = sum_zz - sum_xx_plus_yy - max_eigenvalue

    # Calculate 3x3 determinants for quaternion components with overflow checking
    determinants = [
      a33 * a44 - a43 * a34,  # a3344_4334
      a32 * a44 - a42 * a34,  # a3244_4234
      a32 * a43 - a42 * a33,  # a3243_4233
      a31 * a43 - a41 * a33,  # a3143_4133
      a31 * a44 - a41 * a34,  # a3144_4134
      a31 * a42 - a41 * a32   # a3142_4132
    ]

    # Check for numerical overflow in determinants
    if Enum.any?(determinants, fn d -> not Validation.is_finite_number?(d) end) do
      {:error, :determinant_overflow}
    else
      [a3344_4334, a3244_4234, a3243_4233, a3143_4133, a3144_4134, a3142_4132] = determinants

      # Calculate quaternion components with robust arithmetic
      quaternion_w = safe_multiply_add([{a22, a3344_4334}, {-a23, a3244_4234}, {a24, a3243_4233}])
      quaternion_x = safe_multiply_add([{a21, a3344_4334}, {-a23, a3144_4134}, {a24, a3143_4133}])
      quaternion_y = safe_multiply_add([{-a21, a3244_4234}, {a22, a3144_4134}, {-a24, a3142_4132}])
      quaternion_z = safe_multiply_add([{a21, a3243_4233}, {-a22, a3143_4133}, {a23, a3142_4132}])

      {:ok, {quaternion_w, quaternion_x, quaternion_y, quaternion_z}}
    end
  end

  @doc false
  @spec safe_multiply_add([{float(), float()}]) :: float()
  def safe_multiply_add(terms) do
    Enum.reduce(terms, 0.0, fn {coeff, value}, acc ->
      product = coeff * value
      if Validation.is_finite_number?(product) do
        acc + product
      else
        acc  # Skip infinite/NaN terms
      end
    end)
  end

  @doc false
  @spec finalize_quaternion({float(), float(), float(), float()}, float()) :: {:ok, Quaternion.t()} | {:error, term()}
  def finalize_quaternion({quaternion_w, quaternion_x, quaternion_y, quaternion_z}, precision) do
    # Check for degenerate quaternion components
    if Enum.all?([quaternion_w, quaternion_x, quaternion_y, quaternion_z], fn c -> abs(c) < precision end) do
      {:ok, {0.0, 0.0, 0.0, 1.0}}  # Identity quaternion
    else
      # Robust normalization approach
      components = [quaternion_w, quaternion_x, quaternion_y, quaternion_z]
      max_component = Enum.max_by(components, &abs/1)

      {norm_w, norm_x, norm_y, norm_z} =
        if abs(max_component) > 1.0e-12 do
          scale = 1.0 / max_component
          {quaternion_w * scale, quaternion_x * scale, quaternion_y * scale, quaternion_z * scale}
        else
          {quaternion_w, quaternion_x, quaternion_y, quaternion_z}
        end

      # Check final quaternion magnitude
      qsqr = norm_w * norm_w + norm_x * norm_x + norm_y * norm_y + norm_z * norm_z

      if qsqr < precision do
        {:ok, {0.0, 0.0, 0.0, 1.0}}
      else
        rotation = {norm_x, norm_y, norm_z, norm_w}
        case Quaternion.normalize(rotation) do
          {normalized_rotation, true} -> {:ok, normalized_rotation}
          {_, false} -> {:error, :quaternion_normalization_failed}
        end
      end
    end
  end
end
