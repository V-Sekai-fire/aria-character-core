# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaJoint do
  @moduledoc """
  Transform hierarchy management for EWBIK bone chains.

  AriaJoint provides efficient transform hierarchy management with parent-child
  relationships, dirty state tracking, and coordinate space conversions. This is
  a port of the IKNode3D class from the many_bone_ik project.

  ## Features

  - Local and global transform caching with dirty state optimization
  - Parent-child bone hierarchy management
  - Coordinate space conversions (local ↔ global)
  - Transform propagation throughout hierarchy
  - Scale management (can disable scale for pure rotational joints)
  - Efficient updates only when transforms are dirty

  ## Usage

      # Create root bone
      {:ok, root} = AriaJoint.new()

      # Create child bone with parent relationship
      {:ok, child} = AriaJoint.new(parent: root)

      # Set local transform
      child = AriaJoint.set_transform(child, transform)

      # Get global transform (automatically computed from hierarchy)
      global_transform = AriaJoint.get_global_transform(child)

  ## Transform Hierarchy

  Each Joint maintains:
  - **Local Transform**: Transform relative to parent bone
  - **Global Transform**: Absolute transform in world space (computed from hierarchy)
  - **Dirty State**: Tracks what needs recomputation for efficiency

  When a bone's transform changes, dirty flags propagate to children automatically.

  ## Coordinate Space Conversions

      # Convert point from world space to local bone space
      local_point = AriaJoint.to_local(bone, world_point)

      # Convert point from local bone space to world space
      world_point = AriaJoint.to_global(bone, local_point)
  """

  alias AriaJoint.{Joint}

  @doc """
  Create a new Joint with optional parent relationship.

  ## Options

  - `:parent` - Parent Joint to attach to (creates parent-child relationship)
  - `:disable_scale` - Whether to disable scale propagation (default: false)

  ## Examples

      # Create root node
      {:ok, root} = AriaJoint.new()

      # Create child node
      {:ok, child} = AriaJoint.new(parent: root)

      # Create node with scale disabled
      {:ok, joint} = AriaJoint.new(disable_scale: true)

  ## Returns

  `{:ok, node}` on success, `{:error, reason}` on failure.
  """
  defdelegate new(opts \\ []), to: Joint

  @doc """
  Set the local transform of a node.

  Updates the local transform and marks appropriate dirty states for efficient
  recomputation of global transforms.

  ## Examples

      transform = AriaMath.Matrix4.translation({0.5, 1.0, 0.0})
      node = AriaJoint.set_transform(node, transform)
  """
  defdelegate set_transform(node, transform), to: Joint

  @doc """
  Set the global transform of a node.

  Automatically computes the appropriate local transform based on parent hierarchy.

  ## Examples

      global_transform = AriaMath.Matrix4.translation({1.0, 2.0, 3.0})
      node = AriaJoint.set_global_transform(node, global_transform)
  """
  defdelegate set_global_transform(node, global_transform), to: Joint

  @doc """
  Get the local transform of a node.

  Updates local transform from rotation and scale if dirty.

  ## Examples

      local_transform = AriaJoint.get_transform(node)
  """
  defdelegate get_transform(node), to: Joint

  @doc """
  Get the global transform of a node.

  Computes global transform from hierarchy if dirty, with efficient caching.

  ## Examples

      global_transform = AriaJoint.get_global_transform(node)
  """
  defdelegate get_global_transform(node), to: Joint

  @doc """
  Set parent-child relationship between nodes.

  Automatically manages bidirectional parent-child relationships and propagates
  transform changes.

  ## Examples

      child = AriaJoint.set_parent(child, parent)
  """
  defdelegate set_parent(node, parent), to: Joint

  @doc """
  Get the parent node of a node.

  ## Examples

      parent = AriaJoint.get_parent(node)

  Returns `nil` if node has no parent.
  """
  defdelegate get_parent(node), to: Joint

  @doc """
  Convert a point from global space to local node space.

  ## Examples

      global_point = {1.0, 2.0, 3.0}
      local_point = AriaJoint.to_local(node, global_point)
  """
  defdelegate to_local(node, global_point), to: Joint

  @doc """
  Convert a point from local node space to global space.

  ## Examples

      local_point = {0.5, 0.0, 0.0}
      global_point = AriaJoint.to_global(node, local_point)
  """
  defdelegate to_global(node, local_point), to: Joint

  @doc """
  Rotate node locally using global basis.

  ## Parameters

  - `node` - The node to rotate
  - `basis` - Global rotation basis to apply
  - `propagate` - Whether to propagate changes to children (default: false)

  ## Examples

      rotation_basis = AriaMath.Matrix4.rotation_y(Math.pi / 4)
      node = AriaJoint.rotate_local_with_global(node, rotation_basis, true)
  """
  defdelegate rotate_local_with_global(node, basis, propagate \\ false), to: Joint

  @doc """
  Enable or disable scale propagation for this node.

  When scale is disabled, the node will orthogonalize its global transform
  to remove scaling effects.

  ## Examples

      node = AriaJoint.set_disable_scale(node, true)
  """
  defdelegate set_disable_scale(node, disable_scale), to: Joint

  @doc """
  Check if scale is disabled for this node.

  ## Examples

      is_disabled = AriaJoint.is_scale_disabled(node)
  """
  defdelegate is_scale_disabled(node), to: Joint

  @doc """
  Clean up node and remove from hierarchy.

  Removes all parent-child relationships and cleans up registry entries.

  ## Examples

      AriaJoint.cleanup(node)
  """
  defdelegate cleanup(node), to: Joint
end
