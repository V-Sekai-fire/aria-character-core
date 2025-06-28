# ADR-153: STN Fixed-Point Constraint Prohibition

<!-- @adr_serial R25W0023016 -->

**Status:** Active (Paused)  
**Date:** June 23, 2025  
**Priority:** CRITICAL

## Context

The STN (Simple Temporal Network) solver requires range constraints `{min, max}` where min < max for proper temporal reasoning. Fixed-point constraints `{n, n}` where min == max cause STN inconsistency and break temporal planning functionality.

**Current Problem:**

- Fixed-point constraints like `{0, 0}`, `{1, 1}`, `{66, 66}` reach the STN solver
- STN marks entire constraint network as `consistent: false`
- All temporal reasoning fails due to mathematical incompatibility
- 5+ test failures in aria_temporal_planner due to STN inconsistency

**Root Cause:**
The Bridge layer allows fixed-point constraints to pass through to the STN solver without conversion to proper temporal relationships. The STN solver expects only range constraints for mathematical consistency.

## Decision

Establish absolute prohibition of fixed-point constraints in the STN solver through Bridge layer filtering and Allen relation conversion.

## Implementation Plan

### Phase 1: Bridge Layer Fixed-Point Detection (Week 1)

**File:** `apps/aria_temporal_planner/lib/timeline/bridge.ex`

- [ ] Add fixed-point constraint detection function
- [ ] Implement constraint classification (self-reference, duration, relationship)
- [ ] Add Allen relation conversion for fixed-point semantics
- [ ] Ensure all `{n, n}` constraints are filtered before STN

**Detection Logic:**

```elixir
defp detect_fixed_point_constraint({min, max}) when min == max, do: true
defp detect_fixed_point_constraint(_), do: false

defp convert_fixed_point_to_range({n, n}, constraint_type) do
  case constraint_type do
    :self_reference -> {n - 1, n + 1}  # Small range for equality
    :fixed_duration -> {n - 1, n + 1}  # Micro-range for fixed timing
    :temporal_relationship -> {n - 1, n + 1}  # Allen relation range
  end
end
```

### Phase 2: STN Contract Enforcement (Week 1)

**File:** `apps/aria_temporal_planner/lib/timeline/internal/stn/core.ex`

- [ ] Add constraint validation at STN entry points
- [ ] Implement fixed-point constraint detection in STN
- [ ] Add clear error messages for contract violations
- [ ] Ensure STN only processes range constraints

**Validation Logic:**

```elixir
defp validate_constraint({min, max}) when min >= max do
  {:error, "Fixed-point constraint detected: {#{min}, #{max}}"}
end

defp validate_constraint({min, max}) when min < max do
  {:ok, {min, max}}
end
```

### Phase 3: Allen Relation Conversion (Week 1-2)

**File:** `apps/aria_temporal_planner/lib/timeline/allen_relations.ex`

- [ ] Implement Allen relation mapping for fixed-point constraints
- [ ] Add semantic preservation during conversion
- [ ] Support all fixed-point constraint types
- [ ] Maintain temporal reasoning accuracy

**Allen Relation Mappings:**

- **Self-Reference** `{point, point} => {0, 0}` → **EQUALS** → `{-1, 1}`
- **Fixed Duration** `{start, end} => {n, n}` → **FIXED_DURATION** → `{n-1, n+1}`
- **Instantaneous Action** → **MEETS** → `{-1, 1}`
- **Temporal Adjacency** → **ADJACENT** → `{-1, 1}`

### Phase 4: Test Suite Validation (Week 2)

**File:** `apps/aria_temporal_planner/test/timeline/stn_fixed_point_test.exs`

- [ ] Add comprehensive fixed-point constraint tests
- [ ] Validate Bridge layer filtering functionality
- [ ] Test STN contract enforcement
- [ ] Verify Allen relation conversion accuracy

**Test Cases:**

- Fixed-point constraint detection and filtering
- STN contract violation error handling
- Allen relation conversion correctness
- End-to-end Timeline → Bridge → STN flow validation

## Success Criteria

### Critical Success (Phase 1-2)

