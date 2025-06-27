# ADR-192: AriaCore ADR-181 Compliance Analysis Report

**Status:** Active  
**Date:** 2025-06-26  
**Priority:** HIGH

## Contributors

- K. S. Ernest Lee, V-Sekai (<https://v-sekai.org>) and Chibifire.com (<https://chibifire.com>), <ernest.lee@chibifire.com>

---

## Executive Summary

This report analyzes the current state of `aria_core` and provides a comprehensive plan for updating it to fully comply with ADR-181 (Unified Durative Action Specification and Planner Standardization). Based on git history analysis and codebase examination, `aria_core` has made significant progress toward ADR-181 compliance but requires several key updates to achieve full standardization.

**Current Compliance Status: 75% Complete**

### Key Findings

✅ **Implemented Successfully:**

- @action attribute processing system
- Basic temporal specification support
- Entity management framework
- Domain creation from modules
- Restaurant domain example with proper ADR-181 patterns

❌ **Missing Critical Components:**

- @command attribute support
- @multigoal_method and @multitodo_method attributes
- Complete temporal pattern validation (only 3 of 9 patterns implemented)
- State validation using direct fact checking
- Goal format standardization enforcement

⚠️ **Partial Implementation Issues:**

- Test failures indicate method metadata format inconsistencies
- Temporal converter has incomplete validation logic
- Missing integration with AriaEngine planning system

---

## Current Implementation Analysis

### Strengths

**1. Solid Foundation Architecture**

- Well-structured module hierarchy with clear separation of concerns
- Sociable testing approach leveraging existing AriaCore systems
- Comprehensive documentation and examples

**2. Core Attribute System**

- `@action` attributes fully implemented with duration and entity requirements
- `@task_method` attributes working for workflow decomposition
- `@unigoal_method` attributes implemented with predicate support

**3. Supporting Systems**

- Entity management with capabilities and type registration
- Temporal interval processing with ISO 8601 support
- State management with relational fact storage
- Domain creation and validation framework

### Critical Gaps

**1. Missing Method Types (High Priority)**

```elixir
# Currently missing - need implementation
@command true
@multigoal_method true  
@multitodo_method true
```

**2. Incomplete Temporal Pattern Support**

Current: Only 3 of 9 ADR-181 temporal patterns implemented

- ✅ Pattern 1: Instant action, anytime
- ✅ Pattern 2: Floating duration  
- ❌ Pattern 3: Deadline constraint
- ✅ Pattern 4: Calculated start (end - duration)
- ❌ Pattern 5: Open start
- ✅ Pattern 6: Calculated end (start + duration)
- ❌ Pattern 7: Fixed interval
- ❌ Pattern 8: Constraint validation
- ❌ Pattern 9: Complex temporal conditions

**3. State Validation Non-Compliance**

Current implementation uses complex state evaluation:

```elixir
# Non-compliant - complex evaluation
case AriaCore.State.Relational.get_fact(state, "ingredient_available", ingredient) do
  {:ok, true} -> true
  _ -> false
end
```

ADR-181 requires direct fact checking:

```elixir
# Required - direct fact checking only
AriaState.RelationalState.get_fact(state, predicate, subject)
```

**4. Goal Format Inconsistencies**

Mixed goal formats found in codebase:

```elixir
# Non-compliant variations found
{"ingredient_available", "tomato", true}  # ✅ Correct
{:cook_meal, [meal_id]}                   # ❌ Wrong - this is a task
{"quality_rating", subject, {:>=, 8}}     # ❌ Wrong - complex value
```

ADR-181 requires ONLY:

```elixir
{predicate, subject, value}  # ✅ ONLY this format allowed
```

---

## Test Failure Analysis

### Current Test Status: 4 Failures

**1. Method Metadata Format Error**

```
Invalid method metadata format: [special_diet_method: %{}, rush_order_method: %{}, prepare_complete_meal_method: %{}]
```

- **Issue:** Task methods storing empty maps instead of proper metadata
- **Impact:** Domain validation failing
- **Fix Required:** Update method metadata processing

**2. Temporal Converter Logic Error**

```
Expected: {"temperature", "oven", {:>=, 350}}
Actual: {"oven", "temperature", {:>=, 350}}
```

- **Issue:** Subject/predicate order inconsistency
- **Impact:** Temporal condition conversion failing
- **Fix Required:** Standardize goal format ordering

**3. Domain Validation Missing**

```
Module does not use AriaCore.Domain
```

- **Issue:** Validation logic not recognizing valid domain modules
- **Impact:** Doctest failures
- **Fix Required:** Improve module validation logic

**4. Domain Merging Logic**

```
length(AriaCore.Domain.list_actions(unified)) > 1 === false
```

- **Issue:** Domain merging not preserving all actions
- **Impact:** Multi-domain scenarios failing
- **Fix Required:** Fix domain merge algorithm

---

## Implementation Plan

### Phase 1: Fix Critical Test Failures (1-2 days)

**Priority: URGENT**

1. **Fix Method Metadata Processing**

   ```elixir
   # Update ActionAttributes.__on_definition__ to store proper metadata
   Module.put_attribute(env.module, :method_metadata, {name, %{type: :task_method}})
   ```

2. **Standardize Goal Format**

   ```elixir
   # Enforce {predicate, subject, value} format throughout
   # Update TemporalConverter to use consistent ordering
   ```

3. **Fix Domain Validation Logic**

   ```elixir
   # Update UnifiedDomain.check_module_uses_domain/1
   # Add proper detection for domain modules
   ```

4. **Fix Domain Merging**

   ```elixir
   # Debug and fix merge_two_domains/3 function
   # Ensure all actions are preserved during merge
   ```

### Phase 2: Complete Missing Attribute Types (3-5 days)

**Priority: HIGH**

1. **Implement @command Attributes**

   ```elixir
   @command true
   @spec cook_meal_command(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
   def cook_meal_command(state, [meal_id]) do
     # Execution-time logic with failure handling
   end
   ```

2. **Implement @multigoal_method Attributes**

   ```elixir
   @multigoal_method true
   @spec optimize_cooking_batch(AriaState.t(), AriaEngine.multigoal()) :: {:ok, AriaEngine.multigoal()} | {:error, atom()}
   ```

3. **Implement @multitodo_method Attributes**

   ```elixir
   @multitodo_method true
   @spec optimize_cooking_sequence(AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
   ```

### Phase 3: Complete Temporal Pattern Support (5-7 days)

**Priority: HIGH**

1. **Implement Missing Temporal Patterns**
   - Pattern 3: Deadline constraint (`end` only)
   - Pattern 5: Open start (`start` only)
   - Pattern 7: Fixed interval (`start` + `end`)
   - Pattern 8: Constraint validation (`start` + `end` + `duration`)

2. **Add Temporal Validation**

   ```elixir
   # Validate all 9 patterns in Temporal.Interval
   def validate_temporal_pattern(start, end, duration) do
     # Implement full ADR-181 pattern validation
   end
   ```

3. **Update Examples**

   ```elixir
   # Add examples for all temporal patterns in RestaurantDomain
   @action end: "2025-06-22T14:00:00-07:00", duration: "PT2H"  # Pattern 4
   @action start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00"  # Pattern 7
   ```

### Phase 4: State Validation Compliance (2-3 days)

**Priority: MEDIUM**

1. **Replace Complex State Evaluation**

   ```elixir
   # Replace all complex case statements with direct fact checking
   # OLD: case AriaCore.State.Relational.get_fact(state, pred, subj) do
   # NEW: AriaState.RelationalState.get_fact(state, pred, subj)
   ```

2. **Standardize Goal Format Enforcement**

   ```elixir
   # Add validation to reject non-compliant goal formats
   def validate_goal({predicate, subject, value}) when is_binary(predicate) and is_binary(subject) do
     :ok
   end
   def validate_goal(invalid_goal) do
     {:error, "Goals must use {predicate, subject, value} format, got: #{inspect(invalid_goal)}"}
   end
   ```

### Phase 5: Integration and Documentation (3-4 days)

**Priority: MEDIUM**

1. **AriaEngine Integration**
   - Connect with existing planning system
   - Ensure compatibility with lazy execution
   - Test with real planning scenarios

2. **Complete Documentation**
   - Update all docstrings for ADR-181 compliance
   - Add comprehensive examples
   - Create migration guide for existing domains

3. **Performance Optimization**
   - Profile attribute processing overhead
   - Optimize domain creation performance
   - Add caching for repeated operations

---

## Risk Assessment

### High Risk Items

1. **Breaking Changes to Existing Domains**
   - **Risk:** Goal format standardization may break existing code
   - **Mitigation:** Provide migration tools and clear upgrade path

2. **Performance Impact**
   - **Risk:** Additional attribute processing may slow compilation
   - **Mitigation:** Profile and optimize critical paths

3. **Integration Complexity**
   - **Risk:** AriaEngine integration may reveal architectural issues
   - **Mitigation:** Incremental integration with comprehensive testing

### Medium Risk Items

1. **Test Suite Maintenance**
   - **Risk:** Complex test scenarios may become brittle
   - **Mitigation:** Focus on integration tests over unit tests

2. **Documentation Drift**
   - **Risk:** Rapid changes may leave documentation outdated
   - **Mitigation:** Update docs in same commits as code changes

---

## Success Criteria

### Phase 1 Success (Test Fixes)

- [ ] All 43 doctests passing
- [ ] All 23 unit tests passing
- [ ] Zero test failures in `mix test`

### Phase 2 Success (Complete Attributes)

- [ ] @command attributes fully implemented and tested
- [ ] @multigoal_method attributes working with examples
- [ ] @multitodo_method attributes working with examples
- [ ] All 6 method types from ADR-181 supported

### Phase 3 Success (Temporal Patterns)

- [ ] All 9 temporal patterns implemented and validated
- [ ] Comprehensive temporal pattern test suite
- [ ] Restaurant domain examples for each pattern

### Phase 4 Success (State Compliance)

- [ ] All state validation uses direct fact checking
- [ ] Goal format enforcement prevents non-compliant goals
- [ ] State validation performance benchmarks met

### Phase 5 Success (Integration)

- [ ] Full AriaEngine integration working
- [ ] Complete documentation with migration guide
- [ ] Performance benchmarks within acceptable ranges

### Overall Success (Full ADR-181 Compliance)

- [ ] 100% compliance with ADR-181 specification
- [ ] All examples working with real planning scenarios
- [ ] Migration path for existing domains documented
- [ ] Performance impact < 10% overhead vs current implementation

---

## Resource Requirements

### Development Time Estimate

- **Phase 1 (Critical Fixes):** 1-2 days
- **Phase 2 (Missing Attributes):** 3-5 days  
- **Phase 3 (Temporal Patterns):** 5-7 days
- **Phase 4 (State Compliance):** 2-3 days
- **Phase 5 (Integration):** 3-4 days

**Total Estimated Time:** 14-21 days

### Dependencies

- Access to AriaEngine planning system for integration testing
- Performance testing environment for benchmarking
- Documentation review and approval process

---

## Conclusion

AriaCore has made substantial progress toward ADR-181 compliance with a solid foundation and well-architected attribute system. The remaining work focuses on completing missing method types, fixing temporal pattern support, and ensuring full state validation compliance.

The implementation plan provides a clear path to 100% ADR-181 compliance within 2-3 weeks, with critical test fixes addressable in 1-2 days. The sociable testing approach has proven effective and should be maintained throughout the remaining implementation phases.

**Recommendation:** Proceed with Phase 1 immediately to resolve test failures, then continue with systematic implementation of remaining phases to achieve full ADR-181 compliance.

---

## Related ADRs

- **ADR-181**: Unified Durative Action Specification and Planner Standardization (parent specification)
- **ADR-182**: Technical Implementation Guide  
- **ADR-183**: Architecture & Standards
- **ADR-184**: Common Use Cases and Patterns

---

## Implementation Status

**Status:** Active - Implementation plan ready for execution  
**Next Steps:** Begin Phase 1 critical test fixes  
**Timeline:** 14-21 days to full compliance  
**Compatibility:** Maintains backward compatibility with migration path
