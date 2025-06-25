# VSEKAI_interactivity_planning

## Contributors

- K. S. Ernest Lee, V-Sekai, ernest.lee@chibifire.com

## Status

Draft

## Dependencies

Written against the glTF 2.0 spec.
Requires KHR_interactivity extension as foundation.

## Overview

The `VSEKAI_interactivity_planning` extension adds temporal planning capabilities to glTF scenes by integrating AriaEngine's unified durative action specification with KHR_interactivity. This extension enables intelligent agent behavior, multi-agent coordination, and temporal constraint satisfaction within interactive 3D environments.

This extension builds upon KHR_interactivity by adding:

- **Durative Actions**: Actions with temporal duration and entity requirements
- **Entity-Capability System**: Flexible trait-based entity modeling  
- **Temporal Constraints**: Start/end times, duration specifications, and temporal relationships
- **Multi-Agent Coordination**: Resource conflict resolution and capability matching
- **IPyHOP Planning Integration**: Solution trees, blacklisting, and goal verification
- **Pure GTPyhop Multigoal Philosophy**: Explicit multigoal handling without automatic fallbacks

## Why Planning vs Imperative Programming

### The Mental Model Shift

When developers first encounter planning patterns, several things feel confusing. Here's the journey from confusion to understanding:

**Confusion 1: "Why don't I just call the function?"**
```javascript
// Normal programming expectation:
cookMeal("pasta");  // Just call it when I want it

// Planning reality: You describe capabilities, planner decides when/how
```

**The "Aha!" Moment:** You're not writing a program - you're describing a toolbox. The planner is the craftsperson who decides which tools to use and when.

**Confusion 2: "This feels backwards and inefficient"**
```javascript
// What it feels like you're doing:
"Hey computer, I have these tools available, and I want pasta. Figure it out."

// What you think you should be doing:
"Step 1: Get ingredients. Step 2: Cook pasta. Step 3: Serve."
```

**The "Aha!" Moment:** The "inefficient" approach handles complexity that would break your step-by-step code:
- What if no ingredients are available?
- What if the chef is in a meeting?
- What if the oven is broken?
- What if you need to coordinate 3 chefs simultaneously?

### Problems That Planning Solves

The planning architecture exists to solve problems that would be nightmarish to code with normal imperative programming:

**Problem 1: Multi-Agent Coordination**
```javascript
// Imperative nightmare: 3 chefs preparing different courses
function coordinateDinnerPrep() {
  if (chef1Available() && chef2Available() && chef3Available()) {
    if (appetizerIngredientsReady() && mainIngredientsReady() && dessertIngredientsReady()) {
      // But wait - what if chef1 needs the oven that chef2 is using?
      // And chef3 needs prep space that chef1 is occupying?
      // And the appetizer must finish before main course starts?
      // This quickly becomes impossible to manage...
    }
  }
}

// Planning solution: Describe capabilities and constraints
// Planner automatically handles coordination, scheduling, and conflicts
```

**Problem 2: Temporal Constraint Satisfaction**
```javascript
// Imperative nightmare: "Dinner ready by 7pm, but prep takes 3 hours, 
// chef has meeting 2-4pm, oven shared with bread baking 5-6pm"
// Try coding all those constraints with if/else statements!

// Planning solution: Declare constraints, let solver figure it out
```

**Problem 3: Dynamic Replanning**
```javascript
// Imperative nightmare: "Oven broke, find alternative cooking method,
// reschedule everything, notify affected parties, update timelines"

// Planning solution: Automatic failure recovery
// When oven action fails, planner:
// 1. Blacklists oven-based actions
// 2. Finds alternative cooking methods (stovetop, grill)
// 3. Replans entire schedule automatically
// 4. Continues execution with new plan
```

### Why Entity Requirements Enable This Magic

The `requires_entities` metadata isn't just documentation - it's the key to intelligent search:

