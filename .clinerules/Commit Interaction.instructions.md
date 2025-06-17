---
applyTo: "**"
textId: "INST-033"
---

## Commit Interaction

Before performing a `git commit` or `git push` operation, you must ask for user confirmation using the `ask_followup_question` tool.

### Process

1.  When a `git commit` or `git push` operation is required, formulate a clear question to the user.
2.  Provide at least two options using the phonetic alphabet (Alpha, Bravo, Charlie, Delta, etc.) as identifiers.
3.  The options should allow the user to:
    *   Confirm the commit/push.
    *   Cancel the commit/push.
    *   (Optionally) Request to review changes before committing/pushing.

### Rationale

This ensures explicit user approval for all repository modifications, preventing unintended commits or pushes and maintaining a collaborative workflow.
