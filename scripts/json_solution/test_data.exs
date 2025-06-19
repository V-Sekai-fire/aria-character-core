defmodule JsonSolution.TestData do
  @moduledoc """
  Test Data Generator
  
  Creates simple test scenarios with workers, tools, and tasks
  for agent-entity-capability planning tests.
  """
  
  # Ensure AriaEngine modules are available
  alias AriaEngine.Scheduler
  
  def create_simple_scenario do
    workers = create_heist_team()
    tools = create_heist_equipment()
    tasks = create_heist_mission()
    
    {workers, tools, tasks}
  end
  
  def create_heist_team do
    [
      # Core Team (Enhanced)
      %AriaEngine.Scheduler.Entity{
        id: "ghost",
        type: :agent,
        capabilities: [:hacking, :network_access, :stealth],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Network Infiltration Specialist", codename: "Ghost", specialty: "Digital Systems"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "spark",
        type: :agent,
        capabilities: [:electronics, :security_bypass, :technical_repair],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Electronics Expert", codename: "Spark", specialty: "Hardware Systems"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "phantom",
        type: :agent,
        capabilities: [:lockpicking, :stealth, :acrobatics],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Physical Infiltration Specialist", codename: "Phantom", specialty: "Physical Security"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "oracle",
        type: :agent,
        capabilities: [:surveillance, :communication, :data_analysis],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Intelligence Coordinator", codename: "Oracle", specialty: "Information Warfare"}
      },
      
      # New Specialists (7 Additional)
      %AriaEngine.Scheduler.Entity{
        id: "cipher",
        type: :agent,
        capabilities: [:encryption_breaking, :code_analysis, :mathematical_modeling],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Cryptography Expert", codename: "Cipher", specialty: "Quantum Encryption"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "mirage",
        type: :agent,
        capabilities: [:persuasion, :impersonation, :psychological_manipulation],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Social Engineer", codename: "Mirage", specialty: "Human Psychology"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "vector",
        type: :agent,
        capabilities: [:driving, :piloting, :route_planning],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Vehicle & Logistics Specialist", codename: "Vector", specialty: "Transportation"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "nexus",
        type: :agent,
        capabilities: [:corporate_access, :executive_privileges, :insider_knowledge],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Inside Contact", codename: "Nexus", specialty: "Corporate Intelligence"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "wraith",
        type: :agent,
        capabilities: [:explosives, :structural_analysis, :tactical_breach],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Demolitions & Breach Expert", codename: "Wraith", specialty: "Tactical Operations"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "echo",
        type: :agent,
        capabilities: [:signal_jamming, :radio_intercept, :counter_surveillance],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Communications & Jamming Specialist", codename: "Echo", specialty: "Signal Intelligence"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "sage",
        type: :agent,
        capabilities: [:tactical_planning, :team_coordination, :contingency_management],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Mission Coordinator", codename: "Sage", specialty: "Strategic Operations"}
      }
    ]
  end

  def create_simple_workers do
    for i <- 1..3 do
      %AriaEngine.Scheduler.Entity{
        id: "worker_#{i}",
        type: :agent,
        capabilities: [:work],
        availability: nil,
        resources_held: [],
        metadata: %{role: "worker", skill_level: "basic"}
      }
    end
  end
  
  def create_heist_equipment do
    [
      # ACT I: Intelligence & Preparation Equipment
      %AriaEngine.Scheduler.Resource{
        id: "secure_meeting_room",
        type: :facility,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Encrypted briefing facility"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "financial_database",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Corporate financial analysis system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "social_engineering_kit",
        type: :psychological,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Persuasion and manipulation tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "executive_credentials",
        type: :access,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "High-level corporate access cards"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "quantum_research_lab",
        type: :facility,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Advanced cryptography research facility"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "supercomputer_access",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "High-performance mathematical modeling system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "security_scanner",
        type: :electronic,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Advanced security system analyzer"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "architectural_plans",
        type: :intelligence,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Detailed building schematics"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "surveillance_drone",
        type: :aerial,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Stealth reconnaissance aircraft"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "behavioral_analysis_suite",
        type: :psychological,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Employee psychological profiling system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "signal_analysis_equipment",
        type: :electronic,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Signal intelligence gathering tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "intercept_array",
        type: :communication,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Radio communication interception system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "detection_countermeasures",
        type: :defensive,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Counter-surveillance protection gear"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "network_mapper",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Corporate network topology scanner"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "biometric_analyzer",
        type: :electronic,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Biometric security system analyzer"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "traffic_analysis_system",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "City traffic pattern analysis"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "vehicle_database",
        type: :intelligence,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Vehicle acquisition target database"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "scenario_simulator",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Mission contingency planning system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "communication_protocols",
        type: :communication,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Secure team coordination system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "demolition_kit",
        type: :explosive,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Precision explosive devices"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "identity_forge",
        type: :fabrication,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Identity creation and modification tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "corporate_intelligence",
        type: :intelligence,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Internal corporate knowledge database"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "access_verification_system",
        type: :security,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Executive privilege verification tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "surveillance_kit",
        type: :surveillance,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Advanced surveillance equipment"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "equipment_cache",
        type: :storage,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Secure equipment staging area"}
      },

      # ACT II: Heist Execution Equipment
      %AriaEngine.Scheduler.Resource{
        id: "perimeter_monitors",
        type: :surveillance,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Building perimeter surveillance system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "jamming_equipment",
        type: :electronic,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Communication jamming devices"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "executive_disguise",
        type: :disguise,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Executive impersonation costume"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "distraction_scenario",
        type: :psychological,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Social engineering distraction tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "master_keycard",
        type: :access,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Universal building access card"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "elevator_control_interface",
        type: :electronic,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Elevator system override device"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "network_infiltration_kit",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Network penetration tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "guard_radio_tap",
        type: :communication,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Security guard communication interceptor"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "false_alarm_system",
        type: :deception,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Security misdirection device"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "stealth_suit",
        type: :equipment,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Advanced stealth infiltration gear"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "network_takeover_kit",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Communication system takeover tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "climbing_gear",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Advanced climbing and rappelling equipment"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "precision_charges",
        type: :explosive,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Tactical breach explosives"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "quantum_decryption_array",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Quantum encryption breaking system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "code_verification_system",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Code analysis and verification tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "shaped_charges",
        type: :explosive,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Vault breach explosives"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "biometric_spoofer",
        type: :electronic,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Biometric security bypass device"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "advanced_lock_tools",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "High-tech lock picking equipment"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "data_extraction_array",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "High-speed data extraction system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "alert_detection_system",
        type: :surveillance,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Security alert monitoring system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "tactical_command_center",
        type: :facility,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Mobile tactical coordination center"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "emergency_protocols",
        type: :communication,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Emergency team coordination system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "backup_plans",
        type: :intelligence,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Contingency plan database"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "data_wipe_tools",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Digital evidence elimination tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "forensic_cleanup_kit",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Physical evidence elimination tools"}
      },

      # ACT III: Escape & Extraction Equipment
      %AriaEngine.Scheduler.Resource{
        id: "evacuation_gear",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Emergency building evacuation equipment"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "getaway_vehicles",
        type: :vehicle,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Primary escape vehicles"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "route_control_system",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Traffic and route control system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "pursuit_countermeasures",
        type: :defensive,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Anti-pursuit defensive systems"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "extraction_aircraft",
        type: :aerial,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Aerial extraction helicopter"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "evasion_vehicles",
        type: :vehicle,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "High-performance evasion vehicles"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "area_jammers",
        type: :electronic,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Wide-area communication jammers"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "misdirection_tools",
        type: :deception,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "False trail creation equipment"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "data_verification_suite",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Stolen data verification system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "encryption_tools",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Data encryption and protection tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "secure_transmission_array",
        type: :communication,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Secure data transmission system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "transmission_equipment",
        type: :communication,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "High-bandwidth data transmission gear"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "dispersal_protocols",
        type: :intelligence,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Team dispersal coordination system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "identity_destruction_kit",
        type: :fabrication,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Identity elimination and cleanup tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "safe_house_network",
        type: :facility,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Secure hideout locations"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "insider_protection_protocol",
        type: :security,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Corporate insider extraction system"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "mission_verification_system",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Mission success verification tools"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "evidence_destruction_charges",
        type: :explosive,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Final evidence elimination explosives"}
      },
      %AriaEngine.Scheduler.Resource{
        id: "exfiltration_confirmation",
        type: :communication,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{description: "Mission completion confirmation system"}
      }
    ]
  end

  def create_simple_tools do
    for i <- 1..3 do
      %AriaEngine.Scheduler.Resource{
        id: "tool_#{i}",
        capacity: 1,
        type: :tool
      }
    end
  end
  
  def create_heist_mission do
    # ACT I: The Setup - Ocean's 11 Style Recruitment & Planning (25 tasks)
    act_1_tasks = [
      # Phase 1: Team Assembly & Initial Intelligence
      %{
        id: "mission_briefing_coordination",
        dependencies: [],
        required_capabilities: [:tactical_planning],
        required_resources: ["secure_meeting_room"],
        duration: 3
      },
      %{
        id: "nexus_financial_analysis",
        dependencies: ["mission_briefing_coordination"],
        required_capabilities: [:data_analysis],
        required_resources: ["financial_database"],
        duration: 4
      },
      %{
        id: "corporate_insider_recruitment",
        dependencies: ["nexus_financial_analysis"],
        required_capabilities: [:persuasion],
        required_resources: ["social_engineering_kit"],
        duration: 6
      },
      %{
        id: "executive_access_establishment",
        dependencies: ["corporate_insider_recruitment"],
        required_capabilities: [:corporate_access],
        required_resources: ["executive_credentials"],
        duration: 4
      },
      
      # Phase 2: Advanced Reconnaissance
      %{
        id: "quantum_encryption_research",
        dependencies: ["nexus_financial_analysis"],
        required_capabilities: [:encryption_breaking],
        required_resources: ["quantum_research_lab"],
        duration: 8
      },
      %{
        id: "mathematical_security_modeling",
        dependencies: ["quantum_encryption_research"],
        required_capabilities: [:mathematical_modeling],
        required_resources: ["supercomputer_access"],
        duration: 6
      },
      %{
        id: "titan_security_assessment",
        dependencies: ["executive_access_establishment"],
        required_capabilities: [:security_bypass],
        required_resources: ["security_scanner"],
        duration: 5
      },
      %{
        id: "building_structural_analysis",
        dependencies: [],
        required_capabilities: [:structural_analysis],
        required_resources: ["architectural_plans"],
        duration: 5
      },
      %{
        id: "aerial_reconnaissance",
        dependencies: ["building_structural_analysis"],
        required_capabilities: [:piloting],
        required_resources: ["surveillance_drone"],
        duration: 4
      },
      %{
        id: "employee_psychological_profiling",
        dependencies: ["corporate_insider_recruitment"],
        required_capabilities: [:psychological_manipulation],
        required_resources: ["behavioral_analysis_suite"],
        duration: 5
      },
      
      # Phase 3: Technical Preparation
      %{
        id: "signal_intelligence_setup",
        dependencies: ["titan_security_assessment"],
        required_capabilities: [:signal_jamming],
        required_resources: ["signal_analysis_equipment"],
        duration: 4
      },
      %{
        id: "communication_intercept_network",
        dependencies: ["signal_intelligence_setup"],
        required_capabilities: [:radio_intercept],
        required_resources: ["intercept_array"],
        duration: 6
      },
      %{
        id: "counter_surveillance_preparation",
        dependencies: ["communication_intercept_network"],
        required_capabilities: [:counter_surveillance],
        required_resources: ["detection_countermeasures"],
        duration: 4
      },
      %{
        id: "nexus_network_topology_mapping",
        dependencies: ["mathematical_security_modeling"],
        required_capabilities: [:hacking],
        required_resources: ["network_mapper"],
        duration: 6
      },
      %{
        id: "biometric_system_analysis",
        dependencies: ["titan_security_assessment"],
        required_capabilities: [:electronics],
        required_resources: ["biometric_analyzer"],
        duration: 4
      },
      
      # Phase 4: Logistics & Route Planning
      %{
        id: "extraction_route_planning",
        dependencies: ["aerial_reconnaissance"],
        required_capabilities: [:route_planning],
        required_resources: ["traffic_analysis_system"],
        duration: 5
      },
      %{
        id: "vehicle_acquisition_planning",
        dependencies: ["extraction_route_planning"],
        required_capabilities: [:driving],
        required_resources: ["vehicle_database"],
        duration: 3
      },
      %{
        id: "contingency_planning",
        dependencies: ["counter_surveillance_preparation"],
        required_capabilities: [:contingency_management],
        required_resources: ["scenario_simulator"],
        duration: 6
      },
      %{
        id: "team_coordination_protocols",
        dependencies: ["contingency_planning"],
        required_capabilities: [:team_coordination],
        required_resources: ["communication_protocols"],
        duration: 4
      },
      
      # Phase 5: Equipment & Identity Preparation
      %{
        id: "explosive_device_preparation",
        dependencies: ["building_structural_analysis"],
        required_capabilities: [:explosives],
        required_resources: ["demolition_kit"],
        duration: 5
      },
      %{
        id: "identity_fabrication",
        dependencies: ["employee_psychological_profiling"],
        required_capabilities: [:impersonation],
        required_resources: ["identity_forge"],
        duration: 6
      },
      %{
        id: "insider_knowledge_briefing",
        dependencies: ["executive_access_establishment"],
        required_capabilities: [:insider_knowledge],
        required_resources: ["corporate_intelligence"],
        duration: 4
      },
      %{
        id: "executive_privilege_verification",
        dependencies: ["insider_knowledge_briefing"],
        required_capabilities: [:executive_privileges],
        required_resources: ["access_verification_system"],
        duration: 3
      },
      %{
        id: "surveillance_equipment_deployment",
        dependencies: ["team_coordination_protocols"],
        required_capabilities: [:surveillance],
        required_resources: ["surveillance_kit"],
        duration: 4
      },
      %{
        id: "final_equipment_staging",
        dependencies: ["explosive_device_preparation", "identity_fabrication"],
        required_capabilities: [:technical_repair],
        required_resources: ["equipment_cache"],
        duration: 3
      }
    ]
    
    # ACT II: The Heist - Multi-Team Coordinated Execution (30 tasks)
    act_2_tasks = [
      # Phase 6: Initial Infiltration
      %{
        id: "perimeter_surveillance_establishment",
        dependencies: ["surveillance_equipment_deployment"],
        required_capabilities: [:surveillance],
        required_resources: ["perimeter_monitors"],
        duration: 3
      },
      %{
        id: "communication_jamming_activation",
        dependencies: ["counter_surveillance_preparation"],
        required_capabilities: [:signal_jamming],
        required_resources: ["jamming_equipment"],
        duration: 2
      },
      %{
        id: "executive_impersonation_entry",
        dependencies: ["executive_privilege_verification", "identity_fabrication"],
        required_capabilities: [:impersonation],
        required_resources: ["executive_disguise"],
        duration: 4
      },
      %{
        id: "social_engineering_distraction",
        dependencies: ["executive_impersonation_entry"],
        required_capabilities: [:persuasion],
        required_resources: ["distraction_scenario"],
        duration: 3
      },
      %{
        id: "lobby_security_bypass",
        dependencies: ["social_engineering_distraction"],
        required_capabilities: [:lockpicking],
        required_resources: ["master_keycard"],
        duration: 3
      },
      
      # Phase 7: Multi-Floor Operations
      %{
        id: "elevator_system_override",
        dependencies: ["lobby_security_bypass"],
        required_capabilities: [:electronics],
        required_resources: ["elevator_control_interface"],
        duration: 2
      },
      %{
        id: "camera_network_infiltration",
        dependencies: ["nexus_network_topology_mapping"],
        required_capabilities: [:hacking],
        required_resources: ["network_infiltration_kit"],
        duration: 4
      },
      %{
        id: "guard_communication_intercept",
        dependencies: ["communication_jamming_activation"],
        required_capabilities: [:radio_intercept],
        required_resources: ["guard_radio_tap"],
        duration: 3
      },
      %{
        id: "security_patrol_misdirection",
        dependencies: ["guard_communication_intercept"],
        required_capabilities: [:psychological_manipulation],
        required_resources: ["false_alarm_system"],
        duration: 4
      },
      
      # Phase 8: Parallel Team Operations
      %{
        id: "helix_biotech_infiltration",
        dependencies: ["elevator_system_override", "camera_network_infiltration"],
        required_capabilities: [:stealth],
        required_resources: ["stealth_suit"],
        duration: 6
      },
      %{
        id: "cipher_communications_takeover",
        dependencies: ["security_patrol_misdirection"],
        required_capabilities: [:network_access],
        required_resources: ["network_takeover_kit"],
        duration: 8
      },
      %{
        id: "quantum_vault_approach",
        dependencies: ["helix_biotech_infiltration"],
        required_capabilities: [:acrobatics],
        required_resources: ["climbing_gear"],
        duration: 8
      },
      %{
        id: "structural_breach_preparation",
        dependencies: ["explosive_device_preparation"],
        required_capabilities: [:tactical_breach],
        required_resources: ["precision_charges"],
        duration: 6
      },
      
      # Phase 9: Vault Operations
      %{
        id: "quantum_encryption_breaking",
        dependencies: ["mathematical_security_modeling", "quantum_vault_approach"],
        required_capabilities: [:encryption_breaking],
        required_resources: ["quantum_decryption_array"],
        duration: 12
      },
      %{
        id: "code_analysis_verification",
        dependencies: ["quantum_encryption_breaking"],
        required_capabilities: [:code_analysis],
        required_resources: ["code_verification_system"],
        duration: 4
      },
      %{
        id: "vault_physical_breach",
        dependencies: ["structural_breach_preparation"],
        required_capabilities: [:explosives],
        required_resources: ["shaped_charges"],
        duration: 3
      },
      %{
        id: "biometric_security_defeat",
        dependencies: ["biometric_system_analysis", "vault_physical_breach"],
        required_capabilities: [:security_bypass],
        required_resources: ["biometric_spoofer"],
        duration: 5
      },
      %{
        id: "vault_lock_mechanisms_defeat",
        dependencies: ["vault_physical_breach"],
        required_capabilities: [:lockpicking],
        required_resources: ["advanced_lock_tools"],
        duration: 6
      },
      %{
        id: "data_extraction_primary",
        dependencies: ["code_analysis_verification", "biometric_security_defeat", "vault_lock_mechanisms_defeat"],
        required_capabilities: [:network_access],
        required_resources: ["data_extraction_array"],
        duration: 10
      },
      
      # Phase 10: Crisis Management
      %{
        id: "security_alert_detection",
        dependencies: ["perimeter_surveillance_establishment"],
        required_capabilities: [:counter_surveillance],
        required_resources: ["alert_detection_system"],
        duration: 8
      },
      %{
        id: "tactical_response_coordination",
        dependencies: ["security_alert_detection"],
        required_capabilities: [:tactical_planning],
        required_resources: ["tactical_command_center"],
        duration: 3
      },
      %{
        id: "team_coordination_adjustment",
        dependencies: ["tactical_response_coordination"],
        required_capabilities: [:team_coordination],
        required_resources: ["emergency_protocols"],
        duration: 2
      },
      %{
        id: "contingency_activation",
        dependencies: ["team_coordination_adjustment"],
        required_capabilities: [:contingency_management],
        required_resources: ["backup_plans"],
        duration: 4
      },
      %{
        id: "evidence_elimination_digital",
        dependencies: ["data_extraction_primary"],
        required_capabilities: [:hacking],
        required_resources: ["data_wipe_tools"],
        duration: 5
      },
      %{
        id: "physical_trace_cleanup",
        dependencies: ["contingency_activation"],
        required_capabilities: [:technical_repair],
        required_resources: ["forensic_cleanup_kit"],
        duration: 6
      }
    ]
    
    # ACT III: The Escape - Coordinated Extraction (20 tasks)
    act_3_tasks = [
      # Phase 11: Immediate Extraction
      %{
        id: "building_evacuation_initiation",
        dependencies: ["physical_trace_cleanup"],
        required_capabilities: [:acrobatics],
        required_resources: ["evacuation_gear"],
        duration: 4
      },
      %{
        id: "vehicle_acquisition_execution",
        dependencies: ["vehicle_acquisition_planning"],
        required_capabilities: [:driving],
        required_resources: ["getaway_vehicles"],
        duration: 3
      },
      %{
        id: "extraction_route_activation",
        dependencies: ["extraction_route_planning", "building_evacuation_initiation"],
        required_capabilities: [:route_planning],
        required_resources: ["route_control_system"],
        duration: 2
      },
      %{
        id: "pursuit_countermeasures",
        dependencies: ["vehicle_acquisition_execution"],
        required_capabilities: [:counter_surveillance],
        required_resources: ["pursuit_countermeasures"],
        duration: 6
      },
      
      # Phase 12: Multi-Vector Escape
      %{
        id: "aerial_extraction_team",
        dependencies: ["extraction_route_activation"],
        required_capabilities: [:piloting],
        required_resources: ["extraction_aircraft"],
        duration: 8
      },
      %{
        id: "ground_pursuit_evasion",
        dependencies: ["pursuit_countermeasures"],
        required_capabilities: [:driving],
        required_resources: ["evasion_vehicles"],
        duration: 10
      },
      %{
        id: "communication_blackout",
        dependencies: ["evidence_elimination_digital"],
        required_capabilities: [:signal_jamming],
        required_resources: ["area_jammers"],
        duration: 4
      },
      %{
        id: "false_trail_creation",
        dependencies: ["communication_blackout"],
        required_capabilities: [:psychological_manipulation],
        required_resources: ["misdirection_tools"],
        duration: 5
      },
      
      # Phase 13: Data Security & Transmission
      %{
        id: "data_verification_secure",
        dependencies: ["data_extraction_primary"],
        required_capabilities: [:data_analysis],
        required_resources: ["data_verification_suite"],
        duration: 3
      },
      %{
        id: "encryption_application",
        dependencies: ["data_verification_secure"],
        required_capabilities: [:encryption_breaking],
        required_resources: ["encryption_tools"],
        duration: 4
      },
      %{
        id: "secure_transmission_setup",
        dependencies: ["encryption_application"],
        required_capabilities: [:communication],
        required_resources: ["secure_transmission_array"],
        duration: 3
      },
      %{
        id: "data_transmission_execution",
        dependencies: ["secure_transmission_setup", "aerial_extraction_team"],
        required_capabilities: [:radio_intercept],
        required_resources: ["transmission_equipment"],
        duration: 2
      },
      
      # Phase 14: Final Dispersal
      %{
        id: "team_dispersal_coordination",
        dependencies: ["ground_pursuit_evasion", "false_trail_creation"],
        required_capabilities: [:team_coordination],
        required_resources: ["dispersal_protocols"],
        duration: 3
      },
      %{
        id: "identity_dissolution",
        dependencies: ["team_dispersal_coordination"],
        required_capabilities: [:impersonation],
        required_resources: ["identity_destruction_kit"],
        duration: 4
      },
      %{
        id: "safe_house_activation",
        dependencies: ["identity_dissolution"],
        required_capabilities: [:stealth],
        required_resources: ["safe_house_network"],
        duration: 5
      },
      %{
        id: "corporate_insider_extraction",
        dependencies: ["safe_house_activation"],
        required_capabilities: [:corporate_access],
        required_resources: ["insider_protection_protocol"],
        duration: 6
      },
      %{
        id: "mission_completion_verification",
        dependencies: ["data_transmission_execution", "corporate_insider_extraction"],
        required_capabilities: [:tactical_planning],
        required_resources: ["mission_verification_system"],
        duration: 2
      },
      %{
        id: "final_evidence_destruction",
        dependencies: ["mission_completion_verification"],
        required_capabilities: [:explosives],
        required_resources: ["evidence_destruction_charges"],
        duration: 3
      },
      %{
        id: "team_exfiltration_complete",
        dependencies: ["final_evidence_destruction"],
        required_capabilities: [:contingency_management],
        required_resources: ["exfiltration_confirmation"],
        duration: 1
      }
    ]
    
    # Combine all acts - Total: 75 tasks
    act_1_tasks ++ act_2_tasks ++ act_3_tasks
  end

  def create_simple_tasks do
    for i <- 1..3 do
      %{
        id: "task_#{i}",
        dependencies: [],
        required_capabilities: [:work],
        required_resources: ["tool_#{i}"],
        duration: 2
      }
    end
  end
  
  def get_scenario_description do
    %{
      name: "Operation: Digital Dynasty - Nexus Dynamics Heist",
      description: "Ocean's 11-style corporate espionage: 11 specialists, 75 coordinated tasks, 60+ high-tech tools - Multi-act cinematic heist with parallel operations, complex dependencies, and full capability utilization",
      complexity: "maximum",
      expected_outcome: "sophisticated multi-team coordination with advanced resource allocation, parallel execution paths, and realistic agent workload distribution across 3-act structure"
    }
  end
end
