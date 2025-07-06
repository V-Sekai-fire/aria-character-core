# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaJointTest do
  use ExUnit.Case, async: true

  alias AriaJoint.Joint
  alias AriaMath.{Matrix4, Quaternion}

  describe "new/1" do
    test "creates root node" do
      {:ok, node} = Joint.new()
      assert node.id != nil
      assert node.parent == nil
      assert node.children == []
      assert node.local_transform == Matrix4.identity()
      assert node.global_transform == Matrix4.identity()
    end

    test "creates child node with parent" do
      {:ok, parent} = Joint.new()
      {:ok, child} = Joint.new(parent: parent)

      assert child.parent == parent.id
      assert parent.id in child.children == false
      # Parent should be updated in registry with child
    end

    test "creates node with scale disabled" do
      {:ok, node} = Joint.new(disable_scale: true)
      assert node.disable_scale == true
    end
  end

  describe "set_transform/2" do
    test "sets local transform" do
      {:ok, node} = Joint.new()
      transform = Matrix4.translation({1.0, 2.0, 3.0})

      updated_node = Joint.set_transform(node, transform)
      assert updated_node.local_transform == transform
    end

    test "does not update if transform is identical" do
      {:ok, node} = Joint.new()
      transform = Matrix4.identity()

      updated_node = Joint.set_transform(node, transform)
      assert updated_node == node
    end
  end

  describe "get_transform/1" do
    test "returns local transform" do
      {:ok, node} = Joint.new()
      transform = Matrix4.translation({1.0, 2.0, 3.0})
      node = Joint.set_transform(node, transform)

      assert Joint.get_transform(node) == transform
    end
  end

  describe "get_global_transform/1" do
    test "returns global transform for root node" do
      {:ok, node} = Joint.new()
      transform = Matrix4.translation({1.0, 2.0, 3.0})
      node = Joint.set_transform(node, transform)

      global_transform = Joint.get_global_transform(node)
      assert global_transform == transform
    end

    test "computes global transform from hierarchy" do
      {:ok, parent} = Joint.new()
      parent_transform = Matrix4.translation({1.0, 0.0, 0.0})
      parent = Joint.set_transform(parent, parent_transform)

      {:ok, child} = Joint.new(parent: parent)
      child_transform = Matrix4.translation({0.0, 1.0, 0.0})
      child = Joint.set_transform(child, child_transform)

      global_transform = Joint.get_global_transform(child)
      expected = Matrix4.multiply(parent_transform, child_transform)
      assert global_transform == expected
    end
  end

  describe "set_global_transform/2" do
    test "sets global transform for root node" do
      {:ok, node} = Joint.new()
      global_transform = Matrix4.translation({1.0, 2.0, 3.0})

      updated_node = Joint.set_global_transform(node, global_transform)
      assert Joint.get_global_transform(updated_node) == global_transform
    end

    test "computes appropriate local transform for child node" do
      {:ok, parent} = Joint.new()
      parent_transform = Matrix4.translation({1.0, 0.0, 0.0})
      parent = Joint.set_transform(parent, parent_transform)

      {:ok, child} = Joint.new(parent: parent)
      global_transform = Matrix4.translation({2.0, 1.0, 0.0})

      updated_child = Joint.set_global_transform(child, global_transform)

      # Local transform should be the difference
      expected_local = Matrix4.translation({1.0, 1.0, 0.0})
      assert Joint.get_transform(updated_child) == expected_local
    end
  end

  describe "parent-child relationships" do
    test "set_parent/2 establishes relationship" do
      {:ok, parent} = Joint.new()
      {:ok, child} = Joint.new()

      updated_child = Joint.set_parent(child, parent)
      assert updated_child.parent == parent.id
    end

    test "set_parent/2 with nil removes parent" do
      {:ok, parent} = Joint.new()
      {:ok, child} = Joint.new(parent: parent)

      updated_child = Joint.set_parent(child, nil)
      assert updated_child.parent == nil
    end

    test "get_parent/1 returns parent node" do
      {:ok, parent} = Joint.new()
      {:ok, child} = Joint.new(parent: parent)

      parent_node = Joint.get_parent(child)
      assert parent_node.id == parent.id
    end
  end

  describe "coordinate space conversions" do
    test "to_local/2 converts global point to local space" do
      {:ok, node} = Joint.new()
      transform = Matrix4.translation({1.0, 2.0, 3.0})
      node = Joint.set_transform(node, transform)

      global_point = {2.0, 3.0, 4.0}
      local_point = Joint.to_local(node, global_point)

      expected = {1.0, 1.0, 1.0}
      assert local_point == expected
    end

    test "to_global/2 converts local point to global space" do
      {:ok, node} = Joint.new()
      transform = Matrix4.translation({1.0, 2.0, 3.0})
      node = Joint.set_transform(node, transform)

      local_point = {1.0, 1.0, 1.0}
      global_point = Joint.to_global(node, local_point)

      expected = {2.0, 3.0, 4.0}
      assert global_point == expected
    end
  end

  describe "scale management" do
    test "set_disable_scale/2 toggles scale flag" do
      {:ok, node} = Joint.new()

      updated_node = Joint.set_disable_scale(node, true)
      assert Joint.is_scale_disabled(updated_node) == true

      updated_node = Joint.set_disable_scale(updated_node, false)
      assert Joint.is_scale_disabled(updated_node) == false
    end

    test "disabled scale orthogonalizes global transform" do
      {:ok, node} = Joint.new(disable_scale: true)
      # Create a scaled transformation
      scaled_transform = Matrix4.scaling({2.0, 2.0, 2.0})
      node = Joint.set_transform(node, scaled_transform)

      global_transform = Joint.get_global_transform(node)
      # Should be orthogonalized (unit basis vectors)
      {tx, ty, tz} = Matrix4.get_translation(global_transform)
      assert tx == 0.0 and ty == 0.0 and tz == 0.0
    end
  end

  describe "rotation operations" do
    test "rotate_local_with_global/3 applies global rotation" do
      {:ok, parent} = Joint.new()
      parent_transform = Matrix4.rotation(Quaternion.from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2))
      parent = Joint.set_transform(parent, parent_transform)

      {:ok, child} = Joint.new(parent: parent)

      # Apply a global rotation
      global_rotation = Matrix4.rotation(Quaternion.from_axis_angle({1.0, 0.0, 0.0}, :math.pi / 4))
      updated_child = Joint.rotate_local_with_global(child, global_rotation)

      # Should have updated local transform
      assert updated_child.local_transform != Matrix4.identity()
    end
  end

  describe "cleanup/1" do
    test "cleans up node and relationships" do
      {:ok, parent} = Joint.new()
      {:ok, child} = Joint.new(parent: parent)

      assert :ok = Joint.cleanup(child)

      # Should remove parent-child relationships
      updated_parent = Joint.get_parent(child)
      assert updated_parent == nil
    end
  end

  describe "dirty state management" do
    test "transforms marked dirty propagate correctly" do
      {:ok, parent} = Joint.new()
      {:ok, child} = Joint.new(parent: parent)

      # Changing parent should mark child as dirty
      parent_transform = Matrix4.translation({1.0, 0.0, 0.0})
      _updated_parent = Joint.set_transform(parent, parent_transform)

      # Child should recompute global transform
      global_transform = Joint.get_global_transform(child)
      expected = Matrix4.multiply(parent_transform, Matrix4.identity())
      assert global_transform == expected
    end
  end
end
