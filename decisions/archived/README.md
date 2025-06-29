# Archived ADRs

This directory contains Architecture Decision Records (ADRs) that have been archived to reduce active decision tracking overhead while preserving historical context.

## Archive Structure

### `completed/`

Contains ADRs for work that has been successfully completed. These ADRs tracked implementation tasks, bug fixes, and feature development that reached their success criteria.

### `obsolete/`

Contains ADRs for systems, features, or components that have been removed from the project. These ADRs are preserved for historical context but are no longer relevant to active development.

## Archive Process

ADRs are archived when:

1. **Completion**: The work described in the ADR has been successfully finished and all success criteria met
2. **Obsolescence**: The system or feature the ADR relates to has been removed from the project
3. **Cleanup**: To maintain a focused set of active decisions in the main `decisions/` directory

## Archived ADR Format

Each archived ADR is replaced with a tombstone that includes:

- Original title and dates
- Summary of what was accomplished or why it became obsolete
- Archive reason and location
- Reference to git history for full original content

## Finding Archived Content

- **Browse by category**: Check `completed/` or `obsolete/` subdirectories
- **Search git history**: Use `git log --follow` to see the full history of any archived ADR
- **Restore if needed**: Archived ADRs can be restored to active status if circumstances change

## Active ADRs

For current, ongoing architectural decisions, see the main `decisions/` directory.

---

*Archive created: June 28, 2025*  
*Archive process documented in: ADR tombstoning and cleanup initiative*
