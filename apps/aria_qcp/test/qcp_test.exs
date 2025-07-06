# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.QCPTest do
  use ExUnit.Case
  doctest AriaQcp.QCP

  alias AriaMath.{Vector3, Quaternion}
  alias AriaQcp.QCP
  alias AriaQcp.QCP.Validation

  describe "weighted_superpose/5 detailed tests" do
    test "handles single point alignment with various orientations" do
      test_cases = [
        # X to Y axis
        {{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}},
        # Y to Z axis
        {{0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}},
        # Z to X axis
        {{0.0, 0.0, 1.0}, {1.0, 0.0, 0.0}},
        # Diagonal alignments
        {{1.0, 1.0, 0.0}, {0.0, 0.0, 1.0}},
        {{1.0, 0.0, 1.0}, {0.0, 1.0, 0.0}}
      ]

      for {moved_point, target_point} <- test_cases do
        assert {:ok, {rotation, translation}} = QCP.weighted_superpose([moved_point], [target_point])

        # Use geometric validation
        assert Validation.validate_rotation(rotation) == :ok
        assert Validation.validate_alignment(rotation, translation, [moved_point], [target_point]) == :ok
      end
    end

    test "handles opposite vectors correctly" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{-1.0, 0.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Use geometric validation - the key is that points align correctly
      assert Validation.validate_rotation(rotation) == :ok
      assert Validation.validate_alignment(rotation, translation, moved, target) == :ok
    end

    test "handles zero-length vectors gracefully" do
      moved = [{0.0, 0.0, 0.0}]
      target = [{1.0, 0.0, 0.0}]

      assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target)

      # Should return identity rotation for zero-length input
      {x, y, z, w} = rotation
      assert abs(x) < 1.0e-10
      assert abs(y) < 1.0e-10
      assert abs(z) < 1.0e-10
      assert abs(w - 1.0) < 1.0e-10
    end

    test "handles multiple points with complex transformations" do
      # Create a cube
      moved = [
        {0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {1.0, 1.0, 0.0},
        {0.0, 0.0, 1.0}, {1.0, 0.0, 1.0}, {0.0, 1.0, 1.0}, {1.0, 1.0, 1.0}
      ]

      # Apply 45-degree rotation around Z axis and translation
      angle = :math.pi / 4
      cos_a = :math.cos(angle)
      sin_a = :math.sin(angle)
      translation = {5.0, 3.0, 2.0}

      target = Enum.map(moved, fn {x, y, z} ->
        # Rotate around Z axis
        new_x = x * cos_a - y * sin_a
        new_y = x * sin_a + y * cos_a
        new_z = z
        # Apply translation
        {new_x + elem(translation, 0), new_y + elem(translation, 1), new_z + elem(translation, 2)}
      end)

      assert {:ok, {rotation, recovered_translation}} = QCP.weighted_superpose(moved, target)

      # Use geometric validation instead of exact numerical checks
      assert Validation.validate_rotation(rotation) == :ok
      assert Validation.validate_alignment(rotation, recovered_translation, moved, target) == :ok
    end

    test "handles weighted points with extreme weights" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]

      # First point has very low weight, second has very high weight
      weights = [1.0e-6, 1.0e6]

      assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target, weights)

      # Should still produce normalized rotation
      {x, y, z, w} = rotation
      magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(magnitude - 1.0) < 1.0e-10
    end

    test "precision parameter affects calculation accuracy" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]

      # Test with different precision levels
      precisions = [1.0e-6, 1.0e-10, 1.0e-15]

      for precision <- precisions do
        assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target, [], true, precision)

        # Should produce valid rotation regardless of precision
        {x, y, z, w} = rotation
        magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
        assert abs(magnitude - 1.0) < 1.0e-10
      end
    end
  end

  describe "edge cases and robustness" do
    test "handles points at machine precision limits" do
      epsilon = 1.0e-15
      moved = [{epsilon, 0.0, 0.0}]
      target = [{0.0, epsilon, 0.0}]

      assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target)

      # Should handle tiny numbers gracefully
      {x, y, z, w} = rotation
      magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(magnitude - 1.0) < 1.0e-10
    end

    test "handles large coordinate values" do
      large_val = 1.0e12
      moved = [{large_val, 0.0, 0.0}]
      target = [{0.0, large_val, 0.0}]

      assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target)

      # Should handle large numbers without overflow
      {x, y, z, w} = rotation
      magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(magnitude - 1.0) < 1.0e-10
    end

    test "handles nearly collinear points" do
      # Points that are almost but not quite collinear
      epsilon = 1.0e-12
      moved = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {2.0, epsilon, 0.0}]
      target = [{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {epsilon, 2.0, 0.0}]

      assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target)

      # Should handle near-degeneracy gracefully
      {x, y, z, w} = rotation
      magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(magnitude - 1.0) < 1.0e-10
    end

    test "handles maximum allowed points" do
      # Test with a reasonable number of points (not the full 10,000 limit for performance)
      point_count = 1000
      moved = for _i <- 1..point_count, do: {:rand.uniform() * 100, :rand.uniform() * 100, :rand.uniform() * 100}

      # Apply simple transformation
      target = Enum.map(moved, fn {x, y, z} -> {x + 10.0, y + 5.0, z - 3.0} end)

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Should handle many points efficiently
      {x, y, z, w} = rotation
      magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(magnitude - 1.0) < 1.0e-10

      # Translation should be approximately (10, 5, -3)
      {tx, ty, tz} = translation
      assert abs(tx - 10.0) < 1.0e-6
      assert abs(ty - 5.0) < 1.0e-6
      assert abs(tz + 3.0) < 1.0e-6
    end
  end

  describe "validation error cases" do
    test "rejects too many points" do
      # Create more than the maximum allowed points
      max_points = 10_001
      moved = List.duplicate({1.0, 0.0, 0.0}, max_points)
      target = List.duplicate({0.0, 1.0, 0.0}, max_points)

      assert {:error, :too_many_points} = QCP.weighted_superpose(moved, target)
    end

    test "rejects weights that are too large" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]
      weights = [1.0e15]  # Exceeds max weight

      assert {:error, :invalid_weights} = QCP.weighted_superpose(moved, target, weights)
    end

    test "rejects all weights too small" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]
      weights = [1.0e-15]  # Below min weight

      assert {:error, :invalid_weights} = QCP.weighted_superpose(moved, target, weights)
    end

    test "rejects degenerate point sets" do
      # All points are the same (degenerate)
      moved = [{1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}]
      target = [{2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}]

      assert {:error, :degenerate_points} = QCP.weighted_superpose(moved, target)
    end
  end

  describe "mathematical properties" do
    test "rotation preserves distances between points" do
      moved = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{5.0, 5.0, 5.0}, {6.0, 5.0, 5.0}, {5.0, 6.0, 5.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Apply transformation to moved points
      transformed = Enum.map(moved, fn point ->
        rotated = Quaternion.rotate_vector(rotation, point)
        Vector3.add(rotated, translation)
      end)

      # Check that distances are preserved
      original_dist_01 = Vector3.distance(Enum.at(moved, 0), Enum.at(moved, 1))
      transformed_dist_01 = Vector3.distance(Enum.at(transformed, 0), Enum.at(transformed, 1))
      assert abs(original_dist_01 - transformed_dist_01) < 1.0e-10

      original_dist_02 = Vector3.distance(Enum.at(moved, 0), Enum.at(moved, 2))
      transformed_dist_02 = Vector3.distance(Enum.at(transformed, 0), Enum.at(transformed, 2))
      assert abs(original_dist_02 - transformed_dist_02) < 1.0e-10
    end

    test "rotation is orthogonal transformation" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0}]

      assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target)

      # Apply rotation to standard basis vectors
      i_rotated = Quaternion.rotate_vector(rotation, {1.0, 0.0, 0.0})
      j_rotated = Quaternion.rotate_vector(rotation, {0.0, 1.0, 0.0})
      k_rotated = Quaternion.rotate_vector(rotation, {0.0, 0.0, 1.0})

      # Check that rotated basis vectors are still orthonormal
      assert abs(Vector3.dot(i_rotated, j_rotated)) < 1.0e-10
      assert abs(Vector3.dot(i_rotated, k_rotated)) < 1.0e-10
      assert abs(Vector3.dot(j_rotated, k_rotated)) < 1.0e-10

      assert abs(Vector3.length(i_rotated) - 1.0) < 1.0e-10
      assert abs(Vector3.length(j_rotated) - 1.0) < 1.0e-10
      assert abs(Vector3.length(k_rotated) - 1.0) < 1.0e-10
    end

    test "determinant of rotation is +1 (proper rotation)" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0}]

      assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target)

      # Convert quaternion to rotation matrix and check determinant
      i_rotated = Quaternion.rotate_vector(rotation, {1.0, 0.0, 0.0})
      j_rotated = Quaternion.rotate_vector(rotation, {0.0, 1.0, 0.0})
      k_rotated = Quaternion.rotate_vector(rotation, {0.0, 0.0, 1.0})

      # Calculate determinant using scalar triple product
      det = Vector3.dot(i_rotated, Vector3.cross(j_rotated, k_rotated))
      assert abs(det - 1.0) < 1.0e-10
    end
  end

  describe "minimal transformation validation" do
    test "validates minimal RMSD for perfect alignment" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Should achieve minimal RMSD (near zero for exact alignment)
      assert Validation.validate_minimal_rmsd(rotation, translation, moved, target) == :ok
    end

    test "validates minimal rotation angle for 90-degree case" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]

      assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target)

      # Should use minimal rotation (≤ 90 degrees)
      assert Validation.validate_minimal_rotation_angle(rotation, :math.pi / 2) == :ok
    end

    test "validates transformation efficiency for pure translation" do
      moved = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}]
      target = [{5.0, 0.0, 0.0}, {6.0, 0.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Should use identity rotation for pure translation
      assert Validation.validate_transformation_efficiency(rotation, translation, :translation_only) == :ok
    end

    test "validates transformation efficiency for rotation only" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target, [], false)

      # Should have zero translation for rotation-only case
      assert Validation.validate_transformation_efficiency(rotation, translation, :rotation_only) == :ok
    end

    test "validates against known optimal transformations" do
      # Test X to Y axis rotation (should be 90 degrees around Z)
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)
      assert Validation.validate_against_known_optimal(rotation, translation, :x_to_y_axis) == :ok

      # Test opposite vectors (should be 180 degrees)
      moved = [{1.0, 0.0, 0.0}]
      target = [{-1.0, 0.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)
      assert Validation.validate_against_known_optimal(rotation, translation, :opposite_vectors) == :ok
    end

    test "validates globally optimal solution" do
      # Complex transformation that should still be globally optimal
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Should pass all optimality checks
      assert Validation.validate_globally_optimal(rotation, translation, moved, target) == :ok
    end

    test "validates identity transformation efficiency" do
      points = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(points, points)

      # Should be pure identity transformation
      assert Validation.validate_transformation_efficiency(rotation, translation, :identity) == :ok
    end

    test "validates minimal transformation for unit translation" do
      moved = [{0.0, 0.0, 0.0}]
      target = [{1.0, 0.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Should use identity rotation for unit translation
      assert Validation.validate_against_known_optimal(rotation, translation, :unit_translation) == :ok
    end
  end

  describe "minimal jerk validation" do
    test "validates minimal jerk for identity transformation" do
      points = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(points, points)

      # Identity transformation should have minimal jerk
      assert Validation.validate_minimal_jerk(rotation, translation) == :ok
    end

    test "validates minimal angular jerk for simple rotations" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]

      assert {:ok, {rotation, _translation}} = QCP.weighted_superpose(moved, target)

      # Single-axis rotation should have minimal angular jerk
      assert Validation.validate_minimal_angular_jerk(rotation) == :ok
    end

    test "validates minimal linear jerk for pure translation" do
      moved = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}]
      target = [{5.0, 0.0, 0.0}, {6.0, 0.0, 0.0}]

      assert {:ok, {_rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Straight-line translation should have minimal linear jerk
      assert Validation.validate_minimal_linear_jerk(translation) == :ok
    end

    test "validates motion coordination for combined transformations" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{5.0, 6.0, 0.0}, {4.0, 5.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Combined rotation and translation should be well-coordinated
      assert Validation.validate_motion_coordination(rotation, translation) == :ok
    end

    test "validates minimal jerk for opposite vector alignment" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{-1.0, 0.0, 0.0}]

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # 180-degree rotation should still have minimal jerk (shortest angular path)
      assert Validation.validate_minimal_jerk(rotation, translation) == :ok
    end

    test "validates minimal jerk for complex multi-point transformations" do
      # Create a triangle
      moved = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {0.5, 0.866, 0.0}]

      # Rotate 60 degrees around Z and translate
      angle = :math.pi / 3
      cos_a = :math.cos(angle)
      sin_a = :math.sin(angle)
      translation_offset = {2.0, 3.0, 1.0}

      target = Enum.map(moved, fn {x, y, z} ->
        new_x = x * cos_a - y * sin_a
        new_y = x * sin_a + y * cos_a
        new_z = z
        {new_x + elem(translation_offset, 0), new_y + elem(translation_offset, 1), new_z + elem(translation_offset, 2)}
      end)

      assert {:ok, {rotation, translation}} = QCP.weighted_superpose(moved, target)

      # Complex transformation should still achieve minimal jerk
      assert Validation.validate_minimal_jerk(rotation, translation) == :ok
    end
  end
end
