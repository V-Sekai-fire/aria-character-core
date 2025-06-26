# ADR-181 aria_core Update Report

**Date:** 2025-06-26  
**Status:** Evidence-Based Planning Analysis  
**Priority:** HIGH

## Executive Summary

This report analyzes the current state of `aria_core` and provides a comprehensive plan for updating it to fully comply with ADR-181 (Unified Durative Action Specification and Planner Standardization). Based on git history analysis and codebase examination, `aria_core` has made significant progress toward ADR-181 compliance but requires several key updates to achieve full standardization.

## Current State Analysis

### Git History Evidence

Recent commits show active ADR-181 implementation work:

```
b60b394 Update 181-unified-durative-action-specification-and-planner-standardization.md
6d1df7d Fix temporal pattern table inconsistencies in ADR-181
b4f852f Enhance ADR-181 type specifications with Elixir best practices
4118b19 Extract AriaCore into dedicated umbrella app
9d6aa56 Complete AriaCore unified action specification system implementation
```

### Implementation Status

**✅ COMPLETED:**
- ✅ Dedicated `aria_core` umbrella app extracted
- ✅ `@action` attribute system implemented in `ActionAttributes` module
- ✅ `@task_method` attribute system implemented
- ✅ `@unigoal_method` attribute system implemented
- ✅ Unified domain creation via `UnifiedDomain.create_from_module/1`
- ✅ Example restaurant domain demonstrating ADR-181 patterns
- ✅ Entity management system with capabilities
- ✅ Temporal interval processing with ISO 8601 support
- ✅ Sociable testing approach leveraging existing systems

**⚠️ PARTIALLY IMPLEMENTED:**
- ⚠️ Integration with `aria_engine_core` Domain system
- ⚠️ Complete temporal pattern validation (9 patterns from ADR-181)
- ⚠️ Comprehensive test coverage
- ⚠️ Documentation alignment with ADR-181 standards

**❌ MISSING:**
- ❌ Integration with existing AriaEngine planner systems
- ❌ Command vs Action distinction implementation
- ❌ Multigoal and Multitodo method support
- ❌ Full ADR-181 compliance validation
- ❌ Migration path for existing domains

## Key Findings

### 1. Architecture Alignment

**Current Architecture:**
```
aria_core/
├── lib/aria_core/
│   ├── action_attributes.ex      # ✅ @action/@task_method/@unigoal_method
│   ├── unified_domain.ex         # ✅ Module-based domain creation
│   ├── domain.ex                 # ✅ Core domain structure
│   ├── entity/management.ex      # ✅ Entity/capability system
│   ├── temporal/interval.ex      # ✅ ISO 8601 temporal processing
│   └── examples/restaurant_domain.ex  # ✅ ADR-181 example
```

**Gap:** Missing integration with `aria_engine_core/lib/domain.ex` which contains the actual planner interface.

### 2. Attribute System Implementation

**Current Implementation Status:**

```elixir
# ✅ WORKING: @action attributes
@action duration: "PT2H", requires_entities: [%{type: "agent", capabilities: [:cooking]}]
def cook_meal(state, [meal_id]) do
  # Implementation
end

# ✅ WORKING: @unigoal_method attributes  
@unigoal_method predicate: "meal_status"
def meal_status_goal(state, [subject, value]) do
  # Implementation
end

# ✅ WORKING: @task_method attributes
@task_method true
def prepare_complete_meal_method(state, [meal_id]) do
  # Implementation
end
```

**Gap:** Missing `@command`, `@multigoal_method`, and `@multitodo_method` attributes per ADR-181.

### 3. Temporal Pattern Support

**Current Support:**
- ✅ Pattern 1: Instant actions (`@action true`)
- ✅ Pattern 2: Floating duration (`@action duration: "PT2H"`)
- ✅ Pattern 6: Calculated end (`@action start: "...", duration: "..."`)
- ✅ Pattern 7: Fixed interval (`@action start: "...", end: "..."`)

**Missing:**
- ❌ Pattern 3: Deadline constraint (`@action end: "..."`)
- ❌ Pattern 4: Calculated start (`@action end: "...", duration: "..."`)
- ❌ Pattern 5: Open start (`@action start: "..."`)
- ❌ Pattern 8: Constraint validation (`@action start: "...", end: "...", duration: "..."`)

## Required Updates

### Phase 1: Complete Attribute System (HIGH Priority)

**1.1 Add Missing Method Types**

```elixir
# Add to ActionAttributes module
@command true
@multigoal_method true  
@multitodo_method true
```

**1.2 Implement Command vs Action Distinction**

```elixir
# Actions: Planning-time pure state transformations
@action duration: "PT2H"
def cook_meal(state, [meal_id]) do
  # Pure state transformation
end

# Commands: Execution-time logic with failure handling
@command true  
def cook_meal_command(state, [meal_id]) do
  case attempt_cooking_with_failure_chance(state, meal_id) do
    {:ok, new_state} -> {:ok, new_state}
    {:error, reason} -> {:error, reason}
  end
end
```

**1.3 Complete Temporal Pattern Support**

```elixir
# Pattern 3: Deadline constraint
@action end: "2025-06-22T14:00:00-07:00"

# Pattern 4: Calculated start  
@action end: "2025-06-22T14:00:00-07:00", duration: "PT2H"

# Pattern 5: Open start
@action start: "2025-06-22T10:00:00-07:00"

# Pattern 8: Constraint validation
@action start: "2025-06-22T10:00:00-07:00", 
        end: "2025-06-22T12:00:00-07:00", 
        duration: "PT2H"
```

### Phase 2: AriaEngine Integration (HIGH Priority)

**2.1 Bridge aria_core with aria_engine_core**

