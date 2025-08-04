# ADR-002: External JSON Registry Storage

<!-- @adr_serial R25W0025C07 -->

## Status

Completed (June 27, 2025)

## Context

The current AriaSerial system uses hardcoded registry entries in `registry.ex`, which creates maintainability issues as the number of serial numbers grows:

**Current Problems:**

- Hardcoded serial entries require recompilation for each new tool
- Registry map becomes large and unwieldy over time
- No separation between code logic and data storage
- Difficult to track registry changes in git history
- Adding new serials requires code changes

**Scale Considerations:**

- Currently ~6 serials, but could grow to 50+ over time
- Need organized storage to prevent folder spam
- Want git-trackable changes to registry data
- Maintain backward compatibility with existing serials

## Decision

Move from hardcoded registry to external JSON storage with organized file structure, while keeping the implementation simple and focused on current needs.

## Architecture

### JSON Storage Structure

```
apps/aria_serial/priv/serial_data/
├── 2025/
│   ├── week_25/
│   │   ├── R_series.json      # R-series serials for this week
│   │   └── metadata.json      # Week summary info
│   └── week_26/
│       ├── R_series.json
│       └── metadata.json
├── projects/
│   ├── aria_core_config.json  # Project-specific settings
│   └── fire_personal_config.json
└── global_metadata.json       # Overall registry metadata
```

### JSON File Format

```json
{
  "week": 25,
  "year": 2025,
  "factory": "R",
  "serials": {
    "R25V001GLTL": {
      "format": "v1",
      "file": "goal_tuples.ex",
      "purpose": "Fix goal tuple parameter order",
      "created": "2025-06-22",
      "week": 25,
      "sequence": 1
    }
  },
  "next_sequence": 7,
  "generated_at": "2025-06-23T20:00:00Z"
}
```

### Implementation Components

**1. Registry Loader Module:**

- Load JSON files and merge into registry map
- Maintain same interface as current hardcoded registry
- Simple file I/O, no complex caching initially

**2. Updated Mix Tasks:**

- `mix serial.create` writes to appropriate week JSON file
- `mix serial.lookup` loads from JSON files
- `mix serial.decode` uses loaded registry data

**3. Migration Strategy:**

- Extract current hardcoded entries to JSON files
- Update registry.ex to load from JSON
- Preserve backward compatibility

## Implementation Plan

### Phase 1: JSON Storage Setup

- [x] Create priv/serial_data directory structure
- [x] Extract current registry entries to week_25 JSON file
- [x] Create global metadata file
- [x] Add JSON schema validation

### Phase 2: Registry Loader

- [x] Create AriaSerial.JsonStorage module
- [x] Implement load_week_data/3 function
- [x] Implement save_week_data/4 function
- [x] Add error handling for missing files

### Phase 3: Update Core Registry

- [x] Modify registry.ex to use JsonStorage
- [x] Maintain existing public API
- [x] Add fallback to hardcoded data if JSON missing
- [x] Test backward compatibility

### Phase 4: Update Mix Tasks

- [x] Update create_serial to write JSON files
- [x] Ensure lookup and decode use new loader
- [x] Add validation for JSON file integrity
- [x] Test all existing functionality

## Benefits

**Maintainability:**

- No recompilation needed for new serials
- Clear separation between code and data
- Git-trackable registry changes
- Organized storage prevents clutter

**Scalability:**

- Ready for growth without code changes
- Weekly organization prevents large files
- Project-specific configurations supported
- Simple to add new factory codes later

**Development Workflow:**

- Easier to review registry changes in PRs
- Simple JSON editing for manual corrections
- Clear audit trail of serial additions
- Backup and restore capabilities

## Consequences

### Positive

- Eliminates need for recompilation when adding serials
- Better organization and git tracking of registry data
- Maintains all existing functionality
- Foundation for future scaling

### Negative

- Slight performance overhead from file I/O
- Additional complexity in deployment (JSON files)
- Need to handle missing file scenarios

### Risk Mitigation

- Keep fallback to hardcoded registry if JSON missing
- Add comprehensive error handling
- Validate JSON schema on load
- Maintain backward compatibility

## Success Criteria

- [x] All existing serial numbers work unchanged
- [x] New serials can be added without recompilation
- [x] Mix tasks function identically to current behavior
- [x] JSON files are properly organized and readable
- [x] Performance impact is negligible for current scale

## Related ADRs

- **ADR-001**: Factory Code Cleanup and Manufacturer Conflict Avoidance (foundation)