```json
{
  "requires_entities": [
    {"type": "chef", "capabilities": ["cooking"]},
    {"type": "oven", "capabilities": ["heating"]}
  ]
}
```

This tells the planner:
- **Resource conflicts**: "Chef can't cook two things simultaneously"
- **Capability matching**: "Only entities with :cooking capability can do this"
- **Availability checking**: "Don't plan this if chef is in meeting"
- **Failure recovery**: "If oven breaks, find alternative heating source"

## Core Concepts

### Entity-Capability Model

All interactive elements are modeled as entities with capabilities that define their behavior:

```json
{
  "entities": {
    "chef_001": {
      "type": "agent",
      "capabilities": ["cooking", "menu_planning", "communication"],
      "state": {
        "experience_level": 8,
        "specialization": "italian_cuisine",
        "available": true,
        "location": "kitchen_001"
      }
    },
    "oven_001": {
      "type": "appliance", 
      "capabilities": ["heating", "baking", "temperature_control"],
      "state": {
        "max_temperature": 500,
        "min_temperature": 150,
        "available": true,
        "current_temperature": 0
      }
    },
    "kitchen_001": {
      "type": "location",
      "capabilities": ["workspace", "food_preparation"],
      "state": {
        "capacity": 4,
        "equipment_available": true,
        "current_occupancy": 0
      }
    }
  }
}
```

**Key Principles:**
- **Capabilities define what entities can do** (static traits)
- **State tracks current conditions** (dynamic properties)
- **No constraints in action metadata** - quantities and availability are state fluents
- **Dynamic validation** - checks current state, not static declarations

### Durative Action Specification

Actions are defined with temporal duration and entity requirements following the unified specification from ADR-181:

```json
{
  "actions": {
    "cook_meal": {
      "duration": "PT2H",
      "requires_entities": [
        {
          "type": "agent",
          "capabilities": ["cooking", "menu_planning"]
        },
        {
          "type": "appliance", 
          "capabilities": ["heating", "baking"]
        },
        {
          "type": "location",
          "capabilities": ["workspace"]
        }
      ],
      "mutual_exclusion": ["kitchen_cleanup"],
      "temporal_constraints": [
        {"type": "before", "action": "gather_ingredients"},
        {"type": "during", "condition": "kitchen_available"}
      ],
      "description": "Prepare a meal using specified ingredients and cooking equipment",
      "conditions": {
        "at_start": [
          {"subject": "chef_001", "predicate": "available", "value": true},
          {"subject": "oven_001", "predicate": "temperature", "constraint": {">=": 350}}
        ],
        "over_all": [
          {"subject": "kitchen_001", "predicate": "workspace", "value": "clean"},
          {"subject": "oven_001", "predicate": "temperature", "constraint": {"between": [350, 450]}}
        ],
        "at_end": [
          {"subject": "meal", "predicate": "quality", "constraint": {">=": 8}}
        ]
      },
      "effects": {
        "at_start": [
          {"subject": "chef_001", "predicate": "status", "value": "cooking"},
          {"subject": "oven_001", "predicate": "status", "value": "in_use"},
          {"subject": "kitchen_001", "predicate": "workspace", "value": "busy"}
        ],
        "over_time": [
          {"subject": "meal", "predicate": "progress", "change": {"increase": 0.02}},
          {"subject": "kitchen_001", "predicate": "heat", "change": {"increase": 2}}
        ],
        "at_end": [
          {"subject": "meal", "predicate": "status", "value": "ready"},
          {"subject": "chef_001", "predicate": "status", "value": "available"},
          {"subject": "oven_001", "predicate": "status", "value": "available"},
          {"subject": "kitchen_001", "predicate": "workspace", "value": "clean"}
        ]
      }
    }
  }
}
```

### Temporal Patterns

The extension supports multiple temporal specification patterns with precision preservation (ADR-182):

**Floating Duration (effort-based scheduling):**
```json
{
  "duration": "PT2H"
}
```