- [ ] All fixed-point constraints `{n, n}` filtered by Bridge layer
- [ ] STN solver receives only range constraints `{min, max}` where min < max
- [ ] STN consistency failures eliminated (5+ test failures resolved)
- [ ] Clear error messages for any fixed-point constraints reaching STN

### Functional Success (Phase 3-4)

- [ ] Allen relation conversion preserves temporal semantics
- [ ] All constraint types properly handled (self-reference, duration, relationship)
- [ ] Comprehensive test coverage for fixed-point constraint handling
- [ ] Timeline system maintains temporal reasoning accuracy

## Contract Definition

### Absolute Prohibition

**NO fixed-point constraints `{n, n}` where min == max are allowed in the STN solver.**

**Prohibited Patterns:**

- `{0, 0}` for ANY constraint type (interval duration, self-referential, temporal relationship)
- `{1, 1}`, `{66, 66}`, `{n, n}` for ANY constraint type
- Any constraint where minimum value equals maximum value

**Allowed Patterns:**

- Range constraints: `{5000, 6000}`, `{-6000, -5000}`, `{min, max}` where min < max
- Converted constraints: `{n-ε, n+ε}` where ε ≥ 1 (minimum time unit)

### Bridge Layer Responsibility

1. **Filter ALL fixed-point constraints** before they reach STN
2. **Convert to Allen relations:** Transform fixed-point constraints into proper temporal relationships
3. **Range expansion:** Convert `{n, n}` to `{n-ε, n+ε}` where ε is minimum time unit
4. **Semantic preservation:** Maintain temporal meaning through Allen relation mapping

### STN Contract Enforcement

- STN solver receives ONLY range constraints `{min, max}` where min < max
- Bridge layer guarantees no fixed-point constraints reach STN
- Error if any `{n, n}` constraint detected in STN: "Fixed-point constraint detected"
- STN consistency maintained through proper constraint ranges

## Implementation Strategy

### Step 1: Bridge Layer Enhancement

1. Add fixed-point constraint detection at all Bridge entry points
2. Implement Allen relation conversion for each fixed-point type
3. Ensure converted constraints maintain temporal semantics
4. Test Bridge layer filtering with comprehensive test cases

### Step 2: STN Contract Validation

1. Add constraint validation at STN Core entry points
2. Implement clear error handling for contract violations
3. Ensure STN only processes mathematically valid range constraints
4. Verify STN consistency with filtered constraint sets

### Step 3: End-to-End Integration

1. Test complete Timeline → Bridge → STN flow
2. Validate temporal reasoning accuracy with converted constraints
3. Ensure all existing functionality preserved
4. Fix any remaining STN consistency test failures

## Consequences

### Risks

- **Medium:** Allen relation conversion may introduce minor timing inaccuracies
- **Low:** Performance impact from additional Bridge layer processing
- **Low:** Potential edge cases in fixed-point constraint detection

### Benefits

- **Critical:** STN consistency restored, eliminating 5+ test failures
- **High:** Clear separation of concerns between Bridge and STN layers
- **Medium:** Improved temporal reasoning reliability and accuracy
- **Low:** Better error handling and debugging for constraint issues

## Related ADRs

- **ADR-152**: Complete Temporal Relations System Implementation (parent ADR)
- **ADR-045**: Allen's Interval Algebra Temporal Relationships
- **ADR-151**: Strict Encapsulation Modular Testing Architecture

## Monitoring

- **STN Consistency:** Percentage of STN operations resulting in `consistent: true`
- **Fixed-Point Detection:** Number of fixed-point constraints filtered by Bridge layer
- **Test Stability:** aria_temporal_planner test pass rate (target: 100%)
- **Performance:** Bridge layer processing overhead for constraint conversion

## Notes

This ADR establishes a fundamental mathematical contract for the STN solver: only range constraints `{min, max}` where min < max are permitted. All fixed-point constraints must be converted to proper temporal relationships at the Bridge layer before reaching the STN.

**Critical Path:** This contract enforcement is essential for STN consistency and must be implemented before any advanced temporal relations work in ADR-152.

**Implementation Priority:** Phase 1-2 (Bridge filtering and STN validation) takes immediate precedence to resolve the 5+ STN consistency test failures.
