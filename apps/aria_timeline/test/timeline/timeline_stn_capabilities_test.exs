# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.STNCapabilitiesTest do
  use ExUnit.Case, async: true
  alias Timeline
  alias Timeline.Interval
  alias Timeline.AgentEntity

  describe("PC-2 algorithm with capability constraints") do
    test "propagates constraints through capability-dependent chain" do
      timeline = Timeline.new()

      architect =
        AgentEntity.create_agent("arch1", "Senior Architect", %{certification: "licensed"},
          capabilities: [:design, :planning, :approval]
        )

      engineer =
        AgentEntity.create_agent("eng1", "Structural Engineer", %{specialty: "structural"},
          capabilities: [:engineering_analysis, :calculations]
        )

      contractor =
        AgentEntity.create_agent("cont1", "General Contractor", %{license: "commercial"},
          capabilities: [:construction, :project_management]
        )

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

      timeline =
        timeline
        |> Timeline.add_interval(design_phase)
        |> Timeline.add_interval(engineering_phase)
        |> Timeline.add_interval(construction_phase)
        |> Timeline.add_constraint(
          "#{design_phase.id}_end",
          "#{engineering_phase.id}_start",
          {3600, 3600}
        )
        |> Timeline.add_constraint(
          "#{engineering_phase.id}_end",
          "#{construction_phase.id}_start",
          {57600, 57600}
        )

      solved_timeline = Timeline.apply_pc2(timeline)
      assert Timeline.consistent?(solved_timeline)
      assert AgentEntity.has_capability?(architect, :design)
      assert AgentEntity.has_capability?(engineer, :engineering_analysis)
      assert AgentEntity.has_capability?(contractor, :construction)
    end

    test "handles temporal consistency with dynamic capability changes" do
      timeline = Timeline.new()

      iot_device =
        AgentEntity.create_entity("iot1", "Smart Sensor", %{firmware: "1.0", battery: 100})

      sensing_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          entity: iot_device,
          label: "Basic Sensing"
        )

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

      timeline =
        timeline
        |> Timeline.add_interval(sensing_phase)
        |> Timeline.add_interval(communication_phase)
        |> Timeline.add_interval(autonomous_phase)
        |> Timeline.add_constraint(
          "#{sensing_phase.id}_end",
          "#{communication_phase.id}_start",
          {-1, 1}
        )
        |> Timeline.add_constraint(
          "#{communication_phase.id}_end",
          "#{autonomous_phase.id}_start",
          {-1, 1}
        )

      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)
      refute AgentEntity.is_currently_agent?(iot_device)
      assert AgentEntity.is_currently_agent?(updated_device)
      assert AgentEntity.is_currently_agent?(ai_device)
      assert AgentEntity.has_capability?(ai_device, :autonomous_operation)
    end
  end

  describe("constraint solving with agent capabilities") do
    test "solves timeline with capability-dependent scheduling" do
      timeline = Timeline.new()

      surgeon =
        AgentEntity.create_agent("surgeon1", "Cardiac Surgeon", %{specialty: "heart"},
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
        AgentEntity.create_entity("or_1", "Operating Room 1", %{
          equipment: ["heart_lung_machine", "monitors"]
        })

      prep_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 07:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          entity: operating_room,
          agent: anesthesiologist,
          label: "Pre-operative Setup",
          metadata: %{required_capabilities: [:anesthesia_management]}
        )

      surgery_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: operating_room,
          agent: surgeon,
          label: "Cardiac Surgery",
          metadata: %{required_capabilities: [:cardiac_surgery, :medical_expertise]}
        )

      recovery_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          entity: operating_room,
          agent: anesthesiologist,
          label: "Recovery Monitoring",
          metadata: %{required_capabilities: [:patient_monitoring]}
        )

      timeline =
        timeline
        |> Timeline.add_interval(prep_phase)
        |> Timeline.add_interval(surgery_phase)
        |> Timeline.add_interval(recovery_phase)
        |> Timeline.add_constraint("#{prep_phase.id}_end", "#{surgery_phase.id}_start", {-1, 1})
        |> Timeline.add_constraint(
          "#{surgery_phase.id}_end",
          "#{recovery_phase.id}_start",
          {-1, 1}
        )

      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)
      assert AgentEntity.has_capability?(surgeon, :cardiac_surgery)
      assert AgentEntity.has_capability?(anesthesiologist, :anesthesia_management)
      assert AgentEntity.has_capability?(anesthesiologist, :patient_monitoring)
    end

    test "handles constraint propagation with capability transitions" do
      timeline = Timeline.new()
      robot = AgentEntity.create_entity("robot1", "Industrial Robot", %{mode: "offline"})

      offline_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          entity: robot,
          label: "Offline Mode"
        )

      manual_robot = AgentEntity.add_capabilities(robot, [:manual_operation, :safety_monitoring])

      manual_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: manual_robot,
          label: "Manual Operation",
          metadata: %{required_capabilities: [:manual_operation]}
        )

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

      timeline =
        timeline
        |> Timeline.add_interval(offline_phase)
        |> Timeline.add_interval(manual_phase)
        |> Timeline.add_interval(auto_phase)
        |> Timeline.add_constraint("#{offline_phase.id}_end", "#{manual_phase.id}_start", {-1, 1})
        |> Timeline.add_constraint("#{manual_phase.id}_end", "#{auto_phase.id}_start", {-1, 1})

      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)
      refute AgentEntity.is_currently_agent?(robot)
      assert AgentEntity.is_currently_agent?(manual_robot)
      assert AgentEntity.is_currently_agent?(auto_robot)
      assert AgentEntity.has_capability?(auto_robot, :autonomous_operation)
    end
  end

  describe("temporal network consistency with capabilities") do
    test "validates complex capability-dependent network" do
      timeline = Timeline.new()

      project_manager =
        AgentEntity.create_agent("pm1", "Project Manager",
          capabilities: [:planning, :coordination, :resource_allocation]
        )

      lead_developer =
        AgentEntity.create_agent("dev1", "Lead Developer",
          capabilities: [:architecture_design, :code_review, :technical_leadership]
        )

      qa_engineer =
        AgentEntity.create_agent("qa1", "QA Engineer",
          capabilities: [:test_planning, :automation, :quality_validation]
        )

      planning =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          agent: project_manager,
          label: "Project Planning",
          metadata: %{required_capabilities: [:planning, :resource_allocation]}
        )

      architecture =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          agent: lead_developer,
          label: "Architecture Design",
          metadata: %{required_capabilities: [:architecture_design]}
        )

      test_planning =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          agent: qa_engineer,
          label: "Test Planning",
          metadata: %{required_capabilities: [:test_planning]}
        )

      timeline =
        timeline
        |> Timeline.add_interval(planning)
        |> Timeline.add_interval(architecture)
        |> Timeline.add_interval(test_planning)
        |> Timeline.add_constraint("#{planning.id}_end", "#{architecture.id}_start", {-1, 1})
        |> Timeline.add_constraint(
          "#{planning.id}_end",
          "#{test_planning.id}_start",
          {7200, 7200}
        )

      solved_timeline = Timeline.solve(timeline)
      assert Timeline.consistent?(solved_timeline)
      assert AgentEntity.has_capability?(project_manager, :planning)
      assert AgentEntity.has_capability?(lead_developer, :architecture_design)
      assert AgentEntity.has_capability?(qa_engineer, :test_planning)
    end

    test "detects inconsistencies in capability-constrained networks" do
      timeline = Timeline.new()

      specialist =
        AgentEntity.create_agent("spec1", "Specialist",
          capabilities: [:specialized_task, :quality_control]
        )

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

      timeline = timeline |> Timeline.add_interval(task1) |> Timeline.add_interval(task2)
      assert Timeline.consistent?(timeline)

      constrained_timeline =
        Timeline.add_constraint(
          timeline,
          "#{task2.id}_start",
          "#{task1.id}_end",
          {-7200, -3600}
        )

      assert Timeline.consistent?(constrained_timeline)
    end
  end
end
