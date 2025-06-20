# AriaTown

AriaTown provides game world simulation and NPC (Non-Player Character) behavior management for the Aria Character Core system. It creates dynamic, interactive virtual environments with intelligent characters.

## Overview

AriaTown implements a comprehensive game world simulation with:

- **NPC Behavior Management**: Intelligent character AI with planning and decision-making
- **World Simulation**: Dynamic environment with persistent state and events
- **Social Interactions**: Complex character relationships and communication
- **Economic Systems**: Resource management and trading mechanics
- **Event-Driven Gameplay**: Dynamic story generation and quest systems

## Core Components

### NPC Management

- Intelligent character behavior using AriaEngine planning
- Personality systems and character traits
- Goal-oriented behavior and decision making
- Social relationship modeling

### World Simulation

- Persistent world state and environment
- Dynamic events and environmental changes
- Time progression and scheduling systems
- Location and spatial relationship management

### Social Systems

- Character-to-character interactions
- Reputation and relationship tracking
- Communication and dialogue systems
- Group dynamics and faction management

### Economic Systems

- Resource production and consumption
- Trading and market mechanics
- Inventory and item management
- Economic simulation and balance

## Usage

### Creating NPCs

```elixir
# Create an NPC with personality and goals
npc = AriaTown.NPC.create(%{
  name: "Alice",
  personality: %{
    friendliness: 0.8,
    curiosity: 0.6,
    ambition: 0.7
  },
  goals: ["find_food", "socialize", "explore"],
  location: "town_square"
})

# Update NPC behavior
AriaTown.NPC.update_behavior(npc, new_goals: ["help_player"])
```

### World Management

```elixir
# Initialize world state
world = AriaTown.World.initialize(%{
  locations: ["town_square", "market", "tavern", "forest"],
  time_of_day: :morning,
  weather: :sunny
})

# Advance world simulation
AriaTown.World.tick(world, delta_time: 60)  # 1 minute

# Handle world events
AriaTown.World.trigger_event(world, :market_day)
```

### Social Interactions

```elixir
# Create interaction between NPCs
interaction = AriaTown.Social.interact(npc1, npc2, :conversation)

# Update relationships
AriaTown.Social.update_relationship(npc1, npc2, :friendship, +0.1)

# Check social status
reputation = AriaTown.Social.get_reputation(npc, :town_square)
```

### Economic Systems

```elixir
# Create economic transaction
transaction = AriaTown.Economy.trade(
  seller: merchant_npc,
  buyer: customer_npc,
  item: "bread",
  price: 5
)

# Update market prices
AriaTown.Economy.update_market_prices(world, supply_demand_changes)
```

## Architecture

AriaTown follows a modular simulation architecture:

```
AriaTown
├── NPCs (Character AI & Behavior)
├── World (Environment & State)
├── Social (Relationships & Interactions)
├── Economy (Resources & Trading)
└── Events (Dynamic Content Generation)
```

## Simulation Features

- **Real-time Simulation**: Continuous world updates and character behavior
- **Emergent Gameplay**: Unscripted interactions and story generation
- **Persistent State**: World and character state preservation
- **Scalable Architecture**: Support for hundreds of NPCs and complex worlds
- **Modular Design**: Easy addition of new systems and mechanics

## NPC AI Features

- **Goal-Oriented Planning**: NPCs use AriaEngine for intelligent decision making
- **Personality-Driven Behavior**: Character traits influence actions and decisions
- **Learning and Adaptation**: NPCs learn from interactions and experiences
- **Social Awareness**: Characters understand and respond to social dynamics
- **Emotional States**: Dynamic emotional responses to events and interactions

## Configuration

Configure AriaTown in your application:

```elixir
config :aria_town,
  simulation_speed: 1.0,
  max_npcs: 100,
  world_persistence: true,
  ai_planning_depth: 5,
  social_update_frequency: 30  # seconds
```

## World Building

AriaTown supports rich world creation:

- **Location Networks**: Connected areas with travel mechanics
- **Resource Distribution**: Strategic placement of resources and services
- **Event Scripting**: Custom events and story triggers
- **Dynamic Weather**: Environmental effects on gameplay
- **Day/Night Cycles**: Time-based behavior changes

## Development

### Running Tests

```bash
mix test test/aria_town/ --timeout 120
```

### Creating Custom NPCs

```elixir
defmodule MyTown.CustomNPC do
  use AriaTown.NPC.Behavior
  
  def personality_traits do
    %{
      merchant: 0.9,
      helpful: 0.7,
      talkative: 0.8
    }
  end
  
  def default_goals do
    ["sell_items", "gather_information", "maintain_shop"]
  end
end
```

### World Event Scripting

```elixir
defmodule MyTown.Events do
  use AriaTown.Events
  
  def festival_event(world) do
    world
    |> increase_npc_happiness(0.2)
    |> spawn_temporary_vendors()
    |> play_festival_music()
  end
end
```

## Integration

AriaTown integrates seamlessly with other Aria components:

- **AriaEngine**: Powers NPC AI and decision making
- **AriaAuth**: Manages player authentication and sessions
- **AriaStorage**: Persists world state and character data
- **AriaSecurity**: Secures player data and prevents cheating

## Use Cases

- **RPG Games**: Rich NPC interactions and world simulation
- **Social Simulations**: Complex character relationship modeling
- **Educational Games**: Historical or cultural simulations
- **Virtual Worlds**: Persistent online environments
- **AI Research**: Testing multi-agent systems and emergent behavior

## Related Components

- **AriaEngine**: Core planning and execution engine
- **AriaAuth**: Authentication and session management
- **AriaStorage**: Persistent storage and archiving
- **AriaSecurity**: Security infrastructure and secrets management

## Status

AriaTown is actively developed with focus on creating rich, believable virtual worlds. The NPC AI system leverages AriaEngine's planning capabilities to create intelligent, goal-oriented characters that provide engaging gameplay experiences.
