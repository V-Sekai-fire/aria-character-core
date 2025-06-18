---
applyTo: "**"
textId: "INST-003"
---

## Debugger tips

When debugging and fixing tests, focus on resolving issues systematically while being mindful of tool limitations.

### The principle

Resolve one error or warning at a time to maintain clarity and control over changes.

### Implementation approach

1. Focus on single issues: Address one error or warning at a time
2. Micro-batch when necessary: To avoid rate-limiting issues with GitHub Copilot, bundle a small number of related fixes into a single interaction
3. Commit frequently: Apply fixes, commit changes, then repeat the process
4. Exercise caution: Be mindful of opportunities to address multiple issues at once, but proceed carefully to avoid introducing new problems

### Benefits

- Clearer debugging: Each fix addresses a specific issue
- Better tracking: Individual commits show exactly what was changed
- Reduced risk: Smaller changes are less likely to introduce new problems
- Tool compatibility: Works within the constraints of development tools

This approach balances systematic problem-solving with practical tool limitations.
