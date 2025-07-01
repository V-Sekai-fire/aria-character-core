# Module Size Guideline Enforcement

**Status:** Active  
**Date:** 2025-06-30  
**Serial:** R25W00004A

## Context

The .clinerules specify module size guidelines that are currently violated across the codebase:
- **200-300 lines**: Review and consider splitting (soft threshold)
- **400-500 lines**: Strong recommendation to split (firm threshold)  
- **500+ lines**: Mandatory splitting (hard limit)

Analysis reveals multiple modules violating these guidelines, with several requiring mandatory splitting.

## Violation Analysis

### Mandatory Splitting Required (500+ lines)
- `aria_core/action_attributes.ex` (596 lines) - **CRITICAL**
- `timeline/internal/stn/core.ex` (550 lines) - **CRITICAL**  
- `aria_serial/mix/tasks/decode.ex` (515 lines) - **CRITICAL**

### Strong Recommendation (400-500 lines)
- `aria_timeline/bridge.ex` (480 lines)
- `aria_gltf/mesh.ex` (480 lines)
- `aria_math/primitives.ex` (477 lines)
- `aria_core/state/relational.ex` (477 lines)
- `aria_storage/casync_decoder.ex` (472 lines)
- `aria_core/temporal/interval.ex` (469 lines)
- `aria_core/unified_domain.ex` (468 lines)
- `aria_hybrid_planner/plan.ex` (455 lines)
- `aria_core/temporal_converter.ex` (453 lines)
- `aria_joint/joint.ex` (444 lines)
- `aria_engine_core/plan.ex` (440 lines)
- `aria_storage/parsers/casync_format/archive_parser.ex` (436 lines)
- `aria_core/entity/management.ex` (412 lines)
- `aria_town.ex` (404 lines)
- `aria_timeline_intervals/allen_relations.ex` (402 lines)
- `aria_hybrid_planner/engine_integration.ex` (401 lines)

## Implementation Plan

### Phase 1: Mandatory Splitting (PRIORITY: HIGH)
**Target:** Eliminate all 500+ line violations

#### Task 1.1: Split AriaCore.ActionAttributes (596 lines) ✅ **COMPLETED**
**File:** `apps/aria_core/lib/aria_core/action_attributes.ex`

**Splitting Strategy:**
- [x] **Main module**: Macro system and `__using__` logic (~60 lines)
- [x] **Documentation module**: All `*_attribute_docs` functions (~145 lines) 
- [x] **Converters module**: All `convert_*_metadata` functions (~125 lines)
- [x] **Registry module**: `create_entity_registry` and `create_temporal_specifications` (~75 lines)
- [x] **Macros module**: All attribute macro definitions (~100 lines)
- [x] **Compiler module**: Compilation-time processing (~165 lines)

**Implementation Steps:**
1. ✅ Create `action_attributes/documentation.ex` for docs functions
2. ✅ Create `action_attributes/converters.ex` for metadata conversion
3. ✅ Create `action_attributes/registry.ex` for registry creation
4. ✅ Create `action_attributes/macros.ex` for attribute macros
5. ✅ Create `action_attributes/compiler.ex` for compilation processing
6. ✅ Update main module to delegate to split modules
7. ✅ All modules now under 200-line guideline

**Results:** Successfully split into 6 focused modules, each with single responsibility and under size guidelines.

#### Task 1.2: Split Timeline.Internal.STN.Core (550 lines) 
**File:** `apps/aria_timeline/lib/timeline/internal/stn/core.ex`

**Splitting Strategy:**
- [ ] **Core operations**: add/remove intervals, constraints (~200 lines)
- [ ] **Consistency module**: validation and mathematical checks (~150 lines)
- [ ] **Scheduling module**: interval queries, slot finding (~200 lines)

**Implementation Steps:**
1. Create `stn/operations.ex` for core add/remove operations
2. Create `stn/consistency.ex` for validation logic  
3. Create `stn/scheduling.ex` for interval scheduling
4. Update main core module to delegate appropriately
5. Verify STN functionality remains intact

#### Task 1.3: Split Mix.Tasks.Serial.Decode (515 lines)
**File:** `apps/aria_serial/lib/mix/tasks/decode.ex`

**Splitting Strategy:**
- [ ] **Mix task interface**: CLI parsing and main run function (~100 lines)
- [ ] **Display module**: Formatting and output functions (~200 lines)
- [ ] **Similarity module**: String matching algorithms (~200 lines)

**Implementation Steps:**
1. Create `serial/display.ex` for output formatting
2. Create `serial/similarity.ex` for string matching
3. Update mix task to use extracted modules
4. Test CLI functionality thoroughly

### Phase 2: Firm Threshold Modules (PRIORITY: MEDIUM)
**Target:** Address 400-500 line modules systematically

#### Planning Approach:
- [ ] Analyze each 400+ line module for logical splitting points
- [ ] Prioritize by architectural impact and usage frequency
- [ ] Split modules with clear responsibility boundaries first
- [ ] Address tightly coupled modules requiring careful extraction

### Phase 3: Soft Threshold Review (PRIORITY: LOW)
**Target:** Review 200-300 line modules for potential improvements

#### Review Criteria:
- [ ] Multiple distinct responsibilities within single module
- [ ] High complexity or cognitive load
- [ ] Frequent modification requiring careful changes
- [ ] Clear benefits from splitting outweigh maintenance overhead

## Success Criteria

### Immediate Success (Phase 1)
- [ ] **Zero modules over 500 lines** - eliminate all mandatory violations
- [ ] **All tests passing** - functionality preserved after splitting
- [ ] **Clean module boundaries** - each split module has single responsibility
- [ ] **Proper delegation** - main modules coordinate split functionality

### Complete Success (All Phases)  
- [ ] **Consistent module sizes** - most modules under 300 lines
- [ ] **Clear architecture** - module boundaries reflect logical responsibilities
- [ ] **Maintainable codebase** - easier to understand and modify individual modules
- [ ] **Documentation compliance** - all modules follow size guidelines

## Implementation Strategy

### Systematic Approach:
1. **Backup original files** with `.bak` extension for safety
2. **Identify logical boundaries** within each large module
3. **Create split modules** with focused responsibilities  
4. **Update main module** to delegate to split modules
5. **Verify functionality** through comprehensive testing
6. **Document split rationale** for future maintenance

### Risk Mitigation:
- **Incremental changes** - split one module completely before starting next
- **Comprehensive testing** - verify each split maintains functionality
- **Clear commit messages** - document what was split and why
- **Backup strategy** - preserve original files during transition

## Related ADRs

- **INST-041**: Apps todo file management - provides umbrella structure requirements
- **INST-036**: Elixir module splitting - defines splitting methodology
- **INST-035**: Logical commit grouping - ensures proper change tracking

## Current Focus

Starting with **AriaCore.ActionAttributes** (596 lines) as the largest violation. This module has clear responsibility boundaries making it an ideal candidate for demonstrating the splitting approach.
