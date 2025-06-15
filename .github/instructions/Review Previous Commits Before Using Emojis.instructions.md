---
applyTo: "**"
---

## Review Previous Commits Before Using Emojis

Before adding emojis to any commit message, you must first review recent commit history to check for emoji overuse and avoid it.

### Required Process

1. **Before writing your commit message**, run `git log --oneline -10` to review the last 10 commit messages.
2. **Count the emojis** used in recent commits - if more than 3 of the last 10 commits contain emojis, do not add emojis to your current commit.
3. **Check for emoji density** - if the last 2-3 commits all contain emojis, skip emojis in your commit regardless of the total count.
4. **When in doubt, omit emojis** - clear, descriptive text is always preferable to emoji overuse.

### Rationale

- **Professional appearance:** Excessive emoji use makes commit history look unprofessional.
- **Readability:** Too many emojis can make commit messages harder to scan and understand.
- **Balance:** Emojis should add personality sparingly, not dominate the commit history.

This requirement ensures our commit history maintains a professional balance between engaging personality and clear communication.
