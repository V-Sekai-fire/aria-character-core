---
applyTo: "**"
textId: "INST-035"
---

## Logical commit grouping

Git commits must always group related changes together that serve the same logical purpose. This ensures each commit represents one complete, coherent unit of work.

### The principle

Each commit should tell a single, cohesive story about what was accomplished. All files modified in a commit should be logically connected and work together toward the same goal.

### What constitutes logical grouping

**Group together when changes:**

- Implement the same feature: All code, tests, and documentation for a single feature
- Fix the same bug: All modifications needed to resolve one specific issue
- Refactor the same concern: All files affected by a single architectural improvement
- Update the same system: All changes to maintain or enhance one logical component
- Address the same requirement: All modifications needed to fulfill one specific need

### Implementation guidelines

**Before staging changes:**

1. Review what you're committing: Use `git diff --cached` to see all staged changes
2. Verify logical connection: Ensure all modified files serve the same purpose
3. Check for mixed concerns: Split unrelated changes into separate commits
4. Confirm completeness: Include all files needed to complete the logical unit

### Examples of good logical grouping

**Feature implementation:**
```
Add user authentication system

- Implement User model with password hashing
- Add authentication middleware
- Create login/logout routes
- Add authentication tests
- Update API documentation for auth endpoints
```

**Bug fix:**
```
Fix FlowWorkflow state corruption during backtracking

- Correct state restoration logic in FlowWorkflow.undo/2
- Add missing state validation in transition handlers
- Fix test fixtures that relied on corrupted state
- Update FlowWorkflow documentation for state guarantees
```

**Refactoring:**
```
Extract planning utilities into separate module

- Move common planning functions to AriaEngine.Plan.Utils
- Update import statements across affected modules
- Maintain backward compatibility with deprecated aliases
- Add comprehensive tests for extracted utilities
```

### What to avoid

**Don't group together:**

- Mixed concerns: Bug fix + new feature + documentation update
- Unrelated areas: Frontend changes + database migration + configuration update
- Different timelines: Urgent fix + long-term refactoring
- Independent changes: Multiple unrelated bug fixes in one commit

**Red flags for poor grouping:**

- Commit touches more than 3-4 logical areas of the codebase
- Changes span multiple unrelated modules without clear connection
- Mix of feature work and maintenance tasks
- Combination of user-facing changes and internal refactoring

### Integration with existing rules

**Works with Single Fix Principle (INST-001):**
- Focus on one logical unit at a time
- Complete that unit fully before moving to the next

**Works with Completeness Check (INST-015):**
- Ensure commit message describes all grouped changes
- Verify all files in the logical group are included

### Benefits

- Clear history: Each commit represents a complete, understandable change
- Easier debugging: Problems can be traced to specific logical units
- Better reviews: Reviewers can understand the complete scope of changes
- Simplified reverting: Entire logical units can be undone cleanly
- Improved bisecting: Git bisect can identify the specific logical change that introduced issues

### Enforcement

This grouping is **mandatory** - commits that mix unrelated concerns must be split into separate, logically coherent commits. Take time to plan your commits so each one tells a clear, complete story.