**Fixed Schedule (time-based scheduling):**
```json
{
  "start": "2025-06-22T10:00:00Z",
  "end": "2025-06-22T11:00:00Z"
}
```

**Open-ended Intervals:**
```json
{
  "start": "2025-06-22T14:00:00Z"
}
```

**Duration vs Start/End Validation Rules:**
- **Mutually exclusive**: Cannot specify both `duration` and `start`/`end`
- **Precision preservation**: Use Timex for temporal calculations
- **Validation constraints**: Enforce logical temporal relationships

### IPyHOP Architecture Integration

Following ADR-183, the extension integrates IPyHOP-compatible features:

**Solution Tree Structure:**
- `:task` - Decompose into subtasks/actions
- `:action` - Execute immediately (highest priority)
- `:goal` - Decompose into subgoals with automatic verification
- `:multigoal` - Require explicit domain methods (no automatic fallbacks)
- `:verify_goal` - Verify goal achievement
- `:verify_multigoal` - Verify multigoal achievement

**Blacklist System:**
```json
{
  "blacklist": {
    "failed_actions": [
      {"action": "cook_meal", "args": ["pasta"], "reason": "oven_malfunction"},
      {"action": "use_oven", "args": ["oven_001"], "reason": "equipment_failure"}
    ],
    "scope": "session",
    "created_at": "2025-06-22T10:30:00Z"
  }
}
```

**Pure GTPyhop Multigoal Philosophy:**
- **NO automatic fallbacks** for multigoals
- **Domain authors must explicitly define multigoal methods**
- **Planning fails if multigoals encountered without domain methods**
- **split_multigoal and MinizinC available as explicit tools only**

### Commands vs Actions Separation

Following ADR-183 architecture:

**Planning-Time Actions** (assume success for planning):
```json
{
  "planning_actions": {
    "cook_meal": {
      "duration": "PT2H",
      "requires_entities": [...],
      "description": "Pure state transformation for planning"
    }
  }
}
```

**Execution-Time Commands** (handle real-world failures):
```json
{
  "execution_commands": {
    "cook_meal_command": {
      "action_ref": "cook_meal",
      "failure_handling": {
        "oven_malfunction": "find_alternative_heating",
        "ingredient_shortage": "adjust_recipe_or_replan",
        "chef_unavailable": "assign_backup_chef"
      }
    }
  }
}
```

## KHR_interactivity Integration

### Using Pointer Nodes for State Access

The extension uses KHR_interactivity's `pointer/get` and `pointer/set` nodes for accessing glTF Object Model properties:

**Getting Entity State:**
```json
{
  "declarations": [
    {
      "op": "pointer/get",
      "inputValueSockets": {
        "entityIndex": {"type": 0}
      },
      "outputValueSockets": {
        "value": {"type": 1},
        "isValid": {"type": 2}
      }
    }
  ],
  "nodes": [
    {
      "declaration": 0,
      "configuration": {
        "pointer": {"value": ["/nodes/{entityIndex}/extensions/VSEKAI_interactivity_planning/state/available"]},
        "type": {"value": [2]}
      },
      "values": {
        "entityIndex": {"value": [0], "type": 0}
      }
    }
  ]
}
```

**Setting Entity State:**
```json
{
  "declarations": [
    {
      "op": "pointer/set",
      "inputValueSockets": {
        "entityIndex": {"type": 0},
        "value": {"type": 2}
      },
      "outputValueSockets": {}
    }
  ],
  "nodes": [
    {
      "declaration": 0,
      "configuration": {
        "pointer": {"value": ["/nodes/{entityIndex}/extensions/VSEKAI_interactivity_planning/state/status"]},
        "type": {"value": [3]}
      },
      "values": {
        "entityIndex": {"value": [0], "type": 0},
        "value": {"value": ["cooking"], "type": 3}
      }
    }
  ]
}
```

### Planning Behavior Graph Integration

