# R25W1089F0F: Extract lib/ modules into independent Elixir apps

<!-- @adr_serial R25W1089F0F -->

**Status:** Active (Paused)  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

The current lib/ directory contains multiple distinct modules that could be extracted into independent Elixir apps within the umbrella project. This would improve modularity, enable independent versioning, and create clearer boundaries between different functional areas.

## Current State Analysis

### Existing lib/ Structure

The lib/ directory contains these major module groups:

1. **aria_auth/** - Authentication and authorization system
2. **aria_engine/** - Core planning and execution engine (large, complex)
3. **aria_security/** - Security utilities and HSM integration
4. **aria_storage/** - File storage and chunking system
5. **aria_town/** - NPC and town management system
6. **aria_png_generator/** - PNG generation utilities

### Dependency Analysis

Based on code analysis, the dependency relationships are:

**Leaf Modules (minimal dependencies):**

- `aria_png_generator` - Only depends on standard library
- `aria_security` - Self-contained security utilities
- `aria_storage` - Self-contained storage system

**Intermediate Dependencies:**

- `aria_auth` - Depends on aria_security for some functionality
- `aria_town` - Depends on aria_engine for planning

**Core Dependencies:**

- `aria_engine` - Central module that many others depend on

## Decision

Extract modules in dependency order, starting with leaf modules that have no internal dependencies.
