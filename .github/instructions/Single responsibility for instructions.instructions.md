---
applyTo: ".github/instructions/**"
textId: "INST-014"
---

## Single Responsibility for Instruction Files

To keep our project's instructions clear, maintainable, and easy to navigate, each instruction file should adhere to the Single Responsibility Principle.

### The Principle

Each instruction file should have one, and only one, area of responsibility. It should address a single, well-defined topic, process, or rule.

### Rationale

- **Clarity:** When files are focused on a single topic, it's easier to find the information you need.
- **Maintainability:** It's simpler to update or retire a small, focused instruction than to untangle a large file with multiple, interwoven rules.
- **Avoiding Confusion:** Overlapping instructions can lead to confusion and conflicting guidance.

### What to Avoid

- **Mixing unrelated rules:** An instruction on "Splitting Large Files" should not contain a to-do list for fixing markdown linting errors in other files.
- **Creating "catch-all" documents:** Avoid creating broad instruction files that cover many different, unrelated topics.
- **Adding temporary tasks:** General instructions are not the place for one-off to-do lists or temporary notes. These are better suited for project management tools, issues, or a temporary ADR.

### How to Apply This

When creating a new instruction, ask yourself:

1. **"What is the single purpose of this instruction?"**
2. **"Does this overlap with any existing instructions?"** If so, consider whether the existing instruction should be expanded or if the new topic is distinct enough to warrant its own file.

By keeping our instructions focused, we make our project easier to work on for everyone. Let's keep it clean and professional!