```json
{
  "extensions": {
    "KHR_interactivity": {
      "graphs": [
        {
          "types": [
            {"signature": "int"},
            {"signature": "float"},
            {"signature": "bool"},
            {"signature": "string"},
            {"signature": "float3"}
          ],
          "variables": [
            {
              "type": 0,
              "value": [0]
            }
          ],
          "events": [
            {
              "id": "planning_goal_achieved",
              "values": {
                "goal": {"type": 3},
                "entity": {"type": 3}
              }
            }
          ],
          "declarations": [
            {"op": "event/onStart"},
            {"op": "pointer/get"},
            {"op": "pointer/set"},
            {"op": "event/send"},
            {"op": "flow/sequence"}
          ],
          "nodes": [
            {
              "declaration": 0,
              "flows": {
                "out": {"node": 4}
              }
            },
            {
              "declaration": 1,
              "configuration": {
                "pointer": {"value": ["/extensions/VSEKAI_interactivity_planning/entities/chef_001/state/available"]},
                "type": {"value": [2]}
              }
            },
            {
              "declaration": 2,
              "configuration": {
                "pointer": {"value": ["/extensions/VSEKAI_interactivity_planning/entities/chef_001/state/status"]},
                "type": {"value": [3]}
              },
              "values": {
                "value": {"value": ["cooking"], "type": 3}
              }
            },
            {
              "declaration": 3,
              "configuration": {
                "event": {"value": [0]}
              },
              "values": {
                "goal": {"value": ["meal_ready"], "type": 3},
                "entity": {"value": ["chef_001"], "type": 3}
              }
            },
            {
              "declaration": 4,
              "flows": {
                "0": {"node": 1},
                "1": {"node": 2},
                "2": {"node": 3}
              }
            }
          ]
        }
      ]
    }
  }
}
```

## glTF Schema Updates

### Extension Root

The extension is added to the glTF root object:

```json
{
  "extensions": {
    "VSEKAI_interactivity_planning": {
      "entities": { ... },
      "actions": { ... },
      "goals": { ... },
      "temporal_constraints": { ... },
      "planning_domain": { ... },
      "execution_context": { ... },
      "blacklist": { ... }
    }
  }
}
```

### Node Extensions

Nodes can be extended with entity and action metadata:

```json
{
  "nodes": [
    {
      "name": "Chef",
      "extensions": {
        "VSEKAI_interactivity_planning": {
          "entity_id": "chef_001",
          "available_actions": ["cook_meal", "gather_ingredients"],
          "current_goals": [
            {"subject": "chef_001", "predicate": "location", "value": "kitchen_001"}
          ],
          "state": {
            "available": true,
            "status": "idle",
            "location": "kitchen_001",
            "experience_level": 8
          }
        }
      }
    }
  ]
}
```

### Scene Extensions

Scenes can define planning domains and execution contexts:

```json
{
  "scenes": [
    {
      "name": "Restaurant Kitchen",
      "extensions": {
        "VSEKAI_interactivity_planning": {
          "domain_name": "cooking_domain",
          "execution_strategy": "lazy_refinement",
          "goal_verification": true,
          "blacklist_failed_actions": true,
          "multigoal_handling": "explicit_only",
          "solution_tree_enabled": true,
          "ipyhop_compatible": true
        }
      }
    }
  ]
}
```

## Tombstoned Features

### Explicitly Rejected Patterns

**Status:** Tombstoned - Architectural violations that must be prevented

1. **❌ TOMBSTONE: Constraints in action metadata** - Quantities, availability, and dynamic properties are state fluents, not action metadata
2. **❌ TOMBSTONE: Automatic multigoal fallbacks** - Violates pure GTPyhop design philosophy
3. **❌ TOMBSTONE: Rigid relations** - Redundant with capability system
4. **❌ TOMBSTONE: Separate planning/execution phases** - IPyHOP uses interleaved planning and execution only
5. **❌ TOMBSTONE: Properties field in entity requirements** - Use capabilities instead
6. **❌ TOMBSTONE: Validation within action functions** - Actions are pure state transformations

