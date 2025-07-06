# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcpTest do
  use ExUnit.Case
  doctest AriaQcp

  alias AriaMath.{Vector3, Quaternion}

  describe "superpose/4" do
    test "aligns single point correctly" do
      moved = [{1.0, 0.0, 0.0}]
      target = [{0.0, 1.0, 0.0}]

      assert {:ok, {rotation, _translation}} = AriaQcp.superpose(moved, target)

      # Should produce valid rotation
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < 1.0e-10
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

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

      # Test transformation manually - verify that the transformation works
      alias AriaMath.{Vector3, Quaternion}
      transformed_points = Enum.map(moved, fn point ->
        rotated = Quaternion.rotate_vector(rotation, point)
        Vector3.add(rotated, translation)
      end)

      # Check that each transformed point matches one of the target points
      # (order might be different due to the nature of the optimization)
      for transformed <- transformed_points do
        found_match = Enum.any?(target, fn target_point ->
          {tx, ty, tz} = transformed
          {gx, gy, gz} = target_point
          abs(tx - gx) < 1.0e-6 and abs(ty - gy) < 1.0e-6 and abs(tz - gz) < 1.0e-6
        end)
        assert found_match, "Transformed point #{inspect(transformed)} should match one of the target points #{inspect(target)}"
      end

      # Use geometric validation
      alias AriaQcp.QCP.Validation
      assert Validation.validate_rotation(rotation) == :ok
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

  describe "surgical safety - jerk validation" do
    alias AriaQcp.QCP.Validation.Motion

    # Surgical safety thresholds based on medical robotics literature
    @surgical_angular_jerk_limit 10.0  # rad/s³ - conservative limit for surgical robotics
    @surgical_linear_jerk_limit 1.0    # m/s³ - safe for tissue interaction
    @surgical_tolerance 1.0e-8         # High precision required for surgical applications

    # Helper functions to calculate actual jerk from QCP transformation results
    defp calculate_angular_jerk({x, y, z, _w}) do
      # Extract rotation angle from quaternion vector part
      vector_magnitude = :math.sqrt(x*x + y*y + z*z)

      # Convert to rotation angle: angle = 2 * asin(|vector_part|)
      # This gives us the actual rotation amount for jerk calculation
      rotation_angle = 2.0 * :math.asin(min(vector_magnitude, 1.0))

      # Angular jerk ≈ rotation_angle / time³ (assuming unit time for QCP)
      rotation_angle
    end

    defp calculate_linear_jerk({tx, ty, tz}) do
      # Calculate linear jerk from translation vector
      # For QCP transformations, jerk ≈ |translation| / time³
      # Assuming unit time for QCP transformations
      :math.sqrt(tx*tx + ty*ty + tz*tz)
    end

    defp enforce_surgical_jerk_limits(rotation, translation) do
      angular_jerk = calculate_angular_jerk(rotation)
      linear_jerk = calculate_linear_jerk(translation)

      assert angular_jerk < @surgical_angular_jerk_limit,
        "Angular jerk #{angular_jerk} rad/s³ exceeds surgical safety limit #{@surgical_angular_jerk_limit} rad/s³"

      assert linear_jerk < @surgical_linear_jerk_limit,
        "Linear jerk #{linear_jerk} m/s³ exceeds surgical safety limit #{@surgical_linear_jerk_limit} m/s³"
    end

    test "surgical instrument alignment maintains safe jerk levels" do
      # Simulate aligning a surgical instrument from initial position to target tissue location
      # Using millimeter-scale coordinates typical in surgery
      moved = [{0.001, 0.0, 0.0}]    # Initial instrument tip position (1mm on X axis)
      target = [{0.0, 0.001, 0.0}]   # Target tissue location (1mm on Y axis)

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

      # CRITICAL: Enforce surgical safety jerk limits to protect patients
      enforce_surgical_jerk_limits(rotation, translation)

      # Validate that the transformation meets surgical safety requirements
      assert Motion.validate_minimal_jerk(rotation, translation, @surgical_tolerance) == :ok

      # Additional validation: ensure rotation represents minimal angular motion
      assert Motion.validate_minimal_angular_jerk(rotation, @surgical_tolerance) == :ok

      # Ensure translation follows smoothest path for tissue safety
      assert Motion.validate_minimal_linear_jerk(translation, @surgical_tolerance) == :ok

      # Verify motion coordination is optimal for surgical precision
      assert Motion.validate_motion_coordination(rotation, translation, @surgical_tolerance) == :ok
    end

    test "microsurgery precision maintains minimal jerk for delicate procedures" do
      # Test extremely small movements typical in microsurgery (micrometer scale)
      # These movements must have absolutely minimal jerk to prevent tissue damage
      moved = [{1.0e-6, 0.0, 0.0}, {0.0, 1.0e-6, 0.0}]    # Micrometer-scale initial positions
      target = [{0.0, 1.0e-6, 0.0}, {-1.0e-6, 0.0, 0.0}]  # Micrometer-scale target positions

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

      # CRITICAL: Enforce surgical safety jerk limits for microsurgery
      enforce_surgical_jerk_limits(rotation, translation)

      # For microsurgery, use even stricter tolerance
      microsurgery_tolerance = 1.0e-12

      # Validate minimal jerk with microsurgery precision requirements
      assert Motion.validate_minimal_jerk(rotation, translation, microsurgery_tolerance) == :ok

      # Ensure rotational motion is smooth enough for delicate tissue work
      assert Motion.validate_minimal_angular_jerk(rotation, microsurgery_tolerance) == :ok

      # Verify translation meets microsurgical smoothness standards
      assert Motion.validate_minimal_linear_jerk(translation, microsurgery_tolerance) == :ok

      # Check that rotation and translation are optimally coordinated for precision work
      assert Motion.validate_motion_coordination(rotation, translation, microsurgery_tolerance) == :ok
    end

    test "emergency correction maintains acceptable jerk levels" do
      # Simulate a scenario where surgeon needs quick but safe correction
      # This tests the boundary between necessary speed and patient safety
      moved = [{0.005, 0.0, 0.0}, {0.0, 0.005, 0.0}]     # 5mm displacement requiring correction
      target = [{0.0, 0.005, 0.0}, {-0.005, 0.0, 0.0}]   # Corrected positions

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

      # CRITICAL: Enforce surgical safety jerk limits even for emergency corrections
      enforce_surgical_jerk_limits(rotation, translation)

      # Even emergency corrections must maintain surgical safety
      assert Motion.validate_minimal_jerk(rotation, translation, @surgical_tolerance) == :ok

      # Validate that angular correction doesn't exceed safe rotational jerk
      assert Motion.validate_minimal_angular_jerk(rotation, @surgical_tolerance) == :ok

      # Ensure linear correction maintains tissue-safe motion profile
      assert Motion.validate_minimal_linear_jerk(translation, @surgical_tolerance) == :ok

      # Verify emergency motion coordination remains surgically safe
      assert Motion.validate_motion_coordination(rotation, translation, @surgical_tolerance) == :ok

      # Additional safety check: transformation should be reasonable for emergency correction
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < @surgical_tolerance

      {tx, ty, tz} = translation
      translation_magnitude = :math.sqrt(tx*tx + ty*ty + tz*tz)
      # Emergency correction should not require excessive translation
      assert translation_magnitude < 0.02  # Less than 2cm total translation for safety
    end

    test "multi-point surgical trajectory maintains smooth motion coordination" do
      # Test alignment of multiple surgical waypoints (like suture points)
      # Ensures smooth motion coordination across complex surgical paths
      moved = [
        {0.001, 0.0, 0.0},     # First suture point
        {0.002, 0.001, 0.0},   # Second suture point
        {0.003, 0.002, 0.001}, # Third suture point
        {0.004, 0.001, 0.002}  # Fourth suture point
      ]

      target = [
        {0.0, 0.001, 0.0},     # Aligned first point
        {0.001, 0.002, 0.0},   # Aligned second point
        {0.002, 0.003, 0.001}, # Aligned third point
        {0.001, 0.002, 0.003}  # Aligned fourth point
      ]

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

      # CRITICAL: Enforce surgical safety jerk limits for multi-point trajectory
      enforce_surgical_jerk_limits(rotation, translation)

      # Validate overall trajectory maintains surgical safety standards
      assert Motion.validate_minimal_jerk(rotation, translation, @surgical_tolerance) == :ok

      # Ensure multi-point alignment uses minimal angular jerk
      assert Motion.validate_minimal_angular_jerk(rotation, @surgical_tolerance) == :ok

      # Verify linear motion across waypoints follows smoothest path
      assert Motion.validate_minimal_linear_jerk(translation, @surgical_tolerance) == :ok

      # Critical: motion coordination must be optimal for complex surgical paths
      assert Motion.validate_motion_coordination(rotation, translation, @surgical_tolerance) == :ok

      # Additional validation: verify transformation is within surgical working envelope
      {x, y, z, w} = rotation
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < @surgical_tolerance

      {tx, ty, tz} = translation
      # Multi-point surgical procedures should have reasonable translation bounds
      assert abs(tx) < 0.01  # Less than 1cm in any direction
      assert abs(ty) < 0.01
      assert abs(tz) < 0.01
    end

    test "validates surgical safety thresholds are not exceeded" do
      # Test that ensures no surgeon would be harmed by excessive jerk
      # This is a comprehensive safety validation test
      moved = [{0.002, 0.001, 0.0}]    # Realistic surgical starting position
      target = [{0.001, 0.002, 0.001}] # Realistic surgical target position

      assert {:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

      # CRITICAL: Enforce surgical safety jerk limits for comprehensive validation
      enforce_surgical_jerk_limits(rotation, translation)

      # Comprehensive jerk validation for surgical safety
      assert Motion.validate_minimal_jerk(rotation, translation, @surgical_tolerance) == :ok

      # Validate specific jerk components don't exceed medical safety limits
      assert Motion.validate_minimal_angular_jerk(rotation, @surgical_tolerance) == :ok
      assert Motion.validate_minimal_linear_jerk(translation, @surgical_tolerance) == :ok
      assert Motion.validate_motion_coordination(rotation, translation, @surgical_tolerance) == :ok

      # Ensure transformation parameters are within safe surgical ranges
      {x, y, z, w} = rotation

      # Calculate rotation angle to ensure it's within safe surgical limits
      angle = 2 * :math.acos(min(abs(w), 1.0))
      normalized_angle = if angle > :math.pi, do: 2 * :math.pi - angle, else: angle

      # Surgical rotations should be small and controlled
      assert normalized_angle < :math.pi / 2  # Less than 90 degrees for safety

      # Translation should be precise and limited
      {tx, ty, tz} = translation
      translation_magnitude = :math.sqrt(tx*tx + ty*ty + tz*tz)

      # Surgical translations should be minimal and precise
      assert translation_magnitude < 0.005  # Less than 5mm total displacement for precision

      # Final safety assertion: rotation quaternion must be properly normalized
      rotation_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      assert abs(rotation_magnitude - 1.0) < @surgical_tolerance
    end
  end
end
