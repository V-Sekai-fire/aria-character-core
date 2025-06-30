# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcp.Eigenvalue do
  @moduledoc """
  Eigenvalue refinement for QCP algorithm.

  This module implements the Newton-Raphson method for finding the maximum
  eigenvalue of the 4x4 QCP matrix, which is essential for optimal rotation calculation.
  """

  alias AriaQcp.State

  @type qcp_state :: State.qcp_state()

  @max_iterations 50
  @default_tolerance 1.0e-11

  @doc """
  Refine the eigenvalue using Newton-Raphson iteration.
  """
  @spec refine_eigenvalue(qcp_state()) :: {:ok, qcp_state()} | {:error, term()}
  def refine_eigenvalue(qcp_state) do
    %{precision: precision, max_eigenvalue: initial_eigenvalue} = qcp_state

    tolerance = max(precision, @default_tolerance)

    try do
      refined_eigenvalue = newton_raphson_eigenvalue(qcp_state, initial_eigenvalue, tolerance)
      {:ok, %{qcp_state | max_eigenvalue: refined_eigenvalue}}
    rescue
      error -> {:error, {:eigenvalue_refinement_failed, error}}
    end
  end

  @doc """
  Newton-Raphson iteration for eigenvalue refinement.
  """
  @spec newton_raphson_eigenvalue(qcp_state(), float(), float()) :: float()
  def newton_raphson_eigenvalue(qcp_state, initial_guess, tolerance) do
    newton_raphson_eigenvalue(qcp_state, initial_guess, tolerance, 0)
  end

  @spec newton_raphson_eigenvalue(qcp_state(), float(), float(), non_neg_integer()) :: float()
  defp newton_raphson_eigenvalue(qcp_state, lambda, tolerance, iteration) do
    if iteration >= @max_iterations do
      lambda  # Return current value if max iterations reached
    else
      {char_poly, char_poly_derivative} = characteristic_polynomial_and_derivative(qcp_state, lambda)

      if abs(char_poly_derivative) < 1.0e-14 do
        lambda  # Avoid division by near-zero derivative
      else
        delta = char_poly / char_poly_derivative
        new_lambda = lambda - delta

        if abs(delta) < tolerance do
          new_lambda
        else
          newton_raphson_eigenvalue(qcp_state, new_lambda, tolerance, iteration + 1)
        end
      end
    end
  end

  @doc """
  Calculate the characteristic polynomial and its derivative for the QCP matrix.
  """
  @spec characteristic_polynomial_and_derivative(qcp_state(), float()) :: {float(), float()}
  def characteristic_polynomial_and_derivative(qcp_state, lambda) do
    %{
      sum_xx_plus_yy: g, sum_xx_minus_yy: h,
      sum_xy_plus_yx: sum_xy_plus_yx, sum_xy_minus_yx: sum_xy_minus_yx,
      sum_xz_plus_zx: sum_xz_plus_zx, sum_xz_minus_zx: sum_xz_minus_zx,
      sum_yz_plus_zy: sum_yz_plus_zy, sum_yz_minus_zy: sum_yz_minus_zy
    } = qcp_state

    # Coefficients for the characteristic polynomial
    # The QCP characteristic polynomial is: λ⁴ - a₃λ³ - a₂λ² - a₁λ - a₀ = 0

    # Calculate polynomial coefficients
    a3 = 0.0  # Coefficient of λ³ (trace is always 0 for centered QCP matrix)

    a2 = -2.0 * (
      sum_xx_plus_yy * sum_xx_plus_yy +
      sum_xy_plus_yx * sum_xy_plus_yx +
      sum_xz_plus_zx * sum_xz_plus_zx +
      sum_yz_plus_zy * sum_yz_plus_zy
    ) / 4.0

    a1 = -8.0 * (
      sum_xy_minus_yx * sum_xz_minus_zx * sum_yz_minus_zy +
      sum_xy_plus_yx * sum_xz_plus_zx * sum_yz_plus_zy * h / 4.0
    )

    # a₀ calculation involves determinant of the inner 3x3 submatrix
    det_3x3 = calculate_3x3_determinant(qcp_state)
    a0 = -det_3x3

    # Evaluate characteristic polynomial: P(λ) = λ⁴ - a₃λ³ - a₂λ² - a₁λ - a₀
    char_poly = lambda * lambda * lambda * lambda -
                a3 * lambda * lambda * lambda -
                a2 * lambda * lambda -
                a1 * lambda -
                a0

    # Evaluate derivative: P'(λ) = 4λ³ - 3a₃λ² - 2a₂λ - a₁
    char_poly_derivative = 4.0 * lambda * lambda * lambda -
                          3.0 * a3 * lambda * lambda -
                          2.0 * a2 * lambda -
                          a1

    {char_poly, char_poly_derivative}
  end

  @doc """
  Calculate the determinant of the 3x3 inner matrix.
  """
  @spec calculate_3x3_determinant(qcp_state()) :: float()
  def calculate_3x3_determinant(qcp_state) do
    %{
      sum_xx: sum_xx, sum_xy: sum_xy, sum_xz: sum_xz,
      sum_yx: sum_yx, sum_yy: sum_yy, sum_yz: sum_yz,
      sum_zx: sum_zx, sum_zy: sum_zy, sum_zz: sum_zz
    } = qcp_state

    # Calculate determinant of the 3x3 matrix formed by the inner product sums
    # | sum_xx  sum_xy  sum_xz |
    # | sum_yx  sum_yy  sum_yz |
    # | sum_zx  sum_zy  sum_zz |

    det = sum_xx * (sum_yy * sum_zz - sum_yz * sum_zy) -
          sum_xy * (sum_yx * sum_zz - sum_yz * sum_zx) +
          sum_xz * (sum_yx * sum_zy - sum_yy * sum_zx)

    det
  end
end
