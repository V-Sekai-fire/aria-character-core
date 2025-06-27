# R25W145A6C9: Developer Navigation Guide

<!-- @adr_serial R25W145A6C9 -->

**Status:** Proposed  
**Date:** 2025-06-25  
**Priority:** HIGH - Developer Experience

## Overview

**Purpose**: Help developers efficiently navigate the AriaEngine codebase and documentation  
**Target Audience**: Developers working with AriaEngine who need to find specific information quickly  
**Scope**: Navigation patterns, file organization, and discovery workflows

## Dependencies

This ADR depends on completion of the core specification ADRs:

- **R25W1398085**: Unified Durative Action Specification and Planner Standardization (core concepts)
- **R25W1405B8B**: Fix Duration Handling Precision Loss (technical details)
- **R25W141BE8A**: Planner Standardization Open Problems (architecture overview)
- **R25W1421349**: Unified Action Specification Examples (reference implementations)
- **R25W143C7C4**: AriaEngine Quick Start Guide (entry point)
- **R25W14477B9**: Common Use Cases and Patterns (practical examples)

## Planned Navigation Structure

### Documentation Hierarchy

**Learning Path**:

1. R25W143C7C4: Quick Start Guide (30 minutes)
2. R25W14477B9: Common Use Cases (45 minutes)
3. R25W145A6C9: Navigation Guide (15 minutes)
4. R25W14702E9: Practical How-To (reference)

**Technical Reference**:

1. R25W1398085: Core Specification (authoritative)
2. R25W1405B8B: Technical Implementation
3. R25W141BE8A: Architecture Standards
4. R25W1421349: Developer Examples

### Codebase Organization

**App Structure**:

- `apps/aria_engine_core/` - Core planning engine
- `apps/aria_state/` - State management
- `apps/aria_hybrid_planner/` - Hybrid planning strategies
- `apps/aria_temporal_planner/` - Temporal constraint handling
- `apps/aria_scheduler/` - Execution scheduling

**Key Files by Purpose**:

- Domain Definition: How to structure domains
- Action Implementation: Action function patterns
- Goal Methods: Goal resolution strategies
- State Management: Subject-predicate-value operations
- Testing: Test patterns and examples

### Discovery Workflows

#### "I want to implement a new action"

**Navigation Path**:

1. Start with R25W1421349 examples
2. Check action attribute patterns in R25W1398085
3. Review duration handling in R25W1405B8B
4. Find similar actions in codebase
5. Follow testing patterns

#### "I need to debug planning failures"

**Navigation Path**:

1. Check troubleshooting in R25W143C7C4
2. Review error patterns in R25W14477B9
3. Examine test failures in relevant apps
4. Use debugging techniques from R25W14702E9

#### "I want to understand the architecture"

**Navigation Path**:

1. Read R25W141BE8A for high-level architecture
2. Review R25W1398085 for core concepts
3. Examine app dependencies and interfaces
4. Study integration patterns

#### "I need to add temporal constraints"

**Navigation Path**:

1. Review temporal examples in R25W1421349
2. Check duration handling in R25W1405B8B
3. Examine `aria_temporal_planner` app
4. Study STN constraint patterns

## Planned Search Strategies

### By Functionality

- **Actions**: Search for `@action` attributes
- **Goals**: Search for `@unigoal_method` attributes
- **Tasks**: Search for `@task_method` attributes
- **State**: Search for `AriaState.ObjectState` usage
- **Tests**: Search for `test/` directories and `_test.exs` files

### By Problem Domain

- **Restaurant/Kitchen**: Search for cooking, ordering examples
- **Scheduling**: Search for meeting, calendar examples
- **Resource Management**: Search for allocation, transport examples
- **Temporal**: Search for duration, timeline examples

### By Error Type

- **Planning Failures**: Search for error handling patterns
- **State Issues**: Search for state validation examples
- **Resource Conflicts**: Search for entity requirement patterns
- **Performance**: Search for optimization examples

## Planned Quick Reference

### Essential Patterns

- Action definition template
- Goal method template
- Task method template
- State operation patterns
- Error handling patterns

### Common Locations

- Domain modules: `lib/*/domains/`
- Core functions: `lib/*/core/`
- Test examples: `test/*/`
- Documentation: `decisions/`

### Debugging Tools

- Test runner commands
- State inspection utilities
- Planning trace tools
- Performance profiling

## Success Criteria

After reading this ADR, developers should be able to:

- [ ] Navigate efficiently between documentation and code
- [ ] Find relevant examples for their specific use case
- [ ] Locate the right files for different types of changes
- [ ] Follow established workflows for common development tasks
- [ ] Debug issues using appropriate tools and techniques
- [ ] Understand the relationship between different components

**Complexity Level**: Beginner to Intermediate  
**Prerequisites**: R25W143C7C4 (Quick Start Guide)  
**Time Investment**: 15 minutes for navigation mastery

## Implementation Notes

**Awaiting**: Completion of ADRs 181-184 to ensure navigation paths reference stable, authoritative content.

**Key Requirements**:

- Navigation paths must reference completed ADRs
- Code locations must reflect current app structure
- Search strategies must work with actual codebase
- Workflows must be validated against real development tasks
- Quick reference must be accurate and up-to-date
