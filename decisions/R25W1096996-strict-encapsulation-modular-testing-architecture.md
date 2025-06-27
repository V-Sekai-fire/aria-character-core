# R25W1096996: Strict Encapsulation and Modular Testing Architecture

<!-- @adr_serial R25W1096996 -->

**Status:** Active (Paused)  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

Breakthrough insight identified: real coding style problem requires strict encapsulation and modularity. Every logical "library" must be actual library in mono-repo, each separately tested with unit tests that never become integration tests.

Current state shows mixed encapsulation:

- Some apps extracted: `ast_migrate`, `elixir_png`, `png_generator`, `aria_security`
- Major lib/ modules remain: `aria_auth`, `aria_engine`, `aria_storage`, `aria_town`
- Testing boundaries unclear between modules
- Integration tests masquerading as unit tests

**Recent Progress:**

- ✅ `aria_security` successfully extracted (2025-06-23)
- ✅ `aria_storage` successfully extracted (2025-06-23)
- ✅ `aria_auth` successfully extracted (2025-06-23)
- ✅ `aria_town` successfully extracted (2025-06-23)
- 🔄 Next target: `aria_engine` (complex, requires subdomain splitting)

## The Strict Encapsulation Principle

### Core Rule

Every logical library = actual Elixir app in umbrella project with:

- Independent test suite
- Clear API boundaries  
- Isolated dependencies
- Single responsibility

### Library Boundary Criteria

Extract when module has:

- **Distinct domain responsibility**
- **Independent testing requirements**
- **Reusable functionality**
- **Clear input/output contracts**
- **Minimal coupling to other domains**

### Testing Isolation Requirements

- **Unit tests**: Test only internal library logic
- **No external dependencies**: Mock all external calls
- **Fast execution**: Sub-second test suites
- **Independent**: Can run without other libraries

## Layered Testing Architecture

### Beautiful Testing Pattern

Each layer's unit tests naturally become integration tests for layer below:

```
Layer N:   Unit Tests (test Layer N logic)
           ↓ (become integration tests for Layer N-1)
Layer N-1: Unit Tests (test Layer N-1 logic)  
           ↓ (become integration tests for Layer N-2)
Layer N-2: Unit Tests (test Layer N-2 logic)
```

### Testing Hierarchy

- **Library Unit Tests**: Internal logic only
- **Library Integration Tests**: API contracts between libraries
- **System Integration Tests**: End-to-end workflows
- **Acceptance Tests**: User-facing functionality

## Connections to Established Knowledge

### Software Engineering Principles

**SOLID Principles:**

- **Single Responsibility**: Each library has one clear domain
- **Dependency Inversion**: Libraries depend on abstractions, not implementations
- **Interface Segregation**: Clean, focused APIs between boundaries

**Architectural Patterns:**

- **Clean Architecture**: Strict dependency rules, layers depend only inward
- **Hexagonal Architecture**: Each library as hexagon with ports/adapters
- **Domain-Driven Design**: Libraries represent bounded contexts
- **Microservices Principles**: Applied at library level within monorepo

### Testing Patterns

**Test Pyramid**: Unit tests at library level, integration between libraries
**Testing Trophy**: Emphasis on integration testing emerging from layered approach
**Contract Testing**: API boundaries verified between libraries
**Isolated Unit Testing**: No external dependencies in unit tests

### Elixir/OTP Specific

**Umbrella Projects**: Natural Elixir way to achieve modular architecture
**OTP Design Principles**: Each app as supervision tree with clear boundaries
**GenServer Isolation**: Process boundaries mirror library boundaries
**Application Boundaries**: Clear start/stop semantics per library

## AST Migration Tool Integration

### Using ast_migrate for Testing Architecture

The `ast_migrate` app provides powerful AST-based transformations to systematically improve code quality and fix testing issues across all extracted apps.

**For detailed information about the AST migration tool, see:** `apps/ast_migrate/decisions/001-git-style-ast-migration-tool.md`

#### Available AST Migration Commands

**Basic Migration:**

