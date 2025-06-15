# ADR-060: Implement Code Documentation Planner Instruction

## Status

Paused (June 15, 2025)
**Priority**: High - Proof of concept for ADR-059 planner-generated instructions
**Reason**: Paused to prioritize completion of ADR-058 (aria_engine core functionality fixes)

## Context

Following the framework established in ADR-059, we need to create the first planner-generated instruction to validate the concept and demonstrate the system's capabilities. Code documentation is an ideal candidate because:

### Problem Characteristics

- **Well-defined workflow**: Clear sequence of analyze → document → validate → commit
- **Repeatable process**: Same steps apply across different modules
- **Measurable outcomes**: Can verify documentation exists and follows standards
- **Self-contained scope**: Doesn't require external systems or complex integrations
- **Common developer task**: Addresses a frequent need in development workflows

### Chosen Problem: "Add comprehensive documentation to an Elixir module"

This involves:

1. Analyzing existing code structure and functionality
2. Identifying missing documentation (module docs, function docs, examples)
3. Generating appropriate documentation following Elixir conventions
4. Validating documentation completeness and correctness
5. Committing changes with proper commit message

## Decision

Create a complete, self-contained planner instruction that automates the process of adding comprehensive documentation to an Elixir module using the framework from ADR-059.

## Implementation Plan

### Phase 1: Planner Instruction Development

- [x] **Define the problem domain**
  - Model the documentation workflow as formal planning problem
  - Include predicates for code analysis, documentation states, and validation
  - Define actions for each step in the documentation process

- [x] **Implement the complete solution**
  - Create self-contained Elixir module with full domain definition
  - Include all helper functions for file manipulation and validation
  - Ensure zero external dependencies beyond aria_engine workspace
  - Add comprehensive error handling and recovery

- [x] **Create the instruction file**
  - Follow ADR-059 structure with complete executable code
  - Include clear usage examples and execution instructions
  - Add proper metadata (textId, applyTo, plannerGenerated flags)

### Phase 2: Testing and Validation

- [ ] **Test with real Elixir modules**
  - Execute instruction on actual undocumented modules in the workspace
  - Verify generated documentation follows Elixir conventions
  - Validate that all steps execute correctly and produce expected outcomes

- [ ] **Verify self-containment**
  - Test execution in fresh environment with only aria workspace
  - Confirm no external dependencies are required
  - Validate error handling for common failure scenarios

### Phase 3: Documentation and Integration

- [ ] **Document the approach**
  - Create clear usage examples for the instruction
  - Document any limitations or requirements
  - Add troubleshooting guide for common issues

- [ ] **Integrate with existing workflow**
  - Ensure instruction follows existing file naming conventions
  - Verify compatibility with other instruction system components
  - Test integration with development workflow

## Success Criteria

- Instruction successfully adds comprehensive documentation to Elixir modules
- Generated documentation follows proper Elixir conventions (@moduledoc, @doc, @spec)
- Complete workflow execution (analyze → document → validate → commit) works end-to-end
- No external dependencies beyond aria_engine workspace
- Generated commit messages follow project conventions
- Instruction can be executed by any developer in the workspace

## Toy Problem Solution

### Problem: Document the AriaFlow.ActionValidation module

**Initial State:**

- Module exists but lacks comprehensive documentation
- Some functions are undocumented
- No module-level documentation or examples
- No clear usage patterns documented

**Goal State:**

- Complete @moduledoc with module purpose and examples
- All public functions have @doc and @spec annotations
- Private functions have appropriate inline documentation
- Module includes usage examples
- Changes are committed with proper message

**Expected Actions Sequence:**

1. Analyze module structure and identify missing docs
2. Generate module documentation with examples
3. Add function documentation for all public functions  
4. Add type specifications where missing
5. Validate documentation completeness
6. Stage and commit changes

## Consequences

### Positive

- **Validates ADR-059 concept**: Proves planner-generated instructions can work
- **Addresses real need**: Code documentation is frequently needed
- **Reusable solution**: Can be applied to any Elixir module
- **Quality assurance**: Formal verification ensures consistent documentation standards

### Negative

- **Limited scope**: Only handles Elixir modules, not other file types
- **Documentation style**: May not match all preferred documentation patterns
- **Complex implementation**: Requires understanding of Elixir AST parsing

### Risks

- **AST parsing complexity**: Analyzing Elixir code structure may be challenging
- **Style consistency**: Generated documentation may not match project style
- **Edge cases**: May not handle all possible module structures correctly

## Monitoring

- Success rate of documentation generation
- Quality of generated documentation (manual review)
- Developer adoption and feedback
- Time savings compared to manual documentation

## Related ADRs

- **ADR-059**: Planner-Generated Instruction Files (parent framework)
- **ADR-011**: Elixir App Readme (related documentation requirements)

## Next Steps

1. **Implement the complete planner instruction** with full domain and execution code
2. **Test with sample modules** in the workspace
3. **Create the instruction file** following ADR-059 format
4. **Validate functionality** and gather feedback
5. **Document lessons learned** for future planner instructions
