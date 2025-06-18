---
applyTo: "**"
textId: "INST-035"
---

## Logical commit grouping

Git commits must always group related changes together that serve the same logical purpose. This ensures each commit represents one complete, coherent unit of work.

**Group together when changes:**

- Implement the same feature: All code, tests, and documentation for a single feature
- Fix the same bug: All modifications needed to resolve one specific issue
- Refactor the same concern: All files affected by a single architectural improvement
- Update the same system: All changes to maintain or enhance one logical component
- Address the same requirement: All modifications needed to fulfill one specific need

**Before staging changes:**

1. Review what you're committing: Use `git diff --cached` to see all staged changes
2. Verify logical connection: Ensure all modified files serve the same purpose
3. Check for mixed concerns: Split unrelated changes into separate commits
4. Confirm completeness: Include all files needed to complete the logical unit

**Don't group together:**

- Mixed concerns: Bug fix + new feature + documentation update
- Unrelated areas: Frontend changes + database migration + configuration update
- Different timelines: Urgent fix + long-term refactoring
- Independent changes: Multiple unrelated bug fixes in one commit

This grouping is **mandatory** - commits that mix unrelated concerns must be split into separate, logically coherent commits.
