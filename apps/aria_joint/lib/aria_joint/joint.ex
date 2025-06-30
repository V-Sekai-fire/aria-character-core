# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaJoint.Joint do
  @moduledoc """
  Transform hierarchy management for EWBIK bone chains.

  Joint provides efficient transform hierarchy management with parent-child
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
      {:ok, root} = Joint.new()

      # Create child bone with parent relationship
      {:ok, child} = Joint.new(parent: root)

      # Set local transform
      child = Joint.set_transform(child, transform)

      # Get global transform (automatically computed from hierarchy)
      global_transform = Joint.get_global_transform(child)

  ## Transform Hierarchy

  Each Joint maintains:
  - **Local Transform**: Transform relative to parent bone
  - **Global Transform**: Absolute transform in world space (computed from hierarchy)
  - **Dirty State**: Tracks what needs recomputation for efficiency

  When a bone's transform changes, dirty flags propagate to children automatically.

  ## Coordinate Space Conversions

      # Convert point from world space to local bone space
      local_point = Joint.to_local(bone, world_point)

      # Convert point from local bone space to world space
      world_point = Joint.to_global(bone, local_point)

  ## Citations

  Port of IKNode3D from many_bone_ik project:
  - Original C++ implementation for Godot Engine transform hierarchy
  - Optimized dirty state tracking for real-time performance
  - Parent-child relationship management for complex bone chains
  """

  alias AriaMath.{Vector3, Quaternion, Matrix4}

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
  @registry_name :joint_registry

  # Robustness constants
  @max_hierarchy_depth 100
  @max_children_per_node 1000
  @transform_validation_tolerance 1.0e-6
  @registry_timeout 5000

  # Dirty state constants
  @dirty_none :dirty_none
  @dirty_vectors :dirty_vectors
  @dirty_local :dirty_local
  @dirty_global :dirty_global

  @type joint_error ::
    :registry_unavailable |
    :node_not_found |
    :circular_dependency |
    :hierarchy_too_deep |
    :too_many_children |
    :invalid_transform |
    :registry_timeout |
    :memory_limit_exceeded

  @doc """
  Create a new Joint with optional parent relationship.

  ## Options

  - `:parent` - Parent Joint to attach to (creates parent-child relationship)
  - `:disable_scale` - Whether to disable scale propagation (default: false)

  ## Examples

      # Create root node
      {:ok, root} = Joint.new()

      # Create child node
      {:ok, child} = Joint.new(parent: root)

      # Create node with scale disabled
      {:ok, joint} = Joint.new(disable_scale: true)

  ## Returns

  `{:ok, node}` on success, `{:error, reason}` on failure.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, joint_error() | term()}
  def new(opts \\ []) do
    try do
      with {:ok, _pid} <- ensure_registry_with_timeout(),
           {:ok, validated_opts} <- validate_creation_options(opts),
           {:ok, node} <- create_and_register_node(validated_opts) do
        {:ok, node}
      end
    rescue
      error -> {:error, {:joint_creation_failed, error}}
    end
  end

  @spec validate_creation_options(keyword()) :: {:ok, keyword()} | {:error, joint_error()}
  defp validate_creation_options(opts) do
    case Keyword.get(opts, :parent) do
      nil ->
        {:ok, opts}

      parent_node ->
        with :ok <- validate_node_struct(parent_node),
             :ok <- validate_hierarchy_constraints(parent_node) do
          {:ok, opts}
        end
    end
  end

  @spec validate_node_struct(t()) :: :ok | {:error, joint_error()}
  defp validate_node_struct(%__MODULE__{} = node) do
    cond do
      not is_reference(node.id) ->
        {:error, :invalid_transform}

      not is_valid_transform?(node.local_transform) ->
        {:error, :invalid_transform}

      not is_valid_transform?(node.global_transform) ->
        {:error, :invalid_transform}

      true ->
        :ok
    end
  end
  defp validate_node_struct(_), do: {:error, :invalid_transform}

  @spec validate_hierarchy_constraints(t()) :: :ok | {:error, joint_error()}
  defp validate_hierarchy_constraints(parent_node) do
    cond do
      calculate_hierarchy_depth(parent_node) >= @max_hierarchy_depth ->
        {:error, :hierarchy_too_deep}

      length(parent_node.children) >= @max_children_per_node ->
        {:error, :too_many_children}

      true ->
        :ok
    end
  end

  @spec create_and_register_node(keyword()) :: {:ok, t()} | {:error, joint_error()}
  defp create_and_register_node(opts) do
    node = %__MODULE__{
      id: make_ref(),
      disable_scale: Keyword.get(opts, :disable_scale, false)
    }

    case safe_registry_register(node) do
      {:ok, _pid} ->
        case Keyword.get(opts, :parent) do
          nil -> {:ok, node}
          parent_node -> safe_set_parent(node, parent_node)
        end

      {:error, reason} -> {:error, reason}
    end
  end

  @spec safe_registry_register(t()) :: {:ok, pid()} | {:error, joint_error()}
  defp safe_registry_register(node) do
    case Registry.register(@registry_name, node.id, node) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_registered, _pid}} -> {:error, :node_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec safe_set_parent(t(), t()) :: {:ok, t()} | {:error, joint_error()}
  defp safe_set_parent(node, parent_node) do
    case set_parent_with_validation(node, parent_node) do
      %__MODULE__{} = updated_node -> {:ok, updated_node}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Set the local transform of a node.

  Updates the local transform and marks appropriate dirty states for efficient
  recomputation of global transforms.

  ## Examples

      transform = Matrix4.translation({0.5, 1.0, 0.0})
      node = Joint.set_transform(node, transform)

  """
  @spec set_transform(t(), transform()) :: t() | {:error, joint_error()}
  def set_transform(node, transform) do
    with :ok <- validate_node_struct(node),
         :ok <- validate_transform_input(transform) do
      if Matrix4.equal?(node.local_transform, transform) do
        node
      else
        updated_node = %{node |
          local_transform: transform,
          dirty: add_dirty_flag(node.dirty, @dirty_vectors)
        }

        case safe_update_registry(updated_node) do
          :ok ->
            safe_propagate_transform_changed(updated_node)
            updated_node

          {:error, reason} ->
            {:error, reason}
        end
      end
    end
  end

  @spec validate_transform_input(transform()) :: :ok | {:error, joint_error()}
  defp validate_transform_input(transform) do
    if is_valid_transform?(transform) do
      :ok
    else
      {:error, :invalid_transform}
    end
  end

  @spec is_valid_transform?(transform()) :: boolean()
  defp is_valid_transform?(transform) when is_tuple(transform) and tuple_size(transform) == 16 do
    transform
    |> Tuple.to_list()
    |> Enum.all?(fn element ->
      is_number(element) and
      element != :nan and
      element != :infinity and
      element != :neg_infinity and
      abs(element) < 1.0e12
    end)
  end
  defp is_valid_transform?(_), do: false

  @doc """
  Set the global transform of a node.

  Automatically computes the appropriate local transform based on parent hierarchy.

  ## Examples

      global_transform = Matrix4.translation({1.0, 2.0, 3.0})
      node = Joint.set_global_transform(node, global_transform)

  """
  @spec set_global_transform(t(), transform()) :: t()
  def set_global_transform(node, global_transform) do
    local_transform = case get_parent_node(node) do
      nil ->
        global_transform

      parent_node ->
        parent_global = get_global_transform(parent_node)
        {parent_inverse, _valid} = Matrix4.inverse(parent_global)
        Matrix4.multiply(parent_inverse, global_transform)
    end

        updated_node = %{node |
          local_transform: local_transform,
          dirty: add_dirty_flag(node.dirty, @dirty_vectors)
        }

        safe_update_registry(updated_node)
        safe_propagate_transform_changed(updated_node)
        updated_node
  end

  @doc """
  Get the local transform of a node.

  Updates local transform from rotation and scale if dirty.

  ## Examples

      local_transform = Joint.get_transform(node)

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

      global_transform = Joint.get_global_transform(node)

  """
  @spec get_global_transform(t()) :: transform()
  def get_global_transform(node) do
    if has_dirty_flag?(node.dirty, @dirty_global) do
      updated_node = if has_dirty_flag?(node.dirty, @dirty_local) do
        update_local_transform(node)
      else
        node
      end

      global_transform = case get_parent_node(updated_node) do
        nil ->
          updated_node.local_transform

        parent_node ->
          parent_global = get_global_transform(parent_node)
          Matrix4.multiply(parent_global, updated_node.local_transform)
      end

      global_transform = if updated_node.disable_scale do
        Matrix4.orthogonalize(global_transform)
      else
        global_transform
      end

      final_node = %{updated_node |
        global_transform: global_transform,
        dirty: remove_dirty_flag(updated_node.dirty, @dirty_global)
      }

      safe_update_registry(final_node)
      final_node.global_transform
    else
      node.global_transform
    end
  end

  @doc """
  Set parent-child relationship between nodes.

  Automatically manages bidirectional parent-child relationships and propagates
  transform changes.

  ## Examples

      child = Joint.set_parent(child, parent)

  """
  @spec set_parent(t(), t() | nil) :: t() | {:error, joint_error()}
  def set_parent(node, nil) do
    with :ok <- validate_node_struct(node) do
      safe_remove_from_parent(node)
    end
  end

  def set_parent(node, parent_node) do
    set_parent_with_validation(node, parent_node)
  end

  @spec set_parent_with_validation(t(), t()) :: t() | {:error, joint_error()}
  defp set_parent_with_validation(node, parent_node) do
    with :ok <- validate_node_struct(node),
         :ok <- validate_node_struct(parent_node),
         :ok <- validate_no_circular_dependency(node, parent_node),
         :ok <- validate_hierarchy_constraints(parent_node) do

      # Remove from current parent if exists
      node_without_parent = case safe_remove_from_parent(node) do
        %__MODULE__{} = updated_node -> updated_node
        {:error, _reason} -> node  # Continue despite cleanup failure
      end

      # Add to new parent
      case safe_add_to_parent(node_without_parent, parent_node) do
        %__MODULE__{} = final_node -> final_node
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @spec validate_no_circular_dependency(t(), t()) :: :ok | {:error, joint_error()}
  defp validate_no_circular_dependency(child_node, potential_parent) do
    if would_create_cycle?(child_node, potential_parent) do
      {:error, :circular_dependency}
    else
      :ok
    end
  end

  @spec would_create_cycle?(t(), t()) :: boolean()
  defp would_create_cycle?(child_node, potential_parent, visited \\ MapSet.new()) do
    cond do
      child_node.id == potential_parent.id ->
        true

      MapSet.member?(visited, potential_parent.id) ->
        false  # Already visited, no cycle through this path

      true ->
        new_visited = MapSet.put(visited, potential_parent.id)
        case get_parent_node(potential_parent) do
          nil -> false
          ancestor -> would_create_cycle?(child_node, ancestor, new_visited)
        end
    end
  end

  @spec safe_remove_from_parent(t()) :: t() | {:error, joint_error()}
  defp safe_remove_from_parent(node) do
    case get_parent_node(node) do
      nil ->
        node

      current_parent ->
        updated_parent = %{current_parent |
          children: List.delete(current_parent.children, node.id)
        }

        case safe_update_registry(updated_parent) do
          :ok ->
            updated_node = %{node | parent: nil}
            case safe_update_registry(updated_node) do
              :ok ->
                safe_propagate_transform_changed(updated_node)
                updated_node
              {:error, reason} ->
                {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @spec safe_add_to_parent(t(), t()) :: t() | {:error, joint_error()}
  defp safe_add_to_parent(node, parent_node) do
    updated_parent = %{parent_node |
      children: [node.id | parent_node.children]
    }

    case safe_update_registry(updated_parent) do
      :ok ->
        updated_node = %{node | parent: parent_node.id}
        case safe_update_registry(updated_node) do
          :ok ->
            safe_propagate_transform_changed(updated_node)
            updated_node
          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get the parent node of a node.

  ## Examples

      parent = Joint.get_parent(node)

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
      local_point = Joint.to_local(node, global_point)

  """
  @spec to_local(t(), Vector3.t()) :: Vector3.t()
  def to_local(node, global_point) do
    global_transform = get_global_transform(node)
    {inverse_transform, _valid} = Matrix4.inverse(global_transform)
    Matrix4.transform_point(inverse_transform, global_point)
  end

  @doc """
  Convert a point from local node space to global space.

  ## Examples

      local_point = {0.5, 0.0, 0.0}
      global_point = Joint.to_global(node, local_point)

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
      node = Joint.rotate_local_with_global(node, rotation_basis, true)

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

        safe_update_registry(updated_node)

        if propagate do
          safe_propagate_transform_changed(updated_node)
        end

        updated_node
    end
  end

  @doc """
  Enable or disable scale propagation for this node.

  When scale is disabled, the node will orthogonalize its global transform
  to remove scaling effects.

  ## Examples

      node = Joint.set_disable_scale(node, true)

  """
  @spec set_disable_scale(t(), boolean()) :: t()
  def set_disable_scale(node, disable_scale) do
    updated_node = %{node | disable_scale: disable_scale}
    safe_update_registry(updated_node)
    updated_node
  end

  @doc """
  Check if scale is disabled for this node.

  ## Examples

      is_disabled = Joint.is_scale_disabled(node)

  """
  @spec is_scale_disabled(t()) :: boolean()
  def is_scale_disabled(node) do
    node.disable_scale
  end

  @doc """
  Clean up node and remove from hierarchy.

  Removes all parent-child relationships and cleans up registry entries.

  ## Examples

      Joint.cleanup(node)

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

  @spec ensure_registry_with_timeout() :: {:ok, pid()} | {:error, joint_error()}
  defp ensure_registry_with_timeout do
    try do
      case Process.whereis(@registry_name) do
        nil -> {:error, :registry_unavailable}
        pid when is_pid(pid) -> {:ok, pid}
      end
    rescue
      _error -> {:error, :registry_unavailable}
    end
  end

  @spec safe_update_registry(t()) :: :ok | {:error, joint_error()}
  defp safe_update_registry(node) do
    try do
      case Registry.lookup(@registry_name, node.id) do
        [{_pid, _old_node}] ->
          Registry.update_value(@registry_name, node.id, fn _old_node -> node end)
          :ok

        [] ->
          {:error, :node_not_found}
      end
    rescue
      _error -> {:error, :registry_unavailable}
    end
  end

  @spec calculate_hierarchy_depth(t(), non_neg_integer()) :: non_neg_integer()
  defp calculate_hierarchy_depth(node, current_depth \\ 0) do
    if current_depth >= @max_hierarchy_depth do
      @max_hierarchy_depth
    else
      case get_parent_node(node) do
        nil -> current_depth
        parent -> calculate_hierarchy_depth(parent, current_depth + 1)
      end
    end
  end

  @spec safe_propagate_transform_changed(t()) :: :ok
  defp safe_propagate_transform_changed(node) do
    try do
      propagate_transform_changed(node)
    rescue
      _error -> :ok  # Continue despite propagation failure
    end
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
          safe_propagate_transform_changed(child_node)
          child_id
      end
    end |> Enum.reject(&is_nil/1)

    # Update node with cleaned children list if needed
    if length(valid_children) != length(node.children) do
      updated_node = %{node | children: valid_children}
      safe_update_registry(updated_node)
    end

    # Mark this node as globally dirty
    updated_node = %{node | dirty: add_dirty_flag(node.dirty, @dirty_global)}
    safe_update_registry(updated_node)
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

    safe_update_registry(updated_node)
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
