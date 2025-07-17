# R25W030C3AA: Aria Queue Functional Implementation

<!-- @adr_serial R25W030C3AA -->

## Status

**ARCHIVED** - Moved to `decisions/archived/obsolete/` (July 16, 2025)

## Tombstone Summary

**Original Status:** Paused (Started: June 15, 2025)

**Why Obsolete:**
- No `aria_queue` application exists in current codebase architecture
- Project uses umbrella architecture with different app structure
- Queue functionality appears to be handled through other mechanisms
- Original assumptions about separate aria_queue app were incorrect

**Archive Reason:** ADR became obsolete due to architectural reality differing from original assumptions.

**Original Intent:**
- Implement aria_queue as functional background job processing system
- Provide Flow-based processing pipelines for job management
- Enable aria_engine and aria_timestrike functionality
- Create Oban-compatible API for existing code

**Current Reality:**
- No aria_queue app found in apps/ directory
- Background processing handled through different architecture
- Flow processing integrated directly in relevant modules
- Job processing needs met through alternative implementations

## Archive Location

**Full ADR content:** `decisions/archived/obsolete/R25W030C3AA-aria-queue-functional-implementation.md`

**Git History:** Use `git log --follow decisions/archived/obsolete/R25W030C3AA-aria-queue-functional-implementation.md` to see complete development history.

## Alternative Solutions

If queue functionality is needed:
- Consider using existing Elixir job processing libraries (Oban, Exq)
- Implement queue functionality within existing umbrella apps
- Use GenStage/Flow for stream processing needs
- Evaluate if background processing is actually required

---

*Archived: July 16, 2025*  
*Original start: June 15, 2025*
