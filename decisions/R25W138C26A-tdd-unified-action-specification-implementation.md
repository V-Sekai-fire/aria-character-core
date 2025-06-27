# R25W138C26A: TDD Unified Action Specification Implementation

<!-- @adr_serial R25W138C26A -->

**Status:** Proposed  
**Date:** 2025-06-25  
**Priority:** HIGH - Implementation Strategy

## Overview

**Purpose**: Test-driven implementation strategy for the unified action specification system  
**Target Audience**: Developers implementing the core AriaEngine specification  
**Scope**: TDD methodology, implementation phases, and testing strategies

## Dependencies

This ADR depends on completion of the core specification ADRs:

- **R25W1398085**: Unified Durative Action Specification and Planner Standardization (authoritative patterns)
- **R25W1405B8B**: Fix Duration Handling Precision Loss (technical implementation)
- **R25W141BE8A**: Planner Standardization Open Problems (architecture standards)
- **R25W1421349**: Unified Action Specification Examples (reference implementations)

## Planned Implementation Strategy

### Migration Strategy Analysis

**Current State**: ADRs 181-184 specify unified action system, but key components are missing from codebase  
**Target State**: Complete TDD implementation of module-based domain pattern with entity validation and enhanced planning

**Migration Approach**:

- Clean break with AST migration (following project's aggressive deprecation pattern)
- Minimal impact - only `aria_scheduler` app requires migration
- Build upon existing solid foundations (Domain infrastructure, StateV2, Hybrid planner)

### Planned TDD Implementation Sequence

#### Phase 1: Module-Based Domain Pattern (Foundation)

**Priority**: CRITICAL - Everything else depends on this  
**Testing Style**: Classic (Sociable) - Domain integration with real components

**Planned Components**:

- `AriaEngine.Domain` macro module
- Attribute parsing (`@action`, `@task_method`, `@unigoal_method`, `@multigoal_method`)
- Integration with existing `Domain.Core` structure
- Metadata extraction and storage
- Backward compatibility with current domain API

#### Phase 2: Entity Validation Framework

**Priority**: HIGH - Required for action requirement validation  
**Testing Style**: Classic (Sociable) - Domain integration with real state management

**Planned Components**:

- `AriaEngine.EntityValidator` module
- Capability matching algorithms
- Entity availability checking
- Integration with StateV2 fact queries
- Comprehensive error reporting

#### Phase 3: Enhanced Planning with Action Priority

**Priority**: MEDIUM - Enhances existing planning system  
**Testing Style**: Mockist (Solitary) - Isolated component testing

**Planned Components**:

- Node type tracking in solution trees
- Action priority in node selection
- Entity validation integration into planning
- Enhanced `Plan.Core` with validation
- Backward compatibility maintenance

#### Phase 4: Automatic Goal Verification

**Priority**: MEDIUM - Enhances existing goal verification  
**Testing Style**: Mockist (Solitary) - Isolated verification logic testing

**Planned Components**:

- Extension of existing `Domain.Utils.verify_goal/7` for automation
- Automatic verification task creation
- Integration with solution tree node types
- Verification failure handling
- Compatibility with manual verification

#### Phase 5: Commands vs Actions Separation

**Priority**: LOW - Architectural enhancement  
**Testing Style**: Mockist (Solitary) - Isolated command/action logic testing

**Planned Components**:

- `AriaEngine.CommandExecution` module
- Command function name generation
- Blacklist integration for command failures
- Planning vs execution phase detection
- Separation between actions and commands

## Planned Testing Philosophy

### Classic Style (Sociable Tests) - Domain Integration Testing

**Use for**: Testing how domain components work together in realistic scenarios

- Real dependencies: StateV2, Domain.Core, EntityValidator working together
- Integration boundaries: Full action workflow from planning to execution
- Realistic scenarios: Complete cooking domain with actual state management

### Mockist Style (Solitary Tests) - Isolated Component Testing

**Use for**: Testing individual components in isolation with clear boundaries

- Mocked dependencies: Isolated testing of EntityValidator, macro parsing, etc.
- Unit boundaries: Single component behavior without external dependencies
- Focused scenarios: Specific validation logic, attribute parsing, error handling

### Decision Criteria

- Domain integration (Phases 1-2): Classic style - test real component interactions
- Component validation (Phases 3-5): Mockist style - test isolated component logic
- Performance testing: Classic style - measure real system behavior
- Error handling: Mockist style - test specific failure scenarios

## Planned Backward Compatibility Strategy

**Preserve existing functionality**:

- All existing `Domain.Core` functionality
- Current action registration patterns
- Existing planning algorithms
- StateV2 fact-based queries
- Timex duration handling
- Blacklist system behavior

**Integration approach**:

- New module pattern extends existing `Domain.add_action/3`
- Entity validation integrates with current state queries
- Action priority enhances existing node selection
- Automatic verification extends manual verification
- Commands system builds on existing `Actions` module

## Success Criteria

After implementation, the system should provide:

- [ ] Complete TDD implementation of module-based domain pattern
- [ ] Entity validation framework with capability matching
- [ ] Enhanced planning with action priority and validation
- [ ] Automatic goal verification with failure handling
- [ ] Clear separation between planning actions and execution commands
- [ ] Full backward compatibility with existing domains
- [ ] Comprehensive test coverage using appropriate testing styles
- [ ] Performance equivalent to or better than current system

**Timeline**: 4-5 weeks (consistent with project's fast iteration cycle)  
**Complexity Level**: Advanced - Core system implementation  
**Prerequisites**: Completion of ADRs 181-184

## Implementation Notes

**Awaiting**: Completion of ADRs 181-184 to ensure implementation follows stable, authoritative patterns.

**Key Requirements**:

- All implementation must follow patterns from R25W1398085
- Technical details must align with R25W1405B8B
- Architecture must follow R25W141BE8A standards
- Examples must be consistent with R25W1421349
- TDD methodology must be rigorously followed
- Backward compatibility must be maintained
- Performance must be validated at each phase
