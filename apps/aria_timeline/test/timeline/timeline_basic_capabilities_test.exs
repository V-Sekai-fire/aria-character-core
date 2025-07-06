# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.BasicCapabilitiesTest do
  use ExUnit.Case, async: true
  alias Timeline
  alias Timeline.Interval
  alias Timeline.AgentEntity

  describe("basic agent and entity creation") do
    test "creates agent with capabilities" do
      agent =
        AgentEntity.create_agent("aria1", "Aria VTuber", %{personality: "helpful"},
          capabilities: [:decision_making, :communication]
        )

      assert agent.type == :agent
      assert agent.id == "aria1"
      assert agent.name == "Aria VTuber"
      assert AgentEntity.has_capability?(agent, :decision_making)
      assert AgentEntity.has_capability?(agent, :communication)
      assert AgentEntity.is_currently_agent?(agent)
    end

    test "creates entity without action capabilities" do
      entity = AgentEntity.create_entity("room1", "Conference Room", %{capacity: 10})
      assert entity.type == :entity
      assert entity.id == "room1"
      assert entity.name == "Conference Room"
      refute AgentEntity.is_currently_agent?(entity)
      refute AgentEntity.has_capability?(entity, :decision_making)
    end

    test "validates agent and entity properly" do
      agent = AgentEntity.create_agent("test_agent", "Test Agent")
      entity = AgentEntity.create_entity("test_entity", "Test Entity")
      assert AgentEntity.valid?(agent)
      assert AgentEntity.valid?(entity)
      assert AgentEntity.agent?(agent)
      assert AgentEntity.entity?(entity)
      refute AgentEntity.agent?(entity)
      refute AgentEntity.entity?(agent)
    end
  end

  describe("capability management") do
    test "adds capabilities to agent" do
      agent =
        AgentEntity.create_agent("robot1", "Service Robot", %{}, capabilities: [:navigation])

      updated_agent = AgentEntity.add_capability(agent, :object_manipulation)
      assert AgentEntity.has_capability?(updated_agent, :navigation)
      assert AgentEntity.has_capability?(updated_agent, :object_manipulation)
      assert length(updated_agent.capabilities) == 2
    end

    test "removes capabilities from agent" do
      agent =
        AgentEntity.create_agent("worker1", "Factory Worker", %{},
          capabilities: [:welding, :assembly, :quality_check]
        )

      updated_agent = AgentEntity.remove_capabilities(agent, [:welding, :assembly])
      refute AgentEntity.has_capability?(updated_agent, :welding)
      refute AgentEntity.has_capability?(updated_agent, :assembly)
      assert AgentEntity.has_capability?(updated_agent, :quality_check)
    end

    test "checks action performance capability" do
      pilot =
        AgentEntity.create_agent("pilot1", "Airline Pilot", %{},
          capabilities: [:flying, :navigation, :decision_making]
        )

      assert AgentEntity.can_perform_action?(pilot, :make_decision)
      assert AgentEntity.can_perform_action?(pilot, :navigate)
      refute AgentEntity.can_perform_action?(pilot, :perform_surgery)
    end
  end

  describe("timeline integration with capabilities") do
    test "adds agent interval to timeline" do
      timeline = Timeline.new()

      agent =
        AgentEntity.create_agent("chef1", "Head Chef", %{specialty: "italian"},
          capabilities: [:cooking, :menu_planning, :team_leadership]
        )

      cooking_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: agent,
          label: "Lunch Preparation"
        )

      updated_timeline = Timeline.add_interval(timeline, cooking_interval)
      assert Timeline.consistent?(updated_timeline)
      assert length(Map.keys(updated_timeline.intervals)) == 1
    end

    test "adds entity interval to timeline" do
      timeline = Timeline.new()

      oven =
        AgentEntity.create_entity("oven1", "Commercial Oven", %{
          temperature_max: 500,
          fuel_type: "gas"
        })

      baking_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          entity: oven,
          label: "Bread Baking"
        )

      updated_timeline = Timeline.add_interval(timeline, baking_interval)
      assert Timeline.consistent?(updated_timeline)
      assert length(Map.keys(updated_timeline.intervals)) == 1
    end

    test "handles mixed agent and entity intervals" do
      timeline = Timeline.new()

      baker =
        AgentEntity.create_agent("baker1", "Master Baker",
          capabilities: [:baking, :recipe_creation]
        )

      oven = AgentEntity.create_entity("oven1", "Bakery Oven")

      prep_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          agent: baker,
          label: "Dough Preparation"
        )

      bake_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          entity: oven,
          label: "Baking Process"
        )

      updated_timeline =
        timeline |> Timeline.add_interval(prep_interval) |> Timeline.add_interval(bake_interval)

      assert Timeline.consistent?(updated_timeline)
      assert length(Map.keys(updated_timeline.intervals)) == 2
    end
  end
end
