# R25W143C7C4: AriaEngine Quick Start Guide

<!-- @adr_serial R25W143C7C4 -->

**Status:** Proposed  
**Date:** 2025-06-25  
**Priority:** HIGH - Developer Onboarding

## Overview

**Purpose**: Get new developers productive with AriaEngine in under 30 minutes  
**Target Audience**: Developers new to AriaEngine who need immediate practical guidance  
**Scope**: Essential concepts and working examples only

## Dependencies

This ADR depends on completion of the core specification ADRs:

- **R25W1398085**: Unified Durative Action Specification and Planner Standardization (authoritative patterns)
- **R25W1405B8B**: Fix Duration Handling Precision Loss (technical implementation)
- **R25W141BE8A**: Planner Standardization Open Problems (architecture standards)
- **R25W1421349**: Unified Action Specification Examples (developer reference)

## Planned Content Structure

### Your First AriaEngine Domain (5 minutes)

- Step 1: Create a Simple Domain Module
- Step 2: Use Your Domain
- Expected Output

### Essential Concepts (10 minutes)

- Actions vs Goals vs Tasks
- State Management
- Planning Flow

### Common Patterns (10 minutes)

- Pattern 1: Resource Requirements
- Pattern 2: Conditional Logic
- Pattern 3: Multiple Goals

### Troubleshooting (5 minutes)

- Problem: "No methods available for goal"
- Problem: "Action failed during execution"
- Problem: Planning takes too long

### Next Steps

- References to ADRs 186-188 for advanced topics
- References to ADRs 181-184 for technical details

## Success Criteria

After reading this ADR, developers should be able to:

- [ ] Create a basic AriaEngine domain with actions and goals
- [ ] Understand the difference between actions, goals, and tasks
- [ ] Use state management with subject-predicate-value facts
- [ ] Plan and execute simple scenarios
- [ ] Troubleshoot common planning issues
- [ ] Know where to find more detailed information

**Time Investment**: 30 minutes to working AriaEngine knowledge  
**Complexity Level**: Beginner-friendly  
**Prerequisites**: Basic Elixir knowledge

## Implementation Notes

**Awaiting**: Completion of ADRs 181-184 to ensure all examples use authoritative patterns and correct function signatures.

**Key Requirements**:

- All code examples must use patterns from R25W1398085
- State management must follow R25W1405B8B precision handling
- Architecture must align with R25W141BE8A standards
- Examples must be consistent with R25W1421349 reference implementations
