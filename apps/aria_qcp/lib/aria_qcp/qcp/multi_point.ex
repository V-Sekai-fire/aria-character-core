# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.QCP.MultiPoint do
  @moduledoc """
  Multi-point rotation calculations for the QCP algorithm.

  Handles the complex quaternion calculation for aligning multiple point sets
  using the characteristic polynomial method.
  """

  alias AriaMath.Quaternion
  alias AriaQcp.QCP.Utils

  @doc """
  Calculates rotation quaternion for aligning multiple points using QCP algorithm.
  """
  @spec calculate_multi_point_rotation(map()) :: {:ok, Quaternion.t()} | {:error, term()}
  def calculate_multi_point_rotation(qcp_state) do
    try do
      # Check for numerical stability before proceeding
      with :ok <- check_matrix_stability(qcp_state),
           {:ok, quaternion_components} <- calculate_quaternion_components(qcp_state) do
        {:ok, quaternion_components}
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

      # More lenient threshold for extreme weights - allow very small eigenvalues
      abs(max_eigenvalue) < precision * 1.0e-6 ->
        {:error, :eigenvalue_too_small}

      true ->
        :ok
    end
  end

  @doc """
  Calculates quaternion components using the characteristic polynomial method.
  Direct translation from the C reference implementation.
  """
  @spec calculate_quaternion_components(map()) :: {:ok, {float(), float(), float(), float()}} | {:error, term()}
  def calculate_quaternion_components(qcp_state) do
    %{
      sum_xx: sxx, sum_xy: sxy, sum_xz: sxz,
      sum_yx: syx, sum_yy: syy, sum_yz: syz,
      sum_zx: szx, sum_zy: szy, sum_zz: szz,
      max_eigenvalue: mx_eigenvalue
    } = qcp_state

    # Direct translation from C code - build 4x4 matrix elements
    # From C: SxzpSzx = Sxz + Szx; etc.
    sxz_p_szx = sxz + szx
    syz_p_szy = syz + szy
    sxy_p_syx = sxy + syx
    syz_m_szy = syz - szy
    sxz_m_szx = sxz - szx
    sxy_m_syx = sxy - syx
    sxx_p_syy = sxx + syy
    sxx_m_syy = sxx - syy

    # Build the 4x4 characteristic matrix elements exactly as in C
    a11 = sxx_p_syy + szz - mx_eigenvalue
    a12 = syz_m_szy
    a13 = -sxz_m_szx
    a14 = sxy_m_syx
    a21 = syz_m_szy
    a22 = sxx_m_syy - szz - mx_eigenvalue
    a23 = sxy_p_syx
    a24 = sxz_p_szx
    a31 = a13
    a32 = a23
    a33 = syy - sxx - szz - mx_eigenvalue
    a34 = syz_p_szy
    a41 = a14
    a42 = a24
    a43 = a34
    a44 = szz - sxx_p_syy - mx_eigenvalue

    # Calculate cofactor determinants exactly as in C
    a3344_4334 = a33 * a44 - a43 * a34
    a3244_4234 = a32 * a44 - a42 * a34
    a3243_4233 = a32 * a43 - a42 * a33
    a3143_4133 = a31 * a43 - a41 * a33
    a3144_4134 = a31 * a44 - a41 * a34
    a3142_4132 = a31 * a42 - a41 * a32

    # Calculate quaternion components exactly as in C
    q1 = a22 * a3344_4334 - a23 * a3244_4234 + a24 * a3243_4233
    q2 = -a21 * a3344_4334 + a23 * a3144_4134 - a24 * a3143_4133
    q3 = a21 * a3244_4234 - a22 * a3144_4134 + a24 * a3142_4132
    q4 = -a21 * a3243_4233 + a22 * a3143_4133 - a23 * a3142_4132

    qsqr = q1 * q1 + q2 * q2 + q3 * q3 + q4 * q4

    # Handle small qsqr case exactly as in C
    evecprec = 1.0e-6
    {final_q1, final_q2, final_q3, final_q4, final_qsqr} =
      if qsqr < evecprec do
        handle_small_qsqr(a11, a12, a13, a14, a21, a22, a23, a24,
                          a31, a32, a33, a34, a41, a42, a43, a44, evecprec)
      else
        {q1, q2, q3, q4, qsqr}
      end

    if final_qsqr < evecprec do
      # Return identity quaternion as in C
      {:ok, {0.0, 0.0, 0.0, 1.0}}
    else
      # Normalize quaternion
      normq = :math.sqrt(final_qsqr)
      normalized_q1 = final_q1 / normq
      normalized_q2 = final_q2 / normq
      normalized_q3 = final_q3 / normq
      normalized_q4 = final_q4 / normq

      # Return in (x,y,z,w) order for our API (C uses q1=w, q2=x, q3=y, q4=z)
      {:ok, {normalized_q2, normalized_q3, normalized_q4, normalized_q1}}
    end
  end

  # Handle small qsqr case exactly as in C reference
  defp handle_small_qsqr(a11, a12, a13, a14, a21, a22, a23, a24,
                        a31, a32, a33, a34, a41, a42, a43, a44, evecprec) do
    # Try second column of adjoint matrix
    a3344_4334 = a33 * a44 - a43 * a34
    a3244_4234 = a32 * a44 - a42 * a34
    a3243_4233 = a32 * a43 - a42 * a33
    a3143_4133 = a31 * a43 - a41 * a33
    a3144_4134 = a31 * a44 - a41 * a34
    a3142_4132 = a31 * a42 - a41 * a32

    q1 = a12 * a3344_4334 - a13 * a3244_4234 + a14 * a3243_4233
    q2 = -a11 * a3344_4334 + a13 * a3144_4134 - a14 * a3143_4133
    q3 = a11 * a3244_4234 - a12 * a3144_4134 + a14 * a3142_4132
    q4 = -a11 * a3243_4233 + a12 * a3143_4133 - a13 * a3142_4132
    qsqr = q1 * q1 + q2 * q2 + q3 * q3 + q4 * q4

    if qsqr < evecprec do
      # Try third column
      a1324_1423 = a13 * a24 - a14 * a23
      a1224_1422 = a12 * a24 - a14 * a22
      a1223_1322 = a12 * a23 - a13 * a22
      a1124_1421 = a11 * a24 - a14 * a21
      a1123_1321 = a11 * a23 - a13 * a21
      a1122_1221 = a11 * a22 - a12 * a21

      q1 = a42 * a1324_1423 - a43 * a1224_1422 + a44 * a1223_1322
      q2 = -a41 * a1324_1423 + a43 * a1124_1421 - a44 * a1123_1321
      q3 = a41 * a1224_1422 - a42 * a1124_1421 + a44 * a1122_1221
      q4 = -a41 * a1223_1322 + a42 * a1123_1321 - a43 * a1122_1221
      qsqr = q1 * q1 + q2 * q2 + q3 * q3 + q4 * q4

      if qsqr < evecprec do
        # Try fourth column
        q1 = a32 * a1324_1423 - a33 * a1224_1422 + a34 * a1223_1322
        q2 = -a31 * a1324_1423 + a33 * a1124_1421 - a34 * a1123_1321
        q3 = a31 * a1224_1422 - a32 * a1124_1421 + a34 * a1122_1221
        q4 = -a31 * a1223_1322 + a32 * a1123_1321 - a33 * a1122_1221
        qsqr = q1 * q1 + q2 * q2 + q3 * q3 + q4 * q4

        {q1, q2, q3, q4, qsqr}
      else
        {q1, q2, q3, q4, qsqr}
      end
    else
      {q1, q2, q3, q4, qsqr}
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
            # Apply RMD check to ensure pure rotation
            final_quaternion = Utils.apply_rmd_flipping_check(normalized_rotation)
            {:ok, final_quaternion}
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
