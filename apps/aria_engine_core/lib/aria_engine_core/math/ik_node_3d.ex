defmodule AriaEngineCore.Math.IKNode3D do
  @moduledoc """
  Transform hierarchy management for EWBIK bone chains.

  IKNode3D provides efficient transform hierarchy management with parent-child
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
      {:ok, root} = IKNode3D.new()

      # Create child bone with parent relationship
      {:ok, child} = IKNode3D.new(parent: root)

      # Set local transform
      child = IKNode3D.set_transform(child, transform)

      # Get global transform (automatically computed from hierarchy)
      global_transform = IKNode3D.get_global_transform(child)

  ## Transform Hierarchy

  Each IKNode3D maintains:
  - **Local Transform**: Transform relative to parent bone
  - **Global Transform**: Absolute transform in world space (computed from hierarchy)
  - **Dirty State**: Tracks what needs recomputation for efficiency

  When a bone's transform changes, dirty flags propagate to children automatically.

  ## Coordinate Space Conversions

      # Convert point from world space to local bone space
      local_point = IKNode3D.to_local(bone, world_point)

      # Convert point from local bone space to world space
      world_point = IKNode3D.to_global(bone, local_point)

  ## Citations

  Port of IKNode3D from many_bone_ik project:
  - Original C++ implementation for Godot Engine transform hierarchy
  - Optimized dirty state tracking for real-time performance
  - Parent-child relationship management for complex bone chains
  """

  alias AriaEngineCore.Math.{Vector3, Quaternion, Matrix4}

  @type transform() :: Matrix4.t()
  @type basis() :: Matrix4.t()
  @type node_id() :: reference()

  @type dirty_state() ::
    :dirty_none |
    :dirty_vectors |
    :dirty_local |
    :dirty_global |
    [:dirty_vectors | :dirty_local | :dirty_global]

  @type t() :: %__MODULE__{
    id: node_id(),
    global_transform: transform(),
    local_transform: transform(),
    rotation: basis(),
    scale: Vector3.t(),
    dirty: dirty_state(),
    parent: node_id() | nil,
    children: [node_id()],
    disable_scale: boolean()
  }

  defstruct [
    :id,
    global_transform: Matrix4.identity(),
    local_transform: Matrix4.identity(),
    rotation: Matrix4.identity(),
    scale: {1.0, 1.0, 1.0},
    dirty: :dirty_none,
    parent: nil,
    children: [],
    disable_scale: false
  ]

  # Global registry for node hierarchy management
  @registry_name :ik_node_3d_registry

  # Dirty state constants
  @dirty_none :dirty_none
  @dirty_vectors :dirty_vectors
  @dirty_local :dirty_local
  @dirty_global :dirty_global

  @doc """
  Create a new IKNode3D with optional parent relationship.

  ## Options

  - `:parent` - Parent IKNode3D to attach to (creates parent-child relationship)
  - `:disable_scale` - Whether to disable scale propagation (default: false)

  ## Examples

      # Create root node
      {:ok, root} = IKNode3D.new()

      # Create child node
      {:ok, child} = IKNode3D.new(parent: root)

      # Create node with scale disabled
      {:ok, joint} = IKNode3D.new(disable_scale: true)

  ## Returns

  `{:ok, node}` on success, `{:error, reason}` on failure.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, term()}
  def new(opts \\ []) do
    with {:ok, _pid} <- ensure_registry() do
      node = %__MODULE__{
        id: make_ref(),
        disable_scale: Keyword.get(opts, :disable_scale, false)
      }

      # Register the node
      Registry.register(@registry_name, node.id, node)

      # Set parent if provided
      case Keyword.get(opts, :parent) do
        nil -> {:ok, node}
        parent_node -> set_parent(node, parent_node)
      end
    end
  end

  @doc """
  Set the local transform of a node.

  Updates the local transform and marks appropriate dirty states for efficient
  recomputation of global transforms.

  ## Examples

      transform = Matrix4.translation({0.5, 1.0, 0.0})
      node = IKNode3D.set_transform(node, transform)

  """
  @spec set_transform(t(), transform()) :: t()
  def set_transform(node, transform) do
    if Matrix4.equal?(node.local_transform, transform) do
      node
    else
      updated_node = %{node |
        local_transform: transform,
        dirty: add_dirty_flag(node.dirty, @dirty_vectors)
      }

      # Update registry and propagate changes
      update_registry(updated_node)
      propagate_transform_changed(updated_node)
      updated_node
    end
  end

  @doc """
  Set the global transform of a node.

  Automatically computes the appropriate local transform based on parent hierarchy.

  ## Examples

      global_transform = Matrix4.translation({1.0, 2.0, 3.0})
      node = IKNode3D.set_global_transform(node, global_transform)

  """
  @spec set_global_transform(t(), transform()) :: t()
  def set_global_transform(node, global_transform) do
    local_transform = case get_parent_node(node) do
      nil ->
        global_transform

      parent_node ->
        parent_global = get_global_transform(parent_node)
        parent_inverse = Matrix4.inverse(parent_global)
        Matrix4.multiply(parent_inverse, global_transform)
    end

    updated_node = %{node |
      local_transform: local_transform,
      dirty: add_dirty_flag(node.dirty, @dirty_vectors)
    }

    update_registry(updated_node)
    propagate_transform_changed(updated_node)
    updated_node
  end

  @doc """
  Get the local transform of a node.

  Updates local transform from rotation and scale if dirty.

  ## Examples

      local_transform = IKNode3D.get_transform(node)

  """
  @spec get_transform(t()) :: transform()
  def get_transform(node) do
    node = if has_dirty_flag?(node.dirty, @dirty_local) do
      update_local_transform(node)
    else
      node
    end

    node.local_transform
  end

  @doc """
  Get the global transform of a node.

  Computes global transform from hierarchy if dirty, with efficient caching.

  ## Examples

      global_transform = IKNode3D.get_global_transform(node)

  """
  @spec get_global_transform(t()) :: transform()
  def get_global_transform(node) do
    node = if has_dirty_flag?(node.dirty, @dirty_global) do
      node = if has_dirty_flag?(node.dirty, @dirty_local) do
        update_local_transform(node)
      else
        node
      end

      global_transform = case get_parent_node(node) do
        nil ->
          node.local_transform

        parent_node ->
          parent_global = get_global_transform(parent_node)
          Matrix4.multiply(parent_global, node.local_transform)
      end

      global_transform = if node.disable_scale do
        Matrix4.orthogonalize(global_transform)
      else
        global_transform
      end

      updated_node = %{node |
        global_transform: global_transform,
        dirty: remove_dirty_flag(node.dirty, @dirty_global)
      }

      update_registry(updated_node)
      updated_node.global_transform
    else
      node.global_transform
    end
  end

  @doc """
  Set parent-child relationship between nodes.

  Automatically manages bidirectional parent-child relationships and propagates
  transform changes.

  ## Examples

      child = IKNode3D.set_parent(child, parent)

  """
  @spec set_parent(t(), t() | nil) :: t()
  def set_parent(node, nil) do
    # Remove from current parent if exists
    case get_parent_node(node) do
      nil -> node
      current_parent ->
        updated_parent = %{current_parent |
          children: List.delete(current_parent.children, node.id)
        }
        update_registry(updated_parent)
    end

    updated_node = %{node | parent: nil}
    update_registry(updated_node)
    propagate_transform_changed(updated_node)
    updated_node
  end

  def set_parent(node, parent_node) do
    # Remove from current parent if exists
    node = set_parent(node, nil)

    # Add to new parent
    updated_parent = %{parent_node |
      children: [node.id | parent_node.children]
    }
    update_registry(updated_parent)

    updated_node = %{node | parent: parent_node.id}
    update_registry(updated_node)
    propagate_transform_changed(updated_node)
    updated_node
  end

  @doc """
  Get the parent node of a node.

  ## Examples

      parent = IKNode3D.get_parent(node)

  Returns `nil` if node has no parent.
  """
  @spec get_parent(t()) :: t() | nil
  def get_parent(node) do
    get_parent_node(node)
  end

  @doc """
  Convert a point from global space to local node space.

  ## Examples

      global_point = {1.0, 2.0, 3.0}
      local_point = IKNode3D.to_local(node, global_point)

  """
  @spec to_local(t(), Vector3.t()) :: Vector3.t()
  def to_local(node, global_point) do
    global_transform = get_global_transform(node)
    inverse_transform = Matrix4.inverse(global_transform)
    Matrix4.transform_point(inverse_transform, global_point)
  end

  @doc """
  Convert a point from local node space to global space.

  ## Examples

      local_point = {0.5, 0.0, 0.0}
      global_point = IKNode3D.to_global(node, local_point)

  """
  @spec to_global(t(), Vector3.t()) :: Vector3.t()
  def to_global(node, local_point) do
    global_transform = get_global_transform(node)
    Matrix4.transform_point(global_transform, local_point)
  end

  @doc """
  Rotate node locally using global basis.

  ## Parameters

  - `node` - The node to rotate
  - `basis` - Global rotation basis to apply
  - `propagate` - Whether to propagate changes to children (default: false)

  ## Examples

      rotation_basis = Matrix4.rotation_y(Math.pi / 4)
      node = IKNode3D.rotate_local_with_global(node, rotation_basis, true)

  """
  @spec rotate_local_with_global(t(), basis(), boolean()) :: t()
  def rotate_local_with_global(node, basis, propagate \\ false) do
    case get_parent_node(node) do
      nil -> node

      parent_node ->
        parent_global = get_global_transform(parent_node)
        parent_basis = Matrix4.extract_basis(parent_global)
        parent_inverse = Matrix4.transpose(parent_basis)

        # new_rot = parent_inverse * basis * parent_basis * local_basis
        local_basis = Matrix4.extract_basis(node.local_transform)
        new_local_basis = parent_inverse
                         |> Matrix4.multiply(basis)
                         |> Matrix4.multiply(parent_basis)
                         |> Matrix4.multiply(local_basis)

        # Update local transform with new basis
        {translation, _rotation, scale} = Matrix4.decompose(node.local_transform)
        new_local_transform = Matrix4.compose(translation, new_local_basis, scale)

        updated_node = %{node |
          local_transform: new_local_transform,
          dirty: add_dirty_flag(node.dirty, @dirty_global)
        }

        update_registry(updated_node)

        if propagate do
          propagate_transform_changed(updated_node)
        end

        updated_node
    end
  end

  @doc """
  Enable or disable scale propagation for this node.

  When scale is disabled, the node will orthogonalize its global transform
  to remove scaling effects.

  ## Examples

      node = IKNode3D.set_disable_scale(node, true)

  """
  @spec set_disable_scale(t(), boolean()) :: t()
  def set_disable_scale(node, disable_scale) do
    updated_node = %{node | disable_scale: disable_scale}
    update_registry(updated_node)
    updated_node
  end

  @doc """
  Check if scale is disabled for this node.

  ## Examples

      is_disabled = IKNode3D.is_scale_disabled(node)

  """
  @spec is_scale_disabled(t()) :: boolean()
  def is_scale_disabled(node) do
    node.disable_scale
  end

  @doc """
  Clean up node and remove from hierarchy.

  Removes all parent-child relationships and cleans up registry entries.

  ## Examples

      IKNode3D.cleanup(node)

  """
  @spec cleanup(t()) :: :ok
  def cleanup(node) do
    # Remove from parent
    set_parent(node, nil)

    # Remove all children
    for child_id <- node.children do
      case Registry.lookup(@registry_name, child_id) do
        [{_pid, child_node}] ->
          set_parent(child_node, nil)
        [] ->
          :ok
      end
    end

    # Unregister from registry
    Registry.unregister(@registry_name, node.id)
    :ok
  end

  # Private helper functions

  @spec ensure_registry() :: {:ok, pid()} | {:error, term()}
  defp ensure_registry do
    case Registry.start_link(keys: :unique, name: @registry_name) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> error
    end
  end

  @spec update_registry(t()) :: :ok
  defp update_registry(node) do
    Registry.update_value(@registry_name, node.id, fn _old_node -> node end)
    :ok
  end

  @spec get_node_by_id(node_id()) :: t() | nil
  defp get_node_by_id(node_id) do
    case Registry.lookup(@registry_name, node_id) do
      [{_pid, node}] -> node
      [] -> nil
    end
  end

  @spec get_parent_node(t()) :: t() | nil
  defp get_parent_node(node) do
    case node.parent do
      nil -> nil
      parent_id -> get_node_by_id(parent_id)
    end
  end

  @spec propagate_transform_changed(t()) :: :ok
  defp propagate_transform_changed(node) do
    # Remove any null references and propagate to valid children
    valid_children = for child_id <- node.children do
      case get_node_by_id(child_id) do
        nil -> nil
        child_node ->
          propagate_transform_changed(child_node)
          child_id
      end
    end |> Enum.reject(&is_nil/1)

    # Update node with cleaned children list
    if length(valid_children) != length(node.children) do
      updated_node = %{node | children: valid_children}
      update_registry(updated_node)
    end

    # Mark this node as globally dirty
    updated_node = %{node | dirty: add_dirty_flag(node.dirty, @dirty_global)}
    update_registry(updated_node)
    :ok
  end

  @spec update_local_transform(t()) :: t()
  defp update_local_transform(node) do
    # local_transform.basis = rotation.scaled(scale)
    rotation_matrix = node.rotation
    {sx, sy, sz} = node.scale
    scale_matrix = Matrix4.scale({sx, sy, sz})
    new_basis = Matrix4.multiply(rotation_matrix, scale_matrix)

    {translation, _old_rotation, _old_scale} = Matrix4.decompose(node.local_transform)
    new_local_transform = Matrix4.compose(translation, new_basis, {sx, sy, sz})

    updated_node = %{node |
      local_transform: new_local_transform,
      dirty: remove_dirty_flag(node.dirty, @dirty_local)
    }

    update_registry(updated_node)
    updated_node
  end

  # Dirty state flag management

  @spec add_dirty_flag(dirty_state(), atom()) :: dirty_state()
  defp add_dirty_flag(@dirty_none, flag), do: flag
  defp add_dirty_flag(current_flags, flag) when is_list(current_flags) do
    if flag in current_flags do
      current_flags
    else
      [flag | current_flags]
    end
  end
  defp add_dirty_flag(current_flag, flag) when is_atom(current_flag) do
    if current_flag == flag do
      current_flag
    else
      [flag, current_flag]
    end
  end

  @spec remove_dirty_flag(dirty_state(), atom()) :: dirty_state()
  defp remove_dirty_flag(@dirty_none, _flag), do: @dirty_none
  defp remove_dirty_flag(current_flags, flag) when is_list(current_flags) do
    remaining = List.delete(current_flags, flag)
    case remaining do
      [] -> @dirty_none
      [single_flag] -> single_flag
      multiple -> multiple
    end
  end
  defp remove_dirty_flag(current_flag, flag) when is_atom(current_flag) do
    if current_flag == flag do
      @dirty_none
    else
      current_flag
    end
  end

  @spec has_dirty_flag?(dirty_state(), atom()) :: boolean()
  defp has_dirty_flag?(@dirty_none, _flag), do: false
  defp has_dirty_flag?(current_flags, flag) when is_list(current_flags) do
    flag in current_flags
  end
  defp has_dirty_flag?(current_flag, flag) when is_atom(current_flag) do
    current_flag == flag
  end
end