```bash
# From the ast_migrate directory
mix ast.simple --rule unit_test_improvements --target /path/to/app
```

**Git-Integrated Migration:**

```bash
mix ast.commit --rule unit_test_improvements --target /path/to/app
```

#### Key Transformation Rules

**1. Unit Test Improvements Rule**

- Extracts intermediate variables in assertions for better readability
- Adds missing assertions to bare function calls
- Improves test structure and debugging capabilities

**2. Namespace Reference Fixes (Custom Rule)**

- Systematically updates module references after app extraction
- Fixes `AriaEngine.Timeline` → `Timeline` namespace issues
- Resolves import statement conflicts

**3. Test Isolation Improvements (Custom Rule)**

- Identifies and removes cross-app dependencies in tests
- Converts integration tests to proper unit tests
- Adds mocking for external dependencies

#### Integration with Testing Workflow

**Phase 5a: Systematic Test Fixes**

```bash
# Fix namespace issues across all apps
for app in apps/*/; do
  cd apps/ast_migrate
  mix ast.simple --rule namespace_fixes --target "../../$app"
done

# Apply unit test improvements
for app in apps/*/; do
  cd apps/ast_migrate
  mix ast.simple --rule unit_test_improvements --target "../../$app"
done
```

**Phase 5b: Contract Test Generation**

```bash
# Generate contract test templates
mix ast.simple --rule contract_test_generator --target ../../apps/aria_temporal_planner
```

**Phase 5c: Test Isolation Validation**

```bash
# Identify and fix cross-app test dependencies
mix ast.simple --rule test_isolation_checker --target ../../apps/aria_hybrid_planner
```

#### Benefits of AST Migration Approach

- **Systematic**: Applies transformations consistently across all apps
- **Safe**: Git integration provides rollback capabilities
- **Trackable**: Each transformation creates a commit with detailed history
- **Extensible**: Easy to add new rules for project-specific patterns
- **Precise**: AST-level transformations avoid regex-based errors

## Implementation Strategy

### Library Extraction Workflow

Each library extraction follows this complete process:

1. **Create New App Structure**
   - Generate `apps/[library_name]/` directory
   - Create `mix.exs` with proper dependencies
   - Set up standard Elixir app structure

2. **Copy Source Code**
   - Move all files from `lib/[library]/` to `apps/[library]/lib/`
   - Preserve directory structure and file organization
   - Maintain existing module namespaces

3. **Migrate Test Suite**
   - Move all files from `test/[library]/` to `apps/[library]/test/`
   - Update test helper and configuration files
   - Ensure test isolation and independence

4. **Configure Dependencies**
   - Update umbrella `mix.exs` to include new app in applications list
   - Configure new app dependencies using umbrella path pattern:

     ```elixir
     defp deps do
       [
         {:aria_security, path: "../aria_security"},
         {:aria_storage, path: "../aria_storage"},
         # external deps...
       ]
     end
     ```

   - Resolve any circular dependency issues

5. **Verify Independent Operation**
   - Run isolated test suite: `cd apps/[library] && mix test`
   - Confirm all tests pass without external dependencies
   - Validate compilation and functionality

6. **Update Import References**
   - Find all imports of moved modules throughout codebase
   - Update import statements to reference new app location
   - Fix any broken module references

7. **Remove Original Code**
   - Delete `lib/[library]/` directory completely
   - Delete `test/[library]/` directory completely
   - Ensure no duplicate code remains

8. **Create Migration Tombstone**
   - Create `lib/[library].tombstone.md` file documenting extraction
   - Include extraction date, new location, and ADR reference
   - Example format:

     ```markdown
     # [Library] Migration Tombstone
     
     **Extracted:** 2025-06-23  
     **New Location:** `apps/[library]/`  
     **ADR Reference:** R25W1096996 Strict Encapsulation
     
     This module was extracted to maintain strict encapsulation boundaries.
     All functionality now available in the dedicated umbrella app.
     ```

9. **Final Verification**
   - Run full umbrella test suite
   - Confirm no broken references or missing modules
   - Validate all functionality preserved

