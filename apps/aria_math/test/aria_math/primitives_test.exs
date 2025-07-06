# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.PrimitivesTest do
  use ExUnit.Case
  doctest AriaMath.Primitives

  alias AriaMath.{Primitives, Matrix4, Quaternion}

  describe "Primitives.box/1" do
    test "creates box with default size" do
      box = Primitives.box()

      assert is_map(box)
      assert Map.has_key?(box, :vertices)
      assert Map.has_key?(box, :indices)
      assert Map.has_key?(box, :normals)
      assert Map.has_key?(box, :uvs)

      # Should have 8 vertices for a box
      assert length(box.vertices) == 8
      # Should have 12 triangles (2 per face * 6 faces) = 36 indices
      assert length(box.indices) == 36
    end

    test "creates box with custom size" do
      size = {2.0, 3.0, 4.0}
      box = Primitives.box(size)

      vertices = box.vertices
      assert length(vertices) == 8

      # Check that vertices respect the size
      {min_x, max_x} = vertices |> Enum.map(fn {x, _y, _z} -> x end) |> Enum.min_max()
      {min_y, max_y} = vertices |> Enum.map(fn {_x, y, _z} -> y end) |> Enum.min_max()
      {min_z, max_z} = vertices |> Enum.map(fn {_x, _y, z} -> z end) |> Enum.min_max()

      assert_in_delta(max_x - min_x, 2.0, 1.0e-6)
      assert_in_delta(max_y - min_y, 3.0, 1.0e-6)
      assert_in_delta(max_z - min_z, 4.0, 1.0e-6)
    end

    test "creates box centered at origin" do
      box = Primitives.box()
      vertices = box.vertices

      # Calculate center
      {sum_x, sum_y, sum_z} =
        vertices
        |> Enum.reduce({0.0, 0.0, 0.0}, fn {x, y, z}, {sx, sy, sz} ->
          {sx + x, sy + y, sz + z}
        end)

      center_x = sum_x / length(vertices)
      center_y = sum_y / length(vertices)
      center_z = sum_z / length(vertices)

      assert_in_delta(center_x, 0.0, 1.0e-6)
      assert_in_delta(center_y, 0.0, 1.0e-6)
      assert_in_delta(center_z, 0.0, 1.0e-6)
    end
  end

  describe "Primitives.sphere/2" do
    test "creates sphere with default parameters" do
      sphere = Primitives.sphere()

      assert is_map(sphere)
      assert Map.has_key?(sphere, :vertices)
      assert Map.has_key?(sphere, :indices)
      assert Map.has_key?(sphere, :normals)
      assert Map.has_key?(sphere, :uvs)

      # Should have vertices (depends on subdivision)
      assert length(sphere.vertices) > 0
      assert length(sphere.indices) > 0
    end

    test "creates sphere with custom radius" do
      radius = 2.0
      sphere = Primitives.sphere(radius)

      vertices = sphere.vertices

      # All vertices should be approximately at distance 'radius' from origin
      for {x, y, z} <- vertices do
        distance = :math.sqrt(x * x + y * y + z * z)
        assert_in_delta(distance, radius, 1.0e-5)
      end
    end

    test "creates sphere with custom subdivisions" do
      radius = 1.0
      subdivisions = 3
      sphere = Primitives.sphere(radius, subdivisions)

      # Higher subdivisions should create more vertices
      assert length(sphere.vertices) > 12  # More than icosahedron base
    end

    test "sphere normals point outward" do
      sphere = Primitives.sphere()

      # For each vertex, the normal should point in the same direction as the position vector
      for {{x, y, z}, {nx, ny, nz}} <- Enum.zip(sphere.vertices, sphere.normals) do
        # Normalize position vector
        len = :math.sqrt(x * x + y * y + z * z)
        if len > 1.0e-10 do
          unit_x = x / len
          unit_y = y / len
          unit_z = z / len

          # Normal should be approximately equal to unit position vector
          assert_in_delta(nx, unit_x, 1.0e-5)
          assert_in_delta(ny, unit_y, 1.0e-5)
          assert_in_delta(nz, unit_z, 1.0e-5)
        end
      end
    end
  end

  describe "Primitives.cylinder/3" do
    test "creates cylinder with default parameters" do
      cylinder = Primitives.cylinder()

      assert is_map(cylinder)
      assert Map.has_key?(cylinder, :vertices)
      assert Map.has_key?(cylinder, :indices)
      assert Map.has_key?(cylinder, :normals)
      assert Map.has_key?(cylinder, :uvs)

      assert length(cylinder.vertices) > 0
      assert length(cylinder.indices) > 0
    end

    test "creates cylinder with custom dimensions" do
      radius = 2.0
      height = 4.0
      segments = 16
      cylinder = Primitives.cylinder(radius, height, segments)

      vertices = cylinder.vertices

      # Check that vertices are within expected bounds
      {min_y, max_y} = vertices |> Enum.map(fn {_x, y, _z} -> y end) |> Enum.min_max()
      assert_in_delta(max_y - min_y, height, 1.0e-5)

      # Check that radial distance is correct for side vertices
      for {x, _y, z} <- vertices do
        radial_distance = :math.sqrt(x * x + z * z)
        # Should be either 0 (center vertices) or approximately radius
        assert radial_distance <= radius + 1.0e-5
      end
    end

    test "cylinder has correct number of segments" do
      segments = 8
      cylinder = Primitives.cylinder(1.0, 2.0, segments)

      # Should have vertices for top circle, bottom circle, and side
      # Exact count depends on implementation, but should be related to segments
      assert length(cylinder.vertices) >= segments * 2
    end
  end

  describe "Primitives.plane/2" do
    test "creates plane with default size" do
      plane = Primitives.plane()

      assert is_map(plane)
      assert Map.has_key?(plane, :vertices)
      assert Map.has_key?(plane, :indices)
      assert Map.has_key?(plane, :normals)
      assert Map.has_key?(plane, :uvs)

      # Plane should have 4 vertices
      assert length(plane.vertices) == 4
      # Plane should have 2 triangles = 6 indices
      assert length(plane.indices) == 6
    end

    test "creates plane with custom size" do
      size = {4.0, 6.0}
      plane = Primitives.plane(size)

      vertices = plane.vertices

      {min_x, max_x} = vertices |> Enum.map(fn {x, _y, _z} -> x end) |> Enum.min_max()
      {min_z, max_z} = vertices |> Enum.map(fn {_x, _y, z} -> z end) |> Enum.min_max()

      assert_in_delta(max_x - min_x, 4.0, 1.0e-6)
      assert_in_delta(max_z - min_z, 6.0, 1.0e-6)
    end

    test "plane normals point upward" do
      plane = Primitives.plane()

      # All normals should point in +Y direction
      for {_nx, ny, _nz} <- plane.normals do
        assert_in_delta(ny, 1.0, 1.0e-6)
      end
    end

    test "plane lies on XZ plane" do
      plane = Primitives.plane()

      # All vertices should have Y = 0
      for {_x, y, _z} <- plane.vertices do
        assert_in_delta(y, 0.0, 1.0e-6)
      end
    end
  end

  describe "Primitives.triangle/1" do
    test "creates triangle with default vertices" do
      triangle = Primitives.triangle()

      assert is_map(triangle)
      assert Map.has_key?(triangle, :vertices)
      assert Map.has_key?(triangle, :indices)
      assert Map.has_key?(triangle, :normals)
      assert Map.has_key?(triangle, :uvs)

      # Triangle should have 3 vertices
      assert length(triangle.vertices) == 3
      # Triangle should have 1 triangle = 3 indices
      assert length(triangle.indices) == 3
    end

    test "creates triangle with custom vertices" do
      vertices = [
        {0.0, 0.0, 0.0},
        {2.0, 0.0, 0.0},
        {1.0, 2.0, 0.0}
      ]
      triangle = Primitives.triangle(vertices)

      assert triangle.vertices == vertices
      assert length(triangle.indices) == 3
    end

    test "triangle normal computed correctly" do
      vertices = [
        {0.0, 0.0, 0.0},
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0}
      ]
      triangle = Primitives.triangle(vertices)

      # Normal should point in +Z direction (right-hand rule)
      [normal] = Enum.uniq(triangle.normals)
      {nx, ny, nz} = normal

      assert_in_delta(nx, 0.0, 1.0e-6)
      assert_in_delta(ny, 0.0, 1.0e-6)
      assert_in_delta(nz, 1.0, 1.0e-6)
    end
  end

  describe "Primitives.transform/2" do
    test "applies transformation matrix to primitive" do
      box = Primitives.box({2.0, 2.0, 2.0})

      # Apply translation
      transform = Matrix4.translation({1.0, 2.0, 3.0})
      transformed_box = Primitives.transform(box, transform)

      # All vertices should be translated
      for {{orig_x, orig_y, orig_z}, {new_x, new_y, new_z}} <-
          Enum.zip(box.vertices, transformed_box.vertices) do
        assert_in_delta(new_x, orig_x + 1.0, 1.0e-6)
        assert_in_delta(new_y, orig_y + 2.0, 1.0e-6)
        assert_in_delta(new_z, orig_z + 3.0, 1.0e-6)
      end
    end

    test "applies rotation transformation" do
      triangle = Primitives.triangle([
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0},
        {0.0, 0.0, 0.0}
      ])

      # 90-degree rotation around Z-axis
      rotation = Matrix4.rotation(Quaternion.from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2.0))
      transformed_triangle = Primitives.transform(triangle, rotation)

      # First vertex (1,0,0) should become approximately (0,1,0)
      [{x1, y1, z1}, {_x2, _y2, _z2}, {_x3, _y3, _z3}] = transformed_triangle.vertices

      assert_in_delta(x1, 0.0, 1.0e-6)
      assert_in_delta(y1, 1.0, 1.0e-6)
      assert_in_delta(z1, 0.0, 1.0e-6)
    end

    test "transforms normals correctly" do
      box = Primitives.box()

      # Apply uniform scaling
      scale_transform = Matrix4.scaling({2.0, 2.0, 2.0})
      transformed_box = Primitives.transform(box, scale_transform)

      # Normals should remain unit length after transformation
      for {nx, ny, nz} <- transformed_box.normals do
        length = :math.sqrt(nx * nx + ny * ny + nz * nz)
        assert_in_delta(length, 1.0, 1.0e-5)
      end
    end
  end

  describe "Primitives.merge/2" do
    test "merges two primitives" do
      box = Primitives.box({1.0, 1.0, 1.0})
      sphere = Primitives.sphere(0.5)

      merged = Primitives.merge(box, sphere)

      # Should have combined vertices
      assert length(merged.vertices) == length(box.vertices) + length(sphere.vertices)

      # Should have combined indices (with offset for sphere)
      assert length(merged.indices) == length(box.indices) + length(sphere.indices)

      # Should have combined normals and UVs
      assert length(merged.normals) == length(box.normals) + length(sphere.normals)
      assert length(merged.uvs) == length(box.uvs) + length(sphere.uvs)
    end

    test "merge adjusts indices correctly" do
      triangle1 = Primitives.triangle([
        {0.0, 0.0, 0.0},
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0}
      ])

      triangle2 = Primitives.triangle([
        {2.0, 0.0, 0.0},
        {3.0, 0.0, 0.0},
        {2.0, 1.0, 0.0}
      ])

      merged = Primitives.merge(triangle1, triangle2)

      # Should have 6 vertices total
      assert length(merged.vertices) == 6

      # Should have 6 indices total (2 triangles)
      assert length(merged.indices) == 6

      # Second triangle indices should be offset by 3
      [i1, i2, i3, i4, i5, i6] = merged.indices
      assert [i1, i2, i3] == [0, 1, 2]
      assert [i4, i5, i6] == [3, 4, 5]
    end
  end
end
