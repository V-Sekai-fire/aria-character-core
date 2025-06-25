# ADR-187: Developer Navigation Guide

**Status:** Active  
**Date:** 2025-06-25  
**Priority:** HIGH - Developer Experience

## Overview

**Purpose**: Help developers quickly find what they need in the AriaEngine codebase and documentation  
**Target Audience**: All AriaEngine developers, especially those new to the project  
**Scope**: Navigation strategies, documentation map, and troubleshooting workflows

## Quick Reference Map

### I Need To...

**Get Started (New to AriaEngine)**
→ **ADR-185**: AriaEngine Quick Start Guide (30 minutes to productivity)

**See Real Examples**
→ **ADR-186**: Common Use Cases and Patterns (restaurant, meetings, resources)

**Understand the Technical Details**
→ **ADR-181**: Core Specification (complete action/goal reference)

**Debug Planning Problems**
→ **ADR-188**: Practical How-To Documentation (debugging section)

**Implement Temporal Actions**
→ **ADR-182**: Technical Implementation (duration handling, validation)

**Understand System Architecture**
→ **ADR-183**: Architecture & Standards (IPyHOP integration, design patterns)

**See Complete Working Examples**
→ **ADR-184**: Developer Guide (comprehensive patterns and examples)

## Documentation Architecture

### Accessibility Layer (Start Here)

```
ADR-185: Quick Start Guide
├── Basic concepts (actions, goals, tasks)
├── Your first domain (5 minutes)
├── Essential patterns (10 minutes)
└── Troubleshooting (5 minutes)

ADR-186: Common Use Cases
├── Restaurant kitchen management
├── Meeting scheduling system
├── Resource management
└── Best practices and patterns

ADR-187: Navigation Guide (this document)
├── How to find what you need
├── Documentation relationships
└── Troubleshooting workflows

ADR-188: Practical How-To
├── Advanced techniques
├── Debugging strategies
└── Integration patterns
```

### Technical Layer (Deep Dive)

```
ADR-181: Core Specification
├── Entity model and capabilities
├── Action specification format
├── Goal format standardization
└── Temporal patterns

ADR-182: Technical Implementation
├── Duration handling and precision
├── Validation framework
├── Entity requirements
└── Type specifications

ADR-183: Architecture & Standards
├── IPyHOP integration
├── Solution tree structure
├── Blacklist system
└── Multigoal philosophy

ADR-184: Developer Guide
├── Complete module patterns
├── IPyHOP compatibility
├── Migration guidance
└── Implementation examples
```

## Finding What You Need

### By Problem Type

**"I don't know where to start"**
1. Read ADR-185 (Quick Start Guide) - 30 minutes
2. Try the examples in ADR-186 (Common Use Cases)
3. Come back here when you need specific help

**"My planning is failing"**
1. Check ADR-188 (Practical How-To) debugging section
2. Verify your domain follows ADR-185 patterns
3. Compare with working examples in ADR-186

**"I need to implement temporal actions"**
1. Start with ADR-185 basic patterns
2. See ADR-186 meeting scheduling example
3. Deep dive into ADR-182 for technical details

**"I'm getting validation errors"**
1. Check ADR-182 validation framework
2. Verify entity requirements format in ADR-181
3. Compare with working examples in ADR-186

**"I need to understand the architecture"**
1. Read ADR-183 for system design
2. See ADR-184 for implementation patterns
3. Check ADR-181 for core concepts

### By Experience Level

**Beginner (New to AriaEngine)**
```
1. ADR-185: Quick Start Guide (required)
2. ADR-186: Common Use Cases (recommended)
3. ADR-187: Navigation Guide (this document)
4. ADR-188: Practical How-To (when needed)
```

**Intermediate (Building Real Systems)**
```
1. ADR-186: Common Use Cases (patterns)
2. ADR-188: Practical How-To (techniques)
3. ADR-182: Technical Implementation (details)
4. ADR-184: Developer Guide (comprehensive examples)
```

**Advanced (System Integration)**
```
1. ADR-183: Architecture & Standards (design)
2. ADR-181: Core Specification (reference)
3. ADR-184: Developer Guide (complete patterns)
4. ADR-182: Technical Implementation (internals)
```

## Code Organization Map

### AriaEngine Apps Structure

```
apps/
├── aria_engine_core/          # Core planning engine
│   ├── lib/aria_engine/
│   │   ├── domain.ex          # Domain creation (see ADR-185)
│   │   ├── planner.ex         # Planning logic (see ADR-183)
│   │   └── state.ex           # State management (see ADR-185)
│   └── test/                  # Core tests
│
├── aria_hybrid_planner/       # Hybrid planning strategies
│   ├── lib/hybrid_planner/
│   │   ├── strategies/        # Execution strategies (see ADR-183)
│   │   └── coordinator.ex     # Planning coordination
│   └── test/                  # Strategy tests
│
├── aria_temporal_planner/     # Temporal planning
│   ├── lib/temporal_planner/
│   │   ├── timeline.ex        # Timeline management (see ADR-182)
│   │   └── constraints.ex     # Temporal constraints
│   └── test/                  # Temporal tests
│
└── aria_scheduler/            # Scheduling and execution
    ├── lib/scheduler/
    │   ├── activities.ex      # Activity scheduling (see ADR-186)
    │   └── execution.ex       # Plan execution
    └── test/                  # Scheduler tests
```

### Key Files for Common Tasks

**Creating Domains**
- `apps/aria_engine_core/lib/aria_engine/domain.ex` - Domain behavior
- See ADR-185 for basic patterns
- See ADR-186 for complete examples

**State Management**
- `apps/aria_engine_core/lib/aria_engine/state.ex` - State operations
- See ADR-185 for subject-predicate-value patterns
- See ADR-186 for state validation examples

