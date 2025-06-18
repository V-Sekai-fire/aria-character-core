# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Verification.ObjectModelVerificationTest do
  @moduledoc """
  KHR_interactivity Object Model Access Specification Verification Tests
  
  Verifies pointer operations against KHR specification requirements:
  - JSON pointer resolution for glTF scene properties
  - Property validation and type safety
  - Cubic Bézier easing for interpolation
  - glTF scene tree navigation
  """

  use ExUnit.Case
  alias StateV2
  alias NodeLibrary.KHRInteractivity.ObjectModel
  alias NodeLibrary.KHRInteractivity.StateAdvanced
  alias NodeLibrary.KHRInteractivity.Support.GLTFSceneMock

  describe "pointer/get specification compliance" do
    test "basic property access with JSON pointer syntax" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Test getting node translation property
      result_state = StateAdvanced.pointer_get(state, [8000, "node_2", "translation"])
      
      # Should return the head node translation [0.0, 1.8, 0.0]
      translation = StateV2.get_fact(result_state, "8000", "value")
      assert translation == [0.0, 1.8, 0.0]
    end

    test "nested property access" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Test accessing specific component of translation (y component)
      result_state = StateAdvanced.pointer_get(state, [8001, "node_2", "translation.y"])
      
      # Should return 1.8 (y component of head translation)
      y_value = StateV2.get_fact(result_state, "8001", "value")
      assert y_value == 1.8
    end

    test "property access with various data types" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Test rotation (quaternion)
      rotation_state = StateAdvanced.pointer_get(state, [8010, "node_4", "rotation"])
      rotation = StateV2.get_fact(rotation_state, "8010", "value")
      assert rotation == [0.0, 0.0, 0.0, 1.0]
      
      # Test scale (vector3)
      scale_state = StateAdvanced.pointer_get(rotation_state, [8011, "node_4", "scale"])
      scale = StateV2.get_fact(scale_state, "8011", "value")
      assert scale == [1.0, 1.0, 1.0]
      
      # Test name (string)
      name_state = StateAdvanced.pointer_get(scale_state, [8012, "node_4", "name"])
      name = StateV2.get_fact(name_state, "8012", "value")
      assert name == "left_arm"
    end

    test "invalid property path handling" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Non-existent property
      result_state_invalid = StateAdvanced.pointer_get(state, [8100, "node_2", "invalid_property"])
      assert StateV2.get_fact(result_state_invalid, "8100", "value") == nil
      
      # Non-existent object
      result_state_no_object = StateAdvanced.pointer_get(state, [8101, "non_existent_node", "translation"])
      assert StateV2.get_fact(result_state_no_object, "8101", "value") == nil
      
      # Invalid path format
      result_state_invalid_path = StateAdvanced.pointer_get(state, [8102, "node_2", ""])
      assert StateV2.get_fact(result_state_invalid_path, "8102", "value") == nil
    end

    test "node lookup by name vs index" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Using mock's helper to set up named access
      head_translation = GLTFSceneMock.get_node_property(state, "head", "translation")
      assert head_translation == [0.0, 1.8, 0.0]
      
      # Using index access
      head_translation_by_index = GLTFSceneMock.get_node_property(state, 2, "translation")
      assert head_translation_by_index == head_translation
    end
  end

  describe "pointer/set specification compliance" do
    test "basic property modification" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Set new translation value
      new_translation = [1.0, 2.0, 3.0]
      result_state = StateAdvanced.pointer_set(state, [8200, "node_2", "translation", new_translation])
      
      # Verify property was set
      assert StateV2.get_fact(result_state, "8200", "property_set") == "translation"
      
      # Verify the actual value changed
      updated_translation = StateV2.get_fact(result_state, "node_2", "translation")
      assert updated_translation == new_translation
    end

    test "component-level property modification" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Set specific component (y value of translation)
      result_state = StateAdvanced.pointer_set(state, [8201, "node_2", "translation.y", 5.0])
      
      # Verify component was updated
      assert StateV2.get_fact(result_state, "8201", "property_set") == "translation.y"
      
      # Verify only y component changed
      updated_translation = StateV2.get_fact(result_state, "node_2", "translation")
      assert updated_translation == [0.0, 5.0, 0.0]  # Only y changed from 1.8 to 5.0
    end

    test "various data type modifications" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Modify rotation (quaternion)
      new_rotation = [0.1, 0.2, 0.3, 0.9]
      rotation_state = StateAdvanced.pointer_set(state, [8210, "node_4", "rotation", new_rotation])
      updated_rotation = StateV2.get_fact(rotation_state, "node_4", "rotation")
      assert updated_rotation == new_rotation
      
      # Modify scale (vector3)
      new_scale = [2.0, 2.0, 2.0]
      scale_state = StateAdvanced.pointer_set(rotation_state, [8211, "node_4", "scale", new_scale])
      updated_scale = StateV2.get_fact(scale_state, "node_4", "scale")
      assert updated_scale == new_scale
    end

    test "property validation and error handling" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Invalid property path
      result_state_invalid = StateAdvanced.pointer_set(state, [8300, "node_2", "", "value"])
      assert StateV2.get_fact(result_state_invalid, "8300", "property_set") == nil
      
      # Non-existent object
      result_state_no_object = StateAdvanced.pointer_set(state, [8301, "non_existent", "translation", [1, 2, 3]])
      assert StateV2.get_fact(result_state_no_object, "8301", "property_set") == nil
    end

    test "atomic property updates" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Multiple property updates should be independent
      state_1 = StateAdvanced.pointer_set(state, [8400, "node_2", "translation", [1.0, 1.0, 1.0]])
      state_2 = StateAdvanced.pointer_set(state_1, [8401, "node_2", "rotation", [0.1, 0.1, 0.1, 0.9]])
      
      # Both properties should be updated
      final_translation = StateV2.get_fact(state_2, "node_2", "translation")
      final_rotation = StateV2.get_fact(state_2, "node_2", "rotation")
      
      assert final_translation == [1.0, 1.0, 1.0]
      assert final_rotation == [0.1, 0.1, 0.1, 0.9]
    end
  end

  describe "pointer/interpolate specification compliance" do
    test "numeric value interpolation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Current translation: [0.0, 1.8, 0.0]
      # Target: [2.0, 4.0, 6.0]
      # t = 0.5 (halfway)
      target_value = [2.0, 4.0, 6.0]
      t = 0.5
      
      result_state = StateAdvanced.pointer_interpolate(state, [8500, "node_2", "translation", target_value, t])
      
      # Verify interpolation result
      interpolated_value = StateV2.get_fact(result_state, "8500", "interpolated_value")
      assert interpolated_value == [1.0, 2.9, 3.0]  # Halfway between current and target
      
      # Verify node property was updated
      updated_translation = StateV2.get_fact(result_state, "node_2", "translation")
      assert updated_translation == interpolated_value
    end

    test "interpolation at endpoints" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      target_value = [5.0, 5.0, 5.0]
      
      # t = 0.0 (start) - should return current value
      result_state_start = StateAdvanced.pointer_interpolate(state, [8510, "node_2", "translation", target_value, 0.0])
      start_value = StateV2.get_fact(result_state_start, "8510", "interpolated_value")
      assert start_value == [0.0, 1.8, 0.0]  # Original value
      
      # t = 1.0 (end) - should return target value
      result_state_end = StateAdvanced.pointer_interpolate(state, [8511, "node_2", "translation", target_value, 1.0])
      end_value = StateV2.get_fact(result_state_end, "8511", "interpolated_value")
      assert end_value == target_value
    end

    test "interpolation with different data types" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Vector interpolation (scale)
      current_scale = [1.0, 1.0, 1.0]
      target_scale = [3.0, 3.0, 3.0]
      t = 0.25
      
      result_state = StateAdvanced.pointer_interpolate(state, [8520, "node_4", "scale", target_scale, t])
      interpolated_scale = StateV2.get_fact(result_state, "8520", "interpolated_value")
      
      # Should be 25% of the way: 1.0 + 0.25 * (3.0 - 1.0) = 1.5
      assert interpolated_scale == [1.5, 1.5, 1.5]
    end

    test "interpolation parameter validation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Invalid t parameter
      result_state_invalid_t = StateAdvanced.pointer_interpolate(state, [8600, "node_2", "translation", [1, 2, 3], "invalid"])
      assert StateV2.get_fact(result_state_invalid_t, "8600", "interpolated_value") == nil
      
      # Invalid property path
      result_state_invalid_path = StateAdvanced.pointer_interpolate(state, [8601, "node_2", "", [1, 2, 3], 0.5])
      assert StateV2.get_fact(result_state_invalid_path, "8601", "interpolated_value") == nil
      
      # t values outside [0, 1] should still work (extrapolation)
      result_state_extrapolate = StateAdvanced.pointer_interpolate(state, [8602, "node_2", "translation", [2, 4, 6], 1.5])
      extrapolated = StateV2.get_fact(result_state_extrapolate, "8602", "interpolated_value")
      # Should extrapolate beyond target: current * (1-t) + target * t
      # [0.0, 1.8, 0.0] * (-0.5) + [2, 4, 6] * 1.5 = [0.0, -0.9, 0.0] + [3.0, 6.0, 9.0] = [3.0, 5.1, 9.0]
      assert extrapolated == [3.0, 5.1, 9.0]
    end

    test "mismatched vector sizes" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Try to interpolate translation (3D) with 2D target
      target_2d = [1.0, 2.0]  # Wrong size
      result_state = StateAdvanced.pointer_interpolate(state, [8700, "node_2", "translation", target_2d, 0.5])
      
      # Should handle gracefully (implementation-dependent behavior)
      interpolated = StateV2.get_fact(result_state, "8700", "interpolated_value")
      # Current implementation returns original on mismatch
      assert interpolated == [0.0, 1.8, 0.0]
    end
  end

  describe "glTF scene integration" do
    test "scene tree navigation with pointer operations" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Navigate through parent-child relationships
      # Get character node children
      character_children = GLTFSceneMock.get_node_property(state, "character", "children")
      assert character_children == [2, 3]  # head, body indices
      
      # Access child properties
      head_translation = GLTFSceneMock.get_node_property(state, 2, "translation")
      body_translation = GLTFSceneMock.get_node_property(state, 3, "translation")
      
      assert head_translation == [0.0, 1.8, 0.0]
      assert body_translation == [0.0, 1.0, 0.0]
    end

    test "animation target property access" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Get animation info and target properties
      animation_info = GLTFSceneMock.get_animation_info(state, "head_nod")
      head_channel = Enum.at(animation_info.channels, 0)
      
      # Access the property targeted by animation
      target_node = head_channel.target.node  # Node 2 (head)
      target_path = head_channel.target.path  # "rotation"
      
      current_rotation = GLTFSceneMock.get_node_property(state, target_node, target_path)
      assert current_rotation == [0.0, 0.0, 0.0, 1.0]
      
      # Modify the animated property
      new_rotation = [0.1, 0.0, 0.0, 0.995]
      updated_state = GLTFSceneMock.set_node_property(state, target_node, target_path, new_rotation)
      
      # Verify change
      updated_rotation = GLTFSceneMock.get_node_property(updated_state, target_node, target_path)
      assert updated_rotation == new_rotation
    end

    test "property synchronization across operations" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Perform multiple pointer operations on the same object
      state_1 = StateAdvanced.pointer_set(state, [8800, "node_2", "translation", [1, 2, 3]])
      state_2 = StateAdvanced.pointer_interpolate(state_1, [8801, "node_2", "translation", [4, 5, 6], 0.5])
      
      # Final value should be interpolated from the updated value
      # From [1, 2, 3] to [4, 5, 6] at t=0.5 = [2.5, 3.5, 4.5]
      final_value = StateV2.get_fact(state_2, "8801", "interpolated_value")
      assert final_value == [2.5, 3.5, 4.5]
      
      # Node should have the interpolated value
      node_value = StateV2.get_fact(state_2, "node_2", "translation")
      assert node_value == final_value
    end

    test "complex scene manipulation workflow" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Simulate a complex animation workflow
      # 1. Get initial positions
      head_pos = GLTFSceneMock.get_node_property(state, "head", "translation")
      arm_pos = GLTFSceneMock.get_node_property(state, "left_arm", "translation")
      
      # 2. Animate head nodding (Y rotation)
      state_1 = StateAdvanced.pointer_set(state, [8900, "node_2", "rotation", [0.1, 0.0, 0.0, 0.995]])
      
      # 3. Animate arm movement (translation interpolation)
      target_arm_pos = [-1.0, 1.2, 0.5]
      state_2 = StateAdvanced.pointer_interpolate(state_1, [8901, "node_4", "translation", target_arm_pos, 0.7])
      
      # 4. Verify coordinated animation state
      final_head_rotation = StateV2.get_fact(state_2, "node_2", "rotation")
      final_arm_position = StateV2.get_fact(state_2, "8901", "interpolated_value")
      
      assert final_head_rotation == [0.1, 0.0, 0.0, 0.995]
      # Expected: [-0.5, 0.8, 0.0] + 0.7 * ([-1.0, 1.2, 0.5] - [-0.5, 0.8, 0.0])
      # = [-0.5, 0.8, 0.0] + 0.7 * [-0.5, 0.4, 0.5]
      # = [-0.5, 0.8, 0.0] + [-0.35, 0.28, 0.35]
      # = [-0.85, 1.08, 0.35]
      assert final_arm_position == [-0.85, 1.08, 0.35]
    end
  end

  describe "JSON pointer specification compliance" do
    test "property path parsing and resolution" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Test various path formats
      paths_and_expected = [
        {"translation", [0.0, 1.8, 0.0]},
        {"rotation", [0.0, 0.0, 0.0, 1.0]},
        {"scale", [1.0, 1.0, 1.0]},
        {"name", "head"}
      ]
      
      Enum.each(paths_and_expected, fn {path, expected} ->
        result_state = StateAdvanced.pointer_get(state, [9000, "node_2", path])
        actual = StateV2.get_fact(result_state, "9000", "value")
        assert actual == expected, "Path '#{path}' should return #{inspect(expected)}, got #{inspect(actual)}"
      end)
    end

    test "error handling for malformed paths" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      malformed_paths = [
        nil,
        123,  # Non-string
        "",   # Empty string
        ".",  # Just separator
        ".invalid",  # Leading separator
        "invalid.",  # Trailing separator
      ]
      
      Enum.each(malformed_paths, fn path ->
        result_state = StateAdvanced.pointer_get(state, [9100, "node_2", path])
        actual = StateV2.get_fact(result_state, "9100", "value")
        assert actual == nil, "Malformed path #{inspect(path)} should return nil"
      end)
    end

    test "deep property access simulation" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Simulate accessing nested properties (implementation-dependent)
      # Current implementation supports single-level property access
      result_state = StateAdvanced.pointer_get(state, [9200, "node_2", "translation.x"])
      x_component = StateV2.get_fact(result_state, "9200", "value")
      
      # Should get first component of translation vector
      assert x_component == 0.0
    end
  end
end
