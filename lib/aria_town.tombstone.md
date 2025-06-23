# AriaTown Module Extraction

This module has been extracted to a separate application.

**New Location**: `apps/aria_town/`

**Extraction Date**: June 23, 2025

**Reason**: Modular architecture - AriaTown is now a standalone application within the umbrella project for better encapsulation and testing.

## What was moved

- `lib/aria_town/` → `apps/aria_town/lib/`
- All AriaTown modules and functionality
- Tests and documentation

## Usage

The AriaTown application is automatically started as part of the umbrella project. All public APIs remain the same:

```elixir
# NPCs
{:ok, npc} = AriaTown.NPCManager.spawn_npc(%{name: "Test NPC"})
AriaTown.NPCManager.list_npcs()

# Persistence
AriaTown.PersistenceManager.trigger_save()
```

## Dependencies

AriaTown is now listed as an internal dependency in the main `mix.exs`:

```elixir
{:aria_town, in_umbrella: true}
