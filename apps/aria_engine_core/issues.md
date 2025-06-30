# AriaEngineCore Issues Report

**Generated:** June 29, 2025  
**Source:** `mix test apps/aria_engine_core` compilation and test output

## Critical Issues (BLOCKING)

### 1. Joint Registry System Failure

**Priority:** CRITICAL - Blocks Phase 2 EWBIK implementation

**Problem:** All Joint tests failing with Registry process startup failures

- **Error Pattern:** `{:error, {:joint_creation_failed, %ErlangError{original: :noproc, reason: nil}}}`
- **Affected Tests:** 20/20 Joint tests failing identically
- **Root Cause:** `AriaEngineCore.Math.Joint.ensure_registry_with_timeout/0` cannot start Registry process

**Test Failures:**

```
** (EXIT from #PID<0.837.0>) no process: the process is not alive or there's no process currently associated with the given name, possibly because its application isn't started
```

**Impact:** Prevents EWBIK bone hierarchy management, blocking all Phase 2+ development

## High Priority Issues

### 2. ~~Missing AriaEngineCore.Domain Module~~ **TOMBSTONED ✅**

**Status:** SOLVED - Functions exist in internal modules, fix delegation

**Problem:** `AriaEngineCore` was delegating to non-existent `AriaEngineCore.Domain` module

**Solution Found:** All functions exist in appropriate internal modules:
- Core functions in `AriaEngineCore.Domain.Core`
- Method functions in `AriaEngineCore.Domain.Methods`  
- Action functions in `AriaEngineCore.Domain.Actions`

**Fix Required:** Update delegation lines in `lib/aria_engine_core.ex`:

```elixir
# Change from:
defdelegate get_task_methods(domain, task_name), to: AriaEngineCore.Domain
defdelegate get_unigoal_methods(domain, predicate), to: AriaEngineCore.Domain
defdelegate get_multigoal_methods(domain), to: AriaEngineCore.Domain
defdelegate get_multitodo_methods(domain), to: AriaEngineCore.Domain
defdelegate get_action_metadata(domain, action_name), to: AriaEngineCore.Domain
defdelegate get_entity_registry(domain), to: AriaEngineCore.Domain
defdelegate get_durative_action(domain, action_name), to: AriaEngineCore.Domain
defdelegate execute_action(domain, state, action_name, args), to: AriaEngineCore.Domain

# Change to:
defdelegate get_task_methods(domain, task_name), to: AriaEngineCore.Domain.Methods
defdelegate get_unigoal_methods(domain, predicate), to: AriaEngineCore.Domain.Methods
defdelegate get_multigoal_methods(domain), to: AriaEngineCore.Domain.Methods
defdelegate get_multitodo_methods(domain), to: AriaEngineCore.Domain.Methods
defdelegate get_action_metadata(domain, action_name), to: AriaEngineCore.Domain.Actions
defdelegate get_entity_registry(domain), to: AriaEngineCore.Domain.Core
defdelegate get_durative_action(domain, action_name), to: AriaEngineCore.Domain.Core
defdelegate execute_action(domain, state, action_name, args), to: AriaEngineCore.Domain.Actions
```

**Note:** Creating a new `AriaEngineCore.Domain` module would violate clean architecture by accessing internal APIs.

### 3. Missing AriaHybridPlanner.Core Module

**Priority:** HIGH - Adapter functionality incomplete

**Undefined Functions:**

- `AriaHybridPlanner.Core.new_coordinator/1`
- `AriaHybridPlanner.Core.plan/5`
- `AriaHybridPlanner.Core.execute/5`

**Affected Files:**

- `lib/aria_engine_core/adapters/hybrid_planner_adapter.ex`

## Medium Priority Issues

### 4. Doctest Precision Failures

**Priority:** MEDIUM - Minor floating-point precision issues

**Failed Doctests:**

1. **Quaternion.rotate_vector/2** - Floating-point precision difference
   - Expected: `{0.0, 1.0, 0.0}`
   - Actual: `{2.220446049250313e-16, 1.0, 0.0}`

2. **Matrix4.inverse/1** - Negative zero vs positive zero
   - Expected: `{1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}`
   - Actual: `{1.0, -0.0, 0.0, -0.0, -0.0, 1.0, -0.0, 0.0, 0.0, -0.0, 1.0, -0.0, -0.0, 0.0, -0.0, 1.0}`

3. **Matrix4.transpose/1** - Integer vs float type mismatch
   - Expected: `{1.0, 5.0, 9.0, 13.0, 2.0, 6.0, 10.0, 14.0, 3.0, 7.0, 11.0, 15.0, 4.0, 8.0, 12.0, 16.0}`
   - Actual: `{1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15, 4, 8, 12, 16}`

## Low Priority Issues (Code Quality)

### 5. Unused Variables in Math Modules

