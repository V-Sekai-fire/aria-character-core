# Apps Todo - Umbrella Project Management

## ⚠️ CRITICAL: Umbrella Workflow Enforcement

**MANDATORY RULE: All Mix commands MUST be executed from umbrella root directory.**

### Verification Commands

Before running ANY Mix commands, verify your location:

```bash
pwd  # Should show /home/ernest.lee/Developer/aria-character-core (umbrella root)
ls   # Should show apps/ directory and root mix.exs
```

### FORBIDDEN Patterns ❌

```bash
# NEVER do these operations:
cd apps/aria_engine_core && mix compile
cd apps/aria_timeline && mix test  
cd apps/any_app && mix deps.get
```

**Why this breaks umbrella coordination:**

- Creates conflicting lock files
- Bypasses umbrella dependency coordination
- Causes environment specification conflicts
- Results in "dependency overriding" errors

### REQUIRED Patterns ✅

```bash
# ALWAYS work from umbrella root:
mix compile                           # Compiles all apps in dependency order
mix test                             # Runs all tests across all apps
mix test apps/aria_engine_core       # Tests specific app from root
mix deps.get                         # Manages dependencies for entire umbrella
mix deps.clean --all                 # Cleans all dependencies
```

### Emergency Recovery

If umbrella gets broken by incorrect workflow:

1. **Return to umbrella root:** `cd /home/ernest.lee/Developer/aria-character-core`
2. **Clean everything:** `mix clean && mix deps.clean --all`
3. **Remove broken artifacts:** `rm -rf _build deps`
4. **Regenerate:** `mix deps.get && mix compile`

---

## Current Status: Umbrella Recovery Complete ✅

**Emergency recovery procedure executed successfully:**

- ✅ Cleaned all build artifacts with `mix clean && mix deps.clean --all`
- ✅ Removed corrupted dependencies with `rm -rf _build deps`
- ✅ Regenerated dependencies with `mix deps.get && mix compile`
- ✅ All apps compile successfully (warnings only, no errors)

**Current Issue: aria_auth cyclic dependency**

- ❌ `AriaAuth.Macaroons.ConfineUserString.__struct__/1` undefined during test compilation
- 🔍 **Root cause:** Compilation order issue in test files referencing struct before module compilation
- 📋 **Next step:** Fix aria_auth module compilation order issue

## Systematic Testing Approach

**Complete Leaf-Order Testing Plan:**

### Tier 1: Leaf apps (no internal dependencies) - 10 apps

1. ❌ `mix test apps/aria_auth` (BLOCKED: cyclic dependency issue)
2. ⏳ `mix test apps/aria_serial`
3. ⏳ `mix test apps/aria_state`
4. ⏳ `mix test apps/aria_storage`
5. ⏳ `mix test apps/aria_town`
6. ⏳ `mix test apps/aria_gltf`
7. ⏳ `mix test apps/aria_security`
8. ⏳ `mix test apps/aria_timeline_intervals`
9. ⏳ `mix test apps/aria_minizinc_executor`
10. ⏳ `mix test apps/ast_migrate`

### Tier 2: Single-dependency apps - 3 apps

11. ⏳ `mix test apps/aria_minizinc_stn` (→ aria_minizinc_executor)
12. ⏳ `mix test apps/aria_minizinc_goal` (→ aria_minizinc_executor)
13. ⏳ `mix test apps/aria_minizinc_multiply` (→ aria_minizinc_executor)

### Tier 3: Timeline layer - 1 app

14. ⏳ `mix test apps/aria_timeline` (→ aria_minizinc_stn)

### Tier 4: Engine core - 1 app

15. ⏳ `mix test apps/aria_engine_core` (→ aria_state, aria_timeline, aria_minizinc_stn, aria_minizinc_goal, aria_minizinc_executor)

### Tier 5: Higher-level integration - 2 apps

16. ⏳ `mix test apps/aria_core` (→ aria_engine_core, aria_state)
17. ⏳ `mix test apps/aria_hybrid_planner` (→ aria_state, aria_timeline, aria_minizinc_stn, aria_engine_core)

### Tier 6: Top-level apps - 1 app

18. ⏳ `mix test apps/aria_membrane_pipeline` (→ aria_engine_core, aria_hybrid_planner, aria_minizinc_goal)

## Known Issues to Address

### 1. aria_auth Cyclic Dependency (PRIORITY: HIGH)

**Error:** `AriaAuth.Macaroons.ConfineUserString.__struct__/1 is undefined`
**Location:** `apps/aria_auth/test/aria_auth/macaroons_test.exs:14`
**Solution:** Fix compilation order in test files or module dependencies

### 2. Duration Parsing Bug (PRIORITY: MEDIUM)

**Issue:** `duration: "PT1H"` (ISO 8601) incorrectly converted to `{:fixed, 1800}`
**Expected:** Proper time unit structure with correct seconds (3600 for 1 hour)
**Location:** `UnifiedActionSpecification` duration parsing logic

### 3. Missing External APIs (PRIORITY: MEDIUM)

Several apps may be missing complete external API modules following umbrella standards

## Next Actions

1. **Immediate:** Fix aria_auth compilation order issue
2. **Sequential:** Execute leaf-order testing plan starting with aria_serial
3. **Systematic:** Address duration parsing and API completeness issues as discovered

**Strategy:** Fix blocking issues first, then proceed with systematic testing in dependency order to catch integration issues early.
