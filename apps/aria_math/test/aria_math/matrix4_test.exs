# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Matrix4Test do
  use ExUnit.Case
  doctest AriaMath.Matrix4

  alias AriaMath.{Matrix4, Quaternion}

  describe "Matrix4.new/16" do
    test "creates matrix from 16 floats" do
      result = Matrix4.new(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
      expected = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      assert result == expected
    end
  end

  describe "Matrix4.multiply/2" do
    test "multiplying by identity returns original" do
      original = {1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16}
      identity = Matrix4.identity()
      result = Matrix4.multiply(original, identity)
      assert result == original
    end

    test "identity multiplication is commutative" do
      matrix = {1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16}
      identity = Matrix4.identity()

      result1 = Matrix4.multiply(matrix, identity)
      result2 = Matrix4.multiply(identity, matrix)
      assert result1 == result2
    end
  end

  describe "Matrix4.determinant/1" do
    test "determinant of identity matrix is 1" do
      result = Matrix4.determinant(Matrix4.identity())
      assert result == 1.0
    end

    test "determinant of zero matrix is 0" do
      result = Matrix4.determinant(Matrix4.zero())
      assert result == 0.0
    end

    test "determinant of scaling matrix" do
      scaling = Matrix4.scaling({2.0, 3.0, 4.0})
      result = Matrix4.determinant(scaling)
      expected = 2.0 * 3.0 * 4.0  # Product of diagonal elements
      assert_in_delta(result, expected, 1.0e-10)
    end
  end

  describe "Matrix4.inverse/1" do
    test "inverse of identity is identity" do
      {inverse, valid} = Matrix4.inverse(Matrix4.identity())
      assert valid == true
      assert inverse == Matrix4.identity()
    end

    test "inverse of zero matrix is invalid" do
      {inverse, valid} = Matrix4.inverse(Matrix4.zero())
      assert valid == false
      assert inverse == Matrix4.identity()  # Returns identity on failure
    end

    test "inverse of scaling matrix" do
      scaling = Matrix4.scaling({2.0, 3.0, 4.0})
      {inverse, valid} = Matrix4.inverse(scaling)
      assert valid == true

      # Multiply original by inverse should give identity
      result = Matrix4.multiply(scaling, inverse)
      identity = Matrix4.identity()

      # Check each component with tolerance
      {r0,_r1,_r2,_r3,_r4,r5,_r6,_r7,_r8,_r9,r10,_r11,_r12,_r13,_r14,r15} = result
      {i0,_i1,_i2,_i3,_i4,i5,_i6,_i7,_i8,_i9,i10,_i11,_i12,_i13,_i14,i15} = identity

      assert_in_delta(r0, i0, 1.0e-10)
      assert_in_delta(r5, i5, 1.0e-10)
      assert_in_delta(r10, i10, 1.0e-10)
      assert_in_delta(r15, i15, 1.0e-10)
    end
  end

  describe "Matrix4.transpose/1" do
    test "transpose of identity is identity" do
      result = Matrix4.transpose(Matrix4.identity())
      assert result == Matrix4.identity()
    end

    test "transpose swaps rows and columns" do
      matrix = {1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16}
      result = Matrix4.transpose(matrix)
      expected = {1,5,9,13, 2,6,10,14, 3,7,11,15, 4,8,12,16}
      assert result == expected
    end

    test "double transpose returns original" do
      original = {1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16}
      result = Matrix4.transpose(Matrix4.transpose(original))
      assert result == original
    end
  end

  describe "Matrix4.translation/1" do
    test "creates translation matrix" do
      result = Matrix4.translation({1.0, 2.0, 3.0})
      expected = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 2.0, 3.0, 1.0}
      assert result == expected
    end

    test "translation matrix transforms points correctly" do
      translation = Matrix4.translation({5.0, 10.0, 15.0})
      point = {0.0, 0.0, 0.0}
      result = Matrix4.transform_point(translation, point)
      assert result == {5.0, 10.0, 15.0}
    end
  end

  describe "Matrix4.scaling/1" do
    test "creates scaling matrix" do
      result = Matrix4.scaling({2.0, 3.0, 4.0})
      expected = {2.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      assert result == expected
    end

    test "scaling matrix transforms points correctly" do
      scaling = Matrix4.scaling({2.0, 3.0, 4.0})
      point = {1.0, 1.0, 1.0}
      result = Matrix4.transform_point(scaling, point)
      assert result == {2.0, 3.0, 4.0}
    end
  end

  describe "Matrix4.rotation/1" do
    test "rotation from identity quaternion is identity matrix" do
      result = Matrix4.rotation(Quaternion.identity())
      identity = Matrix4.identity()
      assert result == identity
    end

    test "rotation matrix transforms vectors correctly" do
      # 90-degree rotation around Z-axis
      angle = :math.pi() / 2.0
      axis = {0.0, 0.0, 1.0}
      quat = Quaternion.from_axis_angle(axis, angle)
      rotation = Matrix4.rotation(quat)

      # Transform X-axis vector, should become Y-axis
      x_vector = {1.0, 0.0, 0.0}
      result = Matrix4.transform_direction(rotation, x_vector)
      {rx, ry, rz} = result

      assert_in_delta(rx, 0.0, 1.0e-10)
      assert_in_delta(ry, 1.0, 1.0e-10)
      assert_in_delta(rz, 0.0, 1.0e-10)
    end
  end

  describe "Matrix4.compose/3 and Matrix4.decompose/1" do
    test "round-trip compose and decompose preserves TRS" do
      translation = {1.0, 2.0, 3.0}
      rotation = Quaternion.from_axis_angle({0.0, 0.0, 1.0}, :math.pi() / 4.0)
      scale = {2.0, 3.0, 4.0}

      matrix = Matrix4.compose(translation, rotation, scale)
      {recovered_translation, recovered_rotation, recovered_scale} = Matrix4.decompose(matrix)

      # Check translation
      {tx, ty, tz} = recovered_translation
      assert_in_delta(tx, 1.0, 1.0e-10)
      assert_in_delta(ty, 2.0, 1.0e-10)
      assert_in_delta(tz, 3.0, 1.0e-10)

      # Check scale
      {sx, sy, sz} = recovered_scale
      assert_in_delta(sx, 2.0, 1.0e-10)
      assert_in_delta(sy, 3.0, 1.0e-10)
      assert_in_delta(sz, 4.0, 1.0e-10)

      # Check rotation (approximately, since decomposition may have numerical differences)
      {_rx, _ry, _rz, _rw} = recovered_rotation
      {_ox, _oy, _oz, _ow} = rotation
      # Compare magnitudes since quaternions q and -q represent same rotation
      rotation_dot = Quaternion.dot(recovered_rotation, rotation)
      assert(abs(rotation_dot) > 0.999)  # Should be very close to ±1
    end
  end

  describe "Matrix4.transform_point/2 and Matrix4.transform_direction/2" do
    test "transform_point applies full transformation" do
      matrix = Matrix4.translation({5.0, 10.0, 15.0})
      point = {1.0, 2.0, 3.0}
      result = Matrix4.transform_point(matrix, point)
      assert result == {6.0, 12.0, 18.0}
    end

    test "transform_direction ignores translation" do
      matrix = Matrix4.translation({5.0, 10.0, 15.0})
      direction = {1.0, 2.0, 3.0}
      result = Matrix4.transform_direction(matrix, direction)
      assert result == {1.0, 2.0, 3.0}  # Should be unchanged
    end

    test "transform_direction applies rotation and scale" do
      # Create a scaling matrix
      matrix = Matrix4.scaling({2.0, 3.0, 4.0})
      direction = {1.0, 1.0, 1.0}
      result = Matrix4.transform_direction(matrix, direction)
      assert result == {2.0, 3.0, 4.0}
    end
  end

  describe "Matrix4.get_translation/1" do
    test "extracts translation from transformation matrix" do
      translation_vec = {10.0, 20.0, 30.0}
      matrix = Matrix4.translation(translation_vec)
      result = Matrix4.get_translation(matrix)
      assert result == translation_vec
    end

    test "extracts translation from identity matrix" do
      result = Matrix4.get_translation(Matrix4.identity())
      assert result == {0.0, 0.0, 0.0}
    end
  end

  describe "constants" do
    test "identity matrix" do
      identity = Matrix4.identity()
      expected = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      assert identity == expected
    end

    test "zero matrix" do
      zero = Matrix4.zero()
      expected = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
      assert zero == expected
    end
  end
end
