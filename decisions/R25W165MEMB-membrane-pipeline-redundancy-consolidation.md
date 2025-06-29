# R25W165MEMB: Membrane Pipeline Redundancy Consolidation

**Status:** Active  
**Date:** 2025-06-28  
**Priority:** HIGH

## Context

Analysis of the aria_membrane_pipeline app reveals significant redundancy in filter implementations, format definitions, and testing components. This redundancy creates maintenance overhead, potential inconsistencies, and confusion about which components to use.

## Identified Redundancies

### 1. Duplicate Response Transformation Logic

**Files:**

- `lib/membrane/response_filter.ex` - Converts PlanningResult to MCPResponse
- `lib/membrane/planner_mcp_filter.ex` - Also converts PlanningResult to MCPResponse

**Issue:** Both filters perform identical transformation from PlanningResult to MCPResponse format with similar telemetry and error handling.

### 2. Overlapping Format Definitions

**Files:**

- `lib/membrane/format/planning_request.ex` - Contains domain, state, goals, options
- `lib/membrane/format/planning_params.ex` - Contains goal, context, constraints

**Issue:** Both represent planning input data but with different structures and field names, creating confusion about which to use.

### 3. Inconsistent Naming and Structure

**Files:**

- `lib/membrane/format/planning_response.ex` - Defines `Membrane.Format.PlanningResult` module

**Issue:** File name suggests "response" but module name is "PlanningResult", creating naming confusion.

### 4. Testing Component Duplication

**Files:**

- `lib/membrane/format_transformer_filter.ex` - Generic transformer with mock scenarios
- `lib/membrane/pipeline_manager.ex` - Contains `Membrane.EchoFilter` for testing

**Issue:** Both provide testing/mocking functionality with overlapping capabilities.

### 5. Specialized Filters in Core Pipeline

**Files:**

- `lib/membrane/minizinc_solver_filter.ex` - Widget assembly specific solver
- `lib/membrane/testing_filter.ex` - Testing-specific functionality

**Issue:** Domain-specific and testing filters mixed with core pipeline components.

## Decision

Consolidate redundant elements to create a cleaner, more maintainable pipeline architecture:

### Phase 1: Response Filter Consolidation

- [x] Merge `ResponseFilter` and `PlannerMCPFilter` into single `ResponseFilter`
- [x] Preserve best features from both implementations
- [x] Remove duplicate `planner_mcp_filter.ex`

### Phase 2: Format Standardization  

- [x] Standardize on `PlanningParams` format (simpler, more focused)
- [x] Remove `PlanningRequest` format
- [x] Update all references to use `PlanningParams`

### Phase 3: Naming Consistency

- [x] Rename `planning_response.ex` to `planning_result.ex` to match module name
- [x] Or rename module to `PlanningResponse` to match file name
- [x] Ensure consistent naming throughout pipeline

### Phase 4: Testing Consolidation

- [x] Merge `FormatTransformerFilter` and `EchoFilter` into single testing component
- [x] Create configurable testing filter with multiple scenarios
- [x] Remove duplicate testing implementations

### Phase 5: Specialized Filter Extraction

- [ ] Move `MinizincSolverFilter` to separate app if still needed
- [ ] Remove testing-specific filters from core pipeline
- [ ] Keep only essential pipeline filters

## Implementation Plan

### Step 1: Analyze Current Usage

1. Search codebase for references to redundant components
2. Identify which implementations are actively used
3. Document dependencies and integration points

### Step 2: Create Consolidated Components

1. Design unified ResponseFilter with best features from both
2. Standardize on PlanningParams format
3. Create comprehensive testing filter

### Step 3: Update Pipeline Configuration

1. Update pipeline manager to use consolidated components
2. Remove references to deprecated filters
3. Update documentation and examples

### Step 4: Remove Redundant Files

1. Delete duplicate filter implementations
2. Remove unused format definitions
3. Clean up imports and references

## Success Criteria

- [ ] Single response transformation filter handling all PlanningResult → MCPResponse conversion
- [ ] Unified format definition for planning parameters
- [ ] Consistent naming throughout pipeline components
- [ ] Single configurable testing component
- [ ] Reduced file count in membrane pipeline app
- [ ] All existing functionality preserved
- [ ] Pipeline tests passing with consolidated components

## Consequences

**Positive:**

- Reduced maintenance overhead
- Clearer component responsibilities
- Easier to understand pipeline flow
- Consistent API across components
- Simplified testing and debugging

**Negative:**

- Requires careful migration to avoid breaking changes
- May need to update external dependencies
- Short-term development overhead for consolidation

## Related ADRs

- R25W025F371 - Replace membrane with flow for parallel processing
- R25W070D1AF - Membrane planning pipeline integration
- R25W071D281 - Fix membrane pipeline implementation

## Files Affected

**To be consolidated:**

- `lib/membrane/response_filter.ex`
- `lib/membrane/planner_mcp_filter.ex`
- `lib/membrane/format/planning_request.ex`
- `lib/membrane/format_transformer_filter.ex`

**To be removed:**

- `lib/membrane/planner_mcp_filter.ex`
- `lib/membrane/format/planning_request.ex`
- `lib/membrane/minizinc_solver_filter.ex` (move to separate app)

**To be renamed:**

- `lib/membrane/format/planning_response.ex` → `planning_result.ex`