**Why constraints are tombstoned:**
- **Action metadata** should define what capabilities are needed (static requirements)
- **State validation** should check current quantities, availability, and dynamic properties
- **Separation of concerns** - keeps action metadata clean and state queries explicit
- **Temporal awareness** - quantities can change over time, constraints cannot

**Example of WRONG approach:**
```json
{
  "requires_entities": [
    {
      "type": "ingredient", 
      "capabilities": ["consumable"],
      "constraints": {"quantity": {"min": 2}}  // ❌ WRONG - quantities are state fluents
    }
  ]
}
```

**Example of CORRECT approach:**
```json
{
  "requires_entities": [
    {
      "type": "ingredient",
      "capabilities": ["consumable"]  // ✅ CORRECT - capabilities only
    }
  ]
}
```

## Implementation Patterns

### Module-Based Domain Pattern (ADR-184)

The extension maintains compatibility with AriaEngine's canonical implementation:

```elixir
defmodule VSekai.Domains.GltfCookingDomain do
  use AriaEngine.Domain
  
  @domain_name "gltf_cooking"
  @description "GLTF-integrated cooking domain with temporal planning"
  
  # Actions (planning-time) with capability system
  @action duration: "PT2H",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :menu_planning]},
            %{type: "oven", capabilities: [:heating, :baking]},
            %{type: "kitchen", capabilities: [:workspace]},
            %{type: "flour", capabilities: [:consumable]},
            %{type: "eggs", capabilities: [:consumable]},
            %{type: "mixing_bowl", capabilities: [:container, :reusable]}
          ],
          mutual_exclusion: ["kitchen_cleanup"],
          temporal_constraints: [
            {:before, "gather_ingredients"},
            {:during, "kitchen_available"}
          ]
  def cook_meal(state, [meal_type]) do
    # CORRECT: Pure state transformation, planner already validated requirements
    state
    |> AriaState.ObjectState.set_fact("meal_status", meal_type, "cooking")
    |> AriaState.ObjectState.set_fact("chef_status", "chef_1", "busy")
    |> AriaState.ObjectState.set_fact("oven_status", "oven_1", "in_use")
  end
  
  # Commands (execution-time) with failure handling
  @command
  def cook_meal_command(state, [meal_type]) do
    case attempt_cooking_with_failure_chance(state, meal_type) do
      {:ok, new_state} -> 
        Logger.info("cook_meal_command succeeded for #{meal_type}")
        {:ok, new_state}
      {:error, reason} ->
        Logger.warn("cook_meal_command failed: #{reason}")
        {:error, reason}  # Triggers blacklisting and replanning
    end
  end
  
  # Unigoal methods with automatic verification
  @unigoal_method predicate: "location"
  def travel_to_location(state, [subject, target]) do
    current = StateV2.get_fact(state, subject, "location")
    if current == target do
      {:ok, []}  # Already achieved
    else
      {:ok, [
        {:walk_to_location, [subject, target]},
        {:verify_location, [subject, target]}  # Auto-verification
      ]}
    end
  end
  
  # EXPLICIT multigoal methods (Pure GTPyhop Style)
  @multigoal_method goal_pattern: :cooking_workflow
  def handle_cooking_workflow(state, multigoal) do
    # Domain author explicitly chooses strategy
    case custom_cooking_optimization(state, multigoal.goals) do
      {:ok, plan} -> {:ok, plan}
      {:error, _} ->
        # Domain author EXPLICITLY chooses fallback
        Logger.debug("Custom optimization failed, using split_multigoal")
        AriaEngine.Multigoal.split_multigoal(state, multigoal.goals)
    end
  end
  
  # Domain creation follows module-based pattern
  def create_domain(opts \\ %{}) do
    domain = __MODULE__.create_base_domain()
    
    # Configure goal verification (IPyHOP feature)
    domain = AriaEngine.Domain.set_verify_goals(domain, Map.get(opts, :verify_goals, true))
    
    # Initialize blacklist system
    domain = %{domain | blacklist: MapSet.new()}
    
    # Configure solution tree tracking
    domain = AriaEngine.Domain.enable_solution_tree(domain, true)
    
    domain
  end
end
```

