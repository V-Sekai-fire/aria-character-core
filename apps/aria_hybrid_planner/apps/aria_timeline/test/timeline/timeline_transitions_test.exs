# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.TransitionsTest do
  use ExUnit.Case, async: true
  alias Timeline
  alias Timeline.Interval
  alias Timeline.AgentEntity

  describe("entity to agent transitions") do
    test "car becomes autonomous agent when gaining capabilities" do
      timeline = Timeline.new()
      car = AgentEntity.create_entity("car1", "Tesla Model 3", %{battery: 85})
      refute AgentEntity.is_currently_agent?(car)

      parked_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: car,
          label: "Parked"
        )

      autonomous_car = AgentEntity.add_capabilities(car, [:autonomous_driving, :decision_making])
      assert AgentEntity.is_currently_agent?(autonomous_car)

      driving_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          agent: autonomous_car,
          label: "Autonomous Driving"
        )

      updated_timeline =
        timeline
        |> Timeline.add_interval(parked_interval)
        |> Timeline.add_interval(driving_interval)

      assert Timeline.consistent?(updated_timeline)
      assert length(Map.keys(updated_timeline.intervals)) == 2
    end

    test "device gains communication capability progressively" do
      timeline = Timeline.new()
      device = AgentEntity.create_entity("sensor1", "Smart Sensor", %{firmware: "1.0"})

      basic_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          entity: device,
          label: "Basic Sensing"
        )

      comm_device = AgentEntity.add_capabilities(device, [:communication])
      assert AgentEntity.is_currently_agent?(comm_device)

      comm_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: comm_device,
          label: "Smart Communication"
        )

      updated_timeline =
        timeline |> Timeline.add_interval(basic_interval) |> Timeline.add_interval(comm_interval)

      assert Timeline.consistent?(updated_timeline)
      assert AgentEntity.has_capability?(comm_device, :communication)
    end
  end

  describe("agent to entity transitions") do
    test "robot loses capabilities and becomes entity" do
      timeline = Timeline.new()

      robot =
        AgentEntity.create_agent("robot1", "Industrial Robot", %{model: "ABB IRB 6700"},
          capabilities: [:welding, :decision_making, :movement]
        )

      assert AgentEntity.is_currently_agent?(robot)

      work_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: robot,
          label: "Active Welding"
        )

      inactive_robot =
        AgentEntity.remove_capabilities(robot, [:welding, :decision_making, :movement])

      refute AgentEntity.is_currently_agent?(inactive_robot)

      maintenance_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          entity: inactive_robot,
          label: "Maintenance Mode"
        )

      updated_timeline =
        timeline
        |> Timeline.add_interval(work_interval)
        |> Timeline.add_interval(maintenance_interval)

      assert Timeline.consistent?(updated_timeline)
    end

    test "agent transitions to entity when all action capabilities removed" do
      worker =
        AgentEntity.create_agent("worker1", "Factory Worker", %{shift: "day"},
          capabilities: [:assembly, :quality_check, :decision_making]
        )

      assert AgentEntity.is_currently_agent?(worker)

      inactive_worker =
        AgentEntity.remove_capabilities(worker, [:assembly, :quality_check, :decision_making])

      refute AgentEntity.is_currently_agent?(inactive_worker)
      refute AgentEntity.can_perform_action?(inactive_worker, :make_decision)
      refute AgentEntity.can_perform_action?(inactive_worker, :execute_action)
    end
  end

  describe("dynamic capability changes during timeline") do
    test "handles multiple transitions in single timeline" do
      timeline = Timeline.new()
      machine = AgentEntity.create_entity("machine1", "CNC Machine", %{status: "offline"})

      offline_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          entity: machine,
          label: "Offline"
        )

      manual_machine = AgentEntity.add_capabilities(machine, [:manual_operation])

      manual_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: manual_machine,
          label: "Manual Operation"
        )

      auto_machine =
        AgentEntity.add_capabilities(manual_machine, [:autonomous_operation, :decision_making])

      auto_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          agent: auto_machine,
          label: "Autonomous Operation"
        )

      maintenance_machine =
        AgentEntity.remove_capabilities(auto_machine, [
          :manual_operation,
          :autonomous_operation,
          :decision_making
        ])

      maintenance_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 18:00:00], "Etc/UTC"),
          entity: maintenance_machine,
          label: "Maintenance"
        )

      updated_timeline =
        timeline
        |> Timeline.add_interval(offline_interval)
        |> Timeline.add_interval(manual_interval)
        |> Timeline.add_interval(auto_interval)
        |> Timeline.add_interval(maintenance_interval)

      assert Timeline.consistent?(updated_timeline)
      assert length(Map.keys(updated_timeline.intervals)) == 4
      refute AgentEntity.is_currently_agent?(machine)
      assert AgentEntity.is_currently_agent?(manual_machine)
      assert AgentEntity.is_currently_agent?(auto_machine)
      refute AgentEntity.is_currently_agent?(maintenance_machine)
    end

    test "validates transition consistency" do
      drone =
        AgentEntity.create_agent("drone1", "Delivery Drone", %{battery: 100},
          capabilities: [:flying, :navigation, :package_delivery]
        )

      assert AgentEntity.is_currently_agent?(drone)
      assert AgentEntity.has_capability?(drone, :flying)
      grounded_drone = AgentEntity.remove_capabilities(drone, [:flying])
      refute AgentEntity.has_capability?(grounded_drone, :flying)
      assert AgentEntity.has_capability?(grounded_drone, :navigation)
      assert AgentEntity.is_currently_agent?(grounded_drone)

      inactive_drone =
        AgentEntity.remove_capabilities(grounded_drone, [:navigation, :package_delivery])

      refute AgentEntity.is_currently_agent?(inactive_drone)
    end
  end
end
