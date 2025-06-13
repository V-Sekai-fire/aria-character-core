# **5. Data Structures & Types**

Before diving into the API, we need to define the core data structures that represent temporal planning concepts.

### **5.1. Temporal Actions**

A `timed_action` represents a concrete action that will be executed at a specific time:

```elixir
@type timed_action :: %{
  id: String.t(),                    # Unique identifier for this action
  agent_id: String.t(),              # Which agent performs this action
  action: atom(),                    # The action type (:move_to, :attack, :scorch, etc.)
  args: list(),                      # Arguments for the action
  start_time: float(),               # When this action begins (in seconds)
  duration: float(),                 # How long this action takes
  end_time: float(),                 # When this action completes (start_time + duration)
  prerequisites: [String.t()],       # IDs of actions that must complete first
  effects: [temporal_effect()],      # What changes this action makes to the world
  status: :scheduled | :executing | :completed | :cancelled
}
```

**Example timed_action:**

```elixir
%{
  id: "alex_move_001",
  agent_id: "alex",
  action: :move_to,
  args: [{8, 4, 0}],
  start_time: 5.0,
  duration: 1.0,                     # Calculated as distance / alex.move_speed (4.0 units from {4,4,0} to {8,4,0})
  end_time: 6.0,
  prerequisites: [],
  effects: [
    %{type: :set, object: "alex", property: "position", value: {8, 4, 0},
      start_time: 6.0, duration: :permanent, condition: nil}
  ],
  status: :scheduled
}
```

### **5.2. Goals & Tasks**

A `goal` represents a high-level objective that the planner must achieve:

```elixir
@type goal :: %{
  id: String.t(),                    # Unique identifier
  type: :survive_encounter | :rescue_hostage | :destroy_bridge | :escape_scenario | :eliminate_all_enemies,
  priority: 1..100,                  # Higher numbers = higher priority
  deadline: float() | :none,         # Must be completed by this time (or no deadline)
  success_condition: goal_condition(),  # What defines success
  failure_condition: goal_condition(),  # What defines failure
  agents: [String.t()],              # Which agents are involved
  constraints: [temporal_constraint()], # Additional constraints
  metadata: map()                    # Additional goal-specific data
}

@type goal_condition :: %{
  type: :and | :or | :not | :predicate,
  conditions: [goal_condition()] | nil,  # For composite conditions
  predicate: atom() | nil,               # For atomic conditions
  args: list()                           # Arguments to the predicate
}
```

**Example goal (rescue_hostage):**

```elixir
%{
  id: "rescue_hostage_001",
  type: :rescue_hostage,
  priority: 90,
  deadline: 30.0,
  success_condition: %{
    type: :and,
    conditions: [
      %{type: :predicate, predicate: :agent_at_position, args: ["alex", {20, 5, 0}]},
      %{type: :predicate, predicate: :world_time_less_than, args: [30.0]}
    ]
  },
  failure_condition: %{
    type: :or,
    conditions: [
      %{type: :predicate, predicate: :world_time_greater_than, args: [30.0]},
      %{type: :predicate, predicate: :agent_dead, args: ["alex"]}
    ]
  },
  agents: ["alex", "maya", "jordan"],
  constraints: [],
  metadata: %{hostage_position: {20, 5, 0}}
}
```

A `task` represents a decomposable unit of work:

```elixir
@type task :: %{
  id: String.t(),                    # Unique identifier
  name: String.t(),                  # Human-readable name
  type: :primitive | :compound,      # Primitive = direct action, Compound = needs decomposition
  action: atom() | nil,              # For primitive tasks
  args: list(),                      # Arguments
  agent_id: String.t(),              # Which agent performs this
  preconditions: [condition()],      # What must be true before this task
  effects: [temporal_effect()],      # What this task changes
  duration: float() | :variable,     # How long this task takes
  subtasks: [task()] | nil,          # For compound tasks
  constraints: [temporal_constraint()], # Temporal relationships
  metadata: map()
}
```

### **5.3. Temporal Constraints**

Constraints define relationships between actions and temporal requirements:

```elixir
@type temporal_constraint :: %{
  id: String.t(),
  type: :before | :after | :during | :meets | :overlaps | :starts | :finishes | :equals | :deadline | :cooldown,
  source: String.t(),                # ID of source action/task
  target: String.t() | nil,          # ID of target action/task (nil for absolute constraints)
  offset: float() | nil,             # Time offset (e.g., "5 seconds after")
  duration: float() | nil,           # For duration-based constraints
  condition: condition() | nil,      # Additional logical condition
  violation_penalty: float()         # Cost of violating this constraint
}
```

**Example temporal constraints:**

```elixir
# "Alex must move before Maya casts Scorch"
%{
  id: "alex_move_before_maya_scorch",
  type: :before,
  source: "alex_move_001",
  target: "maya_scorch_001",
  offset: nil,
  duration: nil,
  condition: nil,
  violation_penalty: 10.0
}

# "Jordan's Now! skill has a 20-second cooldown"
%{
  id: "jordan_now_cooldown",
  type: :cooldown,
  source: "jordan_now_001",
  target: nil,
  offset: nil,
  duration: 20.0,
  condition: nil,
  violation_penalty: 100.0
}
```

### **5.4. Temporal Effects & Conditions**

Effects describe how actions change the world state:

```elixir
@type temporal_effect :: %{
  type: :set | :add | :remove | :modify,
  object: String.t(),                # What object is affected
  property: String.t(),              # What property changes
  value: any(),                      # New value
  start_time: float(),               # When this effect begins
  duration: float() | :permanent,    # How long this effect lasts
  condition: condition() | nil       # Conditional effect
}

@type condition :: %{
  type: :equals | :not_equals | :greater | :less | :greater_equal | :less_equal | :exists | :not_exists,
  object: String.t(),
  property: String.t(),
  value: any()
}
```

### **5.5. Planning Methods**

Methods define how to decompose compound tasks into subtasks:

```elixir
@type planning_method :: %{
  id: String.t(),
  name: String.t(),
  task_name: String.t(),             # Which task type this method applies to
  preconditions: [condition()],      # When this method is applicable
  subtasks: [task()],                # What subtasks to create
  constraints: [temporal_constraint()], # Temporal relationships between subtasks
  priority: integer(),               # Method selection priority
  cost_estimate: float()             # Estimated cost of this decomposition
}
```

**Example planning method (rescue_hostage decomposition):**

```elixir
%{
  id: "rescue_hostage_method_001",
  name: "Direct Rush to Hostage",
  task_name: "rescue_hostage",
  preconditions: [
    %{type: :greater, object: "alex", property: "hp", value: 50},
    %{type: :less, object: "world", property: "time", value: 25.0}
  ],
  subtasks: [
    %{id: "clear_path", name: "Clear Path", type: :compound, agent_id: "maya"},
    %{id: "rush_hostage", name: "Rush to Hostage", type: :compound, agent_id: "alex"},
    %{id: "provide_support", name: "Provide Support", type: :compound, agent_id: "jordan"}
  ],
  constraints: [
    %{type: :before, source: "clear_path", target: "rush_hostage", offset: 1.0}
  ],
  priority: 80,
  cost_estimate: 15.5
}
```

### **5.6. Multi-Goal Structures**

For handling multiple competing or complementary goals:

```elixir
@type goal_network :: %{
  goals: [goal()],
  relationships: [goal_relationship()],
  resolution_strategy: :priority | :utility | :deadline | :custom,
  global_constraints: [temporal_constraint()]
}

@type goal_relationship :: %{
  type: :conflicts | :supports | :requires | :enables,
  source_goal: String.t(),
  target_goal: String.t(),
  strength: float()                  # How strong this relationship is
}
```

### **5.7. World & Map Structures**

The game world contains static objects, environmental elements, and the map layout:

```elixir
@type world_state :: %{
  time: float(),                     # Current game time in seconds
  map: game_map(),                   # The map layout and terrain
  objects: [world_object()],         # Interactive objects (pillars, hostage, etc.)
  environmental_effects: [environmental_effect()], # Active environmental effects
  metadata: map()                    # Additional world-specific data
}

@type game_map :: %{
  width: integer(),                  # Map width in grid units
  height: integer(),                 # Map height in grid units
  depth: integer(),                  # Map depth in grid units (usually 1 for 2D)
  cells: %{                          # Map cells by coordinate
    {integer(), integer(), integer()} => map_cell()
  },
  escape_zone: [map_coordinate()],   # Coordinates that are escape zones
  spawn_points: %{                   # Named spawn locations
    atom() => map_coordinate()
  }
}

@type map_cell :: %{
  walkable: boolean(),               # Can agents move through this cell
  cover: boolean(),                  # Does this cell provide cover
  chasm: boolean(),                  # Is this cell a dangerous chasm
  escape_zone: boolean(),            # Is this cell part of the escape zone
  terrain_type: atom(),              # :grass, :stone, :water, etc.
  metadata: map()                    # Additional cell-specific data
}

@type map_coordinate :: {integer(), integer(), integer()}

@type world_object :: %{
  id: String.t(),                    # Unique identifier
  type: atom(),                      # :pillar, :hostage, :door, etc.
  position: map_coordinate(),        # Location in the world
  hp: integer() | nil,               # Hit points (for destructible objects)
  max_hp: integer() | nil,           # Maximum hit points
  properties: map(),                 # Object-specific properties
  interactions: [interaction()],     # Available interactions
  metadata: map()
}

@type interaction :: %{
  id: atom(),                        # :interact, :attack, :rescue, etc.
  name: String.t(),                  # Display name
  duration: float(),                 # Time required to perform interaction
  requirements: [condition()],       # Conditions to perform interaction
  effects: [temporal_effect()],      # What happens when interaction completes
  metadata: map()
}

@type environmental_effect :: %{
  id: String.t(),
  type: atom(),                      # :fire, :smoke, :darkness, etc.
  area: [map_coordinate()],          # Affected coordinates
  start_time: float(),               # When this effect started
  duration: float() | :permanent,    # How long this effect lasts
  properties: map(),                 # Effect-specific properties
  metadata: map()
}
```

**Example world_state (TimeStrike):**

```elixir
%{
  time: 0.0,
  map: %{
    width: 25,
    height: 10,
    depth: 1,
    cells: %{
      # Most cells are walkable grass
      {0, 0, 0} => %{walkable: true, cover: false, chasm: false, escape_zone: false, terrain_type: :grass},
      # Escape zone at the right edge
      {24, 5, 0} => %{walkable: true, cover: false, chasm: false, escape_zone: true, terrain_type: :grass},
      # Add more cells as needed...
    },
    escape_zone: [
      {24, 0, 0}, {24, 1, 0}, {24, 2, 0}, {24, 3, 0}, {24, 4, 0},
      {24, 5, 0}, {24, 6, 0}, {24, 7, 0}, {24, 8, 0}, {24, 9, 0}
    ],
    spawn_points: %{
      alex_start: {4, 4, 0},
      maya_start: {3, 5, 0},
      jordan_start: {4, 6, 0},
      hostage_location: {20, 5, 0}
    }
  },
  objects: [
    %{
      id: "bridge_pillar_1",
      type: :pillar,
      position: {10, 3, 0},
      hp: 150,
      max_hp: 150,
      properties: %{destructible: true},
      interactions: [
        %{
          id: :interact,
          name: "Attack Pillar",
          duration: 2.0,
          requirements: [],
          effects: [
            %{type: :modify, object: "bridge_pillar_1", property: "hp", value: -25}
          ]
        }
      ]
    },
    %{
      id: "bridge_pillar_2", 
      type: :pillar,
      position: {10, 7, 0},
      hp: 150,
      max_hp: 150,
      properties: %{destructible: true},
      interactions: [
        %{
          id: :interact,
          name: "Attack Pillar", 
          duration: 2.0,
          requirements: [],
          effects: [
            %{type: :modify, object: "bridge_pillar_2", property: "hp", value: -25}
          ]
        }
      ]
    },
    %{
      id: "hostage",
      type: :hostage,
      position: {20, 5, 0},
      hp: 1,
      max_hp: 1,
      properties: %{execution_time: 30.0},
      interactions: [
        %{
          id: :rescue,
          name: "Rescue Hostage",
          duration: 1.0,
          requirements: [
            %{type: :equals, object: "world", property: "time", value: {:less_than, 30.0}}
          ],
          effects: [
            %{type: :set, object: "hostage", property: "rescued", value: true}
          ]
        }
      ]
    }
  ],
  environmental_effects: [],
  metadata: %{
    scenario: "timestrike",
    hostage_execution_time: 30.0,
    reinforcement_arrival_time: 45.0
  }
}
````
