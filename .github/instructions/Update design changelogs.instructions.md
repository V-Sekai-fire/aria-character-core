---
applyTo: "**"
textId: "INST-010"
---

## Update design changelogs

When notable changes are made to the system's design, update the relevant design changelogs to maintain accurate documentation.

### The principle

Design changes should be documented immediately to ensure the documentation remains current and accurately reflects the state of the codebase.

### Implementation approach

1. **Identify the affected area:** Determine which design changelog needs updating
2. **Document the change:** Add an entry describing what was changed and why
3. **Include relevant details:** Add context that will help future developers understand the decision
4. **Commit with the change:** Include changelog updates in the same commit as the design change

### Examples

- **Temporal planner changes:** Update `docs/aria_timestrike/temporal_planner_design_resolutions.md`
- **Architecture changes:** Update relevant architecture decision records
- **API changes:** Update interface documentation and changelogs

### Benefits

- **Historical context:** Maintains a clear record of design evolution
- **Better understanding:** Helps current and future developers understand decisions
- **Reduced confusion:** Prevents questions about why certain design choices were made
- **Documentation consistency:** Keeps documentation in sync with actual implementation

This practice follows the problem-first approach - the problem is losing track of design decisions, and the solution is immediate documentation.
