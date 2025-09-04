defmodule AriaViewerWeb.IKChannel do
  use Phoenix.Channel

  alias AriaJoint.HierarchyManager
  alias AriaGltf
  alias AriaEwbik

  def join("ik:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("ik:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("update_target", %{"endEffector" => end_effector, "position" => position}, socket) do
    # Parse the end effector and position
    case parse_end_effector(end_effector) do
      {:ok, bone_name} ->
        case parse_position(position) do
          {:ok, target_pos} ->
            # Perform IK solving
            case solve_ik(bone_name, target_pos, socket) do
              {:ok, joint_rotations} ->
                # Broadcast new pose to all clients
                broadcast!(socket, "new_pose", %{joints: joint_rotations})
                {:reply, :ok, socket}
              {:error, reason} ->
                {:reply, {:error, %{reason: reason}}, socket}
            end
          {:error, reason} ->
            {:reply, {:error, %{reason: "Invalid position: #{reason}"}}, socket}
        end
      {:error, reason} ->
        {:reply, {:error, %{reason: "Invalid end effector: #{reason}"}}, socket}
    end
  end

  def handle_in("load_model", %{"model_path" => model_path}, socket) do
    case load_vrm_model(model_path) do
      {:ok, skeleton_data} ->
        # Store skeleton data in socket for future IK operations
        socket = assign(socket, :skeleton, skeleton_data)
        {:reply, {:ok, %{message: "Model loaded successfully"}}, socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  # Parse VRM bone name from end effector string
  defp parse_end_effector(end_effector) do
    # Map common end effector names to VRM bone names
    bone_mapping = %{
      "leftHand" => "leftHand",
      "rightHand" => "rightHand",
      "leftFoot" => "leftFoot",
      "rightFoot" => "rightFoot",
      "head" => "head"
    }

    case Map.get(bone_mapping, end_effector) do
      nil -> {:error, "Unknown end effector: #{end_effector}"}
      bone_name -> {:ok, bone_name}
    end
  end

  # Parse position from JSON format
  defp parse_position(%{"x" => x, "y" => y, "z" => z}) do
    try do
      {:ok, {x, y, z}}
    rescue
      _ -> {:error, "Position values must be numbers"}
    end
  end

  defp parse_position(_), do: {:error, "Position must be an object with x, y, z keys"}

  # Load VRM model and extract skeleton
  defp load_vrm_model(model_path) do
    case AriaGltf.load_file(model_path) do
      {:ok, document} ->
        # Find the first skin in the document
        case find_first_skin(document) do
          nil ->
            {:error, "No skin found in VRM document"}
          skin_data ->
            case AriaGltf.Skin.from_json(skin_data) do
              {:ok, skin} ->
                case AriaGltf.Skin.build_joint_hierarchy(skin, document.nodes) do
                  {:ok, joint_hierarchy} ->
                    case HierarchyManager.new() do
                      {:ok, manager} ->
                        # Convert joint hierarchy to list for rebuild_from_nodes
                        joint_list = Map.values(joint_hierarchy)
                        manager = HierarchyManager.rebuild_from_nodes(manager, joint_list)
                        {:ok, %{manager: manager, hierarchy: joint_hierarchy, skin: skin}}
                    end
                  {:error, reason} ->
                    {:error, "Failed to build joint hierarchy: #{reason}"}
                end
              {:error, reason} ->
                {:error, "Failed to parse skin: #{reason}"}
            end
        end
      {:error, reason} ->
        {:error, "Failed to load VRM file: #{reason}"}
    end
  end

  # Find the first skin in the document
  defp find_first_skin(document) do
    case document.skins do
      nil -> nil
      [] -> nil
      [first_skin | _] -> first_skin
    end
  end

  # Get skeleton data from socket state
  defp get_skeleton_data(socket) do
    case socket.assigns[:skeleton] do
      nil ->
        {:error, "No skeleton data loaded. Please load a VRM model first."}
      skeleton_data ->
        {:ok, skeleton_data}
    end
  end

  # Map VRM bone name to joint index
  defp map_vrm_bone_to_index(bone_name, skin, _hierarchy) do
    _ = skin  # Explicitly mark as intentionally unused for now
    # VRM bone name mapping (simplified for common bones)
    vrm_bone_mapping = %{
      "hips" => 0,
      "spine" => 1,
      "chest" => 2,
      "neck" => 3,
      "head" => 4,
      "leftShoulder" => 5,
      "leftUpperArm" => 6,
      "leftLowerArm" => 7,
      "leftHand" => 8,
      "rightShoulder" => 9,
      "rightUpperArm" => 10,
      "rightLowerArm" => 11,
      "rightHand" => 12,
      "leftUpperLeg" => 13,
      "leftLowerLeg" => 14,
      "leftFoot" => 15,
      "rightUpperLeg" => 16,
      "rightLowerLeg" => 17,
      "rightFoot" => 18
    }

    case Map.get(vrm_bone_mapping, bone_name) do
      nil ->
        {:error, "Unknown VRM bone: #{bone_name}"}
      joint_index ->
        # Validate that joint index exists in skin joints
        if joint_index in skin.joints do
          {:ok, joint_index}
        else
          {:error, "Joint index #{joint_index} not found in skin joints"}
        end
    end
  end

  # Perform IK solving using AriaEwbik
  defp perform_ik_solving(_manager, joint_index, _target_pos) do
    # TODO: Implement actual AriaEwbik integration
    # For now, return placeholder rotations
    # This would call AriaEwbik.solve() with proper parameters

    # Placeholder: Return some basic joint rotations
    # In real implementation, this would:
    # 1. Set up IK constraints for the target joint
    # 2. Call AriaEwbik.solve() with the hierarchy manager
    # 3. Return the computed joint rotations

    {:ok, [
      %{joint_index: joint_index, rotation: {0.0, 0.0, 0.0, 1.0}},
      %{joint_index: joint_index - 1, rotation: {0.1, 0.2, 0.3, 0.9}}  # Parent joint
    ]}
  end

  # Convert joint rotations to VRM format with bone names
  defp convert_to_vrm_format(joint_rotations, _hierarchy, _skin) do
    # Reverse mapping from joint index to VRM bone name
    index_to_bone = %{
      0 => "hips",
      1 => "spine",
      2 => "chest",
      3 => "neck",
      4 => "head",
      5 => "leftShoulder",
      6 => "leftUpperArm",
      7 => "leftLowerArm",
      8 => "leftHand",
      9 => "rightShoulder",
      10 => "rightUpperArm",
      11 => "rightLowerArm",
      12 => "rightHand",
      13 => "leftUpperLeg",
      14 => "leftLowerLeg",
      15 => "leftFoot",
      16 => "rightUpperLeg",
      17 => "rightLowerLeg",
      18 => "rightFoot"
    }

    Enum.map(joint_rotations, fn %{joint_index: joint_index, rotation: rotation} ->
      bone_name = Map.get(index_to_bone, joint_index, "unknown")
      # Convert quaternion tuple to list format
      rotation_list = Tuple.to_list(rotation)
      %{bone: bone_name, rotation: rotation_list}
    end)
  end

  # Perform IK solving with real skeleton infrastructure
  defp solve_ik(bone_name, target_pos, socket) do
    # Get skeleton data from socket state
    case get_skeleton_data(socket) do
      {:ok, %{manager: manager, hierarchy: hierarchy, skin: skin}} ->
        # Map VRM bone name to joint index
        case map_vrm_bone_to_index(bone_name, skin, hierarchy) do
          {:ok, joint_index} ->
            # Perform IK solving using AriaEwbik
            case perform_ik_solving(manager, joint_index, target_pos) do
              {:ok, joint_rotations} ->
                # Convert to VRM bone names and quaternion format
                vrm_rotations = convert_to_vrm_format(joint_rotations, hierarchy, skin)
                {:ok, vrm_rotations}
            end
          {:error, reason} ->
            {:error, "Bone mapping failed: #{reason}"}
        end
      {:error, reason} ->
        {:error, "No skeleton data available: #{reason}"}
    end
  end
end