### JavaScript/WebGL Implementation

A reference JavaScript implementation provides browser compatibility:

```javascript
class VsekaiInteractivityPlanning {
  constructor(gltf, khrInteractivity) {
    this.gltf = gltf;
    this.khri = khrInteractivity;
    this.entities = this.parseEntities();
    this.actions = this.parseActions();
    this.planner = new TemporalPlanner(this.entities, this.actions);
    this.solutionTree = new SolutionTree();
    this.blacklist = new Set();
  }
  
  executeAction(actionName, args) {
    const action = this.actions[actionName];
    if (!action) throw new Error(`Unknown action: ${actionName}`);
    
    // Check blacklist before execution
    const actionKey = `${actionName}:${JSON.stringify(args)}`;
    if (this.blacklist.has(actionKey)) {
      throw new Error(`Action ${actionName} is blacklisted`);
    }
    
    // Validate entity requirements using capability system
    const validatedEntities = this.validateEntityRequirements(action.requires_entities);
    
    // Execute with temporal constraints and failure handling
    return this.planner.executeWithTiming(action, args, validatedEntities)
      .catch(error => {
        // Blacklist failed action
        this.blacklist.add(actionKey);
        throw error;
      });
  }
  
  validateEntityRequirements(requirements) {
    return requirements.map(req => {
      const entities = this.findEntitiesWithCapabilities(req.type, req.capabilities);
      const availableEntities = entities.filter(entity => 
        this.getEntityState(entity.id, "available") === true
      );
      
      if (availableEntities.length === 0) {
        throw new Error(`No available entity with type ${req.type} and capabilities ${req.capabilities.join(', ')}`);
      }
      
      return availableEntities[0]; // Return first available entity
    });
  }
  
  getEntityState(entityId, property) {
    // Use KHR_interactivity pointer/get node
    const pointer = `/extensions/VSEKAI_interactivity_planning/entities/${entityId}/state/${property}`;
    return this.khri.getPointer(pointer);
  }
  
  setEntityState(entityId, property, value) {
    // Use KHR_interactivity pointer/set node
    const pointer = `/extensions/VSEKAI_interactivity_planning/entities/${entityId}/state/${property}`;
    return this.khri.setPointer(pointer, value);
  }
}
```

## JSON Schema

### Entity Schema

```json
{
  "entity": {
    "type": "object",
    "properties": {
      "type": {
        "type": "string",
        "description": "Entity type (agent, appliance, location, consumable)"
      },
      "capabilities": {
        "type": "array",
        "items": {"type": "string"},
        "description": "List of capabilities this entity possesses"
      },
      "state": {
        "type": "object",
        "description": "Current dynamic state properties (quantities, availability, etc.)"
      }
    },
    "required": ["type", "capabilities"]
  }
}
```

### Action Schema