### Phase 1: Analyze Current Dependencies

- [x] Map dependency graph for all lib/ modules
- [x] Identify leaf modules (minimal dependencies)
- [x] Document circular dependencies requiring resolution
- [x] Prioritize extraction order by dependency depth

**Dependency Analysis Results:**

**Already Extracted Apps:**

- `ast_migrate/` - Git-style AST migration tool (independent)
- `elixir_png/` - PNG processing utilities (independent)
- `png_generator/` - Schedule visualization (independent)
- `aria_security/` - Self-contained security utilities ✅ **COMPLETED 2025-06-23**

**Remaining lib/ Modules to Extract:**

**Leaf Modules (Minimal Dependencies):**

1. **aria_storage** - File operations and chunk storage
   - Dependencies: External only (Waffle, Ecto, compression libs)
   - No internal aria_* dependencies
   - Clear API boundaries
   - Independent test suite possible

**Intermediate Dependencies:**
3. **aria_auth** - Authentication with macaroons

- Dependencies: aria_security (minimal), external (Ecto, Macfly)
- Clear API boundaries
- Independent test suite possible

**Complex Dependencies:**
4. **aria_town** - NPC management system

- Dependencies: aria_engine (heavy), external (GenServer)
- Currently stub implementation
- Depends on AriaEngine's hybrid planner

5. **aria_engine** - Core planning and temporal systems
   - Dependencies: Complex internal structure, external (Membrane, MiniZinc)
   - Largest module requiring subdomain extraction
   - Multiple internal circular dependencies

**Circular Dependencies Identified:**

- AriaEngine.Timeline ↔ AriaEngine.TemporalPlanner
- AriaEngine.HybridPlanner ↔ AriaEngine.Planning
- AriaEngine.Scheduler ↔ AriaEngine.Domain

**Extraction Priority Order:**

1. ✅ aria_security (leaf, zero internal deps) - **COMPLETED 2025-06-23**
2. aria_storage (leaf, zero internal deps)  
3. aria_auth (depends only on aria_security)
4. aria_town (depends on aria_engine, but minimal coupling)
5. aria_engine (complex, requires subdomain splitting)

**Current Focus:** aria_storage extraction (next leaf module)

### Phase 2: Extract Leaf Modules First

- [x] Extract `aria_security` (self-contained utilities) ✅ **COMPLETED 2025-06-23**
  - ✅ Created `apps/aria_security/` with proper structure
  - ✅ Moved all source files preserving namespaces
  - ✅ Configured dependencies (vaultex, httpoison, jason)
  - ✅ Independent test suite (2 tests, 0 failures)
  - ✅ Zero internal aria_* dependencies confirmed
  - ✅ Migration tombstone created
- [x] Extract `aria_storage` (file operations) ✅ **COMPLETED 2025-06-23**
  - ✅ Created `apps/aria_storage/` with proper structure
  - ✅ Moved all source files preserving namespaces
  - ✅ Configured dependencies (waffle, ecto, compression libs)
  - ✅ Independent test suite (112 tests, 0 failures)
  - ✅ Zero internal aria_* dependencies confirmed
  - ✅ Migration tombstone created
  - ✅ TestOutput helper module created for test compatibility
- [x] Extract `aria_auth` (authentication) ✅ **COMPLETED 2025-06-23**
  - ✅ Created `apps/aria_auth/` with proper structure
  - ✅ Moved all source files preserving namespaces
  - ✅ Configured dependencies (ecto, postgrex, bcrypt, macfly)
  - ✅ Independent test suite (35 tests, 0 failures)
  - ✅ Zero internal aria_* dependencies confirmed
  - ✅ Migration tombstone created
  - ✅ Main delegation module created for API compatibility
- [x] Extract `aria_town` (NPC management) ✅ **COMPLETED 2025-06-23**
  - ✅ Created `apps/aria_town/` with proper structure
  - ✅ Moved all source files preserving namespaces
  - ✅ Configured dependencies (gen_server, logger)
  - ✅ Independent test suite (3 tests, 0 failures)
  - ✅ Stub implementation with clear API boundaries
  - ✅ Migration tombstone created
  - ✅ Updated main application to remove direct GenServer starts
