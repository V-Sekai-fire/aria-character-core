# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcp.QCP.MultiPoint do
  @moduledoc """
  Multi-point rotation calculations for the QCP algorithm.

  Handles the complex quaternion calculation for aligning multiple point sets
  using the characteristic polynomial method.
  """

  alias AriaMath.Quaternion

  @doc """
  Calculates rotation quaternion for aligning multiple points using QCP algorithm.
  """
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

  @doc """
  Checks matrix stability before quaternion calculation.
  """
  @spec check_matrix_stability(map()) :: :ok | {:error, term()}
  def check_matrix_stability(qcp_state) do
    %{max_eigenvalue: max_eigenvalue, precision: precision} = qcp_state

    # Check for reasonable eigenvalue magnitude
    cond do
      not is_finite_number?(max_eigenvalue) ->
        {:error, :infinite_eigenvalue}

      abs(max_eigenvalue) > 1.0e12 ->
        {:error, :eigenvalue_too_large}

      abs(max_eigenvalue) < precision * 1000 ->
        {:error, :eigenvalue_too_small}

      true ->
        :ok
    end
  end

  @doc """
  Calculates quaternion components using the characteristic polynomial method.
  """
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
    if Enum.any?(determinants, fn d -> not is_finite_number?(d) end) do
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

  @doc """
  Safely multiplies and adds terms, handling numerical overflow.
  """
  @spec safe_multiply_add([{float(), float()}]) :: float()
  def safe_multiply_add(terms) do
    Enum.reduce(terms, 0.0, fn {coeff, value}, acc ->
      product = coeff * value
      if is_finite_number?(product) do
        acc + product
      else
        acc  # Skip infinite/NaN terms
      end
    end)
  end

  @doc """
  Finalizes and normalizes the quaternion.
  """
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
          {normalized_rotation, true} ->
            # Ensure canonical representation (w >= 0) without RMD flipping for multi-point
            {x, y, z, w} = normalized_rotation
            if w >= 0.0 do
              {:ok, {x, y, z, w}}
            else
              {:ok, {-x, -y, -z, -w}}
            end
          {_, false} -> {:error, :quaternion_normalization_failed}
        end
      end
    end
  end

  @doc """
  Checks if a number is finite (not NaN or infinity).
  """
  @spec is_finite_number?(number()) :: boolean()
  def is_finite_number?(x) when is_number(x) do
    not (x != x or x == :infinity or x == :neg_infinity)
  end
  def is_finite_number?(_), do: false
end
