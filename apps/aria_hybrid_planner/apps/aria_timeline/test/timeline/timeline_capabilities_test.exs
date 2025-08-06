# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.CapabilitiesTest do
  use ExUnit.Case, async: true

  alias Timeline
  alias Timeline.Interval
  alias Timeline.AgentEntity

  describe "capability-based agent/entity transitions" do
    test "entity becomes agent when given action capabilities" do
      timeline = Timeline.new()

      # Start with a basic entity (car)
      car = AgentEntity.create_entity("car1", "Tesla Model 3", %{battery: 85})
      refute AgentEntity.is_currently_agent?(car)

      # Create interval with entity
      interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: car,
          label: "Parked Car"
        )

      timeline = Timeline.add_interval(timeline, interval)
      assert Timeline.consistent?(timeline)

      # Add autonomous driving capability - car becomes agent
      autonomous_car = AgentEntity.add_capabilities(car, [:autonomous_driving, :decision_making])
      assert AgentEntity.is_currently_agent?(autonomous_car)
      assert AgentEntity.has_capability?(autonomous_car, :autonomous_driving)

      # Create new interval with agent capabilities
      driving_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          agent: autonomous_car,
          label: "Autonomous Driving"
        )

      timeline = Timeline.add_interval(timeline, driving_interval)
      assert Timeline.consistent?(timeline)
      assert length(Map.keys(timeline.intervals)) == 2
    end

    test "agent becomes entity when capabilities are removed" do
      timeline = Timeline.new()

      # Start with an agent
      robot =
        AgentEntity.create_agent(
          "robot1",
          "Industrial Robot",
          %{model: "ABB IRB 6700"},
          capabilities: [:welding, :decision_making, :movement]
        )

      assert AgentEntity.is_currently_agent?(robot)

      # Create interval with agent
      work_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: robot,
          label: "Active Welding"
        )

      timeline = Timeline.add_interval(timeline, work_interval)
      assert Timeline.consistent?(timeline)

      # Remove action capabilities - robot becomes entity
      inactive_robot =
        AgentEntity.remove_capabilities(robot, [:welding, :decision_making, :movement])

      refute AgentEntity.is_currently_agent?(inactive_robot)

      # Create interval as entity (maintenance mode)
      maintenance_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          entity: inactive_robot,
          label: "Maintenance Mode"
        )

      timeline = Timeline.add_interval(timeline, maintenance_interval)
      assert Timeline.consistent?(timeline)
    end

    test "dynamic capability changes during timeline execution" do
      timeline = Timeline.new()

      # Create a device that gains capabilities over time
      device = AgentEntity.create_entity("device1", "Smart Device", %{firmware_version: "1.0"})

      # Phase 1: Basic entity (no capabilities)
      basic_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          entity: device,
          label: "Basic Operation"
        )

      # Phase 2: Gains communication capability
      comm_device = AgentEntity.add_capabilities(device, [:communication])

      comm_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: comm_device,
          label: "Communication Enabled"
        )

      # Phase 3: Gains full autonomy
      autonomous_device =
        AgentEntity.add_capabilities(comm_device, [:decision_making, :autonomous_operation])

      autonomous_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          agent: autonomous_device,
          label: "Fully Autonomous"
        )

      timeline =
        timeline
        |> Timeline.add_interval(basic_interval)
        |> Timeline.add_interval(comm_interval)
        |> Timeline.add_interval(autonomous_interval)

      assert Timeline.consistent?(timeline)
      assert length(Map.keys(timeline.intervals)) == 3

      # Verify capability progression
      refute AgentEntity.is_currently_agent?(device)
      assert AgentEntity.is_currently_agent?(comm_device)
      assert AgentEntity.is_currently_agent?(autonomous_device)
      assert AgentEntity.has_capability?(autonomous_device, :autonomous_operation)
    end
  end

  describe "resource constraint testing with capabilities" do
    test "capability-dependent activity assignment" do
      timeline = Timeline.new()

      # Create agents with different capabilities
      surgeon =
        AgentEntity.create_agent(
          "surgeon1",
          "Dr. Smith",
          %{specialty: "cardiac"},
          capabilities: [:surgery, :decision_making, :medical_expertise]
        )

      nurse =
        AgentEntity.create_agent(
          "nurse1",
          "Nurse Johnson",
          %{certification: "RN"},
          capabilities: [:patient_care, :communication, :assistance]
        )

      # Surgery requires surgical capability
      surgery_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: surgeon,
          label: "Heart Surgery",
          metadata: %{required_capabilities: [:surgery, :medical_expertise]}
        )

      # Patient care can be done by nurse
      care_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          agent: nurse,
          label: "Post-op Care",
          metadata: %{required_capabilities: [:patient_care]}
        )

      timeline =
        timeline
        |> Timeline.add_interval(surgery_interval)
        |> Timeline.add_interval(care_interval)

      assert Timeline.consistent?(timeline)

      # Verify capability matching
      assert AgentEntity.has_capability?(surgeon, :surgery)
      assert AgentEntity.has_capability?(nurse, :patient_care)
      refute AgentEntity.has_capability?(nurse, :surgery)
    end

    test "resource conflicts with capability requirements" do
      timeline = Timeline.new()

      # Single specialized agent
      pilot =
        AgentEntity.create_agent(
          "pilot1",
          "Captain Smith",
          %{license: "commercial"},
          capabilities: [:flying, :navigation, :decision_making]
        )

      # Two overlapping flights requiring the same pilot
      flight1 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: pilot,
          label: "Flight NYC-LAX",
          metadata: %{required_capabilities: [:flying, :navigation]}
        )

      flight2 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          agent: pilot,
          label: "Flight LAX-SFO",
          metadata: %{required_capabilities: [:flying, :navigation]}
        )

      timeline =
        timeline
        |> Timeline.add_interval(flight1)
        |> Timeline.add_interval(flight2)

      # Timeline should still be consistent (overlapping intervals are allowed)
      # but this represents a resource conflict that scheduling logic should detect
      assert Timeline.consistent?(timeline)

      # Add constraint that flights must be sequential (pilot can't be in two places)
      timeline =
        Timeline.add_constraint(
          timeline,
          "#{flight1.id}_end",
          "#{flight2.id}_start",
          # flight2 must start after flight1 ends
          {0, :infinity}
        )

      assert Timeline.consistent?(timeline)
    end

    test "multi-agent capability coordination" do
      timeline = Timeline.new()

      # Create team with complementary capabilities
      project_manager =
        AgentEntity.create_agent(
          "pm1",
          "Alice Manager",
          %{experience: "10 years"},
          capabilities: [:planning, :coordination, :decision_making]
        )

      developer =
        AgentEntity.create_agent(
          "dev1",
          "Bob Developer",
          %{language: "Elixir"},
          capabilities: [:coding, :problem_solving, :technical_analysis]
        )

      tester =
        AgentEntity.create_agent(
          "qa1",
          "Carol Tester",
          %{specialty: "automation"},
          capabilities: [:testing, :quality_assurance, :bug_detection]
        )

      # Sequential project phases requiring different capabilities
      planning_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          agent: project_manager,
          label: "Project Planning",
          metadata: %{required_capabilities: [:planning, :coordination]}
        )

      development_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          agent: developer,
          label: "Development",
          metadata: %{required_capabilities: [:coding, :technical_analysis]}
        )

      testing_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          agent: tester,
          label: "Testing",
          metadata: %{required_capabilities: [:testing, :quality_assurance]}
        )

      # Add sequential constraints
      timeline =
        timeline
        |> Timeline.add_interval(planning_phase)
        |> Timeline.add_interval(development_phase)
        |> Timeline.add_interval(testing_phase)
        |> Timeline.add_constraint(
          "#{planning_phase.id}_end",
          "#{development_phase.id}_start",
          {0, 0}
        )
        |> Timeline.add_constraint(
          "#{development_phase.id}_end",
          "#{testing_phase.id}_start",
          {0, 0}
        )

      assert Timeline.consistent?(timeline)

      # Verify each agent has required capabilities
      assert AgentEntity.has_capability?(project_manager, :planning)
      assert AgentEntity.has_capability?(developer, :coding)
      assert AgentEntity.has_capability?(tester, :testing)
    end
  end

  describe "entity ownership and temporal constraints" do
    test "entity ownership transfers during timeline" do
      timeline = Timeline.new()

      # Create agents and entity
      manager1 = AgentEntity.create_agent("mgr1", "Manager A", %{department: "IT"})
      manager2 = AgentEntity.create_agent("mgr2", "Manager B", %{department: "HR"})

      conference_room =
        AgentEntity.create_entity(
          "room1",
          "Conference Room A",
          %{capacity: 10, location: "Building 1"},
          owner_agent_id: "mgr1"
        )

      # Phase 1: Room owned by manager1
      meeting1 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          entity: conference_room,
          agent: manager1,
          label: "IT Team Meeting",
          metadata: %{owner_required: true}
        )

      # Transfer ownership
      transferred_room = AgentEntity.transfer_ownership(conference_room, "mgr2")

      # Phase 2: Room owned by manager2
      meeting2 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 11:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:30:00], "Etc/UTC"),
          entity: transferred_room,
          agent: manager2,
          label: "HR Team Meeting",
          metadata: %{owner_required: true}
        )

      timeline =
        timeline
        |> Timeline.add_interval(meeting1)
        |> Timeline.add_interval(meeting2)

      assert Timeline.consistent?(timeline)

      # Verify ownership changes
      assert AgentEntity.owned_by?(conference_room, "mgr1")
      assert AgentEntity.owned_by?(transferred_room, "mgr2")
      refute AgentEntity.owned_by?(transferred_room, "mgr1")
    end

    test "shared resource with multiple potential owners" do
      timeline = Timeline.new()

      # Create multiple agents who can use the same equipment
      operator1 =
        AgentEntity.create_agent(
          "op1",
          "Operator Alice",
          %{shift: "morning"},
          capabilities: [:machine_operation, :safety_protocols]
        )

      operator2 =
        AgentEntity.create_agent(
          "op2",
          "Operator Bob",
          %{shift: "afternoon"},
          capabilities: [:machine_operation, :safety_protocols, :maintenance]
        )

      # Shared equipment (entity)
      cnc_machine =
        AgentEntity.create_entity(
          "cnc1",
          "CNC Machine #1",
          %{model: "Haas VF-2", status: "operational"}
        )

      # Sequential usage by different operators
      morning_shift =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: cnc_machine,
          agent: operator1,
          label: "Morning Production",
          metadata: %{required_capabilities: [:machine_operation]}
        )

      afternoon_shift =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 17:00:00], "Etc/UTC"),
          entity: cnc_machine,
          agent: operator2,
          label: "Afternoon Production + Maintenance",
          metadata: %{required_capabilities: [:machine_operation, :maintenance]}
        )

      # Add constraint for shift change (1 hour break)
      timeline =
        timeline
        |> Timeline.add_interval(morning_shift)
        |> Timeline.add_interval(afternoon_shift)
        # 1 hour gap
        |> Timeline.add_constraint(
          "#{morning_shift.id}_end",
          "#{afternoon_shift.id}_start",
          {3600, 3600}
        )

      assert Timeline.consistent?(timeline)

      # Verify both operators can use the machine
      assert AgentEntity.has_capability?(operator1, :machine_operation)
      assert AgentEntity.has_capability?(operator2, :machine_operation)
      assert AgentEntity.has_capability?(operator2, :maintenance)
      refute AgentEntity.has_capability?(operator1, :maintenance)
    end
  end

  describe "STN solving with capability constraints" do
    test "PC-2 algorithm with agent capability dependencies" do
      timeline = Timeline.new()

      # Create a complex scenario with capability dependencies
      architect =
        AgentEntity.create_agent(
          "arch1",
          "Senior Architect",
          %{certification: "licensed"},
          capabilities: [:design, :planning, :approval, :decision_making]
        )

      engineer =
        AgentEntity.create_agent(
          "eng1",
          "Structural Engineer",
          %{specialty: "structural"},
          capabilities: [:engineering_analysis, :calculations, :technical_review]
        )

      contractor =
        AgentEntity.create_agent(
          "cont1",
          "General Contractor",
          %{license: "commercial"},
          capabilities: [:construction, :project_management, :resource_coordination]
        )

      # Sequential phases with dependencies
      design_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: architect,
          label: "Architectural Design",
          metadata: %{required_capabilities: [:design, :planning]}
        )

      engineering_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          agent: engineer,
          label: "Structural Analysis",
          metadata: %{
            required_capabilities: [:engineering_analysis],
            depends_on: [design_phase.id]
          }
        )

      construction_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-02 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-05 17:00:00], "Etc/UTC"),
          agent: contractor,
          label: "Construction",
          metadata: %{required_capabilities: [:construction], depends_on: [engineering_phase.id]}
        )

      # Add intervals and constraints
      timeline =
        timeline
        |> Timeline.add_interval(design_phase)
        |> Timeline.add_interval(engineering_phase)
        |> Timeline.add_interval(construction_phase)
        # 1 hour gap
        |> Timeline.add_constraint(
          "#{design_phase.id}_end",
          "#{engineering_phase.id}_start",
          {3600, 3600}
        )
        # 16 hour gap (overnight)
        |> Timeline.add_constraint(
          "#{engineering_phase.id}_end",
          "#{construction_phase.id}_start",
          {57600, 57600}
        )

      # Apply PC-2 algorithm
      solved_timeline = Timeline.apply_pc2(timeline)
      assert Timeline.consistent?(solved_timeline)

      # Verify constraint propagation worked
      design_to_construction =
        Timeline.get_constraint(
          solved_timeline,
          "#{design_phase.id}_end",
          "#{construction_phase.id}_start"
        )

      # Should have propagated the minimum delay through the chain
      assert design_to_construction != nil
      {min_delay, _max_delay} = design_to_construction
      # The actual propagated constraint should be at least the sum of the explicit gaps
      # PC-2 may not include the full engineering duration in this specific constraint
      # sum of explicit gaps between phases
      assert min_delay >= 3600 + 57600
    end

    test "temporal consistency with dynamic capability changes" do
      timeline = Timeline.new()

      # Device that gains capabilities through software updates
      iot_device =
        AgentEntity.create_entity(
          "iot1",
          "Smart Sensor",
          %{firmware: "1.0", battery: 100}
        )

      # Phase 1: Basic sensing (entity)
      sensing_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          entity: iot_device,
          label: "Basic Sensing"
        )

      # Phase 2: Firmware update gives communication capability
      updated_device =
        AgentEntity.add_capabilities(iot_device, [:communication, :data_transmission])

      communication_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          agent: updated_device,
          label: "Smart Communication",
          metadata: %{required_capabilities: [:communication]}
        )

      # Phase 3: AI update gives decision-making capability
      ai_device =
        AgentEntity.add_capabilities(updated_device, [:decision_making, :autonomous_operation])

      autonomous_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 18:00:00], "Etc/UTC"),
          agent: ai_device,
          label: "Autonomous Operation",
          metadata: %{required_capabilities: [:decision_making, :autonomous_operation]}
        )

      # Add sequential constraints
      timeline =
        timeline
        |> Timeline.add_interval(sensing_phase)
        |> Timeline.add_interval(communication_phase)
        |> Timeline.add_interval(autonomous_phase)
        |> Timeline.add_constraint(
          "#{sensing_phase.id}_end",
          "#{communication_phase.id}_start",
          {0, 0}
        )
        |> Timeline.add_constraint(
          "#{communication_phase.id}_end",
          "#{autonomous_phase.id}_start",
          {0, 0}
        )

      # Solve and verify consistency
      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)

      # Verify capability progression is maintained
      refute AgentEntity.is_currently_agent?(iot_device)
      assert AgentEntity.is_currently_agent?(updated_device)
      assert AgentEntity.is_currently_agent?(ai_device)
      assert AgentEntity.has_capability?(ai_device, :autonomous_operation)
    end
  end

  describe "complex real-world scenarios" do
    test "hospital surgery scheduling with specialized capabilities" do
      timeline = Timeline.new()

      # Create medical team with different specializations
      cardiac_surgeon =
        AgentEntity.create_agent(
          "surgeon_cardiac",
          "Dr. Heart",
          %{specialty: "cardiothoracic", years_experience: 15},
          capabilities: [:cardiac_surgery, :decision_making, :medical_expertise, :leadership]
        )

      anesthesiologist =
        AgentEntity.create_agent(
          "anesthesia1",
          "Dr. Sleep",
          %{specialty: "anesthesiology", certification: "board_certified"},
          capabilities: [:anesthesia_management, :patient_monitoring, :emergency_response]
        )

      surgical_nurse =
        AgentEntity.create_agent(
          "nurse_surgical",
          "Nurse Precision",
          %{specialty: "OR", certification: "CNOR"},
          capabilities: [:surgical_assistance, :sterile_technique, :equipment_management]
        )

      # Operating room (entity with specific capabilities)
      operating_room =
        AgentEntity.create_entity(
          "or_1",
          "Operating Room 1",
          %{equipment: ["heart_lung_machine", "monitors", "surgical_tools"], sterile: true}
        )

      # Pre-op phase
      pre_op =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 07:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          entity: operating_room,
          agent: surgical_nurse,
          label: "Pre-operative Setup",
          metadata: %{required_capabilities: [:sterile_technique, :equipment_management]}
        )

      # Anesthesia induction
      anesthesia_induction =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 08:30:00], "Etc/UTC"),
          entity: operating_room,
          agent: anesthesiologist,
          label: "Anesthesia Induction",
          metadata: %{required_capabilities: [:anesthesia_management]}
        )

      # Main surgery
      cardiac_surgery =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:30:00], "Etc/UTC"),
          entity: operating_room,
          agent: cardiac_surgeon,
          label: "Cardiac Surgery",
          metadata: %{
            required_capabilities: [:cardiac_surgery, :medical_expertise],
            supporting_agents: [anesthesiologist.id, surgical_nurse.id]
          }
        )

      # Recovery
      recovery =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:30:00], "Etc/UTC"),
          entity: operating_room,
          agent: anesthesiologist,
          label: "Recovery and Extubation",
          metadata: %{required_capabilities: [:anesthesia_management, :patient_monitoring]}
        )

      # Add all intervals with proper sequencing
      timeline =
        timeline
        |> Timeline.add_interval(pre_op)
        |> Timeline.add_interval(anesthesia_induction)
        |> Timeline.add_interval(cardiac_surgery)
        |> Timeline.add_interval(recovery)
        |> Timeline.add_constraint("#{pre_op.id}_end", "#{anesthesia_induction.id}_start", {0, 0})
        |> Timeline.add_constraint(
          "#{anesthesia_induction.id}_end",
          "#{cardiac_surgery.id}_start",
          {0, 0}
        )
        |> Timeline.add_constraint("#{cardiac_surgery.id}_end", "#{recovery.id}_start", {0, 0})

      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)

      # Verify all required capabilities are present
      assert AgentEntity.has_capability?(cardiac_surgeon, :cardiac_surgery)
      assert AgentEntity.has_capability?(anesthesiologist, :anesthesia_management)
      assert AgentEntity.has_capability?(surgical_nurse, :sterile_technique)

      # Verify timeline has all phases
      assert length(Map.keys(solved_timeline.intervals)) == 4
    end

    test "autonomous vehicle fleet coordination" do
      timeline = Timeline.new()

      # Create fleet of vehicles with different capabilities
      delivery_truck =
        AgentEntity.create_entity(
          "truck1",
          "Delivery Truck Alpha",
          %{capacity: 1000, fuel: 80, location: "depot"}
        )

      passenger_car =
        AgentEntity.create_entity(
          "car1",
          "Autonomous Sedan",
          %{capacity: 4, battery: 90, location: "downtown"}
        )

      # Vehicles gain autonomous capabilities when activated
      autonomous_truck =
        AgentEntity.add_capabilities(
          delivery_truck,
          [:autonomous_driving, :navigation, :decision_making, :cargo_management]
        )

      autonomous_car =
        AgentEntity.add_capabilities(
          passenger_car,
          [:autonomous_driving, :navigation, :decision_making, :passenger_service]
        )

      # Delivery mission
      delivery_mission =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          agent: autonomous_truck,
          label: "Package Delivery Route",
          metadata: %{
            required_capabilities: [:autonomous_driving, :cargo_management],
            route: ["depot", "customer_a", "customer_b", "depot"]
          }
        )

      # Passenger transport
      passenger_trip =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC"),
          agent: autonomous_car,
          label: "Passenger Transport",
          metadata: %{
            required_capabilities: [:autonomous_driving, :passenger_service],
            route: ["downtown", "airport"]
          }
        )

      # Maintenance window (vehicles become entities)
      maintenance_truck =
        AgentEntity.remove_capabilities(
          autonomous_truck,
          [:autonomous_driving, :navigation, :decision_making]
        )

      truck_maintenance =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: maintenance_truck,
          label: "Truck Maintenance",
          metadata: %{maintenance_type: "routine_service"}
        )

      timeline =
        timeline
        |> Timeline.add_interval(delivery_mission)
        |> Timeline.add_interval(passenger_trip)
        |> Timeline.add_interval(truck_maintenance)
        |> Timeline.add_constraint(
          "#{delivery_mission.id}_end",
          "#{truck_maintenance.id}_start",
          {0, 0}
        )

      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)

      # Verify capability transitions
      assert AgentEntity.is_currently_agent?(autonomous_truck)
      assert AgentEntity.is_currently_agent?(autonomous_car)
      refute AgentEntity.is_currently_agent?(maintenance_truck)

      # Verify specialized capabilities
      assert AgentEntity.has_capability?(autonomous_truck, :cargo_management)
      assert AgentEntity.has_capability?(autonomous_car, :passenger_service)
    end
  end
end