- [x] Extract remaining `aria_png_generator` functionality ✅ **COMPLETED (pre-existing)**
  - ✅ Already extracted to `apps/png_generator/`
  - ✅ Tombstone file created documenting migration
  - ✅ Module renamed from AriaEngine.PngGenerator to PngGenerator
- [x] Verify independent test suites for each ✅ **COMPLETED 2025-06-23**
  - ✅ All extracted apps have independent test suites
  - ✅ Zero cross-dependencies in unit tests confirmed

**Phase 2 Progress:** 5/5 tasks completed (all leaf modules successfully extracted)

### Phase 3: Extract Intermediate Dependencies

- [x] Extract `aria_auth` (depends on aria_security) ✅ **COMPLETED 2025-06-23**
- [x] Extract `aria_town` (depends on aria_engine) ✅ **COMPLETED 2025-06-23**
- [ ] Resolve any circular dependencies discovered

**Phase 3 Progress:** 2/3 tasks completed (aria_auth and aria_town extractions successful)

### Phase 4: Extract Core Dependencies

**AriaEngine Subdomain Analysis:**

Based on directory structure analysis, aria_engine contains these logical subdomains:

1. **aria_temporal_planner** - Temporal reasoning and STN solving
   - `temporal_planner/` - STN planner, actions, methods
   - `timeline/` - Timeline management, intervals, Allen relations
   - Dependencies: External (MiniZinc), minimal internal coupling

2. **aria_hybrid_planner** - Hybrid planning coordination
   - `hybrid_planner/` - Strategy coordination, factory patterns
   - `plan/` - Core planning logic, backtracking, execution
   - Dependencies: aria_temporal_planner, external (libgraph)

3. **aria_scheduler** - Activity scheduling and domain conversion
   - `scheduler/` - Core scheduling, domain conversion, resource management
   - Dependencies: aria_hybrid_planner, aria_temporal_planner

4. **aria_membrane_pipeline** - Membrane-based processing pipelines
   - `membrane/` - Filters, sources, sinks, pipeline management
   - Dependencies: External (Membrane), aria_scheduler

5. **aria_engine_core** - Core state, domain, and utility functions
   - Root level files: `state.ex`, `domain.ex`, `multigoal.ex`, etc.
   - Dependencies: Minimal, mostly self-contained

**Extraction Strategy:**

- [x] **Phase 4a**: Extract `aria_temporal_planner` (foundation layer) ✅ **COMPLETED 2025-06-23**
  - ✅ Created `apps/aria_temporal_planner/` with proper structure
  - ✅ Moved `temporal_planner/` and `timeline/` subdirectories
  - ✅ Extracted related root files (`timeline.ex`, `timeline_graph.ex`)
  - ✅ Migrated temporal planning tests (26 files compiled successfully)
  - ✅ Verified STN solving and timeline functionality

- [x] **Phase 4b**: Extract `aria_hybrid_planner` (planning layer) ✅ **COMPLETED 2025-06-23**
  - ✅ Created `apps/aria_hybrid_planner/` with proper structure
  - ✅ Moved `hybrid_planner/`, `plan/`, and `planning/` subdirectories
  - ✅ Extracted planning-related root files (`planning.ex`, `planner_adapter.ex`)
  - ✅ Migrated hybrid planning tests (31 files compiled successfully)
  - ✅ Configured dependencies on aria_temporal_planner and aria_engine_core
  - ✅ Verified compilation with expected warnings for missing modules

