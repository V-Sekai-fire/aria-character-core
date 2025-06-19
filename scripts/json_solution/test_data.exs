defmodule JsonSolution.TestData do
  @moduledoc """
  Test Data Generator
  
  Creates simple test scenarios with workers, tools, and tasks
  for agent-entity-capability planning tests.
  """
  
  def create_simple_scenario do
    workers = create_heist_team()
    tools = create_heist_equipment()
    tasks = create_heist_mission()
    
    {workers, tools, tasks}
  end
  
  def create_heist_team do
    [
      %AriaEngine.Scheduler.Entity{
        id: "ghost",
        type: :agent,
        capabilities: [:hacking, :network_access, :stealth],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Network Infiltration Specialist", codename: "Ghost"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "spark",
        type: :agent,
        capabilities: [:electronics, :security_bypass, :technical_repair],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Electronics Expert", codename: "Spark"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "phantom",
        type: :agent,
        capabilities: [:lockpicking, :stealth, :acrobatics],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Physical Infiltration Specialist", codename: "Phantom"}
      },
      %AriaEngine.Scheduler.Entity{
        id: "oracle",
        type: :agent,
        capabilities: [:surveillance, :communication, :data_analysis],
        current_activity: nil,
        availability: nil,
        resources_held: [],
        metadata: %{role: "Intelligence Coordinator", codename: "Oracle"}
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
      %AriaEngine.Scheduler.Resource{
        id: "hacking_rig",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{}
      },
      %AriaEngine.Scheduler.Resource{
        id: "multitool",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{}
      },
      %AriaEngine.Scheduler.Resource{
        id: "lockpick_set",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{}
      },
      %AriaEngine.Scheduler.Resource{
        id: "portable_drive",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{}
      },
      %AriaEngine.Scheduler.Resource{
        id: "laptop",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{}
      },
      %AriaEngine.Scheduler.Resource{
        id: "cleanup_kit",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{}
      },
      %AriaEngine.Scheduler.Resource{
        id: "grappling_hook",
        type: :physical,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{}
      },
      %AriaEngine.Scheduler.Resource{
        id: "radio_array",
        type: :computational,
        capacity: 1,
        current_usage: 0,
        constraints: %{},
        availability_schedule: [],
        metadata: %{}
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
    [
      %{
        id: "reconnaissance",
        dependencies: [],
        required_capabilities: [:surveillance],
        required_resources: ["laptop"],
        duration: 3
      },
      %{
        id: "network_breach",
        dependencies: ["reconnaissance"],
        required_capabilities: [:hacking],
        required_resources: ["hacking_rig"],
        duration: 4
      },
      %{
        id: "security_disable",
        dependencies: ["network_breach"],
        required_capabilities: [:electronics],
        required_resources: ["multitool"],
        duration: 3
      },
      %{
        id: "physical_entry",
        dependencies: ["security_disable"],
        required_capabilities: [:lockpicking],
        required_resources: ["lockpick_set"],
        duration: 2
      },
      %{
        id: "data_extraction",
        dependencies: ["physical_entry"],
        required_capabilities: [:network_access],
        required_resources: ["portable_drive"],
        duration: 5
      },
      %{
        id: "evidence_cleanup",
        dependencies: ["data_extraction"],
        required_capabilities: [:technical_repair],
        required_resources: ["cleanup_kit"],
        duration: 3
      },
      %{
        id: "escape_route",
        dependencies: ["evidence_cleanup"],
        required_capabilities: [:stealth],
        required_resources: ["grappling_hook"],
        duration: 2
      },
      %{
        id: "exfiltration",
        dependencies: ["escape_route"],
        required_capabilities: [:communication],
        required_resources: ["radio_array"],
        duration: 1
      }
    ]
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
      name: "Digital Vault Infiltration",
      description: "4 specialists, 8 sequential tasks, 8 specialized tools - Complex capability matching with dependencies",
      complexity: "high",
      expected_outcome: "coordinated sequential execution with resource optimization"
    }
  end
end
