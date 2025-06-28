# ADR-154: Timeline Module Namespace Aliasing Fixes

<!-- @adr_serial R25W0033FAE -->

**Status:** Active (Paused)  
**Date:** June 23, 2025  
**Priority:** HIGH

## Context

After the modularization effort in ADR-151, timeline test files contain namespace conflicts that prevent proper test execution. Test files reference `AriaEngine.Timeline` but the module is now located at `Timeline` in the `aria_temporal_planner` app.

**Current Issues:**

- Test imports use outdated `AriaEngine.Timeline` references
- Module aliasing conflicts in test helper files
- Compilation errors preventing test suite execution
- Inconsistent namespace usage across test files

**Impact:**

- Timeline test suite cannot execute properly
- Development workflow blocked for timeline functionality
- Quality assurance gaps in temporal planning system

## Decision

Systematically update all timeline test files to use the correct `Timeline` namespace and resolve module aliasing conflicts throughout the test suite.

## Implementation Plan

### Phase 1: Create AST Migration Rule (Day 1)

**File:** `apps/ast_migrate/lib/rules/timeline_namespace_fixes.ex`

- [ ] Create new AST transformation rule for timeline namespace updates
- [ ] Target pattern: `AriaEngine.Timeline` → `Timeline`
- [ ] Handle alias statements, import statements, and qualified calls
- [ ] Ensure comprehensive coverage of all namespace patterns

**AST Rule Implementation:**

```elixir
defmodule AstMigrate.Rules.TimelineNamespaceFixes do
  @moduledoc """
  Fixes timeline namespace references from AriaEngine.Timeline to Timeline
  """
  
  def transform_alias({:alias, meta, [{:__aliases__, _, [:AriaEngine, :Timeline]} | rest]}) do
    {:alias, meta, [{:__aliases__, meta, [:Timeline]} | rest]}
  end
  
  def transform_import({:import, meta, [{:__aliases__, _, [:AriaEngine, :Timeline]} | rest]}) do
    {:import, meta, [{:__aliases__, meta, [:Timeline]} | rest]}
  end
  
  def transform_qualified_call({{:., meta1, [{:__aliases__, meta2, [:AriaEngine, :Timeline]}, func]}, meta3, args}) do
    {{:., meta1, [{:__aliases__, meta2, [:Timeline]}, func]}, meta3, args}
  end
end
```

### Phase 2: Execute AST Migration (Day 1)

**AST Migration Execution:**

- [ ] Run `cd apps/ast_migrate && mix ast.simple --rule timeline_namespace_fixes --target ../../apps/aria_temporal_planner/test/`
- [ ] Review transformation results for completeness
- [ ] Validate that all namespace patterns were handled correctly
- [ ] Check for any edge cases requiring manual adjustment

**Git-Integrated Migration (Alternative):**

- [ ] Run `cd apps/ast_migrate && mix ast.commit --rule timeline_namespace_fixes --target ../../apps/aria_temporal_planner/test/`
- [ ] Review commit diff for transformation accuracy
- [ ] Ensure git history preserves transformation details

### Phase 3: Validation and Testing (Day 1)

**Compilation Validation:**

- [ ] Run `cd apps/aria_temporal_planner && mix compile` to check for errors
- [ ] Fix any remaining compilation issues not handled by AST migration
- [ ] Ensure all test files compile without warnings

**Test Execution Validation:**

- [ ] Run `cd apps/aria_temporal_planner && mix test` to verify test execution
- [ ] Identify any runtime namespace errors missed by AST transformation
- [ ] Fix module resolution issues during test execution

### Phase 4: Quality Assurance (Day 1-2)

**AST Migration Review:**

- [ ] Review all transformed files for correctness
- [ ] Validate that transformation preserved code semantics
- [ ] Check for any missed namespace patterns requiring additional rules
- [ ] Ensure consistent transformation across all test files

**Integration Testing:**

- [ ] Run full test suite to verify no regressions
- [ ] Check for any remaining namespace-related warnings
- [ ] Validate test isolation and independence
- [ ] Confirm AST migration completeness

## Success Criteria

### Critical Success

- [ ] All timeline test files compile without namespace errors
- [ ] Test suite executes without module resolution failures
- [ ] No `AriaEngine.Timeline` references remain in test files
- [ ] Consistent namespace usage across all test files

### Quality Success

- [ ] Clean compilation with zero warnings related to namespaces
- [ ] Test execution time improved (no module resolution overhead)
- [ ] Clear, consistent import patterns for future development
- [ ] Documentation updated to reflect correct namespace usage

## Implementation Strategy

### Step 1: AST Rule Development

1. Create comprehensive AST transformation rule for timeline namespace fixes
2. Handle all namespace patterns: aliases, imports, qualified calls
3. Test AST rule on sample files to ensure correctness
4. Validate transformation preserves code semantics

### Step 2: Systematic AST Migration

1. Execute AST migration on all timeline test files
2. Review transformation results for completeness
3. Handle any edge cases requiring manual adjustment
4. Validate git integration and commit history

### Step 3: Validation and Testing

1. Compile after AST migration to verify syntax correctness
2. Run individual test files to verify functionality
3. Execute full test suite to ensure no regressions
4. Confirm namespace consistency across all files

## Files Requiring Updates

**Primary Test Files:**

- `test/timeline/interval_iso8601_test.exs`
- `test/timeline/internal/stn/operations_test.exs`
- `test/temporal_planner/stn_method_test.exs`
- `test/timeline/timeline_stn_capabilities_test.exs`

**Supporting Files:**

- `test/test_helper.exs`
- Any additional test utilities or shared modules

**Documentation:**

- Test file comments and documentation strings
- README files referencing timeline testing

## Consequences

### Risks

- **Low:** Potential for introducing new test failures during updates
- **Low:** Risk of missing some namespace references in complex test files
- **Low:** Temporary test suite instability during transition

### Benefits

- **High:** Timeline test suite becomes executable and reliable
- **High:** Development workflow restored for timeline functionality
- **Medium:** Consistent namespace usage improves code maintainability
- **Medium:** Foundation for additional timeline testing improvements

## Related ADRs

- **ADR-151**: Strict Encapsulation Modular Testing Architecture (modularization foundation)
- **ADR-152**: Complete Temporal Relations System Implementation (superseded parent)
- **ADR-153**: STN Fixed-Point Constraint Prohibition (parallel timeline work)
- **ADR-155**: Hybrid Planner Test Suite Restoration (related testing issue)
- **AST Migration Tool**: `apps/ast_migrate/decisions/001-git-style-ast-migration-tool.md` (implementation tool)

## Monitoring

- **Compilation Success:** Zero namespace-related compilation errors
- **Test Execution:** Successful test suite execution without module resolution failures
- **Code Quality:** Consistent namespace usage across all timeline test files
- **Development Velocity:** Improved timeline development workflow efficiency

## Notes

This ADR addresses the immediate testing infrastructure issue that blocks timeline development. The namespace aliasing fixes are essential for restoring the timeline test suite and enabling further timeline testing improvements.

**Implementation Priority:** This is a prerequisite for all other timeline testing work and should be completed before proceeding with STN consistency fixes or other timeline improvements.

**Quick Win Potential:** These are straightforward find-and-replace operations that will immediately improve the timeline testing situation.
