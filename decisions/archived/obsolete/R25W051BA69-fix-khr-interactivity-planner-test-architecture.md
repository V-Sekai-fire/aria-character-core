# TOMBSTONE: Fix KHR Interactivity Node Library Planner Test Architecture

**Status:** Obsolete and Archived  
**Original Date:** June 18, 2025  
**Deletion Date:** June 18, 2025  
**Archived Date:** June 28, 2025  
**Archive Location:** `decisions/archived/obsolete/`

## Summary

This ADR addressed fundamental architectural issues in KHR Interactivity node library planner tests, including test isolation problems, API layer confusion, and broken execution flow. The work was completed successfully but became obsolete when the entire KHR system was deleted.

## Archive Reason

**Obsolete ADR:** The entire KHR_interactivity system has been deleted from the project. All KHR node library, domain implementation, tests, and related infrastructure have been removed.

## Historical Context

This ADR tackled critical testing architecture problems in the KHR (Khronos glTF Interactivity) system:

- **Test Isolation Issues**: Fixed shared GLTF scene mocks causing test interference
- **API Layer Confusion**: Clarified boundaries between StateV2 facts and GLTF scene execution
- **Execution Flow**: Implemented proper `run_lazy_refineahead()` execution instead of manual helpers
- **4-Layer Architecture**: Established proper separation between domain, plan, planner, and GLTF scene layers

## Key Achievements (Before System Deletion)

- ✅ Test isolation with per-test GLTF scene initialization
- ✅ Proper execution flow using `PlannerAdapter.run_lazy_refineahead()`
- ✅ Scene state validation via `GLTFSceneMock.get_node_property()`
- ✅ 4-layer architectural separation
- ✅ Domain registration working (22 actions, 44 task methods)

## System Deletion Context

The KHR system was removed as part of project scope reduction and architectural simplification. This ADR represents completed work that became obsolete due to strategic project decisions rather than technical failure.

---
*This ADR has been archived as the related system no longer exists. The original content is preserved in git history for reference.*

*For active ADRs, see the main `decisions/` directory.*
