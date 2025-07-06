# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

ExUnit.start()

defmodule AriaQcp.GeometricTestHelpers do
  @moduledoc """
  Test helper functions for geometric validation in QCP tests.

  These functions wrap the library validation functions with ExUnit assertions,
  making tests more robust to floating-point precision and quaternion representation variations.
  """

  import ExUnit.Assertions
  alias AriaQcp.QCP.Validation
  alias AriaMath.{Vector3, Quaternion}

  @default_tolerance 1.0e-10

  @doc """
  Verifies that a quaternion represents a valid rotation (normalized).
  """
  def assert_valid_rotation(rotation, tolerance \\ @default_tolerance) do
    case Validation.validate_rotation(rotation, tolerance) do
      :ok -> :ok
      {:error, :invalid_rotation} ->
        {x, y, z, w} = rotation
        magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
        assert false, "Rotation quaternion not normalized: magnitude = #{magnitude}"
    end
  end

  @doc """
  Verifies that applying a rotation to moved points aligns them with target points.
  """
  def assert_points_aligned(rotation, translation, moved_points, target_points, tolerance \\ @default_tolerance) do
    case Validation.validate_alignment(rotation, translation, moved_points, target_points, tolerance) do
      :ok -> :ok
      {:error, :points_not_aligned} ->
        transformed_points = Enum.map(moved_points, fn point ->
          rotated = Quaternion.rotate_vector(rotation, point)
          Vector3.add(rotated, translation)
        end)

        Enum.zip(transformed_points, target_points)
        |> Enum.with_index()
        |> Enum.each(fn {{transformed, target}, index} ->
          {tx, ty, tz} = transformed
          {gx, gy, gz} = target

          assert abs(tx - gx) < tolerance, "Point #{index} X mismatch: #{tx} vs #{gx}"
          assert abs(ty - gy) < tolerance, "Point #{index} Y mismatch: #{ty} vs #{gy}"
          assert abs(tz - gz) < tolerance, "Point #{index} Z mismatch: #{tz} vs #{gz}"
        end)
    end
  end

  @doc """
  Verifies that two unit vectors are aligned (pointing in same direction).
  """
  def assert_vectors_aligned(vector1, vector2, tolerance \\ @default_tolerance) do
    case Validation.validate_vector_alignment(vector1, vector2, tolerance) do
      :ok -> :ok
      {:error, :vectors_not_aligned} ->
        {norm1, success1} = Vector3.normalize(vector1)
        {norm2, success2} = Vector3.normalize(vector2)

        assert success1, "Failed to normalize first vector: #{inspect(vector1)}"
        assert success2, "Failed to normalize second vector: #{inspect(vector2)}"

        {n1x, n1y, n1z} = norm1
        {n2x, n2y, n2z} = norm2

        assert abs(n1x - n2x) < tolerance, "X component mismatch: #{n1x} vs #{n2x}"
        assert abs(n1y - n2y) < tolerance, "Y component mismatch: #{n1y} vs #{n2y}"
        assert abs(n1z - n2z) < tolerance, "Z component mismatch: #{n1z} vs #{n2z}"
    end
  end

  @doc """
  Verifies that a rotation represents approximately the expected angle.
  """
  def assert_rotation_angle(rotation, expected_angle_radians, tolerance \\ @default_tolerance) do
    case Validation.validate_rotation_angle(rotation, expected_angle_radians, tolerance) do
      :ok -> :ok
      {:error, :incorrect_rotation_angle} ->
        {_x, _y, _z, w} = rotation
        actual_angle = 2 * :math.acos(min(abs(w), 1.0))
        assert false, "Rotation angle mismatch: expected #{expected_angle_radians}, got #{actual_angle}"
    end
  end

  @doc """
  Verifies that two quaternions represent the same rotation (handles q and -q equivalence).
  """
  def assert_rotations_equivalent(rotation1, rotation2, tolerance \\ @default_tolerance) do
    case Validation.validate_rotations_equivalent(rotation1, rotation2, tolerance) do
      :ok -> :ok
      {:error, :rotations_not_equivalent} ->
        assert false, "Rotations not equivalent: #{inspect(rotation1)} vs #{inspect(rotation2)}"
    end
  end

  @doc """
  Verifies that a rotation preserves distances between points.
  """
  def assert_distances_preserved(rotation, points, tolerance \\ @default_tolerance) do
    case Validation.validate_distances_preserved(rotation, points, tolerance) do
      :ok -> :ok
      {:error, :distances_not_preserved} ->
        rotated_points = Enum.map(points, fn point ->
          Quaternion.rotate_vector(rotation, point)
        end)

        # Check all pairwise distances to find the specific failure
        for {i, point1} <- Enum.with_index(points),
            {j, point2} <- Enum.with_index(points),
            i < j do

          original_distance = Vector3.distance(point1, point2)
          rotated_distance = Vector3.distance(Enum.at(rotated_points, i), Enum.at(rotated_points, j))

          assert abs(original_distance - rotated_distance) < tolerance,
                 "Distance not preserved between points #{i} and #{j}: #{original_distance} vs #{rotated_distance}"
        end
    end
  end

  @doc """
  Verifies that a rotation is a proper rotation (determinant = +1, not a reflection).
  """
  def assert_proper_rotation(rotation, tolerance \\ @default_tolerance) do
    case Validation.validate_proper_rotation(rotation, tolerance) do
      :ok -> :ok
      {:error, :improper_rotation} ->
        # Apply rotation to standard basis vectors for detailed error message
        i_rotated = Quaternion.rotate_vector(rotation, {1.0, 0.0, 0.0})
        j_rotated = Quaternion.rotate_vector(rotation, {0.0, 1.0, 0.0})
        k_rotated = Quaternion.rotate_vector(rotation, {0.0, 0.0, 1.0})
        det = Vector3.dot(i_rotated, Vector3.cross(j_rotated, k_rotated))
        assert false, "Rotation is not proper (determinant = #{det}, expected 1.0)"
    end
  end

  @doc """
  Verifies that a rotation preserves orthogonality of basis vectors.
  """
  def assert_orthogonality_preserved(rotation, tolerance \\ @default_tolerance) do
    # Apply rotation to standard basis vectors
    i_rotated = Quaternion.rotate_vector(rotation, {1.0, 0.0, 0.0})
    j_rotated = Quaternion.rotate_vector(rotation, {0.0, 1.0, 0.0})
    k_rotated = Quaternion.rotate_vector(rotation, {0.0, 0.0, 1.0})

    # Check orthogonality
    assert abs(Vector3.dot(i_rotated, j_rotated)) < tolerance, "i and j not orthogonal after rotation"
    assert abs(Vector3.dot(i_rotated, k_rotated)) < tolerance, "i and k not orthogonal after rotation"
    assert abs(Vector3.dot(j_rotated, k_rotated)) < tolerance, "j and k not orthogonal after rotation"

    # Check unit length preservation
    assert abs(Vector3.length(i_rotated) - 1.0) < tolerance, "i vector length not preserved"
    assert abs(Vector3.length(j_rotated) - 1.0) < tolerance, "j vector length not preserved"
    assert abs(Vector3.length(k_rotated) - 1.0) < tolerance, "k vector length not preserved"
  end

  @doc """
  Verifies that a transformation achieves the expected geometric result for known test cases.
  """
  def assert_known_transformation(rotation, translation, test_case, tolerance \\ @default_tolerance) do
    case test_case do
      :identity ->
        # Should be identity rotation and zero translation
        {x, y, z, w} = rotation
        assert abs(x) < tolerance and abs(y) < tolerance and abs(z) < tolerance
        assert abs(abs(w) - 1.0) < tolerance  # |w| = 1 for identity (handle q/-q)

        {tx, ty, tz} = translation
        assert abs(tx) < tolerance and abs(ty) < tolerance and abs(tz) < tolerance

      :ninety_degree_z ->
        # Should be 90-degree rotation around Z axis
        assert_rotation_angle(rotation, :math.pi / 2, tolerance)

      :one_eighty_degree ->
        # Should be 180-degree rotation
        assert_rotation_angle(rotation, :math.pi, tolerance)

      {:translation_only, expected_translation} ->
        # Should be identity rotation
        {x, y, z, w} = rotation
        assert abs(x) < tolerance and abs(y) < tolerance and abs(z) < tolerance
        assert abs(abs(w) - 1.0) < tolerance

        # Should match expected translation
        {tx, ty, tz} = translation
        {ex, ey, ez} = expected_translation
        assert abs(tx - ex) < tolerance and abs(ty - ey) < tolerance and abs(tz - ez) < tolerance
    end
  end
end
