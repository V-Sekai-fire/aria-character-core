# ADR-151: Strict Encapsulation and Modular Testing Architecture

**Status:** Active  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

Breakthrough insight identified: real coding style problem requires strict encapsulation and modularity. Every logical "library" must be actual library in mono-repo, each separately tested with unit tests that never become integration tests.

Current state shows mixed encapsulation:
- Some apps extracted: `ast_migrate`, `elixir_png`, `png_generator`
- Major lib/ modules remain: `aria_auth`, `aria_engine`, `aria_security`, `aria_storage`, `aria_town`
- Testing boundaries unclear between modules
- Integration tests masquerading as unit tests

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

## Implementation Strategy

### Phase 1: Analyze Current Dependencies
- [ ] Map dependency graph for all lib/ modules
- [ ] Identify leaf modules (minimal dependencies)
- [ ] Document circular dependencies requiring resolution
- [ ] Prioritize extraction order by dependency depth

### Phase 2: Extract Leaf Modules First
- [ ] Extract `aria_security` (self-contained utilities)
- [ ] Extract `aria_storage` (file operations)
- [ ] Extract remaining `aria_png_generator` functionality
- [ ] Verify independent test suites for each

### Phase 3: Extract Intermediate Dependencies
- [ ] Extract `aria_auth` (depends on aria_security)
- [ ] Extract `aria_town` (depends on aria_engine)
- [ ] Resolve any circular dependencies discovered

### Phase 4: Extract Core Dependencies
- [ ] Extract `aria_engine` components by subdomain
- [ ] Split large modules using existing patterns
- [ ] Maintain API compatibility during transition

### Phase 5: Verify Testing Architecture
- [ ] Audit all test suites for proper isolation
- [ ] Implement contract tests between library boundaries
- [ ] Verify layered testing pattern implementation
- [ ] Document testing guidelines per library

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

- **ADR-150**: Extract lib/ modules to apps (implementation foundation)
- **ADR-056**: TODO encapsulation (API abstraction principles)
- **ADR-022**: Test-driven development (testing methodology)

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
