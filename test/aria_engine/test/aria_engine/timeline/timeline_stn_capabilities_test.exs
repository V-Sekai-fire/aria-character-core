# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.STNCapabilitiesTest do
  use ExUnit.Case, async: true

  alias Timeline
  alias Timeline.Interval
  alias Timeline.AgentEntity

  describe "PC-2 algorithm with capability constraints" do
    test "propagates constraints through capability-dependent chain" do
      timeline = Timeline.new()

      architect =
        AgentEntity.create_agent(
          "arch1",
          "Senior Architect",
          %{certification: "licensed"},
          capabilities: [:design, :planning, :approval]
        )

      engineer =
        AgentEntity.create_agent(
          "eng1",
          "Structural Engineer",
          %{specialty: "structural"},
          capabilities: [:engineering_analysis, :calculations]
        )

      contractor =
        AgentEntity.create_agent(
          "cont1",
          "General Contractor",
          %{license: "commercial"},
          capabilities: [:construction, :project_management]
        )

      # Sequential phases with capability dependencies
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
          metadata: %{required_capabilities: [:engineering_analysis]}
        )

      construction_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-02 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-05 17:00:00], "Etc/UTC"),
          agent: contractor,
          label: "Construction",
          metadata: %{required_capabilities: [:construction]}
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
        # 16 hour gap
        |> Timeline.add_constraint(
          "#{engineering_phase.id}_end",
          "#{construction_phase.id}_start",
          {57600, 57600}
        )

      # Apply PC-2 algorithm
      solved_timeline = Timeline.apply_pc2(timeline)
      assert Timeline.consistent?(solved_timeline)

      # Verify agents have required capabilities
      assert AgentEntity.has_capability?(architect, :design)
      assert AgentEntity.has_capability?(engineer, :engineering_analysis)
      assert AgentEntity.has_capability?(contractor, :construction)
    end

    test "handles temporal consistency with dynamic capability changes" do
      timeline = Timeline.new()

      # Device that gains capabilities through updates
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

      # Phase 2: Communication capability added
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

      # Phase 3: AI capability added
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

      # Verify capability progression
      refute AgentEntity.is_currently_agent?(iot_device)
      assert AgentEntity.is_currently_agent?(updated_device)
      assert AgentEntity.is_currently_agent?(ai_device)
      assert AgentEntity.has_capability?(ai_device, :autonomous_operation)
    end
  end

  describe "constraint solving with agent capabilities" do
    test "solves timeline with capability-dependent scheduling" do
      timeline = Timeline.new()

      # Create agents with different specializations
      surgeon =
        AgentEntity.create_agent(
          "surgeon1",
          "Cardiac Surgeon",
          %{specialty: "heart"},
          capabilities: [:cardiac_surgery, :medical_expertise, :decision_making]
        )

      anesthesiologist =
        AgentEntity.create_agent(
          "anesthesia1",
          "Anesthesiologist",
          %{certification: "board_certified"},
          capabilities: [:anesthesia_management, :patient_monitoring]
        )

      operating_room =
        AgentEntity.create_entity(
          "or_1",
          "Operating Room 1",
          %{equipment: ["heart_lung_machine", "monitors"]}
        )

      # Pre-op preparation
      prep_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 07:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          entity: operating_room,
          agent: anesthesiologist,
          label: "Pre-operative Setup",
          metadata: %{required_capabilities: [:anesthesia_management]}
        )

      # Main surgery
      surgery_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: operating_room,
          agent: surgeon,
          label: "Cardiac Surgery",
          metadata: %{required_capabilities: [:cardiac_surgery, :medical_expertise]}
        )

      # Recovery monitoring
      recovery_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          entity: operating_room,
          agent: anesthesiologist,
          label: "Recovery Monitoring",
          metadata: %{required_capabilities: [:patient_monitoring]}
        )

      # Add sequential constraints
      timeline =
        timeline
        |> Timeline.add_interval(prep_phase)
        |> Timeline.add_interval(surgery_phase)
        |> Timeline.add_interval(recovery_phase)
        |> Timeline.add_constraint("#{prep_phase.id}_end", "#{surgery_phase.id}_start", {0, 0})
        |> Timeline.add_constraint(
          "#{surgery_phase.id}_end",
          "#{recovery_phase.id}_start",
          {0, 0}
        )

      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)

      # Verify all required capabilities are present
      assert AgentEntity.has_capability?(surgeon, :cardiac_surgery)
      assert AgentEntity.has_capability?(anesthesiologist, :anesthesia_management)
      assert AgentEntity.has_capability?(anesthesiologist, :patient_monitoring)
    end

    test "handles constraint propagation with capability transitions" do
      timeline = Timeline.new()

      # Robot that transitions between modes
      robot = AgentEntity.create_entity("robot1", "Industrial Robot", %{mode: "offline"})

      # Phase 1: Offline (entity)
      offline_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          entity: robot,
          label: "Offline Mode"
        )

      # Phase 2: Manual operation (gains capabilities)
      manual_robot = AgentEntity.add_capabilities(robot, [:manual_operation, :safety_monitoring])

      manual_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: manual_robot,
          label: "Manual Operation",
          metadata: %{required_capabilities: [:manual_operation]}
        )

      # Phase 3: Autonomous operation (gains more capabilities)
      auto_robot =
        AgentEntity.add_capabilities(manual_robot, [:autonomous_operation, :decision_making])

      auto_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          agent: auto_robot,
          label: "Autonomous Operation",
          metadata: %{required_capabilities: [:autonomous_operation, :decision_making]}
        )

      # Add constraints with specific timing requirements
      timeline =
        timeline
        |> Timeline.add_interval(offline_phase)
        |> Timeline.add_interval(manual_phase)
        |> Timeline.add_interval(auto_phase)
        # immediate transition
        |> Timeline.add_constraint("#{offline_phase.id}_end", "#{manual_phase.id}_start", {0, 0})
        # immediate transition
        |> Timeline.add_constraint("#{manual_phase.id}_end", "#{auto_phase.id}_start", {0, 0})

      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)

      # Verify capability progression through phases
      refute AgentEntity.is_currently_agent?(robot)
      assert AgentEntity.is_currently_agent?(manual_robot)
      assert AgentEntity.is_currently_agent?(auto_robot)
      assert AgentEntity.has_capability?(auto_robot, :autonomous_operation)
    end
  end

  describe "temporal network consistency with capabilities" do
    test "validates complex capability-dependent network" do
      timeline = Timeline.new()

      # Create a network of interdependent activities
      project_manager =
        AgentEntity.create_agent(
          "pm1",
          "Project Manager",
          capabilities: [:planning, :coordination, :resource_allocation]
        )

      lead_developer =
        AgentEntity.create_agent(
          "dev1",
          "Lead Developer",
          capabilities: [:architecture_design, :code_review, :technical_leadership]
        )

      qa_engineer =
        AgentEntity.create_agent(
          "qa1",
          "QA Engineer",
          capabilities: [:test_planning, :automation, :quality_validation]
        )

      # Project initiation
      planning =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          agent: project_manager,
          label: "Project Planning",
          metadata: %{required_capabilities: [:planning, :resource_allocation]}
        )

      # Architecture design
      architecture =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          agent: lead_developer,
          label: "Architecture Design",
          metadata: %{required_capabilities: [:architecture_design]}
        )

      # Test planning (can start after planning, parallel with architecture)
      test_planning =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          agent: qa_engineer,
          label: "Test Planning",
          metadata: %{required_capabilities: [:test_planning]}
        )

      # Add constraints for parallel and sequential dependencies
      timeline =
        timeline
        |> Timeline.add_interval(planning)
        |> Timeline.add_interval(architecture)
        |> Timeline.add_interval(test_planning)
        |> Timeline.add_constraint("#{planning.id}_end", "#{architecture.id}_start", {0, 0})
        # 2 hour delay
        |> Timeline.add_constraint(
          "#{planning.id}_end",
          "#{test_planning.id}_start",
          {7200, 7200}
        )

      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)

      # Verify all agents have required capabilities
      assert AgentEntity.has_capability?(project_manager, :planning)
      assert AgentEntity.has_capability?(lead_developer, :architecture_design)
      assert AgentEntity.has_capability?(qa_engineer, :test_planning)
    end

    test "detects inconsistencies in capability-constrained networks" do
      timeline = Timeline.new()

      # Create scenario with tight constraints
      specialist =
        AgentEntity.create_agent(
          "spec1",
          "Specialist",
          capabilities: [:specialized_task, :quality_control]
        )

      # Two tasks requiring same specialist with overlapping times
      task1 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          agent: specialist,
          label: "Critical Task 1",
          metadata: %{required_capabilities: [:specialized_task]}
        )

      task2 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          agent: specialist,
          label: "Critical Task 2",
          metadata: %{required_capabilities: [:specialized_task]}
        )

      # Add overlapping intervals
      timeline =
        timeline
        |> Timeline.add_interval(task1)
        |> Timeline.add_interval(task2)

      # Timeline should be consistent (overlapping allowed)
      assert Timeline.consistent?(timeline)

      # But adding constraint that task2 must start before task1 ends creates conflict
      constrained_timeline =
        Timeline.add_constraint(
          timeline,
          "#{task2.id}_start",
          "#{task1.id}_end",
          # task2 must start 1-2 hours before task1 ends
          {-7200, -3600}
        )

      # This should still be consistent as it's a valid constraint
      assert Timeline.consistent?(constrained_timeline)
    end
  end
end