- [x] **Phase 4c**: Extract `aria_scheduler` (scheduling layer) ✅ **COMPLETED 2025-06-23**
  - ✅ Created `apps/aria_scheduler/` with proper structure
  - ✅ Moved `scheduler/` subdirectory with all scheduling components
  - ✅ Extracted scheduler root file (`scheduler.ex`)
  - ✅ Migrated scheduling tests (compiled successfully)
  - ✅ Configured dependencies on aria_hybrid_planner, aria_engine_core, aria_temporal_planner
  - ✅ Created AriaScheduler.Core delegation module for API compatibility
  - ✅ Resolved circular dependency issues by removing aria_hybrid_planner from aria_engine_core
  - ✅ Verified compilation with expected warnings for missing external dependencies
  - ✅ Created migration tombstone documenting extraction

- [x] **Phase 4d**: Extract `aria_membrane_pipeline` (pipeline layer) ✅ **COMPLETED 2025-06-23**
  - ✅ Created `apps/aria_membrane_pipeline/` with proper structure
  - ✅ Moved `membrane/` subdirectory with all pipeline components
  - ✅ Migrated membrane pipeline tests (23 files compiled successfully)
  - ✅ Configured dependencies on aria_engine_core, aria_hybrid_planner, aria_temporal_planner, aria_scheduler
  - ✅ Added Membrane Framework dependencies (membrane_core, membrane_file_plugin)
  - ✅ Created main AriaMembranePipeline module with API delegation
  - ✅ Updated main mix.exs to include aria_membrane_pipeline dependency
  - ✅ Verified compilation with expected warnings for missing modules
  - ✅ Created migration tombstone documenting extraction
  - ✅ Removed duplicated files from original lib/aria_engine location

- [x] **Phase 4e**: Consolidate `aria_engine_core` (core utilities) ✅ **COMPLETED 2025-06-23**
  - ✅ Created `apps/aria_engine_core/` with proper structure
  - ✅ Moved core files: `state.ex`, `domain.ex`, `multigoal.ex`, `utils.ex`, `info.ex`, `validation.ex`, `state_v2.ex`
  - ✅ Moved `minizinc/` subdirectory for external solver execution
  - ✅ Moved domain subdirectory with actions, methods, and durative actions
  - ✅ Moved `domain_behaviour.ex` and `actions.ex` root files
  - ✅ Configured dependencies (jason, libgraph, porcelain)
  - ✅ Updated main `mix.exs` to include aria_engine_core dependency
  - ✅ Updated aria_temporal_planner to depend on aria_engine_core
  - ✅ Migrated core utility tests (26 tests, 0 failures)
  - ✅ Removed duplicated modules from main lib/aria_engine/
  - ✅ Verified independent test suite and compilation
  - ✅ Created migration tombstone documenting extraction

**Phase 4 Progress:** 5/5 subdomain extractions completed (aria_temporal_planner, aria_hybrid_planner, aria_scheduler, aria_membrane_pipeline, and aria_engine_core) ✅ **ALL COMPLETED 2025-06-23**

### Phase 4f: Cleanup Duplicate Modules and Resolve Compilation Conflicts ✅ **COMPLETED 2025-06-23**

- ✅ **Removed entire lib/aria_engine/ directory** containing duplicate modules
- ✅ **Removed conflicting files**: lib/aria_auth.ex, lib/aria_engine.ex, lib/state.ex
- ✅ **Removed duplicate directories**: lib/aria_storage/, lib/aria_png_generator/
- ✅ **Removed old test directory**: test/aria_engine/ with outdated test files
- ✅ **Resolved compilation errors**: Module redefinition warnings eliminated
- ✅ **Enabled clean compilation**: Umbrella project compiles successfully
- ✅ **Verified app independence**: aria_engine_core tests pass (26 tests, 0 failures)
- ✅ **Implemented strict encapsulation**: Each app operates independently without namespace conflicts

**Cleanup Results:**

- **102 files removed**: 25,443 lines of duplicate code eliminated
- **Zero compilation errors**: Clean umbrella project compilation achieved
- **Independent app testing**: Each app can be tested in isolation
- **Namespace conflicts resolved**: No module redefinition warnings

### Phase 5: Verify Testing Architecture

- [x] **AST Migration Tool Integration** ✅ **COMPLETED 2025-06-23**
  - ✅ Integrated `ast_migrate` app for systematic code transformations
  - ✅ Available for fixing test warnings, namespace issues, and code improvements
  - ✅ Git-integrated migrations with automatic commit creation
  - ✅ Rule-based transformation system for consistent code changes
