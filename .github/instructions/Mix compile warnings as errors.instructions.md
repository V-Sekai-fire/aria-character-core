---
applyTo: "*.exs;*.ex"
textId: "INST-023"
---

## Mix compile warnings as errors

To maintain code quality and reduce the backlog of potential issues, compile Elixir code with warnings treated as errors.

### The principle

All warnings should be treated as errors to force immediate resolution and maintain high code quality.

### Implementation approach

Run the following command to compile with warnings as errors:

```
mix compile --warnings-as-errors
```

### Benefits

- **Higher code quality:** Forces resolution of all warnings
- **Prevents warning accumulation:** Stops warnings from building up over time
- **Consistent standards:** Ensures all code meets the same quality bar
- **Early problem detection:** Catches potential issues before they become bugs

### When to use

- **Before committing:** Ensure no warnings exist in code being committed
- **In CI/CD pipelines:** Enforce quality standards automatically
- **During code reviews:** Verify clean compilation

This follows the problem-first approach - warnings indicate real problems that should be addressed immediately.
