# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Support.GLTFSceneMock do
  @moduledoc """
  Mock glTF scene tree for KHR_interactivity verification testing.
  
  Provides realistic glTF scene structure with:
  - Node hierarchy with transforms
  - Animation definitions and timelines  
  - Property accessors matching glTF patterns
  - Animation channel targeting
  """

  alias StateV2

  @doc """
  Create a complete mock glTF scene with realistic structure.
  
  Scene structure:
  - root (scene)
    - character (node)
      - head (node with animation)
      - body (node)
        - left_arm (node with animation)
        - right_arm (node)
    - environment (node)
      - light (node)
  """
  def create_mock_scene do
    %{
      scenes: [
        %{
          name: "main_scene",
          nodes: [0]  # root node index
        }
      ],
      nodes: [
        # Node 0: root
        %{
          name: "root",
          children: [1, 5],
          translation: [0.0, 0.0, 0.0],
          rotation: [0.0, 0.0, 0.0, 1.0],
          scale: [1.0, 1.0, 1.0]
        },
        # Node 1: character
        %{
          name: "character", 
          children: [2, 3],
          translation: [0.0, 0.0, 0.0],
          rotation: [0.0, 0.0, 0.0, 1.0],
          scale: [1.0, 1.0, 1.0]
        },
        # Node 2: head (animated)
        %{
          name: "head",
          children: [],
          translation: [0.0, 1.8, 0.0],
          rotation: [0.0, 0.0, 0.0, 1.0],
          scale: [1.0, 1.0, 1.0]
        },
        # Node 3: body
        %{
          name: "body",
          children: [4],
          translation: [0.0, 1.0, 0.0],
          rotation: [0.0, 0.0, 0.0, 1.0],
          scale: [1.0, 1.0, 1.0]
        },
        # Node 4: left_arm (animated)
        %{
          name: "left_arm",
          children: [],
          translation: [-0.5, 0.8, 0.0],
          rotation: [0.0, 0.0, 0.0, 1.0],
          scale: [1.0, 1.0, 1.0]
        },
        # Node 5: environment
        %{
          name: "environment",
          children: [6],
          translation: [0.0, 0.0, 0.0],
          rotation: [0.0, 0.0, 0.0, 1.0],
          scale: [1.0, 1.0, 1.0]
        },
        # Node 6: light
        %{
          name: "light",
          children: [],
          translation: [0.0, 3.0, 2.0],
          rotation: [0.0, 0.0, 0.0, 1.0],
          scale: [1.0, 1.0, 1.0]
        }
      ],
      animations: [
        # Animation 0: head_nod
        %{
          name: "head_nod",
          channels: [
            %{
              sampler: 0,
              target: %{
                node: 2,  # head node
                path: "rotation"
              }
            }
          ],
          samplers: [
            %{
              input: 0,   # time accessor
              output: 1,  # rotation accessor
              interpolation: "LINEAR"
            }
          ]
        },
        # Animation 1: arm_wave
        %{
          name: "arm_wave", 
          channels: [
            %{
              sampler: 0,
              target: %{
                node: 4,  # left_arm node
                path: "rotation"
              }
            }
          ],
          samplers: [
            %{
              input: 2,   # time accessor
              output: 3,  # rotation accessor
              interpolation: "LINEAR"
            }
          ]
        }
      ],
      accessors: [
        # Accessor 0: head_nod time
        %{
          count: 3,
          type: "SCALAR",
          componentType: 5126,  # FLOAT
          data: [0.0, 1.0, 2.0]
        },
        # Accessor 1: head_nod rotation keyframes
        %{
          count: 3,
          type: "VEC4", 
          componentType: 5126,  # FLOAT
          data: [
            [0.0, 0.0, 0.0, 1.0],      # t=0.0: neutral
            [0.1, 0.0, 0.0, 0.995],    # t=1.0: nod down
            [0.0, 0.0, 0.0, 1.0]       # t=2.0: neutral
          ]
        },
        # Accessor 2: arm_wave time
        %{
          count: 4,
          type: "SCALAR",
          componentType: 5126,  # FLOAT
          data: [0.0, 0.5, 1.0, 1.5]
        },
        # Accessor 3: arm_wave rotation keyframes
        %{
          count: 4,
          type: "VEC4",
          componentType: 5126,  # FLOAT
          data: [
            [0.0, 0.0, 0.0, 1.0],      # t=0.0: neutral
            [0.0, 0.0, 0.5, 0.866],    # t=0.5: wave up
            [0.0, 0.0, 0.0, 1.0],      # t=1.0: neutral  
            [0.0, 0.0, -0.5, 0.866]    # t=1.5: wave down
          ]
        }
      ]
    }
  end

  @doc """
  Initialize StateV2 with mock glTF scene data.
  """
  def setup_state_with_scene(state \\ nil) do
    scene = create_mock_scene()
    state = state || StateV2.new()

    # Store scene structure
    state = StateV2.set_fact(state, "gltf_scene", "structure", scene)
    
    # Store nodes with accessible paths
    state = Enum.reduce(Enum.with_index(scene.nodes), state, fn {node, node_index}, acc_state ->
      node_id = "node_#{node_index}"
      acc_state
      |> StateV2.set_fact(node_id, "name", node.name)
      |> StateV2.set_fact(node_id, "translation", node.translation)
      |> StateV2.set_fact(node_id, "rotation", node.rotation)
      |> StateV2.set_fact(node_id, "scale", node.scale)
      |> StateV2.set_fact(node_id, "children", Map.get(node, :children, []))
      |> StateV2.set_fact("node_by_name_#{node.name}", "index", node_index)
    end)
    
    # Store animations with timeline data
    state = Enum.reduce(Enum.with_index(scene.animations), state, fn {animation, index}, acc_state ->
      animation_id = "animation_#{index}"
      acc_state
      |> StateV2.set_fact(animation_id, "name", animation.name)
      |> StateV2.set_fact(animation_id, "channels", animation.channels)
      |> StateV2.set_fact(animation_id, "samplers", animation.samplers)
      |> StateV2.set_fact(animation_id, "duration", get_animation_duration(scene, animation))
      |> StateV2.set_fact("animation_by_name_#{animation.name}", "index", index)
    end)
    
    # Store accessors for keyframe data
    state = Enum.reduce(Enum.with_index(scene.accessors), state, fn {accessor, index}, acc_state ->
      accessor_id = "accessor_#{index}"
      acc_state
      |> StateV2.set_fact(accessor_id, "count", accessor.count)
      |> StateV2.set_fact(accessor_id, "type", accessor.type)
      |> StateV2.set_fact(accessor_id, "componentType", accessor.componentType)
      |> StateV2.set_fact(accessor_id, "data", accessor.data)
    end)

    state
  end

  @doc """
  Get node property value using JSON pointer-style path.
  """
  def get_node_property(state, node_name_or_index, property_path) do
    node_id = resolve_node_to_data_id(state, node_name_or_index)
    
    case String.split(property_path, ".") do
      [property] ->
        StateV2.get_fact(state, node_id, property)
      [property, component] ->
        case StateV2.get_fact(state, node_id, property) do
          list when is_list(list) ->
            component_index = component_to_index(component)
            Enum.at(list, component_index)
          _ -> nil
        end
      _ -> nil
    end
  end

  @doc """
  Set node property value using JSON pointer-style path.
  """
  def set_node_property(state, node_name_or_index, property_path, value) do
    node_id = resolve_node_to_data_id(state, node_name_or_index)
    
    case String.split(property_path, ".") do
      [property] ->
        StateV2.set_fact(state, node_id, property, value)
      [property, component] ->
        current_value = StateV2.get_fact(state, node_id, property)
        if is_list(current_value) do
          component_index = component_to_index(component)
          updated_value = List.replace_at(current_value, component_index, value)
          StateV2.set_fact(state, node_id, property, updated_value)
        else
          state
        end
      _ -> state
    end
  end

  @doc """
  Get animation timeline information.
  """
  def get_animation_info(state, animation_name_or_index) do
    animation_id = resolve_animation_to_data_id(state, animation_name_or_index)
    
    %{
      name: StateV2.get_fact(state, animation_id, "name"),
      duration: StateV2.get_fact(state, animation_id, "duration"),
      channels: StateV2.get_fact(state, animation_id, "channels"),
      samplers: StateV2.get_fact(state, animation_id, "samplers")
    }
  end

  @doc """
  Create animation playback state for testing.
  """
  def create_animation_playback_state(animation_id, options \\ %{}) do
    %{
      animation_id: animation_id,
      start_time: Map.get(options, :start_time, 0.0),
      playback_start: Map.get(options, :playback_start, current_time()),
      current_time: Map.get(options, :current_time, 0.0),
      is_playing: Map.get(options, :is_playing, false),
      is_paused: Map.get(options, :is_paused, false),
      playback_rate: Map.get(options, :playback_rate, 1.0),
      loop_mode: Map.get(options, :loop_mode, :none)
    }
  end

  # Private helper functions

  defp resolve_node_id(node_name) when is_binary(node_name) do
    "node_by_name_#{node_name}"
  end

  defp resolve_node_id(node_index) when is_integer(node_index) do
    "node_#{node_index}"
  end

  defp resolve_animation_id(animation_name) when is_binary(animation_name) do
    "animation_by_name_#{animation_name}"
  end

  defp resolve_animation_id(animation_index) when is_integer(animation_index) do
    "animation_#{animation_index}"
  end

  defp component_to_index("x"), do: 0
  defp component_to_index("y"), do: 1
  defp component_to_index("z"), do: 2
  defp component_to_index("w"), do: 3
  defp component_to_index(index) when is_binary(index) do
    String.to_integer(index)
  end
  defp component_to_index(index) when is_integer(index), do: index

  defp get_animation_duration(scene, animation) do
    # Get maximum time from all channels
    Enum.reduce(animation.channels, 0.0, fn channel, max_duration ->
      sampler = Enum.at(animation.samplers, channel.sampler)
      time_accessor = Enum.at(scene.accessors, sampler.input)
      
      case time_accessor.data do
        times when is_list(times) -> max(max_duration, Enum.max(times))
        _ -> max_duration
      end
    end)
  end

  defp resolve_node_to_data_id(state, node_name) when is_binary(node_name) do
    # Get the index from the name lookup, then convert to data ID
    case StateV2.get_fact(state, "node_by_name_#{node_name}", "index") do
      nil -> nil
      index -> "node_#{index}"
    end
  end

  defp resolve_node_to_data_id(_state, node_index) when is_integer(node_index) do
    "node_#{node_index}"
  end

  defp resolve_animation_to_data_id(state, animation_name) when is_binary(animation_name) do
    # Get the index from the name lookup, then convert to data ID
    case StateV2.get_fact(state, "animation_by_name_#{animation_name}", "index") do
      nil -> nil
      index -> "animation_#{index}"
    end
  end

  defp resolve_animation_to_data_id(_state, animation_index) when is_integer(animation_index) do
    "animation_#{animation_index}"
  end

  defp current_time do
    :os.system_time(:millisecond) / 1000.0
  end
end