- [ ] **Phase 5a: Systematic Test Fixes** (Primary) + ast_migrate Rule Discovery (Maintenance)
  - [ ] Use `ast_migrate` to systematically fix namespace references across all apps
  - [ ] Apply unit test improvement rules across all extracted apps
  - [ ] Identify and resolve cross-app dependencies in tests
  - [ ] *Maintenance: Replace hard-coded rule mappings with dynamic module discovery*
  - [ ] *Maintenance: Enable seamless addition of new transformation rules*
- [ ] **Phase 5b: Contract Test Generation** (Primary) + Git Integration Cleanup (Maintenance)
  - [ ] Define API contract specifications for each app
  - [ ] Create contract test suites using `ast_migrate` templates
  - [ ] Verify interface compatibility between apps
  - [ ] *Maintenance: Replace shell Git commands with native Erlang `:git` module*
  - [ ] *Maintenance: Improve reliability of automated Git operations*
- [ ] **Phase 5c: Test Isolation Validation** (Primary) + Rule Interface Simplification (Maintenance)
  - [ ] Validate test isolation at each layer
  - [ ] Ensure unit tests don't become integration tests
  - [ ] Document testing boundaries and responsibilities
  - [ ] *Maintenance: Streamline Rules.Behaviour interface to essential callbacks only*
  - [ ] *Maintenance: Simplify creation of new test isolation transformation rules*
- [ ] **Phase 5d: Testing Guidelines Documentation** (Primary) + Logging Reduction (Maintenance)
  - [ ] Create testing standards documentation
  - [ ] Define AST migration rules for common test patterns
  - [ ] Establish code quality automation workflows
  - [ ] *Maintenance: Remove verbose logging cruft from `ast_migrate` core operations*
  - [ ] *Maintenance: Provide cleaner output for systematic transformations*

**Phase 5 Progress:** 1/4 phases completed (AST migration tool integration)

## Success Criteria

### Encapsulation Metrics

- **Library Count**: Each logical domain has dedicated app
- **Clear Dependency Direction**: Higher layers depend on lower layers only
- **API Surface**: Clear, documented interfaces between libraries
- **Test Isolation**: Zero external dependencies in unit tests

### Testing Quality Indicators

- **Test Speed**: Library unit tests complete under 1 second
- **Test Independence**: Any library test suite runs in isolation
- **Coverage Clarity**: Unit vs integration test boundaries clear
- **Contract Verification**: API boundaries tested between libraries

### Architectural Validation

- **Circular Dependencies**: Zero circular dependencies between libraries
- **Single Responsibility**: Each library has one clear domain purpose
- **Reusability**: Libraries usable independently in other projects
- **Documentation**: Clear README per library explaining purpose

## Related ADRs

- **R25W1089F0F**: Extract lib/ modules to apps (implementation foundation)
- **R25W1108E80**: Critical Zero Duration Contract Violation (interleaved implementation)
- **ADR-056**: TODO encapsulation (API abstraction principles)
- **R25W0101F54**: Test-driven development (testing methodology)

## Consequences

### Benefits

- **Clear Boundaries**: Explicit separation between domains
- **Better Testing**: True unit tests with clear integration boundaries
- **Improved Maintainability**: Changes isolated to specific libraries
- **Enhanced Reusability**: Libraries usable across projects
- **Faster Development**: Parallel work on independent libraries

### Risks

- **Initial Overhead**: Extraction work requires significant effort
- **Dependency Management**: Complex dependency resolution during transition
- **API Design**: Requires careful interface design between libraries
- **Testing Migration**: Existing tests need classification and migration

### Mitigation Strategies

- **Incremental Extraction**: Start with leaf modules, work toward core
- **Maintain Compatibility**: Preserve existing APIs during transition
- **Comprehensive Testing**: Verify functionality at each extraction step
- **Clear Documentation**: Document library purposes and boundaries
