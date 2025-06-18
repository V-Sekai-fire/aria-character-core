---
applyTo: "**"
textId: "INST-001"
---

## Single Fix Principle

When debugging or implementing fixes, focus on making one targeted change at a time. This principle is essential for maintainable development and effective troubleshooting.

### The Principle

Make one focused change, test it, commit it, then move to the next issue. Avoid bundling multiple unrelated fixes together.

### Why This Matters

- Easier debugging: If something breaks, you know exactly which change caused it
- Clearer commits: Each commit has a single, clear purpose
- Simpler reviews: Changes are easier to understand and verify
- Faster resolution: You can identify and fix root causes more quickly
- Less complexity: Reduces the mental overhead of tracking multiple changes

### How to Apply

1. Identify the single most critical failing test or error
2. Make the minimal change needed to fix that specific issue
3. Test that the fix works
4. Commit the change with a clear message
5. Move to the next issue

### What to Avoid

- Fixing multiple unrelated functions in one commit
- Making "while I'm here" changes to unrelated code
- Bundling refactoring with bug fixes
- Trying to solve multiple test failures simultaneously

### Exception

The only exception is when multiple failures have the exact same root cause - for example, a missing function that multiple tests depend on. In that case, fix the root cause once.

This principle leads to more reliable, maintainable code and faster development cycles.
