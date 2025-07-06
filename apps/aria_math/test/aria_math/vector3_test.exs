# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3Test do
  use ExUnit.Case
  doctest AriaMath.Vector3

  alias AriaMath.{Vector3, Primitives}

  describe "Vector3.new/3" do
    test "creates vector from three floats" do
      result = Vector3.new(1.0, 2.0, 3.0)
      assert result == {1.0, 2.0, 3.0}
    end

    test "converts integers to floats" do
      result = Vector3.new(1, 2, 3)
      assert result == {1.0, 2.0, 3.0}
    end
  end

  describe "Vector3.length/1" do
    test "calculates length of unit vectors" do
      assert Vector3.length({1.0, 0.0, 0.0}) == 1.0
      assert Vector3.length({0.0, 1.0, 0.0}) == 1.0
      assert Vector3.length({0.0, 0.0, 1.0}) == 1.0
    end

    test "calculates length of 3-4-5 triangle" do
      result = Vector3.length({3.0, 4.0, 0.0})
      assert result == 5.0
    end

    test "calculates length of zero vector" do
      assert Vector3.length({0.0, 0.0, 0.0}) == 0.0
    end

    test "handles special IEEE-754 cases" do
      # Infinity components should return positive infinity
      inf = Primitives.inf()
      assert Primitives.isinf_float(Vector3.length({inf, 0.0, 0.0}))
      assert Primitives.isinf_float(Vector3.length({0.0, inf, 0.0}))
      assert Primitives.isinf_float(Vector3.length({0.0, 0.0, inf}))
    end
  end

  describe "Vector3.normalize/1" do
    test "normalizes non-zero vectors" do
      {normalized, valid} = Vector3.normalize({3.0, 4.0, 0.0})
      assert valid == true
      assert_in_delta(elem(normalized, 0), 0.6, 1.0e-10)
      assert_in_delta(elem(normalized, 1), 0.8, 1.0e-10)
      assert_in_delta(elem(normalized, 2), 0.0, 1.0e-10)
    end

    test "handles zero vector" do
      {normalized, valid} = Vector3.normalize({0.0, 0.0, 0.0})
      assert valid == false
      assert normalized == {0.0, 0.0, 0.0}
    end

    test "handles unit vectors" do
      {normalized, valid} = Vector3.normalize({1.0, 0.0, 0.0})
      assert valid == true
      assert normalized == {1.0, 0.0, 0.0}
    end
  end

  describe "Vector3.dot/2" do
    test "calculates dot product of orthogonal vectors" do
      result = Vector3.dot({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      assert result == 0.0
    end

    test "calculates dot product of parallel vectors" do
      result = Vector3.dot({1.0, 2.0, 3.0}, {2.0, 4.0, 6.0})
      assert result == 28.0  # 1*2 + 2*4 + 3*6 = 2 + 8 + 18 = 28
    end

    test "calculates dot product of identical vectors" do
      result = Vector3.dot({1.0, 2.0, 3.0}, {1.0, 2.0, 3.0})
      assert result == 14.0  # 1*1 + 2*2 + 3*3 = 1 + 4 + 9 = 14
    end
  end

  describe "Vector3.cross/2" do
    test "calculates cross product of unit vectors" do
      result = Vector3.cross({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      assert result == {0.0, 0.0, 1.0}
    end

    test "calculates cross product resulting in zero" do
      result = Vector3.cross({1.0, 2.0, 3.0}, {2.0, 4.0, 6.0})
      assert result == {0.0, 0.0, 0.0}
    end

    test "cross product is anti-commutative" do
      a = {1.0, 2.0, 3.0}
      b = {4.0, 5.0, 6.0}
      cross_ab = Vector3.cross(a, b)
      cross_ba = Vector3.cross(b, a)

      {x1, y1, z1} = cross_ab
      {x2, y2, z2} = cross_ba

      assert_in_delta(x1, -x2, 1.0e-10)
      assert_in_delta(y1, -y2, 1.0e-10)
      assert_in_delta(z1, -z2, 1.0e-10)
    end
  end

  describe "Vector3.add/2" do
    test "adds two vectors" do
      result = Vector3.add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      assert result == {5.0, 7.0, 9.0}
    end

    test "adding zero vector returns original" do
      original = {1.0, 2.0, 3.0}
      zero = {0.0, 0.0, 0.0}
      result = Vector3.add(original, zero)
      assert result == original
    end
  end

  describe "Vector3.sub/2" do
    test "subtracts two vectors" do
      result = Vector3.sub({5.0, 7.0, 9.0}, {1.0, 2.0, 3.0})
      assert result == {4.0, 5.0, 6.0}
    end

    test "subtracting from itself returns zero" do
      original = {1.0, 2.0, 3.0}
      result = Vector3.sub(original, original)
      assert result == {0.0, 0.0, 0.0}
    end
  end

  describe "Vector3.mul/2" do
    test "multiplies vectors component-wise" do
      result = Vector3.mul({2.0, 3.0, 4.0}, {5.0, 6.0, 7.0})
      assert result == {10.0, 18.0, 28.0}
    end
  end

  describe "Vector3.scale/2" do
    test "scales vector by scalar" do
      result = Vector3.scale({1.0, 2.0, 3.0}, 2.0)
      assert result == {2.0, 4.0, 6.0}
    end

    test "scaling by zero returns zero vector" do
      result = Vector3.scale({1.0, 2.0, 3.0}, 0.0)
      assert result == {0.0, 0.0, 0.0}
    end
  end

  describe "Vector3.min/2 and Vector3.max/2" do
    test "calculates component-wise minimum" do
      result = Vector3.min({1.0, 5.0, 3.0}, {4.0, 2.0, 6.0})
      assert result == {1.0, 2.0, 3.0}
    end

    test "calculates component-wise maximum" do
      result = Vector3.max({1.0, 5.0, 3.0}, {4.0, 2.0, 6.0})
      assert result == {4.0, 5.0, 6.0}
    end
  end

  describe "Vector3.mix/3" do
    test "linear interpolation at endpoints" do
      a = {0.0, 0.0, 0.0}
      b = {1.0, 1.0, 1.0}

      result_0 = Vector3.mix(a, b, 0.0)
      assert result_0 == a

      result_1 = Vector3.mix(a, b, 1.0)
      assert result_1 == b
    end

    test "linear interpolation at midpoint" do
      a = {0.0, 0.0, 0.0}
      b = {2.0, 4.0, 6.0}

      result = Vector3.mix(a, b, 0.5)
      assert result == {1.0, 2.0, 3.0}
    end
  end

  describe "constants" do
    test "zero vector" do
      assert Vector3.zero() == {0.0, 0.0, 0.0}
    end

    test "unit vectors" do
      assert Vector3.unit_x() == {1.0, 0.0, 0.0}
      assert Vector3.unit_y() == {0.0, 1.0, 0.0}
      assert Vector3.unit_z() == {0.0, 0.0, 1.0}
    end
  end
end
