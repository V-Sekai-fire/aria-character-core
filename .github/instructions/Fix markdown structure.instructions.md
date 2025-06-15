---
applyTo: ".github/instructions/**"
---

## Files Requiring Markdown Structure Fixes

The following deprecated ADR files have multiple top-level headings that violate MD025 and should be restructured:

- `decisions/036-evolving-ariaengine-planner-blueprint.md` - Has both main title and "# Original ADR Content (Deprecated)"
- `decisions/038-timeline-based-temporal-planner-implementation.md` - Has both main title and "# Original ADR Content (Deprecated)"
- `decisions/039-temporal-planner-reentrancy-stability.md` - Has both main title and "# Original ADR Content (Not Necessary)"

These files should use proper markdown hierarchy with only one H1 heading and appropriate H2/H3 subheadings for the deprecated content sections.
