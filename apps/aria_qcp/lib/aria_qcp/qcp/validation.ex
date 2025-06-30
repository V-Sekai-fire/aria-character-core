# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcp.QCP.Validation do
  @moduledoc """
  Validation functions for the QCP algorithm.

  Handles validation of point sets, weights, numerical stability checks,
  and geometric validation of QCP results.
  """

  alias AriaMath.{Vector3, Quaternion}

  @max_points 10_000
  @min_weight 1.0e-12
  @max_weight 1.0e12
  @default_tolerance 1.0e-10

  @type point_set :: [Vector3.t()]
  @type weights :: [float()]
  @type rotation :: {float(), float(), float(), float()}
  @type translation :: Vector3.t()
  @type validation_error ::
    :empty_point_sets |
    :mismatched_point_set_sizes |
    :mismatched_weight_count |
    :negative_weights |
    :too_many_points |
    :invalid_weights |
    :degenerate_points |
    :numerical_instability |
    :invalid_rotation |
    :points_not_aligned |
    :vectors_not_aligned |
    :incorrect_rotation_angle |
    :rotations_not_equivalent |
    :distances_not_preserved |
    :improper_rotation |
    :orthogonality_not_preserved |
    :transformation_mismatch

  @doc """
  Validates all inputs for the QCP algorithm.
  """
  @spec validate_inputs(point_set(), point_set(), weights()) :: :ok | {:error, validation_error()}
  def validate_inputs(moved, target, weights) do
    with :ok <- validate_point_sets(moved, target),
         :ok <- validate_weights(weights, length(moved)),
         :ok <- validate_numerical_stability(moved, target) do
      :ok
    end
  end

  @doc """
  Validates point sets for basic requirements.
  """
  @spec validate_point_sets(point_set(), point_set()) :: :ok | {:error, validation_error()}
  def validate_point_sets(moved, target) do
    cond do
      length(moved) == 0 or length(target) == 0 ->
        {:error, :empty_point_sets}

      length(moved) != length(target) ->
        {:error, :mismatched_point_set_sizes}

      length(moved) > @max_points ->
        {:error, :too_many_points}

      not all_valid_vectors?(moved) or not all_valid_vectors?(target) ->
        {:error, :degenerate_points}

      true ->
        :ok
    end
  end

  @doc """
  Validates weight array for consistency and numerical stability.
  """
  @spec validate_weights(weights(), non_neg_integer()) :: :ok | {:error, validation_error()}
  def validate_weights(weights, point_count) do
    cond do
      length(weights) > 0 and length(weights) != point_count ->
        {:error, :mismatched_weight_count}

      Enum.any?(weights, fn w -> w < 0.0 end) ->
        {:error, :negative_weights}

      Enum.any?(weights, fn w -> not is_finite_number?(w) end) ->
        {:error, :invalid_weights}

      Enum.any?(weights, fn w -> w > @max_weight end) ->
        {:error, :invalid_weights}

      Enum.all?(weights, fn w -> w < @min_weight end) and length(weights) > 0 ->
        {:error, :invalid_weights}

      true ->
        :ok
    end
  end

  @doc """
  Validates numerical stability of point sets.
  """
  @spec validate_numerical_stability(point_set(), point_set()) :: :ok | {:error, validation_error()}
  def validate_numerical_stability(moved, target) do
    # Check for degenerate cases that could cause numerical instability
    moved_span = calculate_point_span(moved)
    target_span = calculate_point_span(target)

    cond do
      moved_span < 1.0e-12 and length(moved) > 1 ->
        {:error, :degenerate_points}

      target_span < 1.0e-12 and length(target) > 1 ->
        {:error, :degenerate_points}

      true ->
        :ok
    end
  end

  @doc """
  Checks if all vectors in a point set are valid (finite numbers).
  """
  @spec all_valid_vectors?(point_set()) :: boolean()
  def all_valid_vectors?(points) do
    Enum.all?(points, fn {x, y, z} ->
      is_finite_number?(x) and is_finite_number?(y) and is_finite_number?(z)
    end)
  end

  @doc """
  Checks if a number is finite (not NaN or infinity).
  """
  @spec is_finite_number?(number()) :: boolean()
  def is_finite_number?(x) when is_number(x) do
    not (x != x or x == :infinity or x == :neg_infinity)
  end
  def is_finite_number?(_), do: false

  @doc """
  Calculates the maximum span (range) of points in any dimension.
  """
  @spec calculate_point_span(point_set()) :: float()
  def calculate_point_span(points) when length(points) <= 1, do: 0.0
  def calculate_point_span(points) do
    {min_x, max_x} = points |> Enum.map(fn {x, _, _} -> x end) |> Enum.min_max()
    {min_y, max_y} = points |> Enum.map(fn {_, y, _} -> y end) |> Enum.min_max()
    {min_z, max_z} = points |> Enum.map(fn {_, _, z} -> z end) |> Enum.min_max()

    max(max_x - min_x, max(max_y - min_y, max_z - min_z))
  end

  # Geometric validation functions for QCP results

  @doc """
  Validates that a quaternion represents a valid rotation (normalized).
  """
  @spec validate_rotation(rotation(), float()) :: :ok | {:error, validation_error()}
  def validate_rotation(rotation, tolerance \\ @default_tolerance) do
    {x, y, z, w} = rotation
    magnitude = :math.sqrt(x*x + y*y + z*z + w*w)

    if abs(magnitude - 1.0) < tolerance do
      :ok
    else
      {:error, :invalid_rotation}
    end
  end

  @doc """
  Validates that applying a rotation to moved points aligns them with target points.
  """
  @spec validate_alignment(rotation(), translation(), point_set(), point_set(), float()) :: :ok | {:error, validation_error()}
  def validate_alignment(rotation, translation, moved_points, target_points, tolerance \\ @default_tolerance) do
    transformed_points = Enum.map(moved_points, fn point ->
      rotated = Quaternion.rotate_vector(rotation, point)
      Vector3.add(rotated, translation)
    end)

    aligned = Enum.zip(transformed_points, target_points)
    |> Enum.all?(fn {transformed, target} ->
      {tx, ty, tz} = transformed
      {gx, gy, gz} = target
      abs(tx - gx) < tolerance and abs(ty - gy) < tolerance and abs(tz - gz) < tolerance
    end)

    if aligned do
      :ok
    else
      {:error, :points_not_aligned}
    end
  end

  @doc """
  Validates that two unit vectors are aligned (pointing in same direction).
  """
  @spec validate_vector_alignment(Vector3.t(), Vector3.t(), float()) :: :ok | {:error, validation_error()}
  def validate_vector_alignment(vector1, vector2, tolerance \\ @default_tolerance) do
    case {Vector3.normalize(vector1), Vector3.normalize(vector2)} do
      {{norm1, true}, {norm2, true}} ->
        {n1x, n1y, n1z} = norm1
        {n2x, n2y, n2z} = norm2

        aligned = abs(n1x - n2x) < tolerance and
                  abs(n1y - n2y) < tolerance and
                  abs(n1z - n2z) < tolerance

        if aligned do
          :ok
        else
          {:error, :vectors_not_aligned}
        end

      _ ->
        {:error, :vectors_not_aligned}
    end
  end

  @doc """
  Validates that a rotation represents approximately the expected angle.
  """
  @spec validate_rotation_angle(rotation(), float(), float()) :: :ok | {:error, validation_error()}
  def validate_rotation_angle(rotation, expected_angle_radians, tolerance \\ @default_tolerance) do
    {_x, _y, _z, w} = rotation

    # Calculate angle from quaternion: angle = 2 * acos(|w|)
    # Use |w| because q and -q represent the same rotation
    actual_angle = 2 * :math.acos(min(abs(w), 1.0))

    # Handle angle wrapping (0 and 2π are the same)
    angle_diff = abs(actual_angle - expected_angle_radians)
    angle_diff_wrapped = min(angle_diff, abs(angle_diff - 2 * :math.pi))

    if angle_diff_wrapped < tolerance do
      :ok
    else
      {:error, :incorrect_rotation_angle}
    end
  end

  @doc """
  Validates that two quaternions represent the same rotation (handles q and -q equivalence).
  """
  @spec validate_rotations_equivalent(rotation(), rotation(), float()) :: :ok | {:error, validation_error()}
  def validate_rotations_equivalent(rotation1, rotation2, tolerance \\ @default_tolerance) do
    {x1, y1, z1, w1} = rotation1
    {x2, y2, z2, w2} = rotation2

    # Check if rotations are the same or negated (both represent same rotation)
    same = abs(x1 - x2) < tolerance and abs(y1 - y2) < tolerance and
           abs(z1 - z2) < tolerance and abs(w1 - w2) < tolerance

    negated = abs(x1 + x2) < tolerance and abs(y1 + y2) < tolerance and
              abs(z1 + z2) < tolerance and abs(w1 + w2) < tolerance

    if same or negated do
      :ok
    else
      {:error, :rotations_not_equivalent}
    end
  end

  @doc """
  Validates that a rotation preserves distances between points.
  """
  @spec validate_distances_preserved(rotation(), point_set(), float()) :: :ok | {:error, validation_error()}
  def validate_distances_preserved(rotation, points, tolerance \\ @default_tolerance) do
    rotated_points = Enum.map(points, fn point ->
      Quaternion.rotate_vector(rotation, point)
    end)

    # Check all pairwise distances
    preserved = for {i, point1} <- Enum.with_index(points),
                    {j, point2} <- Enum.with_index(points),
                    i < j do
      original_distance = Vector3.distance(point1, point2)
      rotated_distance = Vector3.distance(Enum.at(rotated_points, i), Enum.at(rotated_points, j))
      abs(original_distance - rotated_distance) < tolerance
    end
    |> Enum.all?()

    if preserved do
      :ok
    else
      {:error, :distances_not_preserved}
    end
  end

  @doc """
  Validates that a rotation is a proper rotation (determinant = +1, not a reflection).
  """
  @spec validate_proper_rotation(rotation(), float()) :: :ok | {:error, validation_error()}
  def validate_proper_rotation(rotation, tolerance \\ @default_tolerance) do
    # Apply rotation to standard basis vectors
    i_rotated = Quaternion.rotate_vector(rotation, {1.0, 0.0, 0.0})
    j_rotated = Quaternion.rotate_vector(rotation, {0.0, 1.0, 0.0})
    k_rotated = Quaternion.rotate_vector(rotation, {0.0, 0.0, 1.0})

    # Calculate determinant using scalar triple product
    det = Vector3.dot(i_rotated, Vector3.cross(j_rotated, k_rotated))

    if abs(det - 1.0) < tolerance do
      :ok
    else
      {:error, :improper_rotation}
    end
  end

  @doc """
  Validates that a rotation preserves orthogonality of basis vectors.
  """
  @spec validate_orthogonality_preserved(rotation(), float()) :: :ok | {:error, validation_error()}
  def validate_orthogonality_preserved(rotation, tolerance \\ @default_tolerance) do
    # Apply rotation to standard basis vectors
    i_rotated = Quaternion.rotate_vector(rotation, {1.0, 0.0, 0.0})
    j_rotated = Quaternion.rotate_vector(rotation, {0.0, 1.0, 0.0})
    k_rotated = Quaternion.rotate_vector(rotation, {0.0, 0.0, 1.0})

    # Check orthogonality and unit length preservation
    orthogonal = abs(Vector3.dot(i_rotated, j_rotated)) < tolerance and
                 abs(Vector3.dot(i_rotated, k_rotated)) < tolerance and
                 abs(Vector3.dot(j_rotated, k_rotated)) < tolerance

    unit_length = abs(Vector3.length(i_rotated) - 1.0) < tolerance and
                  abs(Vector3.length(j_rotated) - 1.0) < tolerance and
                  abs(Vector3.length(k_rotated) - 1.0) < tolerance

    if orthogonal and unit_length do
      :ok
    else
      {:error, :orthogonality_not_preserved}
    end
  end

  @doc """
  Validates that a transformation achieves the expected geometric result for known test cases.
  """
  @spec validate_known_transformation(rotation(), translation(), atom(), float()) :: :ok | {:error, validation_error()}
  def validate_known_transformation(rotation, translation, test_case, tolerance \\ @default_tolerance) do
    case test_case do
      :identity ->
        validate_identity_transformation(rotation, translation, tolerance)

      :ninety_degree_z ->
        validate_rotation_angle(rotation, :math.pi / 2, tolerance)

      :one_eighty_degree ->
        validate_rotation_angle(rotation, :math.pi, tolerance)

      {:translation_only, expected_translation} ->
        validate_translation_only(rotation, translation, expected_translation, tolerance)

      _ ->
        {:error, :transformation_mismatch}
    end
  end

  # Private helper functions

  defp validate_identity_transformation(rotation, translation, tolerance) do
    {x, y, z, w} = rotation
    {tx, ty, tz} = translation

    identity_rotation = abs(x) < tolerance and abs(y) < tolerance and abs(z) < tolerance and
                       abs(abs(w) - 1.0) < tolerance

    zero_translation = abs(tx) < tolerance and abs(ty) < tolerance and abs(tz) < tolerance

    if identity_rotation and zero_translation do
      :ok
    else
      {:error, :transformation_mismatch}
    end
  end

  defp validate_translation_only(rotation, translation, expected_translation, tolerance) do
    {x, y, z, w} = rotation
    {tx, ty, tz} = translation
    {ex, ey, ez} = expected_translation

    identity_rotation = abs(x) < tolerance and abs(y) < tolerance and abs(z) < tolerance and
                       abs(abs(w) - 1.0) < tolerance

    correct_translation = abs(tx - ex) < tolerance and abs(ty - ey) < tolerance and abs(tz - ez) < tolerance

    if identity_rotation and correct_translation do
      :ok
    else
      {:error, :transformation_mismatch}
    end
  end
end
