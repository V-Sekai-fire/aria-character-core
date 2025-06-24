# ADR-166: ARC Prize 2025 Core Strategy

**Status:** Proposed  
**Date:** June 24, 2025  
**Priority:** HIGH

## The Challenge

The ARC Prize 2025 offers $1,000,000 for creating an AI system that can solve grid transformation puzzles with few-shot learning. Given 2-3 examples of a puzzle, the AI must understand the pattern and solve new puzzles it's never seen before.

**Current Best Performance:** 34% accuracy  
**Our Goal:** Build a competitive ARC solver using Aria's hybrid reasoning architecture

## Why Aria is Perfect for This

Aria already has the key components needed for ARC:

- **Hybrid Planning** - Coordinates multiple solving approaches
- **Grid Reasoning** - Handles spatial transformations naturally  
- **Pattern Learning** - Discovers rules from examples
- **Strategy Coordination** - Combines different reasoning methods
- **Constraint Solving** - Handles complex spatial relationships

## Our Approach

### Simple Version
Build a super-smart puzzle solver that learns patterns from examples, then uses multiple reasoning strategies working together to solve new puzzles.

### Technical Version
Create a computation-first system where massive search discovers grid transformations, pattern learning guides strategy selection, and hybrid planning coordinates learned approaches for interpretable execution.

### Key Innovation
Follow the "Bitter Lesson" - prioritize computation and learning over hand-crafted rules, then channel discoveries through interpretable planning execution.

## Implementation Strategy

**"Bicycle to Car" Progression:** Build working systems at each stage, starting simple and adding sophistication incrementally.

**Stage Overview:**
- **Stages 1-3:** Computational discovery (search, patterns, domain learning)
- **Stage 4:** Neural reasoning integration (GRPO-fine-tuned models)
- **Stages 5-7:** Coordination and production readiness
- **Stages 8+:** Advanced research features (if time permits)

**Risk Management:** Each stage produces a working ARC solver, so we can submit whatever we achieve by the competition deadline.

## Success Targets

- **Minimum Viable:** 5-10% accuracy (basic competitive submission)
- **Target Performance:** 15-20% accuracy (respectable showing)
- **Stretch Goal:** 25%+ accuracy (approaching state-of-the-art)

## Detailed Implementation

For complete technical details, see:

- **ADR-168**: ARC Prize Implementation Plan (12-stage development roadmap)
- **ADR-169**: ARC Prize Technical Architecture (umbrella apps and integration)
- **ADR-170**: ARC Prize Risk Analysis (comprehensive risk assessment)

## Decision

**Approved:** Develop ARC Prize 2025 solution using Aria's hybrid architecture with computation-first approach and interpretable execution.

**Next Steps:** Begin Stage 1 implementation with basic grid operations and computational search foundation.

## Related ADRs

- **ADR-168**: ARC Prize Implementation Plan
- **ADR-169**: ARC Prize Technical Architecture  
- **ADR-170**: ARC Prize Risk Analysis

## Consequences

### Positive
- Demonstrates Aria's capabilities on world-class AI challenge
- Validates hybrid symbolic-neural reasoning approach
- Potential breakthrough in abstract reasoning research

### Negative
- High-risk, resource-intensive project
- No guarantee of competitive performance
- Adds complexity to Aria ecosystem

### Neutral
- Valuable learning experience regardless of outcome
- Technology transfer to other reasoning applications
- Positions Aria in AI research community

This represents Aria's most ambitious application to date, targeting one of AI's grand challenges while demonstrating the power of hybrid reasoning architectures.
