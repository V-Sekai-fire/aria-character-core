defmodule AriaQcpTest do
  use ExUnit.Case
  doctest AriaQcp

  alias AriaMath.{Vector3, Quaternion}

  describe "superpose/4" do
    test "aligns single point correctly" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

      # Check that rotation is approximately correct (90 degree rotation around Z axis)
      {_, _, _, w} = rotation
      assert abs(w - 0.7071067811865476) < 1.0e-10
    end

    test "handles identity transformation" do
      points = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}]

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(points, points)

      # Should be identity rotation and zero translation
      {x, y, z, w} = rotation
      assert abs(x) < 1.0e-10
      assert abs(y) < 1.0e-10
      assert abs(z) < 1.0e-10
      assert abs(w - 1.0) < 1.0e-10

      {tx, ty, tz} = translation
      assert abs(tx) < 1.0e-10
      assert abs(ty) < 1.0e-10
      assert abs(tz) < 1.0e-10
    end

    test "handles translation only" do
      moved = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{1.0, 1.0, 1.0}, {2.0, 1.0, 1.0}, {1.0, 2.0, 1.0}]

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

      # Should be identity rotation
      {x, y, z, w} = rotation
      assert abs(x) < 1.0e-10
      assert abs(y) < 1.0e-10
      assert abs(z) < 1.0e-10
      assert abs(w - 1.0) < 1.0e-10

      # Should be translation by (1, 1, 1)
      {tx, ty, tz} = translation
      assert abs(tx - 1.0) < 1.0e-10
      assert abs(ty - 1.0) < 1.0e-10
      assert abs(tz - 1.0) < 1.0e-10
    end

    test "handles 180 degree rotation" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{-1.0, 0.0, 0.0}, {0.0, -1.0, 0.0}]

      assert {:ok, {rotation, _translation}} = AriaQcp.superpose(moved, target)

      # Should be 180 degree rotation around Z axis
      {x, y, z, w} = rotation
      assert abs(z) < 1.0e-10 or abs(abs(z) - 1.0) < 1.0e-10
      assert abs(w) < 1.0e-10
    end
  end

  describe "rotation_only/4" do
    test "returns zero translation" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]

      assert {:ok, {_rotation, translation}} = AriaQcp.rotation_only(moved, target)

      assert translation == {0.0, 0.0, 0.0}
    end

    test "calculates correct rotation without translation" do
      moved = [{1.0, 1.0, 1.0}, {2.0, 1.0, 1.0}]
      target = [{1.0, 1.0, 1.0}, {1.0, 2.0, 1.0}]

      assert {:ok, {rotation, translation}} = AriaQcp.rotation_only(moved, target)

      # Translation should be zero
      assert translation == {0.0, 0.0, 0.0}

      # Should have some rotation
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < 1.0e-10
    end
  end

  describe "weighted_superpose/5" do
    test "handles weighted points correctly" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
      weights = [1.0, 1.0]

      assert {:ok, {rotation, _translation}} = AriaQcp.weighted_superpose(moved, target, weights, true)

      # Should produce valid rotation
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < 1.0e-10
    end

    test "handles different weights" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
      weights = [0.1, 0.9]  # Second point has much higher weight

      assert {:ok, {rotation, _translation}} = AriaQcp.weighted_superpose(moved, target, weights, true)

      # Should produce valid rotation
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < 1.0e-10
    end

    test "handles custom precision" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]

      assert {:ok, {rotation, _translation}} = AriaQcp.weighted_superpose(moved, target, [], true, 1.0e-12)

      # Should produce valid rotation with high precision
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < 1.0e-12
    end
  end

  describe "error handling" do
    test "returns error for empty point sets" do
      assert {:error, :empty_point_sets} = AriaQcp.superpose([], [])
    end

    test "returns error for mismatched point set sizes" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}, {1.0, 1.0, 0.0}]

      assert {:error, :mismatched_point_set_sizes} = AriaQcp.superpose(moved, target)
    end

    test "returns error for mismatched weight count" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
      weights = [1.0]  # Only one weight for two points

      assert {:error, :mismatched_weight_count} = AriaQcp.weighted_superpose(moved, target, weights, true)
    end

    test "returns error for negative weights" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]
      weights = [-1.0]

      assert {:error, :negative_weights} = AriaQcp.weighted_superpose(moved, target, weights, true)
    end

    test "returns error for invalid weights" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]
      weights = [:infinity]

      assert {:error, :invalid_weights} = AriaQcp.weighted_superpose(moved, target, weights, true)
    end

    test "returns error for degenerate points" do
      moved = [{:nan, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]

      assert {:error, :degenerate_points} = AriaQcp.superpose(moved, target)
    end
  end

  describe "numerical stability" do
    test "handles very small points" do
      moved = [{1.0e-15, 0.0, 0.0}]
      target = [{0.0, 1.0e-15, 0.0}]

      assert {:ok, {rotation, _translation}} = AriaQcp.superpose(moved, target)

      # Should produce valid rotation even for tiny points
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < 1.0e-10
    end

    test "handles large points" do
      moved = [{1.0e6, 0.0, 0.0}]
      target = [{0.0, 1.0e6, 0.0}]

      assert {:ok, {rotation, _translation}} = AriaQcp.superpose(moved, target)

      # Should produce valid rotation even for large points
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < 1.0e-10
    end

    test "handles collinear points" do
      moved = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {2.0, 0.0, 0.0}]
      target = [{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 2.0, 0.0}]

      assert {:ok, {rotation, _translation}} = AriaQcp.superpose(moved, target)

      # Should produce valid rotation
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < 1.0e-10
    end
  end

  describe "integration with AriaMath" do
    test "works with Vector3 operations" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

      # Test that we can use the result with Vector3 operations
      test_point = {1.0, 0.0, 0.0}
      rotated_point = Quaternion.rotate_vector(rotation, test_point)
      final_point = Vector3.add(rotated_point, translation)

      # Should be a valid 3D point
      {x, y, z} = final_point
      assert is_float(x)
      assert is_float(y)
      assert is_float(z)
    end

    test "quaternion normalization is preserved" do
      moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}]
      target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, -1.0}]

      assert {:ok, {rotation, _translation}} = AriaQcp.superpose(moved, target)

      # Verify quaternion is normalized
      {normalized_rotation, success} = Quaternion.normalize(rotation)
      assert success

      # Original should already be normalized
      {x, y, z, w} = rotation
      {nx, ny, nz, nw} = normalized_rotation
      assert abs(x - nx) < 1.0e-10
      assert abs(y - ny) < 1.0e-10
      assert abs(z - nz) < 1.0e-10
      assert abs(w - nw) < 1.0e-10
    end
  end

  describe "performance characteristics" do
    test "handles moderate number of points efficiently" do
      # Generate 100 random points
      moved = for _ <- 1..100, do: {:rand.uniform() * 10, :rand.uniform() * 10, :rand.uniform() * 10}

      # Apply a known transformation
      rotation_angle = :math.pi / 4  # 45 degrees
      cos_half = :math.cos(rotation_angle / 2)
      sin_half = :math.sin(rotation_angle / 2)
      test_rotation = {0.0, 0.0, sin_half, cos_half}  # Rotation around Z axis
      test_translation = {5.0, 3.0, 2.0}

      target = Enum.map(moved, fn point ->
        rotated = Quaternion.rotate_vector(test_rotation, point)
        Vector3.add(rotated, test_translation)
      end)

      # Measure time (should complete quickly)
      start_time = System.monotonic_time(:microsecond)
      assert {:ok, {recovered_rotation, recovered_translation}} = AriaQcp.superpose(moved, target)
      end_time = System.monotonic_time(:microsecond)

      # Should complete in reasonable time (less than 100ms for 100 points)
      elapsed_time = end_time - start_time
      assert elapsed_time < 100_000  # 100ms in microseconds

      # Verify the recovered transformation is close to the original
      {rx, ry, rz, rw} = recovered_rotation
      {tx, ty, tz} = recovered_translation

      # Rotation should be normalized
      rotation_magnitude = :math.sqrt(rx*rx + ry*ry + rz*rz + rw*rw)
      assert abs(rotation_magnitude - 1.0) < 1.0e-10

      # Translation should be reasonable
      assert abs(tx) < 100.0
      assert abs(ty) < 100.0
      assert abs(tz) < 100.0
    end
  end
end