Current gap: `aria_core` creates its own domain structure, but `aria_engine_core` has the actual planner interface.

```elixir
# Required: Update UnifiedDomain to create aria_engine_core Domain
def create_from_module(domain_module) do
  # Current: Creates AriaCore.Domain
  # Required: Creates Domain (from aria_engine_core)
  base_domain = Domain.new(domain_module)  # aria_engine_core
  # ... process attributes and return Domain.t()
end
```

**2.2 Implement Goal Format Standardization**

ADR-181 requires ONLY `{predicate, subject, value}` format:

```elixir
# ✅ CORRECT (ADR-181 compliant)
{"meal_status", "soup_1", "ready"}

# ❌ INCORRECT (legacy formats to remove)
{:meal_status, "soup_1", "ready"}
[:meal_status, "soup_1", "ready"]
%{predicate: "meal_status", subject: "soup_1", value: "ready"}
```

**2.3 State Validation Standardization**

ADR-181 requires direct fact checking:

```elixir
# ✅ CORRECT (ADR-181 compliant)
AriaState.RelationalState.get_fact(state, predicate, subject)

# ❌ INCORRECT (complex evaluation functions to remove)
evaluate_complex_condition(state, condition)
check_multiple_predicates(state, predicate_list)
```

### Phase 3: Testing and Validation (MEDIUM Priority)

**3.1 Create Comprehensive Test Suite**

```elixir
# Required: test/aria_core/unified_action_specification_test.exs
defmodule AriaCoreUnifiedActionSpecificationTest do
  use ExUnit.Case
  
  test "all 9 temporal patterns supported" do
    # Test each pattern from ADR-181
  end
  
  test "attribute system compliance" do
    # Test @action, @command, @task_method, etc.
  end
  
  test "integration with aria_engine_core" do
    # Test domain creation and planning
  end
end
```

**3.2 ADR-181 Compliance Validation**

```elixir
def validate_adr_181_compliance(domain_module) do
  # Check all requirements from ADR-181
  # Return detailed compliance report
end
```

### Phase 4: Documentation and Migration (MEDIUM Priority)

**4.1 Update Documentation**

- Update `aria_core/README.md` with ADR-181 compliance status
- Add migration guide for existing domains
- Document integration with aria_engine_core

**4.2 Create Migration Tools**

```elixir
defmodule AriaCore.Migration do
  def migrate_legacy_domain(legacy_domain) do
    # Convert legacy domain to ADR-181 format
  end
end
```

## Implementation Timeline

### Week 1: Core Attribute System
- [ ] Add missing method types (`@command`, `@multigoal_method`, `@multitodo_method`)
- [ ] Complete temporal pattern support (all 9 patterns)
- [ ] Implement command vs action distinction

### Week 2: AriaEngine Integration  
- [ ] Bridge aria_core with aria_engine_core Domain system
- [ ] Standardize goal format to `{predicate, subject, value}`
- [ ] Implement state validation standardization

### Week 3: Testing and Validation
- [ ] Create comprehensive test suite
- [ ] Implement ADR-181 compliance validation
- [ ] Test integration with existing AriaEngine systems

### Week 4: Documentation and Migration
- [ ] Update documentation for ADR-181 compliance
- [ ] Create migration guide and tools
- [ ] Validate with real-world domain examples

## Risk Assessment

### HIGH RISK
- **Integration Complexity:** Bridging aria_core with aria_engine_core may require significant refactoring
- **Breaking Changes:** ADR-181 compliance may break existing domain definitions

### MEDIUM RISK  
- **Performance Impact:** Additional attribute processing may affect compilation time
- **Testing Coverage:** Comprehensive testing of all temporal patterns requires significant effort

### LOW RISK
- **Documentation Lag:** Documentation updates are straightforward
- **Migration Tools:** Can be developed incrementally

## Success Criteria

### Technical Compliance
- [ ] All 6 method types supported (`@action`, `@command`, `@task_method`, `@unigoal_method`, `@multigoal_method`, `@multitodo_method`)
- [ ] All 9 temporal patterns implemented and tested
- [ ] Full integration with aria_engine_core Domain system
- [ ] 100% ADR-181 compliance validation passing

### Functional Requirements
- [ ] Existing restaurant domain example works with aria_engine_core planner
- [ ] New domains can be created using ADR-181 syntax
- [ ] Legacy domains can be migrated to ADR-181 format
- [ ] Performance equivalent to current implementation

### Documentation and Usability
- [ ] Complete ADR-181 compliance documentation
- [ ] Migration guide for existing domains
- [ ] Working examples demonstrating all features
- [ ] Integration guide with aria_engine_core

## Conclusion

`aria_core` has made substantial progress toward ADR-181 compliance with a solid foundation of attribute systems, entity management, and temporal processing. The primary remaining work involves:

1. **Completing the attribute system** with missing method types
2. **Integrating with aria_engine_core** for actual planner compatibility  
3. **Implementing comprehensive testing** to ensure reliability
4. **Providing migration paths** for existing domains

The estimated effort is 3-4 weeks for full ADR-181 compliance, with the integration work being the most complex component. The sociable testing approach already implemented provides a solid foundation for leveraging existing AriaEngine systems while adding the new ADR-181 capabilities.

## Next Steps

1. **Immediate:** Complete Phase 1 (attribute system) to achieve basic ADR-181 compliance
2. **Short-term:** Implement Phase 2 (AriaEngine integration) for functional compatibility
3. **Medium-term:** Execute Phases 3-4 (testing and documentation) for production readiness

This plan provides a clear path to full ADR-181 compliance while maintaining compatibility with existing AriaEngine systems and providing migration support for legacy domains.
