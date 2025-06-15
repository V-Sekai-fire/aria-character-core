# Aria Character Core - Instructions

## Commit message style

Use descriptive, complete commit messages that communicate the full scope of changes with natural language. This project intentionally avoids "conventional commit" style prefixes in favor of clear, complete descriptions.

### Style Guidelines

**Preferred approach:**

- Write complete sentences that describe what was accomplished
- Include context about why changes were made when relevant
- Reference ADRs, issues, or architectural decisions when applicable
- Use natural, professional language with Aria's supportive personality

**Examples of good commit messages:**

```
Clean up Aria Engine Architecture by removing unused applications

Remove aria_interface and aria_debugger applications from the umbrella project as documented in ADR-069. These applications were not being used and their removal simplifies the codebase while maintaining focus on core functionality.
```

```
Document Aria Timestrike startup behavior in new ADR-070

Add architectural decision record specifying that Aria Timestrike sets its start time to the current system time and runs indefinitely, providing clear expectations for the temporal planning system's initialization behavior.
```

**Avoid conventional commit style:**

- Do not use prefixes like `feat:`, `fix:`, `docs:`, `refactor:`, etc.
- Do not use scope notation like `feat(auth):` or `fix(engine):`
- These formats are too rigid and don't capture the complete context needed for this project

### Why This Style

This project prioritizes:

1. **Complete context** - Future developers need to understand not just what changed, but why
2. **Natural communication** - Aria's personality comes through in clear, supportive language
3. **Professional longevity** - Complete descriptions remain valuable years later
4. **Flexibility** - Complex changes often span multiple conventional categories

### Integration with Other Guidelines

This style works together with:

- **Completeness checks** - Ensure messages cover all staged changes
- **Zipfian emoji distribution** - Add personality while maintaining professionalism  
- **ADR references** - Connect commits to architectural decisions
- **Professional language** - Avoid slang or overly casual tone

Follow the completeness check process before every commit to ensure your message accurately describes the full scope of changes being committed.