```json
{
  "action": {
    "type": "object",
    "properties": {
      "duration": {
        "type": "string",
        "pattern": "^P(?:\\d+Y)?(?:\\d+M)?(?:\\d+D)?(?:T(?:\\d+H)?(?:\\d+M)?(?:\\d+(?:\\.\\d+)?S)?)?$",
        "description": "ISO 8601 duration string"
      },
      "start": {
        "type": "string",
        "format": "date-time",
        "description": "ISO 8601 start datetime"
      },
      "end": {
        "type": "string", 
        "format": "date-time",
        "description": "ISO 8601 end datetime"
      },
      "requires_entities": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "type": {"type": "string"},
            "capabilities": {
              "type": "array",
              "items": {"type": "string"}
            }
          },
          "required": ["type", "capabilities"]
        }
      },
      "mutual_exclusion": {
        "type": "array",
        "items": {"type": "string"},
        "description": "Actions that cannot run simultaneously"
      },
      "temporal_constraints": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "type": {"enum": ["before", "after", "during", "overlaps"]},
            "action": {"type": "string"},
            "condition": {"type": "string"}
          }
        }
      },
      "conditions": {
        "type": "object",
        "properties": {
          "at_start": {"type": "array"},
          "over_all": {"type": "array"},
          "at_end": {"type": "array"}
        }
      },
      "effects": {
        "type": "object",
        "properties": {
          "at_start": {"type": "array"},
          "over_time": {"type": "array"},
          "at_end": {"type": "array"}
        }
      }
    },
    "oneOf": [
      {"required": ["duration"]},
      {"required": ["start", "end"]},
      {"required": ["start"]},
      {"required": ["end"]}
    ]
  }
}
```

### Goal Schema

```json
{
  "goal": {
    "type": "object",
    "properties": {
      "subject": {"type": "string"},
      "predicate": {"type": "string"},
      "value": {},
      "constraint": {
        "type": "object",
        "description": "Constraint specification for goal satisfaction"
      }
    },
    "required": ["subject", "predicate", "value"]
  }
}
```

### Planning Domain Schema

```json
{
  "planning_domain": {
    "type": "object",
    "properties": {
      "name": {"type": "string"},
      "execution_strategy": {
        "enum": ["lazy_refinement", "total_order", "partial_order"]
      },
      "goal_verification": {"type": "boolean"},
      "blacklist_failed_actions": {"type": "boolean"},
      "multigoal_handling": {
        "enum": ["explicit_only", "split_allowed", "minizinc_allowed"]
      },
      "solution_tree_enabled": {"type": "boolean"},
      "ipyhop_compatible": {"type": "boolean"}
    },
    "required": ["name", "execution_strategy"]
  }
}
```

## Known Implementations

- **AriaEngine (Elixir)**: Reference implementation with full temporal planning capabilities
  - Repository: https://github.com/v-sekai/aria-character-core
  - Module: `apps/aria_temporal_planner`
  - ADRs: 181-184 (Unified Durative Action Specification)
- **V-Sekai Godot Integration**: Godot engine integration via MCP server
  - Planning interface for NPC behavior and scene orchestration
  - IPyHOP-compatible solution trees and blacklisting

## Resources

- **AriaEngine Documentation**: Comprehensive planning system documentation
  - ADR-181: Core Specification - Unified Durative Action Specification and Planner Standardization
  - ADR-182: Technical Implementation - Fix Duration Handling Precision Loss
  - ADR-183: Architecture & Standards - Planner Standardization Open Problems (IPyHOP Integration)
  - ADR-184: Developer Guide - Unified Action Specification Examples
- **KHR_interactivity Specification**: Foundation interactivity extension with pointer/get and pointer/set nodes
- **ISO 8601**: Temporal specification standards for durations and datetimes
- **IPyHOP Planning**: Interleaved planning and execution methodology with solution trees
- **GTPyhop**: Goal decomposition and pure multigoal handling philosophy

## Example Usage

### Restaurant Kitchen Scene

```json
{
  "asset": {"version": "2.0"},
  "extensionsUsed": ["KHR_interactivity", "VSEKAI_interactivity_planning"],
  "extensions": {
    "KHR_interactivity": {
      "graphs": [
        {
          "types": [
            {"signature": "int"},
            {"signature": "float"},
            {"signature": "bool"},
            {"signature": "string"}
          ],
          "variables": [
            {"type": 0, "value": [0]},
            {"type": 2, "value": [true]}
          ],
          "events": [
            {
              "id": "cooking_complete",
              "values": {
                "meal_type": {"type": 3},
                "chef_id": {"type": 3
