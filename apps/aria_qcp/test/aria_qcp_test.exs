# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcpTest do
  use ExUnit.Case
  doctest AriaQcp

  alias AriaMath.{Vector3, Quaternion}

  test "basic QCP calculation with simple rotation" do
    # Simple 90-degree rotation test
    moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
    target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]

    case AriaQcp.calculate(moved, target) do
      {:ok, {rotation, translation, rmsd}} ->
        assert is_tuple(rotation)
        assert tuple_size(rotation) == 4
        assert is_tuple(translation)
        assert tuple_size(translation) == 3
        assert is_float(rmsd)
        assert rmsd >= 0.0

      {:error, reason} ->
        flunk("QCP calculation failed: #{inspect(reason)}")
    end
  end

  test "identity transformation for identical point sets" do
    points = [{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}]

    case AriaQcp.calculate(points, points) do
      {:ok, {rotation, translation, rmsd}} ->
        # Should be close to identity rotation and zero translation
        {x, y, z, w} = rotation
        assert abs(w - 1.0) < 1.0e-6 or abs(w + 1.0) < 1.0e-6  # w should be ±1
        assert abs(x) < 1.0e-6
        assert abs(y) < 1.0e-6
        assert abs(z) < 1.0e-6

        {tx, ty, tz} = translation
        assert abs(tx) < 1.0e-6
        assert abs(ty) < 1.0e-6
        assert abs(tz) < 1.0e-6

        assert rmsd < 1.0e-6

      {:error, reason} ->
        flunk("Identity QCP calculation failed: #{inspect(reason)}")
    end
  end

  test "RMSD calculation for identical point sets" do
    points = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}]

    case AriaQcp.rmsd(points, points) do
      {:ok, rmsd_value} ->
        assert abs(rmsd_value) < 1.0e-12

      {:error, reason} ->
        flunk("RMSD calculation failed: #{inspect(reason)}")
    end
  end

  test "RMSD calculation for different point sets" do
    points_a = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}]
    points_b = [{1.0, 0.0, 0.0}, {2.0, 0.0, 0.0}]

    case AriaQcp.rmsd(points_a, points_b) do
      {:ok, rmsd_value} ->
        expected_rmsd = 1.0  # Distance of 1.0 for each point
        assert abs(rmsd_value - expected_rmsd) < 1.0e-6

      {:error, reason} ->
        flunk("RMSD calculation failed: #{inspect(reason)}")
    end
  end

  test "weighted superposition with equal weights" do
    moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
    target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
    weights = [1.0, 1.0]

    case AriaQcp.weighted_superpose(moved, target, weights, true, 1.0e-6) do
      {:ok, {rotation, translation}} ->
        assert is_tuple(rotation)
        assert tuple_size(rotation) == 4
        assert is_tuple(translation)
        assert tuple_size(translation) == 3

      {:error, reason} ->
        flunk("Weighted superposition failed: #{inspect(reason)}")
    end
  end

  test "error handling for mismatched point counts" do
    moved = [{1.0, 0.0, 0.0}]
    target = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]

    case AriaQcp.calculate(moved, target) do
      {:error, :mismatched_point_set_sizes} ->
        :ok

      {:error, reason} ->
        flunk("Expected mismatched_point_set_sizes error, got: #{inspect(reason)}")

      {:ok, _} ->
        flunk("Expected error for mismatched point counts")
    end
  end

  test "error handling for empty point sets" do
    case AriaQcp.calculate([], []) do
      {:error, :empty_point_sets} ->
        :ok

      {:error, reason} ->
        flunk("Expected empty_point_sets error, got: #{inspect(reason)}")

      {:ok, _} ->
        flunk("Expected error for empty point sets")
    end
  end

  test "apply transformation to point set" do
    points = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
    identity_rotation = {0.0, 0.0, 0.0, 1.0}
    translation = {1.0, 2.0, 3.0}

    transformed_points = AriaQcp.apply_transformation(points, identity_rotation, translation)

    expected = [{2.0, 2.0, 3.0}, {1.0, 3.0, 3.0}]

    Enum.zip(transformed_points, expected)
    |> Enum.each(fn {{ax, ay, az}, {ex, ey, ez}} ->
      assert abs(ax - ex) < 1.0e-6
      assert abs(ay - ey) < 1.0e-6
      assert abs(az - ez) < 1.0e-6
    end)
  end
end
