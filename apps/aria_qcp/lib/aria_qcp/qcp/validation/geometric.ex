# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.QCP.Validation.Geometric do
  @moduledoc """
  Geometric validation functions for QCP algorithm results.

  Handles validation of rotations, alignments, vector operations,
  and geometric properties of transformations.
  """

  alias AriaMath.{Vector3, Quaternion}

  @default_tolerance 1.0e-10

  @type point_set :: [Vector3.t()]
  @type rotation :: {float(), float(), float(), float()}
  @type translation :: Vector3.t()
  @type validation_error ::
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
