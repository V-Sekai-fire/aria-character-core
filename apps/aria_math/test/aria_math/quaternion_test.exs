# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.QuaternionTest do
  use ExUnit.Case
  doctest AriaMath.Quaternion

  alias AriaMath.Quaternion

  describe "Quaternion.new/4" do
    test "creates quaternion from four floats" do
      result = Quaternion.new(0.0, 0.0, 0.0, 1.0)
      assert result == {0.0, 0.0, 0.0, 1.0}
    end

    test "converts integers to floats" do
      result = Quaternion.new(0, 0, 0, 1)
      assert result == {0.0, 0.0, 0.0, 1.0}
    end
  end

  describe "Quaternion.conjugate/1" do
    test "conjugates quaternion" do
      result = Quaternion.conjugate({1.0, 2.0, 3.0, 4.0})
      assert result == {-1.0, -2.0, -3.0, 4.0}
    end

    test "conjugate of identity quaternion" do
      result = Quaternion.conjugate({0.0, 0.0, 0.0, 1.0})
      assert result == {0.0, 0.0, 0.0, 1.0}
    end
  end

  describe "Quaternion.multiply/2" do
    test "multiplying by identity returns original" do
      original = {1.0, 0.0, 0.0, 0.0}
      identity = {0.0, 0.0, 0.0, 1.0}
      result = Quaternion.multiply(original, identity)
      assert result == original
    end

    test "multiplication is non-commutative" do
      a = {1.0, 0.0, 0.0, 0.0}
      b = {0.0, 1.0, 0.0, 0.0}

      result_ab = Quaternion.multiply(a, b)
      result_ba = Quaternion.multiply(b, a)

      assert result_ab != result_ba
    end

    test "basic quaternion multiplication" do
      # i * j = k
      i = {1.0, 0.0, 0.0, 0.0}
      j = {0.0, 1.0, 0.0, 0.0}
      k = {0.0, 0.0, 1.0, 0.0}

      result = Quaternion.multiply(i, j)
      assert result == k
    end
  end

  describe "Quaternion.angle_between/2" do
    test "angle between identical quaternions is zero" do
      q = {0.0, 0.0, 0.0, 1.0}
      result = Quaternion.angle_between(q, q)
      assert_in_delta(result, 0.0, 1.0e-10)
    end

    test "angle between opposite quaternions" do
      q1 = {0.0, 0.0, 0.0, 1.0}
      q2 = {0.0, 0.0, 0.0, -1.0}
      result = Quaternion.angle_between(q1, q2)
      assert_in_delta(result, 0.0, 1.0e-10)  # Should be 0 because we take abs of dot product
    end
  end

  describe "Quaternion.from_axis_angle/2" do
    test "creates quaternion from Z-axis rotation" do
      axis = {0.0, 0.0, 1.0}
      angle = :math.pi() / 2.0  # 90 degrees

      result = Quaternion.from_axis_angle(axis, angle)
      {x, y, z, w} = result

      expected_sin = :math.sin(angle / 2.0)
      expected_cos = :math.cos(angle / 2.0)

      assert_in_delta(x, 0.0, 1.0e-10)
      assert_in_delta(y, 0.0, 1.0e-10)
      assert_in_delta(z, expected_sin, 1.0e-10)
      assert_in_delta(w, expected_cos, 1.0e-10)
    end

    test "creates identity from zero angle" do
      axis = {1.0, 0.0, 0.0}
      angle = 0.0

      result = Quaternion.from_axis_angle(axis, angle)
      assert_in_delta(elem(result, 0), 0.0, 1.0e-10)
      assert_in_delta(elem(result, 1), 0.0, 1.0e-10)
      assert_in_delta(elem(result, 2), 0.0, 1.0e-10)
      assert_in_delta(elem(result, 3), 1.0, 1.0e-10)
    end
  end

  describe "Quaternion.to_axis_angle/1" do
    test "decomposes identity quaternion" do
      identity = {0.0, 0.0, 0.0, 1.0}
      {axis, angle} = Quaternion.to_axis_angle(identity)

      # Should return arbitrary unit axis and zero angle
      assert_in_delta(angle, 0.0, 1.0e-10)
      # Axis should be unit length
      {ax, ay, az} = axis
      axis_length = :math.sqrt(ax * ax + ay * ay + az * az)
      assert_in_delta(axis_length, 1.0, 1.0e-10)
    end

    test "round-trip conversion preserves rotation" do
      original_axis = {0.0, 1.0, 0.0}
      original_angle = :math.pi() / 3.0  # 60 degrees

      quat = Quaternion.from_axis_angle(original_axis, original_angle)
      {recovered_axis, recovered_angle} = Quaternion.to_axis_angle(quat)

      assert_in_delta(recovered_angle, original_angle, 1.0e-10)

      {rax, ray, raz} = recovered_axis
      {oax, oay, oaz} = original_axis
      assert_in_delta(rax, oax, 1.0e-10)
      assert_in_delta(ray, oay, 1.0e-10)
      assert_in_delta(raz, oaz, 1.0e-10)
    end
  end

  describe "Quaternion.from_directions/2" do
    test "creates quaternion rotating X to Y" do
      x_axis = {1.0, 0.0, 0.0}
      y_axis = {0.0, 1.0, 0.0}

      result = Quaternion.from_directions(x_axis, y_axis)

      # Should be a 90-degree rotation around Z-axis
      {x, y, z, w} = result
      assert_in_delta(x, 0.0, 1.0e-10)
      assert_in_delta(y, 0.0, 1.0e-10)
      assert_in_delta(z, 0.7071067811865476, 1.0e-10)  # sin(π/4)
      assert_in_delta(w, 0.7071067811865475, 1.0e-10)  # cos(π/4)
    end

    test "handles parallel vectors in same direction" do
      direction = {1.0, 0.0, 0.0}
      result = Quaternion.from_directions(direction, direction)

      # Should return identity quaternion
      assert result == {0.0, 0.0, 0.0, 1.0}
    end

    test "handles parallel vectors in opposite directions" do
      a = {1.0, 0.0, 0.0}
      b = {-1.0, 0.0, 0.0}

      result = Quaternion.from_directions(a, b)
      {x, y, z, w} = result

      # Should be a 180-degree rotation
      assert_in_delta(w, 0.0, 1.0e-10)
      # Rotation axis should be perpendicular and unit length
      axis_length = :math.sqrt(x * x + y * y + z * z)
      assert_in_delta(axis_length, 1.0, 1.0e-10)
    end
  end

  describe "Quaternion.normalize/1" do
    test "normalizes non-unit quaternion" do
      {normalized, valid} = Quaternion.normalize({0.0, 0.0, 0.0, 2.0})
      assert valid == true
      assert normalized == {0.0, 0.0, 0.0, 1.0}
    end

    test "handles zero quaternion" do
      {normalized, valid} = Quaternion.normalize({0.0, 0.0, 0.0, 0.0})
      assert valid == false
      assert normalized == {0.0, 0.0, 0.0, 1.0}  # Returns identity
    end

    test "normalizes arbitrary quaternion" do
      {normalized, valid} = Quaternion.normalize({1.0, 1.0, 1.0, 1.0})
      assert valid == true

      # Should have unit length
      {x, y, z, w} = normalized
      length = :math.sqrt(x * x + y * y + z * z + w * w)
      assert_in_delta(length, 1.0, 1.0e-10)
    end
  end

  describe "Quaternion.slerp/3" do
    test "slerp at endpoints returns input quaternions" do
      a = {0.0, 0.0, 0.0, 1.0}
      b = {1.0, 0.0, 0.0, 0.0}

      result_0 = Quaternion.slerp(a, b, 0.0)
      result_1 = Quaternion.slerp(a, b, 1.0)

      {ax, ay, az, aw} = a
      {r0x, r0y, r0z, r0w} = result_0
      assert_in_delta(r0x, ax, 1.0e-10)
      assert_in_delta(r0y, ay, 1.0e-10)
      assert_in_delta(r0z, az, 1.0e-10)
      assert_in_delta(r0w, aw, 1.0e-10)

      {bx, by, bz, bw} = b
      {r1x, r1y, r1z, r1w} = result_1
      assert_in_delta(r1x, bx, 1.0e-10)
      assert_in_delta(r1y, by, 1.0e-10)
      assert_in_delta(r1z, bz, 1.0e-10)
      assert_in_delta(r1w, bw, 1.0e-10)
    end

    test "slerp result has unit length" do
      a = {0.0, 0.0, 0.0, 1.0}
      b = {0.7071067811865476, 0.0, 0.0, 0.7071067811865475}

      result = Quaternion.slerp(a, b, 0.5)
      {x, y, z, w} = result

      length = :math.sqrt(x * x + y * y + z * z + w * w)
      assert_in_delta(length, 1.0, 1.0e-10)
    end
  end

  describe "Quaternion.length/1" do
    test "calculates length of unit quaternion" do
      identity = {0.0, 0.0, 0.0, 1.0}
      assert_in_delta(Quaternion.length(identity), 1.0, 1.0e-10)
    end

    test "calculates length of arbitrary quaternion" do
      q = {1.0, 1.0, 1.0, 1.0}
      expected = 2.0  # sqrt(1+1+1+1) = 2
      assert_in_delta(Quaternion.length(q), expected, 1.0e-10)
    end

    test "calculates length of zero quaternion" do
      zero = {0.0, 0.0, 0.0, 0.0}
      assert Quaternion.length(zero) == 0.0
    end
  end

  describe "Quaternion.dot/2" do
    test "dot product of identical quaternions" do
      q = {1.0, 2.0, 3.0, 4.0}
      result = Quaternion.dot(q, q)
      expected = 1.0 + 4.0 + 9.0 + 16.0  # 1² + 2² + 3² + 4²
      assert result == expected
    end

    test "dot product of orthogonal quaternions" do
      a = {1.0, 0.0, 0.0, 0.0}
      b = {0.0, 1.0, 0.0, 0.0}
      result = Quaternion.dot(a, b)
      assert result == 0.0
    end
  end

  describe "constants and utilities" do
    test "identity quaternion" do
      assert Quaternion.identity() == {0.0, 0.0, 0.0, 1.0}
    end

    test "is_identity? recognizes identity quaternion" do
      assert Quaternion.is_identity?({0.0, 0.0, 0.0, 1.0}) == true
    end

    test "is_identity? rejects non-identity quaternion" do
      assert Quaternion.is_identity?({0.1, 0.0, 0.0, 0.995}) == false
    end

    test "is_identity? handles approximate identity" do
      epsilon = 1.0e-7
      almost_identity = {epsilon / 2, epsilon / 2, epsilon / 2, 1.0 - epsilon / 2}
      assert Quaternion.is_identity?(almost_identity) == true
    end
  end
end
