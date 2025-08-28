# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule TimelineGraphTest do
  use ExUnit.Case, async: true
  doctest TimelineGraph
  alias TimelineGraph
  alias Timeline.AgentEntity
  alias AriaState

  describe("new/0") do
    test "creates empty timeline graph with StateV2" do
      timeline_graph = TimelineGraph.new()
      assert timeline_graph.entities == %{}
      assert %AriaState.ObjectState{} = timeline_graph.state
      assert timeline_graph.bridge_strength == %{}
      assert timeline_graph.lod_promotion_queue == []
      assert timeline_graph.growth_triggers == %{}
    end
  end

  describe("create_entity/4") do
    setup do
      {:ok, timeline_graph: TimelineGraph.new()}
    end

    test("creates entity with automatic timeline attachment", %{timeline_graph: timeline_graph}) do
      properties = %{"type" => "furniture", "material" => "wood"}

      {:ok, updated_graph, entity_id} =
        TimelineGraph.create_entity(timeline_graph, "chair1", "Wooden Chair", properties)

      assert entity_id == "chair1"
      assert "chair1" in TimelineGraph.get_entity_ids(updated_graph)
      entity_props = TimelineGraph.get_entity_properties(updated_graph, "chair1")
      assert entity_props["type"] == "furniture"
      assert entity_props["material"] == "wood"
      {:ok, lod} = TimelineGraph.get_lod(updated_graph, "chair1")
      assert lod in [:very_low, :low, :medium]
      assert TimelineGraph.is_currently_agent?(updated_graph, "chair1") == false
    end

    test("creates potential agent entity", %{timeline_graph: timeline_graph}) do
      properties = %{"type" => "humanoid", "location" => "tower"}

      {:ok, updated_graph, entity_id} =
        TimelineGraph.create_entity(timeline_graph, "guard", "Tower Guard", properties)

      assert entity_id == "guard"
      assert TimelineGraph.is_currently_agent?(updated_graph, "guard") == false
      props = TimelineGraph.get_entity_properties(updated_graph, "guard")
      assert props["type"] == "humanoid"
      assert props["location"] == "tower"
    end

    test("handles empty properties", %{timeline_graph: timeline_graph}) do
      {:ok, updated_graph, entity_id} =
        TimelineGraph.create_entity(timeline_graph, "simple_entity", "Simple Entity")

      assert entity_id == "simple_entity"
      props = TimelineGraph.get_entity_properties(updated_graph, "simple_entity")
      assert props == %{}
    end
  end

  describe("add_capabilities/3") do
    setup do
      timeline_graph = TimelineGraph.new()

      {:ok, timeline_graph, _} =
        TimelineGraph.create_entity(timeline_graph, "door1", "Castle Door", %{
          "type" => "portal",
          "state" => "closed"
        })

      {:ok, timeline_graph: timeline_graph}
    end

    test("transitions entity to agent when adding action capabilities", %{
      timeline_graph: timeline_graph
    }) do
      assert TimelineGraph.is_currently_agent?(timeline_graph, "door1") == false

      {:ok, updated_graph} =
        TimelineGraph.add_capabilities(timeline_graph, "door1", [
          :autonomous_operation,
          :decision_making
        ])

      assert TimelineGraph.is_currently_agent?(updated_graph, "door1") == true
      assert "door1" in updated_graph.lod_promotion_queue
    end

    test("promotes LOD when transitioning to agent", %{timeline_graph: timeline_graph}) do
      {:ok, initial_lod} = TimelineGraph.get_lod(timeline_graph, "door1")

      {:ok, updated_graph} =
        TimelineGraph.add_capabilities(timeline_graph, "door1", [:autonomous_operation])

      {:ok, new_lod} = TimelineGraph.get_lod(updated_graph, "door1")
      assert lod_higher_than?(new_lod, initial_lod)
    end

    test("handles non-existent entity", %{timeline_graph: timeline_graph}) do
      result = TimelineGraph.add_capabilities(timeline_graph, "nonexistent", [:some_capability])
      assert result == {:error, :entity_not_found}
    end

    test("adds capabilities without agent transition", %{timeline_graph: timeline_graph}) do
      {:ok, updated_graph} =
        TimelineGraph.add_capabilities(timeline_graph, "door1", [:data_storage])

      entity_timeline = Map.get(updated_graph.entities, "door1")
      assert entity_timeline.last_growth != nil
    end
  end

  describe("entity property management") do
    setup do
      timeline_graph = TimelineGraph.new()

      {:ok, timeline_graph, _} =
        TimelineGraph.create_entity(timeline_graph, "player", "Player Character", %{
          "health" => 100,
          "location" => "room1"
        })

      {:ok, timeline_graph: timeline_graph}
    end

    test("set_entity_property/4 updates state and triggers timeline growth", %{
      timeline_graph: timeline_graph
    }) do
      initial_props = TimelineGraph.get_entity_properties(timeline_graph, "player")
      assert initial_props["location"] == "room1"

      {:ok, updated_graph} =
        TimelineGraph.set_entity_property(timeline_graph, "player", "location", "room2")

      updated_props = TimelineGraph.get_entity_properties(updated_graph, "player")
      assert updated_props["location"] == "room2"
      assert updated_props["health"] == 100
      entity_timeline = Map.get(updated_graph.entities, "player")
      assert entity_timeline.last_growth != nil
    end

    test("get_entity_properties/2 uses entity-first StateV2 API", %{
      timeline_graph: timeline_graph
    }) do
      props = TimelineGraph.get_entity_properties(timeline_graph, "player")
      assert is_map(props)
      assert props["health"] == 100
      assert props["location"] == "room1"
    end

    test("set_entity_property/4 handles non-existent entity", %{timeline_graph: timeline_graph}) do
      result =
        TimelineGraph.set_entity_property(
          timeline_graph,
          "nonexistent",
          "some_prop",
          "some_value"
        )

      assert result == {:error, :entity_not_found}
    end
  end

  describe("entity and agent queries") do
    setup do
      timeline_graph = TimelineGraph.new()

      {:ok, timeline_graph, _} =
        TimelineGraph.create_entity(timeline_graph, "chair1", "Wooden Chair", %{
          "type" => "furniture"
        })

      {:ok, timeline_graph, _} =
        TimelineGraph.create_entity(timeline_graph, "guard", "Tower Guard", %{
          "type" => "humanoid"
        })

      {:ok, timeline_graph} =
        TimelineGraph.add_capabilities(timeline_graph, "guard", [
          :patrol,
          :investigate,
          :decision_making
        ])

      {:ok, timeline_graph, _} =
        TimelineGraph.create_entity(timeline_graph, "table1", "Oak Table", %{
          "type" => "furniture"
        })

      {:ok, timeline_graph: timeline_graph}
    end

    test("get_entity_ids/1 returns all entities", %{timeline_graph: timeline_graph}) do
      entity_ids = TimelineGraph.get_entity_ids(timeline_graph)
      assert "chair1" in entity_ids
      assert "guard" in entity_ids
      assert "table1" in entity_ids
      assert length(entity_ids) == 3
    end

    test("get_agent_ids/1 returns only agents", %{timeline_graph: timeline_graph}) do
      agent_ids = TimelineGraph.get_agent_ids(timeline_graph)
      assert "guard" in agent_ids
      assert "chair1" not in agent_ids
      assert "table1" not in agent_ids
    end

    test("is_currently_agent?/2 correctly identifies agents", %{timeline_graph: timeline_graph}) do
      assert TimelineGraph.is_currently_agent?(timeline_graph, "guard") == true
      assert TimelineGraph.is_currently_agent?(timeline_graph, "chair1") == false
      assert TimelineGraph.is_currently_agent?(timeline_graph, "table1") == false
      assert TimelineGraph.is_currently_agent?(timeline_graph, "nonexistent") == false
    end
  end

  describe("LOD management") do
    setup do
      timeline_graph = TimelineGraph.new()

      {:ok, timeline_graph, _} =
        TimelineGraph.create_entity(timeline_graph, "npc1", "Background NPC", %{
          "type" => "humanoid"
        })

      {:ok, timeline_graph: timeline_graph}
    end

    test("get_lod/2 returns current LOD level", %{timeline_graph: timeline_graph}) do
      {:ok, lod} = TimelineGraph.get_lod(timeline_graph, "npc1")
      assert lod in [:very_low, :low, :medium, :high, :ultra_high]
    end

    test("get_lod/2 handles non-existent entity", %{timeline_graph: timeline_graph}) do
      result = TimelineGraph.get_lod(timeline_graph, "nonexistent")
      assert result == {:error, :not_found}
    end

    test("process_lod_promotions/1 promotes queued entities", %{timeline_graph: timeline_graph}) do
      timeline_graph_with_queue = %{timeline_graph | lod_promotion_queue: ["npc1"]}
      {:ok, initial_lod} = TimelineGraph.get_lod(timeline_graph_with_queue, "npc1")
      promoted_graph = TimelineGraph.process_lod_promotions(timeline_graph_with_queue)
      {:ok, new_lod} = TimelineGraph.get_lod(promoted_graph, "npc1")
      assert lod_higher_than?(new_lod, initial_lod) || new_lod == :ultra_high
      assert promoted_graph.lod_promotion_queue == []
    end

    test("process_lod_promotions/1 handles empty queue", %{timeline_graph: timeline_graph}) do
      result = TimelineGraph.process_lod_promotions(timeline_graph)
      assert result.lod_promotion_queue == []
      assert result.entities == timeline_graph.entities
    end
  end

  describe("integration with AgentEntity system") do
    test "uses existing AgentEntity.create_entity/4" do
      timeline_graph = TimelineGraph.new()

      {:ok, updated_graph, entity_id} =
        TimelineGraph.create_entity(timeline_graph, "test_entity", "Test Entity", %{
          "test_prop" => "test_value"
        })

      entity_timeline = Map.get(updated_graph.entities, entity_id)
      assert entity_timeline != nil
      assert AgentEntity.entity?(entity_timeline.entity)
    end

    test "capability-based agent determination works" do
      timeline_graph = TimelineGraph.new()

      {:ok, timeline_graph, _} =
        TimelineGraph.create_entity(timeline_graph, "test_agent", "Test Agent")

      assert TimelineGraph.is_currently_agent?(timeline_graph, "test_agent") == false

      {:ok, updated_graph} =
        TimelineGraph.add_capabilities(timeline_graph, "test_agent", [
          :decision_making,
          :autonomous_action
        ])

      entity_timeline = Map.get(updated_graph.entities, "test_agent")
      agent_status = AgentEntity.is_currently_agent?(entity_timeline.entity)
      timeline_graph_status = TimelineGraph.is_currently_agent?(updated_graph, "test_agent")
      assert agent_status == timeline_graph_status
    end
  end

  defp lod_higher_than?(new_lod, old_lod) do
    lod_values = %{very_low: 1, low: 2, medium: 3, high: 4, ultra_high: 5}
    Map.get(lod_values, new_lod, 0) > Map.get(lod_values, old_lod, 0)
  end
end
