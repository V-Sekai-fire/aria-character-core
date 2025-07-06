# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.QCP.State do
  @moduledoc """
  State management functions for the QCP algorithm.

  Handles initialization, weight normalization, and point centering operations.
  """

  alias AriaMath.Vector3

  @min_weight 1.0e-12
  @max_weight 1.0e12

  @type point_set :: [Vector3.t()]
  @type weights :: [float()]

  @doc """
  Initializes the QCP state structure with all necessary data.
  """
  @spec initialize_qcp_state(point_set(), point_set(), weights(), boolean(), float()) ::
          {:ok, map()} | {:error, term()}
  def initialize_qcp_state(moved, target, weights, translate, precision) do
    try do
      weights_normalized = normalize_weights(weights, length(moved))

      qcp_state = %{
        moved: moved,
        target: target,
        weights: weights_normalized,
        translate: translate,
        precision: max(precision, 1.0e-15),  # Ensure minimum precision
        moved_center: {0.0, 0.0, 0.0},
        target_center: {0.0, 0.0, 0.0},
        w_sum: 0.0,
        # Inner product matrix components
        sum_xx: 0.0, sum_xy: 0.0, sum_xz: 0.0,
        sum_yx: 0.0, sum_yy: 0.0, sum_yz: 0.0,
        sum_zx: 0.0, sum_zy: 0.0, sum_zz: 0.0,
        # Derived sums for characteristic polynomial
        sum_xx_plus_yy: 0.0, sum_xx_minus_yy: 0.0,
        sum_xy_plus_yx: 0.0, sum_xy_minus_yx: 0.0,
        sum_xz_plus_zx: 0.0, sum_xz_minus_zx: 0.0,
        sum_yz_plus_zy: 0.0, sum_yz_minus_zy: 0.0,
        max_eigenvalue: 0.0,
        # Robustness tracking
        numerical_warnings: []
      }

      if translate do
        {:ok, center_and_translate_points(qcp_state)}
      else
        w_sum = Enum.sum(weights_normalized)
        {:ok, %{qcp_state | w_sum: w_sum}}
      end
    rescue
      error -> {:error, {:initialization_failed, error}}
    end
  end

  @doc """
  Normalizes weights to prevent numerical issues.
  """
  @spec normalize_weights(weights(), non_neg_integer()) :: weights()
  def normalize_weights([], point_count), do: List.duplicate(1.0, point_count)
  def normalize_weights(weights, _point_count) do
    # Clamp weights to prevent numerical issues
    Enum.map(weights, fn w ->
      cond do
        w < @min_weight -> @min_weight
        w > @max_weight -> @max_weight
        true -> w
      end
    end)
  end

  @doc """
  Centers points around their weighted centroids and updates state.
  """
  @spec center_and_translate_points(map()) :: map()
  def center_and_translate_points(qcp_state) do
    %{moved: moved, target: target, weights: weights} = qcp_state

    moved_center = calculate_weighted_center(moved, weights)
    target_center = calculate_weighted_center(target, weights)

    # Translate points to center around origin
    moved_centered = Enum.map(moved, fn point -> Vector3.sub(point, moved_center) end)
    target_centered = Enum.map(target, fn point -> Vector3.sub(point, target_center) end)

    w_sum = Enum.sum(weights)

    %{qcp_state |
      moved: moved_centered,
      target: target_centered,
      moved_center: moved_center,
      target_center: target_center,
      w_sum: w_sum
    }
  end

  @doc """
  Calculates the weighted center of a point set.
  """
  @spec calculate_weighted_center([Vector3.t()], [float()]) :: Vector3.t()
  def calculate_weighted_center(points, weights) do
    total_weight = Enum.sum(weights)

    if total_weight > @min_weight do
      weighted_sum = points
                     |> Enum.zip(weights)
                     |> Enum.reduce({0.0, 0.0, 0.0}, fn {point, weight}, acc ->
                       # Use robust addition to prevent overflow
                       scaled_point = Vector3.scale(point, weight)
                       Vector3.add(acc, scaled_point)
                     end)

      # Safeguard against division by very small numbers
      scale_factor = 1.0 / total_weight
      if abs(scale_factor) < @max_weight do
        Vector3.scale(weighted_sum, scale_factor)
      else
        # Fallback to geometric center if weights are degenerate
        geometric_center(points)
      end
    else
      # Fallback to geometric center if total weight is too small
      geometric_center(points)
    end
  end

  @doc """
  Calculates the geometric center (centroid) of a point set.
  """
  @spec geometric_center([Vector3.t()]) :: Vector3.t()
  def geometric_center([]), do: {0.0, 0.0, 0.0}
  def geometric_center(points) do
    count = length(points)
    sum = Enum.reduce(points, {0.0, 0.0, 0.0}, &Vector3.add/2)
    Vector3.scale(sum, 1.0 / count)
  end

  @doc """
  Calculates the inner product matrix for the QCP algorithm.
  """
  @spec calculate_inner_product(map()) :: {:ok, map()} | {:error, term()}
  def calculate_inner_product(qcp_state) do
    %{moved: moved, target: target, weights: weights} = qcp_state

    # Initialize sums
    sums = Enum.zip([moved, target, weights])
           |> Enum.reduce(
             %{
               sum_xx: 0.0, sum_xy: 0.0, sum_xz: 0.0,
               sum_yx: 0.0, sum_yy: 0.0, sum_yz: 0.0,
               sum_zx: 0.0, sum_zy: 0.0, sum_zz: 0.0,
               sum_of_squares1: 0.0, sum_of_squares2: 0.0
             },
             fn {moved_point, target_point, weight}, acc ->
               # Apply weight to moved point
               weighted_moved = Vector3.scale(moved_point, weight)
               {wx, wy, wz} = weighted_moved
               {tx, ty, tz} = target_point

               # Calculate dot products for inner product matrix
               new_sums = %{
                 sum_xx: acc.sum_xx + wx * tx,
                 sum_xy: acc.sum_xy + wx * ty,
                 sum_xz: acc.sum_xz + wx * tz,
                 sum_yx: acc.sum_yx + wy * tx,
                 sum_yy: acc.sum_yy + wy * ty,
                 sum_yz: acc.sum_yz + wy * tz,
                 sum_zx: acc.sum_zx + wz * tx,
                 sum_zy: acc.sum_zy + wz * ty,
                 sum_zz: acc.sum_zz + wz * tz,
                 sum_of_squares1: acc.sum_of_squares1 + Vector3.dot(weighted_moved, moved_point),
                 sum_of_squares2: acc.sum_of_squares2 + weight * Vector3.dot(target_point, target_point)
               }

               new_sums
             end)

    # Calculate maximum eigenvalue exactly as in C reference
    # From C: mxEigenV = E0 = (G1 + G2) * 0.5
    # where G1 = sum of squares of moved points (weighted)
    # and G2 = sum of squares of target points (weighted)
    max_eigenvalue = (sums.sum_of_squares1 + sums.sum_of_squares2) * 0.5

    updated_state = %{qcp_state |
      sum_xx: sums.sum_xx, sum_xy: sums.sum_xy, sum_xz: sums.sum_xz,
      sum_yx: sums.sum_yx, sum_yy: sums.sum_yy, sum_yz: sums.sum_yz,
      sum_zx: sums.sum_zx, sum_zy: sums.sum_zy, sum_zz: sums.sum_zz,
      sum_xx_plus_yy: sums.sum_xx + sums.sum_yy,
      sum_xx_minus_yy: sums.sum_xx - sums.sum_yy,
      sum_xy_plus_yx: sums.sum_xy + sums.sum_yx,
      sum_xy_minus_yx: sums.sum_xy - sums.sum_yx,
      sum_xz_plus_zx: sums.sum_xz + sums.sum_zx,
      sum_xz_minus_zx: sums.sum_xz - sums.sum_zx,
      sum_yz_plus_zy: sums.sum_yz + sums.sum_zy,
      sum_yz_minus_zy: sums.sum_yz - sums.sum_zy,
      max_eigenvalue: max_eigenvalue
    }

    {:ok, updated_state}
  end
end