**Priority:** LOW - Code cleanup needed

**AriaEngineCore.Math.Quaternion:**

- `from_directions/2`: Unused variables `az`, `bx`, `by`, `bz`

**AriaEngineCore.Math.Matrix4:**

- `decompose/1`: Unused variables `m3`, `m7`, `m11`, `m15`

**AriaEngineCore.Math.Vector3:**

- Pattern matching warning: `0.0` vs `+0.0/-0.0` in `div_scalar/2`

**AriaEngineCore.Math.Joint:**

- Unused module attribute `@transform_validation_tolerance`
- Unused alias `Quaternion`

**AriaEngineCore.Math.Primitives:**

- Unused function `is_finite/1`

### 6. Unused Aliases in Test Files

**Priority:** LOW - Test cleanup needed

**Test Files with Unused Aliases:**

- `test/aria_engine_core/math/matrix4_test.exs`: Unused `Vector3` alias
- `test/aria_engine_core/math/joint_test.exs`: Unused `Vector3` alias

**Matrix4 Test Unused Variables:**

- Multiple unused variables in matrix decomposition tests (`i1`-`i15`, `r1`-`r15`)
- Unused quaternion components (`ox`, `oy`, `oz`, `ow`, `rx`, `ry`, `rz`, `rw`)

### 7. Division by Zero Warnings

**Priority:** LOW - IEEE-754 compliance warnings

**Affected Files:**

- `lib/aria_engine_core/math/quaternion.ex`: Lines 287, 291
- `lib/aria_engine_core/math/vector3.ex`: Lines 395, 411, 419
- `lib/aria_engine_core/math/primitives.ex`: Lines 47, 61, 1200

**Note:** These are intentional IEEE-754 infinity/NaN generation patterns, but trigger compiler warnings.

### 8. Documentation Issues

**Priority:** LOW - Documentation cleanup

**AriaCore Examples:**

- Duplicate `@doc` attribute in `UnifiedDomainExamples.create_domain/0`
- Unused variables in example functions (`state` parameters)

## External Dependencies Issues

### 9. Membrane Framework Integration Issues

**Priority:** MEDIUM - Third-party integration problems

**Missing Membrane Functions:**

- `Membrane.PipelineManager.start_link/1`
- `Membrane.PipelineManager.create_pipeline/1`
- `Membrane.PipelineManager.create_testing_pipeline/1`
- `Membrane.PipelineManager.configure_pipeline_topology/2`
- `Membrane.PipelineManager.list_active_pipelines/0`
- `Membrane.PipelineManager.stop_pipeline/1`
- `Membrane.PipelineManager.send_request_to_pipeline/2`
- `Membrane.PipelineManager.get_manager_stats/0`
- `Membrane.Pipeline.notify_child/3`
- `Membrane.Format.PlanningResult.success/3`
- `Membrane.Format.PlanningParams.error/2`
- `Membrane.Format.MCPResponse.success/3`

**Type System Issues:**

- Unknown key `.results` in `PlanningResult` struct
- Type violations in response filter conversions

### 10. AriaState Integration Issues

**Priority:** MEDIUM - State management integration

**Missing Functions:**

- `AriaState.RelationalState.get_all_facts/1`

### 11. AriaCore Domain Integration Issues

**Priority:** MEDIUM - Core domain integration

**Missing Functions:**

- `AriaCore.Domain.new/1`
- `AriaCore.Domain.enable_solution_tree/2`

### 12. AriaGltf Module Redefinition Issues

**Priority:** LOW - Build system issues

**Redefined Modules:**

- `AriaGltf.Material.PbrMetallicRoughness`
- `AriaGltf.Material.NormalTextureInfo`
- `AriaGltf.Material.OcclusionTextureInfo`

**Function Grouping Issues:**

- `put_if_present/3` and `put_if_present/4` clauses not grouped together

### 13. AriaHybridPlanner Type Issues

**Priority:** LOW - Type system warnings

**Type Violations:**

- Unreachable `:ok` clause in `Plan.SimpleExecutor.execute_action_command/5`
- Function returns `dynamic({:error, binary()})` but pattern matches `:ok`

## Summary

**Total Issues:** 13 categories

- **Critical:** 1 (Joint Registry failure)
- **High Priority:** 2 (Missing Domain/HybridPlanner modules)
- **Medium Priority:** 4 (Doctests, external integrations)
- **Low Priority:** 6 (Code quality, cleanup)

**Immediate Action Required:**

1. Fix Joint Registry system to unblock EWBIK development
2. Implement missing AriaEngineCore.Domain module
3. Address AriaHybridPlanner.Core dependency

**Test Status:**

- **Passing:** 120 tests, 59 doctests
- **Failing:** 23 tests (20 Joint + 3 doctests)
- **Success Rate:** 84% (excluding blocked Joint tests: 100%)
