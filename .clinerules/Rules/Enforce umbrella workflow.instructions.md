---
applyTo: "apps/**"
textId: "INST-046"
---

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
