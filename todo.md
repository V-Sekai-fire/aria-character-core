Perfect! Based on your preferences, here's the detailed implementation plan:

## Comprehensive Cross-App Architectural Boundary Correction Plan

### Phase 1: Complete AST-Based Violation Analysis

**Use `ast_migrate` for systematic detection of ALL violations**

1. **Comprehensive codebase audit** using `ast_migrate` to identify:

   - Legacy namespace violations (`AriaEngine.*`, `AriaCore.*` patterns)
   - Internal module imports across app boundaries (`App.Internal.Module`)
   - Direct internal usage patterns
   - Cross-app dependency chains

2. **Categorize ALL violation types** found across the entire umbrella
3. **Map complete dependency chains** to understand interconnections
4. **Quantify total scope** with violation counts per category and per app

### Phase 2: External API Completeness First (Priority)

**Before fixing any violations, ensure all external APIs are complete**

**Leaf apps first (dependency order):**

1. **aria_auth** - Audit and complete external API
2. **aria_serial** - Audit and complete external API
3. **aria_state** - Audit and complete external API (already looks good)
4. **aria_storage** - Audit and complete external API
5. **aria_town** - Audit and complete external API
6. **aria_gltf** - Audit and complete external API
7. **aria_security** - Audit and complete external API
8. **aria_timeline_intervals** - Audit and complete external API
9. **aria_minizinc_executor** - Audit and complete external API
10. **ast_migrate** - Audit and complete external API

**Then single-dependency apps:** 11. **aria_minizinc_stn** - Complete external API 12. **aria_minizinc_goal** - Complete external API  
13. **aria_minizinc_multiply** - Complete external API

**Then higher-level apps:** 14. **aria_timeline** - Complete external API 15. **aria_engine_core** - Complete external API (partially done) 16. **aria_core** - Complete external API (looks comprehensive) 17. **aria_hybrid_planner** - Complete external API (looks good) 18. **aria_membrane_pipeline** - Complete external API

**For each app:**

- Identify what functions are needed by other apps
- Add missing delegation functions to `lib/app_name.ex`
- Ensure 100% external API coverage before moving to violations

### Phase 3: Systematic Violation Fixing by Type

**Fix ALL violations of each type across ALL apps before moving to next type**

**Type A: Legacy namespace violations**

- All `AriaEngine.*` patterns → proper external APIs
- All `AriaCore.*` direct usage → external APIs
- Apply fixes across entire codebase systematically

**Type B: Internal module imports**

- All `alias App.Internal.Module` across app boundaries → external APIs
- All direct internal function calls → external API calls
- Apply fixes across entire codebase systematically

**Type C: Cross-cutting functionality**

- Identify functionality that belongs in different apps
- Extract or migrate as needed following INST-045 patterns
- Apply architectural corrections systematically

### Phase 4: Comprehensive Validation

**After each violation type is fixed across ALL apps:**

1. **Full compilation verification** - All 18 apps compile without errors
2. **Complete test suite execution** - All tests pass
3. **Cross-app integration verification** - All app interactions work
4. **Performance validation** - No significant regressions

### Phase 5: Final Compliance Verification

**Systematic verification that ALL architectural requirements are met:**

1. **Zero cross-app internal imports** - No `alias App.Internal.Module` patterns
2. **Complete external APIs** - All needed functionality available through `lib/app_name.ex`
3. **Full compilation** - All apps compile without warnings or errors
4. **Functional preservation** - All tests pass and features work as before
5. **Clean architecture** - Apps communicate only through external APIs

## Implementation Strategy

**Step 1: AST Analysis** - Use `ast_migrate` to map ALL violations comprehensively
**Step 2: External API Completion** - Complete ALL external APIs in leaf-first order
**Step 3: Systematic Violation Fixing** - Fix ALL violations by type across entire codebase
**Step 4: Comprehensive Validation** - Verify complete architectural compliance

This approach ensures:

- **Complete coverage** - No violations missed due to systematic AST-based detection
- **Proper dependency order** - Leaf apps completed first, then dependencies
- **External API priority** - All APIs complete before fixing violations
- **Systematic approach** - All violations of each type fixed together
- **Full validation** - Complete architectural compliance verified

Ready to proceed with this comprehensive plan? I'll start with the AST-based violation analysis using `ast_migrate` to map the complete scope, then move to external API completion in leaf order.
