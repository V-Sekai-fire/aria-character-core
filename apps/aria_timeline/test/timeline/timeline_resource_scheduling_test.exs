# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.ResourceSchedulingTest do
  use ExUnit.Case, async: true
  alias Timeline
  alias Timeline.Interval
  alias Timeline.AgentEntity

  describe("capability-dependent activity assignment") do
    test "assigns surgery to qualified surgeon" do
      timeline = Timeline.new()

      surgeon =
        AgentEntity.create_agent("surgeon1", "Dr. Smith", %{specialty: "cardiac"},
          capabilities: [:surgery, :decision_making, :medical_expertise]
        )

      nurse =
        AgentEntity.create_agent("nurse1", "Nurse Johnson", %{certification: "RN"},
          capabilities: [:patient_care, :communication]
        )

      surgery_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: surgeon,
          label: "Heart Surgery",
          metadata: %{required_capabilities: [:surgery, :medical_expertise]}
        )

      care_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          agent: nurse,
          label: "Post-op Care",
          metadata: %{required_capabilities: [:patient_care]}
        )

      updated_timeline =
        timeline
        |> Timeline.add_interval(surgery_interval)
        |> Timeline.add_interval(care_interval)

      assert Timeline.consistent?(updated_timeline)
      assert AgentEntity.has_capability?(surgeon, :surgery)
      assert AgentEntity.has_capability?(nurse, :patient_care)
      refute AgentEntity.has_capability?(nurse, :surgery)
    end

    test "assigns specialized manufacturing tasks correctly" do
      timeline = Timeline.new()

      welder =
        AgentEntity.create_agent("welder1", "Certified Welder", %{certification: "AWS D1.1"},
          capabilities: [:welding, :safety_protocols]
        )

      assembler =
        AgentEntity.create_agent("assembler1", "Assembly Tech", %{experience: "5 years"},
          capabilities: [:assembly, :blueprint_reading]
        )

      welding_station =
        AgentEntity.create_entity("weld_station_1", "Welding Station #1", %{
          equipment: ["MIG_welder", "safety_booth"]
        })

      welding_task =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          entity: welding_station,
          agent: welder,
          label: "Component Welding",
          metadata: %{required_capabilities: [:welding, :safety_protocols]}
        )

      assembly_task =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:30:00], "Etc/UTC"),
          agent: assembler,
          label: "Final Assembly",
          metadata: %{required_capabilities: [:assembly, :blueprint_reading]}
        )

      updated_timeline =
        timeline |> Timeline.add_interval(welding_task) |> Timeline.add_interval(assembly_task)

      assert Timeline.consistent?(updated_timeline)
      assert AgentEntity.has_capability?(welder, :welding)
      assert AgentEntity.has_capability?(assembler, :assembly)
    end
  end

  describe("resource conflicts with capability requirements") do
    test "detects pilot scheduling conflict" do
      timeline = Timeline.new()

      pilot =
        AgentEntity.create_agent("pilot1", "Captain Smith", %{license: "commercial"},
          capabilities: [:flying, :navigation, :decision_making]
        )

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

      updated_timeline =
        timeline |> Timeline.add_interval(flight1) |> Timeline.add_interval(flight2)

      assert Timeline.consistent?(updated_timeline)

      sequential_timeline =
        Timeline.add_constraint(
          updated_timeline,
          "#{flight1.id}_end",
          "#{flight2.id}_start",
          {0, :infinity}
        )

      assert Timeline.consistent?(sequential_timeline)
    end

    test "handles shared equipment with different operators" do
      timeline = Timeline.new()

      operator1 =
        AgentEntity.create_agent("op1", "Morning Operator", %{shift: "morning"},
          capabilities: [:machine_operation, :safety_protocols]
        )

      operator2 =
        AgentEntity.create_agent("op2", "Afternoon Operator", %{shift: "afternoon"},
          capabilities: [:machine_operation, :maintenance]
        )

      cnc_machine = AgentEntity.create_entity("cnc1", "CNC Machine #1", %{model: "Haas VF-2"})

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
          label: "Afternoon Production",
          metadata: %{required_capabilities: [:machine_operation]}
        )

      updated_timeline =
        timeline
        |> Timeline.add_interval(morning_shift)
        |> Timeline.add_interval(afternoon_shift)
        |> Timeline.add_constraint(
          "#{morning_shift.id}_end",
          "#{afternoon_shift.id}_start",
          {3600, 3600}
        )

      assert Timeline.consistent?(updated_timeline)
      assert AgentEntity.has_capability?(operator1, :machine_operation)
      assert AgentEntity.has_capability?(operator2, :machine_operation)
      assert AgentEntity.has_capability?(operator2, :maintenance)
    end
  end

  describe("multi-agent coordination") do
    test "coordinates project team with complementary capabilities" do
      timeline = Timeline.new()

      project_manager =
        AgentEntity.create_agent("pm1", "Alice Manager", %{experience: "10 years"},
          capabilities: [:planning, :coordination, :decision_making]
        )

      developer =
        AgentEntity.create_agent("dev1", "Bob Developer", %{language: "Elixir"},
          capabilities: [:coding, :problem_solving]
        )

      tester =
        AgentEntity.create_agent("qa1", "Carol Tester", %{specialty: "automation"},
          capabilities: [:testing, :quality_assurance]
        )

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
          metadata: %{required_capabilities: [:coding]}
        )

      testing_phase =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          agent: tester,
          label: "Testing",
          metadata: %{required_capabilities: [:testing]}
        )

      updated_timeline =
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

      assert Timeline.consistent?(updated_timeline)
      assert AgentEntity.has_capability?(project_manager, :planning)
      assert AgentEntity.has_capability?(developer, :coding)
      assert AgentEntity.has_capability?(tester, :testing)
    end

    test "handles emergency response with multiple specialists" do
      timeline = Timeline.new()

      fire_chief =
        AgentEntity.create_agent("chief1", "Fire Chief", %{rank: "chief"},
          capabilities: [:incident_command, :decision_making, :coordination]
        )

      paramedic =
        AgentEntity.create_agent("medic1", "Paramedic", %{certification: "EMT-P"},
          capabilities: [:emergency_medical, :patient_transport]
        )

      firefighter =
        AgentEntity.create_agent("ff1", "Firefighter", %{specialty: "rescue"},
          capabilities: [:fire_suppression, :rescue_operations]
        )

      command_setup =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 14:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:35:00], "Etc/UTC"),
          agent: fire_chief,
          label: "Incident Command Setup",
          metadata: %{required_capabilities: [:incident_command]}
        )

      rescue_operation =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 14:35:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          agent: firefighter,
          label: "Victim Rescue",
          metadata: %{required_capabilities: [:rescue_operations]}
        )

      medical_treatment =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 15:30:00], "Etc/UTC"),
          agent: paramedic,
          label: "Medical Treatment",
          metadata: %{required_capabilities: [:emergency_medical]}
        )

      updated_timeline =
        timeline
        |> Timeline.add_interval(command_setup)
        |> Timeline.add_interval(rescue_operation)
        |> Timeline.add_interval(medical_treatment)
        |> Timeline.add_constraint(
          "#{command_setup.id}_end",
          "#{rescue_operation.id}_start",
          {0, 0}
        )
        |> Timeline.add_constraint(
          "#{rescue_operation.id}_end",
          "#{medical_treatment.id}_start",
          {0, 0}
        )

      assert Timeline.consistent?(updated_timeline)
      assert AgentEntity.has_capability?(fire_chief, :incident_command)
      assert AgentEntity.has_capability?(firefighter, :rescue_operations)
      assert AgentEntity.has_capability?(paramedic, :emergency_medical)
    end
  end
end
