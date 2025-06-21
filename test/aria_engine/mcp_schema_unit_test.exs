defmodule AriaEngine.MCPSchemaUnitTest do
  use ExUnit.Case, async: true
  
  alias AriaEngine.MCPToolsV2

  describe "schema structure validation" do
    test "all tools have valid schema definitions" do
      tools = MCPToolsV2.get_tools()
      
      assert length(tools) > 0
      
      Enum.each(tools, fn tool ->
        assert is_binary(tool["name"])
        assert is_binary(tool["version"])
        assert is_binary(tool["description"])
        assert is_map(tool["inputSchema"])
        
        # Verify schema has required structure
        schema = tool["inputSchema"]
        assert schema["type"] == "object"
        assert is_map(schema["properties"])
      end)
    end

    test "schedule_activities schema has enhanced duration support" do
      schema = MCPToolsV2.get_input_schema(:schedule_activities)
      
      # Navigate to activities.items.properties.duration
      activities_schema = schema["properties"]["activities"]
      assert activities_schema["type"] == "array"
      
      activity_schema = activities_schema["items"]
      assert activity_schema["type"] == "object"
      
      duration_schema = activity_schema["properties"]["duration"]
      
      # Verify oneOf structure for enhanced duration support
      assert Map.has_key?(duration_schema, "oneOf")
      one_of_options = duration_schema["oneOf"]
      
      assert length(one_of_options) == 2
      
      # First option: ISO 8601 duration string
      string_option = Enum.at(one_of_options, 0)
      assert string_option["type"] == "string"
      assert String.contains?(string_option["description"], "ISO 8601")
      
      # Second option: Object with start/end
      object_option = Enum.at(one_of_options, 1)
      assert object_option["type"] == "object"
      assert Map.has_key?(object_option["properties"], "start")
      assert Map.has_key?(object_option["properties"], "end")
    end

    test "schedule_activities schema includes entities and resources" do
      schema = MCPToolsV2.get_input_schema(:schedule_activities)
      properties = schema["properties"]
      
      # Verify entities schema
      assert Map.has_key?(properties, "entities")
      entities_schema = properties["entities"]
      assert entities_schema["type"] == "array"
      
      entity_properties = entities_schema["items"]["properties"]
      assert Map.has_key?(entity_properties, "id")
      assert Map.has_key?(entity_properties, "capabilities")
      assert Map.has_key?(entity_properties, "availability")
      
      # Verify resources schema
      assert Map.has_key?(properties, "resources")
      resources_schema = properties["resources"]
      assert resources_schema["type"] == "object"
      assert Map.has_key?(resources_schema, "additionalProperties")
    end

    test "pipeline management schemas are properly defined" do
      # Test configure_pipeline_layout schema
      layout_schema = MCPToolsV2.get_input_schema(:configure_pipeline_layout)
      assert layout_schema["properties"]["topology"]["type"] == "string"
      assert is_list(layout_schema["properties"]["topology"]["enum"])
      
      # Test start_planning_pipeline schema
      start_schema = MCPToolsV2.get_input_schema(:start_planning_pipeline)
      assert start_schema["properties"]["topology"]["type"] == "string"
      assert "echo_pipeline" in start_schema["properties"]["topology"]["enum"]
      
      # Test get_pipeline_status schema
      status_schema = MCPToolsV2.get_input_schema(:get_pipeline_status)
      assert status_schema["properties"]["pipeline_id"]["type"] == "string"
      assert "pipeline_id" in status_schema["required"]
    end
  end

  describe "parameter validation logic" do
    test "required fields are properly marked" do
      schema = MCPToolsV2.get_input_schema(:schedule_activities)
      
      # Top-level required fields
      assert "schedule_name" in schema["required"]
      assert "activities" in schema["required"]
      
      # Activity-level required fields
      activity_schema = schema["properties"]["activities"]["items"]
      assert "id" in activity_schema["required"]
      assert "duration" in activity_schema["required"]
    end

    test "optional fields have proper defaults" do
      schema = MCPToolsV2.get_input_schema(:start_planning_pipeline)
      topology_prop = schema["properties"]["topology"]
      
      assert topology_prop["default"] == "echo_pipeline"
    end

    test "enum constraints are properly defined" do
      schema = MCPToolsV2.get_input_schema(:configure_pipeline_layout)
      topology_enum = schema["properties"]["topology"]["enum"]
      
      expected_topologies = ["linear", "parallel", "multi_strategy", "custom"]
      assert topology_enum == expected_topologies
    end
  end

  describe "duration format validation" do
    test "duration supports both string and object formats" do
      schema = MCPToolsV2.get_input_schema(:schedule_activities)
      duration_schema = schema["properties"]["activities"]["items"]["properties"]["duration"]
      
      one_of_options = duration_schema["oneOf"]
      
      # String format (ISO 8601)
      string_format = Enum.find(one_of_options, &(&1["type"] == "string"))
      assert string_format != nil
      assert String.contains?(string_format["description"], "PT2H30M")
      
      # Object format (start/end interval)
      object_format = Enum.find(one_of_options, &(&1["type"] == "object"))
      assert object_format != nil
      
      start_prop = object_format["properties"]["start"]
      end_prop = object_format["properties"]["end"]
      
      assert start_prop["type"] == "string"
      assert end_prop["type"] == "string"
      assert String.contains?(start_prop["description"], "ISO 8601")
      assert String.contains?(end_prop["description"], "ISO 8601")
    end

    test "entity availability supports duration format" do
      schema = MCPToolsV2.get_input_schema(:schedule_activities)
      entity_schema = schema["properties"]["entities"]["items"]
      availability_schema = entity_schema["properties"]["availability"]
      
      # Should support both string and object formats
      assert Map.has_key?(availability_schema, "oneOf")
      one_of_options = availability_schema["oneOf"]
      
      string_option = Enum.find(one_of_options, &(&1["type"] == "string"))
      object_option = Enum.find(one_of_options, &(&1["type"] == "object"))
      
      assert string_option != nil
      assert object_option != nil
    end
  end

  describe "error handling and edge cases" do
    test "all schema functions are accessible" do
      # Test that all schema functions can be called directly
      tools = [
        :configure_pipeline_layout,
        :setup_element_config,
        :start_planning_pipeline,
        :stop_planning_pipeline,
        :get_pipeline_status,
        :get_pipeline_metrics,
        :schedule_activities,
        :list_active_pipelines,
        :send_pipeline_request
      ]
      
      Enum.each(tools, fn tool ->
        schema = MCPToolsV2.get_input_schema(tool)
        assert is_map(schema)
        assert schema["type"] == "object"
      end)
    end

    test "schema completeness for complex tools" do
      schema = MCPToolsV2.get_input_schema(:schedule_activities)
      properties = schema["properties"]
      
      # Verify all expected top-level properties exist
      expected_properties = [
        "schedule_name",
        "activities", 
        "entities",
        "resources",
        "constraints",
        "simulation_options",
        "resource_management",
        "pipeline_topology"
      ]
      
      Enum.each(expected_properties, fn prop ->
        assert Map.has_key?(properties, prop), "Missing property: #{prop}"
      end)
    end

    test "nested schema validation for activities" do
      schema = MCPToolsV2.get_input_schema(:schedule_activities)
      activity_props = schema["properties"]["activities"]["items"]["properties"]
      
      # Verify all activity properties
      expected_activity_props = [
        "id",
        "name", 
        "duration",
        "dependencies",
        "required_capabilities",
        "required_resources",
        "participants",
        "type"
      ]
      
      Enum.each(expected_activity_props, fn prop ->
        assert Map.has_key?(activity_props, prop), "Missing activity property: #{prop}"
      end)
    end
  end

  describe "backward compatibility" do
    test "legacy duration string format still supported" do
      schema = MCPToolsV2.get_input_schema(:schedule_activities)
      duration_schema = schema["properties"]["activities"]["items"]["properties"]["duration"]
      
      # Ensure string format is still the first option for backward compatibility
      one_of_options = duration_schema["oneOf"]
      first_option = Enum.at(one_of_options, 0)
      
      assert first_option["type"] == "string"
      assert String.contains?(first_option["description"], "ISO 8601")
    end

    test "all tools maintain version 2.0.0" do
      tools = MCPToolsV2.get_tools()
      
      Enum.each(tools, fn tool ->
        assert tool["version"] == "2.0.0"
      end)
    end
  end
end
