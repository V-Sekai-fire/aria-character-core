# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.QCPTest do
  use ExUnit.Case
  doctest AriaMath.QCP

  alias AriaMath.{QCP, Vector3, Quaternion, Matrix4}

  describe "QCP.calculate/2" do
    test "identical point sets return identity transformation" do
      points_a = [
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0},
        {0.0, 0.0, 1.0}
      ]
      points_b = points_a

      {rotation, translation, rmsd} = QCP.calculate(points_a, points_b)

      # Should be identity rotation
      assert Quaternion.is_identity?(rotation)

      # Should be zero translation
      {tx, ty, tz} = translation
      assert_in_delta(tx, 0.0, 1.0e-10)
      assert_in_delta(ty, 0.0, 1.0e-10)
      assert_in_delta(tz, 0.0, 1.0e-10)

      # Should be zero RMSD
      assert_in_delta(rmsd, 0.0, 1.0e-10)
    end

    test "translated point sets return correct translation" do
      points_a = [
        {0.0, 0.0, 0.0},
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0}
      ]

      # Translate by (2, 3, 4)
      points_b = [
        {2.0, 3.0, 4.0},
        {3.0, 3.0, 4.0},
        {2.0, 4.0, 4.0}
      ]

      {rotation, translation, rmsd} = QCP.calculate(points_a, points_b)

      # Should be identity rotation (no rotation needed)
      assert Quaternion.is_identity?(rotation)

      # Should recover the translation
      {tx, ty, tz} = translation
      assert_in_delta(tx, 2.0, 1.0e-10)
      assert_in_delta(ty, 3.0, 1.0e-10)
      assert_in_delta(tz, 4.0, 1.0e-10)

      # Should be zero RMSD
      assert_in_delta(rmsd, 0.0, 1.0e-10)
    end

    test "rotated point sets return correct rotation" do
      # Original points forming a right triangle
      points_a = [
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0},
        {0.0, 0.0, 0.0}
      ]

      # 90-degree rotation around Z-axis
      points_b = [
        {0.0, 1.0, 0.0},
        {-1.0, 0.0, 0.0},
        {0.0, 0.0, 0.0}
      ]

      {rotation, translation, rmsd} = QCP.calculate(points_a, points_b)

      # Should be approximately 90-degree rotation around Z-axis
      {axis, angle} = Quaternion.to_axis_angle(rotation)
      {ax, ay, az} = axis

      # Axis should be approximately Z-axis
      assert_in_delta(ax, 0.0, 1.0e-6)
      assert_in_delta(ay, 0.0, 1.0e-6)
      assert_in_delta(abs(az), 1.0, 1.0e-6)

      # Angle should be approximately 90 degrees
      assert_in_delta(abs(angle), :math.pi() / 2.0, 1.0e-6)

      # Translation should be minimal
      {tx, ty, tz} = translation
      assert_in_delta(tx, 0.0, 1.0e-6)
      assert_in_delta(ty, 0.0, 1.0e-6)
      assert_in_delta(tz, 0.0, 1.0e-6)

      # RMSD should be very small
      assert rmsd < 1.0e-6
    end

    test "handles single point case" do
      points_a = [{1.0, 2.0, 3.0}]
      points_b = [{4.0, 5.0, 6.0}]

      {rotation, translation, rmsd} = QCP.calculate(points_a, points_b)

      # Should be identity rotation (no rotation determinable from single point)
      assert Quaternion.is_identity?(rotation)

      # Should recover the translation difference
      {tx, ty, tz} = translation
      assert_in_delta(tx, 3.0, 1.0e-10)
      assert_in_delta(ty, 3.0, 1.0e-10)
      assert_in_delta(tz, 3.0, 1.0e-10)

      # RMSD should be zero for perfect match
      assert_in_delta(rmsd, 0.0, 1.0e-10)
    end

    test "handles two point case" do
      points_a = [
        {0.0, 0.0, 0.0},
        {1.0, 0.0, 0.0}
      ]

      points_b = [
        {0.0, 0.0, 0.0},
        {0.0, 1.0, 0.0}
      ]

      {rotation, translation, rmsd} = QCP.calculate(points_a, points_b)

      # Should find a rotation that aligns the line segments
      # Translation should be minimal since both sets include origin
      {tx, ty, tz} = translation
      assert_in_delta(tx, 0.0, 1.0e-6)
      assert_in_delta(ty, 0.0, 1.0e-6)
      assert_in_delta(tz, 0.0, 1.0e-6)

      # RMSD should be small for good alignment
      assert rmsd < 1.0e-6
    end

    test "returns error for mismatched point count" do
      points_a = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}]
      points_b = [{0.0, 0.0, 0.0}]

      assert_raise ArgumentError, fn ->
        QCP.calculate(points_a, points_b)
      end
    end

    test "returns error for empty point sets" do
      assert_raise ArgumentError, fn ->
        QCP.calculate([], [])
      end
    end
  end

  describe "QCP.apply_transformation/3" do
    test "applies rotation and translation to points" do
      points = [
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0},
        {0.0, 0.0, 1.0}
      ]

      # 90-degree rotation around Z-axis
      rotation = Quaternion.from_axis_angle({0.0, 0.0, 1.0}, :math.pi() / 2.0)
      translation = {1.0, 2.0, 3.0}

      transformed_points = QCP.apply_transformation(points, rotation, translation)

      # Check first point: (1,0,0) -> (0,1,0) + translation -> (1,3,3)
      [{x1, y1, z1}, {x2, y2, z2}, {x3, y3, z3}] = transformed_points

      assert_in_delta(x1, 1.0, 1.0e-10)
      assert_in_delta(y1, 3.0, 1.0e-10)
      assert_in_delta(z1, 3.0, 1.0e-10)

      # Check second point: (0,1,0) -> (-1,0,0) + translation -> (0,2,3)
      assert_in_delta(x2, 0.0, 1.0e-10)
      assert_in_delta(y2, 2.0, 1.0e-10)
      assert_in_delta(z2, 3.0, 1.0e-10)
    end

    test "applies identity transformation unchanged" do
      points = [
        {1.0, 2.0, 3.0},
        {4.0, 5.0, 6.0}
      ]

      rotation = Quaternion.identity()
      translation = {0.0, 0.0, 0.0}

      transformed_points = QCP.apply_transformation(points, rotation, translation)

      assert transformed_points == points
    end
  end

  describe "QCP.rmsd/2" do
    test "calculates zero RMSD for identical point sets" do
      points_a = [
        {1.0, 2.0, 3.0},
        {4.0, 5.0, 6.0},
        {7.0, 8.0, 9.0}
      ]

      rmsd = QCP.rmsd(points_a, points_a)
      assert_in_delta(rmsd, 0.0, 1.0e-10)
    end

    test "calculates correct RMSD for translated points" do
      points_a = [
        {0.0, 0.0, 0.0},
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0}
      ]

      # Translate all points by (1,0,0)
      points_b = [
        {1.0, 0.0, 0.0},
        {2.0, 0.0, 0.0},
        {1.0, 1.0, 0.0}
      ]

      rmsd = QCP.rmsd(points_a, points_b)
      # RMSD should be 1.0 (all points displaced by distance 1)
      assert_in_delta(rmsd, 1.0, 1.0e-10)
    end

    test "returns error for mismatched point count" do
      points_a = [{0.0, 0.0, 0.0}]
      points_b = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}]

      assert_raise ArgumentError, fn ->
        QCP.rmsd(points_a, points_b)
      end
    end
  end
end
