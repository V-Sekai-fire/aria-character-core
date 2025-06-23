# AriaEngine Core Migration Tombstone

**Extracted:** 2025-06-23  
**New Location:** `apps/aria_engine_core/`  
**ADR Reference:** ADR-151 Strict Encapsulation

This module was extracted to maintain strict encapsulation boundaries.
All core functionality (state management, domain utilities, validation, 
multigoal processing, and MiniZinc execution) now available in the 
dedicated umbrella app.

## Extracted Components

- Core state management (`state.ex`, `state_v2.ex`)
- Domain utilities and behavior (`domain.ex`, `domain_behaviour.ex`, `actions.ex`)
- Validation and utility functions (`validation.ex`, `utils.ex`, `info.ex`)
- Multigoal processing (`multigoal.ex`)
- MiniZinc solver execution (`minizinc/`)
- Domain subdirectory with actions, methods, and durative actions

## Dependencies

The aria_engine_core app is now a dependency of:
- aria_temporal_planner (for core state and domain functionality)
- Main aria_character_core project (for engine integration)