**Planning and Execution**
- `apps/aria_engine_core/lib/aria_engine/planner.ex` - Core planning
- `apps/aria_hybrid_planner/lib/hybrid_planner/` - Strategy execution
- See ADR-183 for architecture details

**Temporal Actions**
- `apps/aria_temporal_planner/lib/temporal_planner/` - Temporal logic
- See ADR-182 for duration handling
- See ADR-186 for meeting scheduling example

## Troubleshooting Workflows

### Planning Failures

```
Planning Failed
├── Check error message type
│
├── "No methods available for goal"
│   ├── Verify @unigoal_method predicate matches goal
│   ├── Check ADR-185 goal method patterns
│   └── Compare with ADR-186 working examples
│
├── "Action failed during execution"
│   ├── Check action function return value
│   ├── Verify state transformation logic
│   └── See ADR-188 debugging techniques
│
├── "Entity requirements not met"
│   ├── Check requires_entities format (ADR-181)
│   ├── Verify entity availability in state
│   └── See ADR-186 resource management example
│
└── "Temporal constraint violation"
    ├── Check duration format (ADR-182)
    ├── Verify start/end time format
    └── See ADR-186 meeting scheduling example
```

### Compilation Errors

```
Compilation Failed
├── Check module structure
│   ├── Verify `use AriaEngine.Domain`
│   ├── Check function signatures
│   └── See ADR-185 basic domain pattern
│
├── Check attribute syntax
│   ├── Verify @action, @unigoal_method format
│   ├── Check metadata structure
│   └── Compare with ADR-186 examples
│
└── Check dependencies
    ├── Verify mix.exs includes aria_engine_core
    ├── Check import statements
    └── See project setup in ADR-185
```

### Runtime Issues

```
Runtime Problems
├── State not updating
│   ├── Check State.set_fact calls
│   ├── Verify fact structure (subject, predicate, value)
│   └── See ADR-185 state management section
│
├── Goals not being achieved
│   ├── Check goal format {subject, predicate, value}
│   ├── Verify method predicate matching
│   └── See ADR-186 goal method examples
│
└── Performance issues
    ├── Check method complexity
    ├── Consider task decomposition
    └── See ADR-186 best practices section
```

## When to Use Which ADR

### Development Phase Guide

**Phase 1: Learning (First Week)**
- ADR-185: Quick Start Guide
- ADR-186: Common Use Cases (restaurant example)
- Practice with simple domains

**Phase 2: Building (First Month)**
- ADR-186: All use cases and patterns
- ADR-188: Practical How-To techniques
- ADR-182: Technical details as needed

**Phase 3: Scaling (Ongoing)**
- ADR-183: Architecture understanding
- ADR-181: Complete specification reference
- ADR-184: Advanced patterns and migration

### Problem-Specific Guide

**Temporal Planning Problems**
1. ADR-186: Meeting scheduling example (practical)
2. ADR-182: Duration handling (technical)
3. ADR-183: Temporal architecture (design)

**Resource Management Problems**
1. ADR-186: Resource management example (practical)
2. ADR-181: Entity requirements specification (reference)
3. ADR-184: Advanced resource patterns (comprehensive)

**Performance Problems**
1. ADR-186: Best practices section (optimization)
2. ADR-188: Debugging techniques (analysis)
3. ADR-183: Architecture patterns (design)

**Integration Problems**
1. ADR-184: Migration guidance (compatibility)
2. ADR-183: System architecture (integration)
3. ADR-188: Integration patterns (practical)

## Documentation Maintenance

### Keeping Documentation Current

**When adding new features:**
1. Update ADR-185 if it affects basic patterns
2. Add examples to ADR-186 if it's a common use case
3. Update this navigation guide if it changes workflows
4. Add how-to guidance in ADR-188 if it's complex

**When fixing bugs:**
1. Update troubleshooting sections in ADR-188
2. Add prevention guidance to relevant ADRs
3. Update examples if they were incorrect

**When changing architecture:**
1. Update ADR-183 for system design changes
2. Update ADR-181 for specification changes
3. Update migration guidance in ADR-184

### Documentation Quality Standards

**All accessibility ADRs (185-188) must:**
- Include working code examples
- Provide clear success criteria
- Reference related technical ADRs
- Include troubleshooting guidance
- Maintain beginner-friendly language

**Cross-references must:**
- Be bidirectional where relevant
- Include specific section references
- Explain why the reference is relevant
- Be kept current when content moves

## Success Criteria

After reading this ADR, you should be able to:

- [x] Find the right documentation for any AriaEngine task
- [x] Navigate between accessibility and technical documentation layers
- [x] Follow troubleshooting workflows for common problems
- [x] Understand the relationship between different ADRs
- [x] Know which ADR to read based on your experience level
- [x] Locate relevant code files for specific functionality

**Navigation Efficiency**: Find what you need in under 2 minutes  
**Problem Resolution**: Follow clear workflows to solve common issues  
**Learning Path**: Understand the progression from beginner to advanced

## Related ADRs

**Accessibility Layer:**
- **ADR-185**: AriaEngine Quick Start Guide (entry point)
- **ADR-186**: Common Use Cases and Patterns (practical examples)
- **ADR-188**: Practical How-To Documentation (advanced techniques)

**Technical Layer:**
- **ADR-181**: Core Specification (complete reference)
- **ADR-182**: Technical Implementation (implementation details)
- **ADR-183**: Architecture & Standards (system design)
- **ADR-184**: Developer Guide (comprehensive patterns)

**Complexity Level**: All levels  
**Prerequisites**: None (this is a navigation aid)  
**Time Investment**: 15 minutes to understand navigation, reference as needed
