# AriaTown

NPC management and virtual world system for Aria Character Core.

## Overview

AriaTown provides the foundation for creating rich, interactive virtual worlds with intelligent NPCs. This module handles NPC lifecycle management, time progression, and semantic data structures for virtual environments.

## Features

- **NPC Management**: Spawn, update, and manage virtual characters
- **Time Management**: Game time progression and scheduling
- **Persistence**: Data storage and retrieval for virtual world state
- **Semantic Web**: RDF-based context schemas for rich data representation
- **JSON-LD Support**: Structured data with semantic meaning

## Architecture

AriaTown is built as a supervision tree with three main components:

- **NPCManager**: Handles NPC lifecycle and behavior coordination
- **TimeManager**: Manages game time and temporal events
- **PersistenceManager**: Handles data storage and retrieval

## Current Status

This is currently a stub implementation providing the basic GenServer structure needed for the supervision tree. Future development will add:

### NPCManager

- NPC lifecycle management (spawn, despawn, persistence)
- Behavior coordination and AI planning integration
- NPC state synchronization and updates
- Social interaction and relationship management

### TimeManager

- Game time progression and scheduling
- Day/night cycles and temporal events
- NPC scheduling coordination
- Time-based triggers and automation

### PersistenceManager

- Virtual world state persistence
- NPC data storage and retrieval
- Configuration management
- Backup and recovery systems

## Planned Integration

Future NPCs will integrate with AriaEngine's hybrid planner for:

- Goal-oriented behavior planning
- Temporal scheduling of activities
- Social interaction planning
- Resource and spatial reasoning

## Dependencies

- **RDF**: Semantic web support for rich data representation
- **Jason**: JSON encoding/decoding
- **Logger**: Logging and debugging support

## Usage

```elixir
# Start the AriaTown application
{:ok, _} = Application.start(:aria_town)

# Spawn an NPC
{:ok, npc} = AriaTown.NPCManager.spawn_npc(%{
  name: "Village Merchant",
  position: {10, 5, 0}
})

# Update NPC state
{:ok, updated_npc} = AriaTown.NPCManager.update_npc(npc.id, %{
  state: :trading,
  mood: :friendly
})

# List all NPCs
npcs = AriaTown.NPCManager.list_npcs()
```

## Testing

Run the test suite:

```bash
cd apps/aria_town
mix test
```

## Development

AriaTown is actively developed with focus on creating rich, believable virtual worlds. The NPC AI system will leverage AriaEngine's planning capabilities to create intelligent, goal-oriented characters that provide engaging gameplay experiences.
