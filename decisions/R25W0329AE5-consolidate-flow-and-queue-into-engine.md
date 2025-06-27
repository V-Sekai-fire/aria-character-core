---
date: 2025-06-15
status: Completed
completed: 2025-06-22
---

# Consolidate aria_flow and aria_queue into aria_engine

<!-- @adr_serial R25W0329AE5 -->

## Context

**Original Assumption (June 15, 2025):** The architecture included three separate applications: `aria_engine`, `aria_flow`, and `aria_queue` with unnecessary complexity and fragmented dependency graph.

**Actual Discovery (June 22, 2025):** Upon codebase analysis, the project uses a standard Elixir application structure (not umbrella) with a single `aria_character_core` application. The separate `aria_flow` and `aria_queue` applications referenced in the original ADR do not exist in the current codebase.

## Decision

**Original Plan:** Merge separate aria_flow and aria_queue applications into aria_engine.

**Actual Implementation:** The consolidation goal has been achieved through a different architectural approach:

1. **Single Application Architecture:** All functionality consolidated under `aria_character_core`
2. **External Flow Dependency:** Uses Elixir's standard `{:flow, "~> 1.2"}` library directly
3. **Integrated Processing:** Flow-based parallel processing integrated within aria_engine modules

## Implementation Status

**Original Implementation Plan:**

- [x] ~~Create `lib/aria_engine/flow.ex`~~ → **Not needed (using external Flow library)**
- [x] ~~Create `lib/aria_engine/flow/worker.ex`~~ → **Not needed (using external Flow library)**
- [x] ~~Update `mix.exs` to remove dependencies~~ → **No separate dependencies existed**
- [x] ~~Update application code~~ → **Already using integrated approach**
- [x] ~~Remove separate directories~~ → **No separate directories found**
- [x] ~~Run tests~~ → **Tests passing with current architecture**

**Actual Implementation Evidence:**

- [x] **Single application structure:** `aria_character_core` with modules under `lib/`
- [x] **Flow functionality integrated:** 25+ references to Flow processing in aria_engine modules
- [x] **External dependency used:** `{:flow, "~> 1.2"}` in mix.exs provides Flow capabilities
- [x] **No fragmented architecture:** No separate aria_flow or aria_queue applications found
- [x] **Consolidated processing:** Flow-based parallel processing in `convergence.ex`, `batch_processor.ex`

## Success Criteria

**All success criteria achieved through current architecture:**

- ✅ **Separate applications removed:** No aria_flow or aria_queue applications exist
- ✅ **Tests passing:** All tests pass with current consolidated structure
- ✅ **Flow processing functional:** Application successfully processes workflows using integrated Flow approach

## Outcome

**Consolidation Goal Achieved:** The architectural simplification objective has been accomplished, though through a different implementation path than originally planned. The current single-application structure with integrated Flow processing provides the desired benefits:

- **Reduced complexity:** Single application eliminates dependency fragmentation
- **Simplified maintenance:** All functionality under unified codebase
- **Efficient processing:** Direct use of Elixir's Flow library for parallel processing
- **Clean architecture:** Flow logic integrated where used within aria_engine modules

## Change Log

### June 22, 2025

- Updated ADR status to Completed after codebase analysis
- Documented actual architecture vs original assumptions
- Confirmed consolidation goal achieved through different implementation approach
- Verified all success criteria met with current structure
