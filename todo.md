Based on my analysis of the `ast_migrate` application, I've identified several areas that need cleanup and maintenance to ensure single responsibility and follow the project's coding standards. Here's my comprehensive plan:

## Current State Analysis

The `ast_migrate` application is a Git-native Elixir AST migration tool with the following structure:

**Core Components:**
- `AstMigrate` - Main orchestration module
- `AstMigrate.Git` - Git operations using system commands
- `AstMigrate.Rules.Behaviour` - Interface for transformation rules
- 7 transformation rules for various namespace and module fixes
- `Mix.Tasks.Migrate` - Unified CLI interface

**Issues Identified:**

1. **Compiler Warnings**: 21 unused variable warnings across multiple rule files
2. **Git Implementation**: Uses shell commands instead of native Erlang `:git` module
3. **Rule Consistency**: Some rules have incomplete implementations (placeholder code)
4. **Module Size**: Some rule files are approaching the 200-300 line threshold
5. **Single Responsibility**: Some modules mix concerns (validation + transformation + logging)

## Cleanup and Maintenance Plan

### Phase 1: Fix Compiler Warnings (HIGH PRIORITY)
**Files affected:**
- `state_module_conflict_resolution.ex` (12 warnings)
- `state_struct_imports.ex` (4 warnings) 
- `timeline_module_references.ex` (4 warnings)

**Tasks:**
- [ ] Prefix unused variables with underscore (`_variable_name`)
- [ ] Remove truly unused variables where possible
- [ ] Ensure pattern matching is intentional vs accidental unused bindings

### Phase 2: Git Module Modernization (MEDIUM PRIORITY)
**File:** `lib/ast_migrate/git.ex`

**Current Issues:**
- Uses `System.cmd("git", ...)` shell commands
- String parsing of Git output
- Shell dependency requirements

**Improvements:**
- [ ] Research Erlang `:git` module API availability
- [ ] Replace shell commands with native `:git` calls where possible
- [ ] Improve error handling with structured Erlang terms
- [ ] Add fallback to shell commands if `:git` module unavailable

### Phase 3: Rule Implementation Completion (MEDIUM PRIORITY)
**Files with placeholder/incomplete code:**
- `state_module_conflict_resolution.ex` - Has TODO comments for context-dependent transformations
- Several rules have validation functions that could be more robust

**Tasks:**
- [ ] Complete context-dependent alias/import transformations
- [ ] Enhance validation functions with better heuristics
- [ ] Add comprehensive test coverage for edge cases

### Phase 4: Single Responsibility Refactoring (LOW PRIORITY)
**Target modules approaching size limits:**
- `membrane_namespace_cleanup.ex` (200+ lines)
- `state_module_conflict_resolution.ex` (250+ lines)

**Refactoring approach:**
- [ ] Extract validation logic into separate modules
- [ ] Create shared transformation utilities
- [ ] Separate AST manipulation from business logic
- [ ] Split large rule files into focused sub-modules

### Phase 5: Architecture Improvements (LOW PRIORITY)
**Current mixing of concerns:**
- Rules handle their own logging, validation, and transformation
- Main module handles both orchestration and file operations

**Improvements:**
- [ ] Extract logging into dedicated module
- [ ] Create validation service for reusable checks
- [ ] Separate file operations from transformation logic
- [ ] Add configuration management for rule parameters

## Implementation Strategy

**Step 1: Immediate Fixes**
1. Fix all compiler warnings (quick wins)
2. Ensure all tests pass
3. Update documentation for any behavior changes

**Step 2: Git Module Enhancement**
1. Research `:git` module availability and API
2. Create compatibility layer for both native and shell Git
3. Implement with feature flags for gradual rollout

**Step 3: Rule Completion**
1. Identify incomplete transformation logic
2. Add comprehensive test cases for edge scenarios
3. Implement missing context-dependent transformations

**Step 4: Modular Refactoring**
1. Extract common patterns into shared utilities
2. Split large files following the module splitting guidelines
3. Ensure each module has single, clear responsibility

## Success Criteria

- [ ] Zero compiler warnings
- [ ] All tests passing
- [ ] Git operations use native Erlang when possible
- [ ] Each rule file under 200 lines
- [ ] Clear separation of concerns across modules
- [ ] Comprehensive documentation for all public APIs
- [ ] Backward compatibility maintained for existing rule interface

This plan addresses the immediate technical debt while setting up the foundation for better maintainability and single responsibility adherence. The phased approach allows us to tackle the most critical issues first while gradually improving the overall architecture.

Would you like me to proceed with this plan? I recommend starting with Phase 1 (fixing compiler warnings) as it's the quickest way to improve code quality.