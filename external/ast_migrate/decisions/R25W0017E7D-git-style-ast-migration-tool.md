# ADR-001: Git-Native Elixir AST Migration Tool

<!-- @adr_serial R25W0017E7D -->

**Status:** Phase 0 Completed ✅  
**Date:** 2025-06-23  
**Priority:** HIGH  
**Complexity:** Medium

## Context

Large-scale Elixir codebases require systematic code transformations that are:

- Too complex for find-and-replace operations
- Too numerous for manual refactoring  
- Too risky for batch processing without granular control
- Too interdependent for simple linear transformations

Our project urgently needs StateV2 → State migration across 1000+ files. Current approaches lack:

- **Incremental application** of transformations
- **Logical rollback** capabilities with proper dependency tracking
- **Conflict resolution** for overlapping changes
- **Collaborative migration** workflows
- **Audit trails** for transformation history
- **Immediate value delivery** for current migration needs

## Decision

Implement a **Git-native** AST migration tool (`mix ast.*`) that leverages Git directly as the version control backend:

1. **Immediate Relief**: Phase 0 simple tool for urgent StateV2 migration
2. **Git Integration**: Use Git commits for transformation tracking
3. **Native Rollback**: Use `git revert` for atomic rollback
4. **Branch Workflows**: Git branches for parallel transformations
5. **Test-Driven Development**: Build with comprehensive test coverage

## Architecture

### **Git-Native Architecture**

**Core Principle**: Leverage Git directly as the version control backend instead of building custom changeset storage.

**Phase 0**: AST-based transformations with Git integration (immediate relief)
**Phase 1**: Advanced AST transformations with comprehensive rule system  
**Phase 2**: Branch-based transformation workflows
**Phase 3**: Production optimization and ecosystem integration

### **EGit Integration Layer**

```elixir
defmodule AstMigrate.Git do
  @moduledoc """
  Git operations using EGit library for native Elixir Git integration.
  """
  
  def create_transformation_branch(repo, rule_name) do
    branch_name = "ast-migration/#{rule_name}-#{timestamp()}"
    
    with {:ok, _} <- EGit.branch(repo, branch_name),
         {:ok, _} <- EGit.checkout(repo, branch_name) do
      {:ok, branch_name}
    else
      error -> {:error, "Failed to create branch: #{inspect(error)}"}
    end
  end
  
  def commit_transformations(repo, message, files) do
    with {:ok, _} <- EGit.add(repo, files),
         {:ok, commit} <- EGit.commit(repo, "[AST] #{message}", author: get_author()) do
      {:ok, commit}
    else
      error -> {:error, "Failed to commit: #{inspect(error)}"}
    end
  end
  
  def rollback_transformation(repo, commit_hash) do
    case EGit.revert(repo, commit_hash) do
      {:ok, revert_commit} -> {:ok, revert_commit}
      error -> {:error, "Failed to revert: #{inspect(error)}"}
    end
  end
  
  def merge_transformation_branch(repo, branch_name) do
    case EGit.merge(repo, branch_name) do
      {:ok, merge_commit} -> {:ok, merge_commit}
      error -> {:error, "Failed to merge: #{inspect(error)}"}
    end
  end
  
  def ensure_clean_working_tree(repo) do
    case EGit.status(repo) do
      {:ok, %{working_tree: [], index: []}} -> :ok
      {:ok, status} -> {:error, "Working tree not clean: #{inspect(status)}"}
      error -> error
    end
  end
  
  defp get_author do
    %{name: "AST Migration Tool", email: "ast-migrate@localhost"}
  end
  
  defp timestamp do
    DateTime.utc_now() |> DateTime.to_unix()
  end
end
```

### **Git-Native Command Interface**

```bash
# Phase 0: Immediate relief with Git integration
mix ast.simple --rule state_v2_to_state --commit "Convert StateV2 to State"

# Apply transformation and commit in one step
mix ast.commit --rule state_v2_to_state --message "Convert StateV2 to State in engine"

# Apply to dedicated branch
mix ast.branch --rule function_signatures --from main

# Interactive application with Git staging
mix ast.apply --rule state_v2_to_state --interactive
git add -p  # Review hunks using Git
git commit -m "Selective StateV2 conversion"

# Rollback using native Git commands
git revert HEAD
git reset --hard HEAD~1

# View transformation history using Git
git log --oneline --grep="AST"
git log --graph --grep="ast-migration"
```

### **Git-Based Dependency Management**

```bash
# Dependent transformations on separate branches
git checkout -b ast-migration/state-conversion
mix ast.apply --rule state_v2_to_state
git commit -m "[AST] Convert StateV2 to State"

git checkout -b ast-migration/typespec-updates  
git merge ast-migration/state-conversion  # Dependency satisfied
mix ast.apply --rule update_typespecs
git commit -m "[AST] Update typespecs after state conversion"
```

### **AST-Based Transformation System**

```elixir
defmodule AstMigrate.Rules.StateV2ToState do
  @moduledoc """
  Transforms StateV2 usage to State using Elixir AST pattern matching.
  """
  
  def transform_file(file_path) do
    with {:ok, content} <- File.read(file_path),
         {:ok, ast} <- Code.string_to_quoted(content),
         transformed_ast <- transform_ast(ast),
         transformed_code <- Macro.to_string(transformed_ast) do
      {:ok, transformed_code}
    else
      error -> {:error, "Failed to transform #{file_path}: #{inspect(error)}"}
    end
  end
  
  # Transform StateV2 struct usage: %StateV2{} -> %State{}
  defp transform_ast({:%, meta, [{:__aliases__, alias_meta, [:StateV2]}, fields]}) do
    {:%, meta, [{:__aliases__, alias_meta, [:State]}, fields]}
  end
  
  # Transform StateV2 module calls: StateV2.function() -> State.function()
  defp transform_ast({{:., dot_meta, [{:__aliases__, alias_meta, [:StateV2]}, function]}, call_meta, args}) do
    {{:., dot_meta, [{:__aliases__, alias_meta, [:State]}, function]}, call_meta, args}
  end
  
  # Transform alias statements: alias AriaEngine.StateV2 -> alias AriaEngine.State
  defp transform_ast({:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :StateV2]}]}) do
    {:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]}]}
  end
  
  # Transform alias with :as option: alias AriaEngine.StateV2, as: S -> alias AriaEngine.State, as: S
  defp transform_ast({:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :StateV2]}, [as: alias_name]]}) do
    {:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]}, [as: alias_name]]}
  end
  
  # Recursively transform nested AST nodes
  defp transform_ast(ast) when is_tuple(ast) do
    ast
    |> Tuple.to_list()
    |> Enum.map(&transform_ast/1)
    |> List.to_tuple()
  end
  
  defp transform_ast(ast) when is_list(ast) do
    Enum.map(ast, &transform_ast/1)
  end
  
  defp transform_ast(ast), do: ast
end

# Rule configuration
%MigrationRule{
  name: "state_v2_to_state",
  module: AstMigrate.Rules.StateV2ToState,
  scope: :module,
  git_branch_prefix: "ast-migration/state-conversion",
  file_patterns: ["lib/**/*.ex", "test/**/*.exs"],
  preconditions: [&has_state_v2_usage?/1],
  postconditions: [&valid_state_usage?/1, &compiles_successfully?/1],
  commit_message: "Convert StateV2 to State in #{&1.module_name}"
}
```

### **AST Transformation Example**

**Input Elixir code:**

```elixir
defmodule MyModule do
  alias AriaEngine.StateV2
  
  def process_state(data) do
    state = %StateV2{entities: data}
    StateV2.update(state, :status, :active)
  end
end
```

**AST representation (simplified):**

```elixir
{:defmodule, [line: 1], [
  {:__aliases__, [line: 1], [:MyModule]},
  [do: {:__block__, [], [
    {:alias, [line: 2], [{:__aliases__, [line: 2], [:AriaEngine, :StateV2]}]},
    {:def, [line: 4], [
      {:process_state, [line: 4], [{:data, [line: 4], nil}]},
      [do: {:__block__, [], [
        {:=, [line: 5], [
          {:state, [line: 5], nil},
          {:%, [line: 5], [{:__aliases__, [line: 5], [:StateV2]}, [entities: {:data, [line: 5], nil}]]}
        ]},
        {{:., [line: 6], [{:__aliases__, [line: 6], [:StateV2]}, :update]}, [line: 6], 
         [{:state, [line: 6], nil}, :status, :active]}
      ]}]
    ]}
  ]}]
]}
```

**Transformed output:**

```elixir
defmodule MyModule do
  alias AriaEngine.State
  
  def process_state(data) do
    state = %State{entities: data}
    State.update(state, :status, :active)
  end
end
```

### **Git Hooks for Validation**

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Validate AST transformations before commit
mix compile --warnings-as-errors
mix test --failed
mix format --check-formatted

# .git/hooks/post-commit  
#!/bin/bash
# Log AST transformation metrics
if git log -1 --pretty=%B | grep -q "\[AST\]"; then
  echo "AST transformation committed: $(git rev-parse HEAD)"
fi
```

### **No Custom Storage Required**

**Git provides all version control features:**

- **Transformations**: Git commits with `[AST]` prefix
- **Rollback**: `git revert` for atomic rollback
- **History**: `git log` for transformation audit trail
- **Branching**: Git branches for parallel transformations
- **Merging**: Git merge for combining transformations
- **Conflicts**: Git merge conflicts for overlapping changes

## Implementation Plan

### **Phase 0: Immediate Relief (1 week)**

- [x] Create AST-based StateV2→State transformation using Code.string_to_quoted/2
- [x] Add EGit integration for automatic commits
- [x] Implement basic pattern matching on AST nodes
- [x] Test on subset of current codebase with real AST transformations
- [x] **Deliverable**: `mix ast.simple --rule state_v2_to_state --commit "Convert StateV2"`

### **Phase 1: Git-Integrated AST Foundation (2 weeks)**

- [x] Build AST parser using Sourceror for robust parsing
- [x] Implement transformation rule system with Git integration
- [x] Create file processing with Task.async_stream
- [x] Add comprehensive error handling and recovery
- [x] **Deliverable**: `mix ast.commit --rule state_v2_to_state --message "Convert StateV2"`

### **Phase 2: Branch-Based Workflows (2 weeks)**

- [ ] Implement Git branch creation for transformations
- [ ] Build dependency management via Git merges
- [ ] Add interactive transformation review with Git staging
- [ ] Create conflict resolution using Git merge conflicts
- [ ] **Deliverable**: `mix ast.branch --rule function_signatures --from main`

### **Phase 3: Production Features (1 week)**

- [ ] Add performance optimization and telemetry
- [ ] Implement comprehensive error handling and recovery
- [ ] Create extensive test suite with property-based testing
- [ ] Add Mix.Tasks.Format integration
- [ ] **Deliverable**: Production-ready tool with full Git integration

**Total Timeline: 6 weeks** (reduced from 10 weeks by eliminating custom version control)

## Success Criteria

### **Phase 0 Success (1 week)**

- [x] **PRIMARY**: Zero `mix compile` errors and warnings
- [x] **PRIMARY**: Zero `mix test` errors and warnings  
- [x] **SECONDARY**: Reduce `mix credo` issues (delayed priority)
- [x] **SECONDARY**: Reduce `mix dialyzer` warnings (delayed priority)
- [x] Zero syntax errors introduced by transformations
- [x] Backup and rollback capability working

### **Overall Success Criteria**

**Functional Requirements**:

- Successfully migrate StateV2 → State across entire codebase
- Handle 1000+ file codebases without memory issues
- Maintain 100% syntax validity of transformed code
- Provide atomic rollback for any changeset

**Quality Requirements**:

- 95%+ test coverage with property-based testing
- Zero data loss with comprehensive backup system
- 95% accuracy rate for automatic transformations
- <2 seconds per file processing time

**Usability Requirements**:

- Git-familiar interface for developers
- Interactive review mode for complex changes
- Clear error reporting and recovery guidance
- <5 minutes to configure new transformation rules

## Technical Decisions

### **Why Git-Native Instead of Custom Version Control?**

- **Zero Storage Complexity**: No need to build custom changeset storage
- **Battle-Tested Reliability**: Git's proven integrity and performance
- **Native Tooling**: All Git tools work (log, diff, blame, bisect, merge)
- **Team Collaboration**: Standard Git workflows for transformations
- **IDE Integration**: All existing Git integrations work out of the box
- **Reduced Development Time**: 6 weeks instead of 10+ weeks

### **Why Git Commits for Transformations?**

- **Logical Grouping**: Each commit represents one semantic transformation
- **Atomic Operations**: Git's atomic commits prevent inconsistent states
- **Dependency Management**: Git branches and merges handle dependencies naturally
- **Audit Trail**: Complete history via `git log` with searchable commit messages
- **Collaborative Workflow**: Multiple developers can work on different transformation branches

### **Why Branch-Based Transformation Workflows?**

- **Parallel Development**: Multiple transformations can proceed simultaneously
- **Safe Experimentation**: Branches allow testing transformations without affecting main
- **Natural Dependencies**: Git merges handle transformation dependencies
- **Conflict Resolution**: Git's merge conflict system handles overlapping changes
- **Review Process**: Pull requests for transformation review and approval

### **EGit Integration Strategy**

```elixir
defmodule AstMigrate.Git do
  @moduledoc """
  Native Elixir Git operations using EGit library.
  Provides structured error handling and type safety.
  """
  
  def ensure_clean_working_tree(repo) do
    case EGit.status(repo) do
      {:ok, %{working_tree: [], index: []}} -> :ok
      {:ok, status} -> {:error, "Working tree not clean: #{inspect(status)}"}
      error -> error
    end
  end
  
  def create_transformation_commit(repo, files, message) do
    with :ok <- ensure_clean_working_tree(repo),
         {:ok, _} <- EGit.add(repo, files),
         {:ok, commit} <- EGit.commit(repo, "[AST] #{message}", author: get_author()) do
      {:ok, commit}
    else
      error -> {:error, "Git commit failed: #{inspect(error)}"}
    end
  end
  
  def get_transformation_history(repo) do
    case EGit.log(repo, grep: "[AST]") do
      {:ok, commits} -> {:ok, commits}
      error -> {:error, "Failed to get history: #{inspect(error)}"}
    end
  end
  
  defp get_author do
    %{name: "AST Migration Tool", email: "ast-migrate@localhost"}
  end
end
```

### **Why EGit Over System.cmd?**

- **Native Elixir**: No shell command dependencies
- **Structured Errors**: Proper error types instead of parsing shell output
- **Type Safety**: Elixir data structures for all Git operations
- **Better Testing**: Easy to mock EGit operations in tests
- **Performance**: No process spawning overhead
- **Reliability**: No shell escaping or command injection risks

### **Error Handling Strategy**

- **Parse Errors**: Skip file, log error, continue with others
- **Transform Errors**: Create partial commit, mark files for manual review
- **Git Errors**: Provide clear guidance for resolution (conflicts, dirty tree)
- **Validation Errors**: Use `git reset` to rollback, preserve original state
- **System Errors**: Full rollback with `git reset --hard` and detailed error report

## Consequences

### **Benefits**

- **Immediate Relief**: Phase 0 solves urgent StateV2 migration need
- **Risk Mitigation**: Logical changesets prevent inconsistent states
- **Developer Confidence**: Familiar Git-like interface and atomic rollback
- **Scalability**: Can handle any codebase size with streaming architecture
- **Maintainability**: Clear audit trail and dependency management
- **Reusability**: Rule system handles future migrations

### **Risks & Mitigations**

**Risk**: AST complexity may cause transformation failures
**Mitigation**: Comprehensive test suite with real-world examples, fallback to manual review

**Risk**: Performance may be slower than simple tools
**Mitigation**: Start with Task.async_stream, upgrade to GenStage/Membrane only if needed

**Risk**: Learning curve for Git-style workflow
**Mitigation**: Familiar Git commands, extensive documentation, simple Phase 0 tool

**Risk**: Dependency resolution complexity
**Mitigation**: Clear error messages, interactive resolution mode, dependency visualization

### **Trade-offs**

- **Complexity vs Safety**: More complex architecture for safer transformations
- **Performance vs Features**: Some overhead for version control capabilities
- **Time vs Quality**: Longer development for production-ready tool

## Validation Strategy

### **Testing Approach**

```elixir
# Property-based testing
property "transformed AST is always valid Elixir" do
  check all ast <- valid_elixir_ast_generator() do
    case AstMigrate.transform(ast, rules) do
      {:ok, transformed} -> 
        assert {:ok, _} = Code.string_to_quoted(Macro.to_string(transformed))
      {:error, _} -> 
        :ok  # Transformation can fail, but shouldn't produce invalid AST
    end
  end
end

# Golden master testing
test "state_v2_migration_matches_expected_output" do
  input = File.read!("test/fixtures/state_v2_input.ex")
  expected = File.read!("test/fixtures/state_v2_expected.ex")
  
  {:ok, result} = AstMigrate.transform_file(input, [StateV2ToState])
  assert result == expected
end
```

### **Validation Pipeline**

1. **Syntax Check**: Code.string_to_quoted/1 validates syntax
2. **Compilation Check**: `mix compile --warnings-as-errors` ensures clean compilation
3. **Test Check**: `mix test` verifies behavior preservation and reduces failures
4. **Code Quality**: `mix credo` ensures style and maintainability standards
5. **Type Check**: `mix dialyzer` validates type safety and reduces warnings
6. **Formatting**: `mix format --check-formatted` maintains code consistency

## Unit Testing Strategy

### **Core AST Transformation Tests**

**StateV2 Struct Transformation**

```elixir
test "transforms StateV2 struct to State struct" do
  input_ast = quote do: %StateV2{entities: data, status: :active}
  expected_ast = quote do: %State{entities: data, status: :active}
  
  result = AstMigrate.Rules.StateV2ToState.transform_ast(input_ast)
  assert result == expected_ast
end
```

**Module Call Transformation**

```elixir
test "transforms StateV2 module calls to State calls" do
  input_ast = quote do: StateV2.update(state, :field, value)
  expected_ast = quote do: State.update(state, :field, value)
  
  result = AstMigrate.Rules.StateV2ToState.transform_ast(input_ast)
  assert result == expected_ast
end
```

**Alias Statement Transformation**

```elixir
test "transforms simple alias statements" do
  input_ast = quote do: alias AriaEngine.StateV2
  expected_ast = quote do: alias AriaEngine.State
  
  result = AstMigrate.Rules.StateV2ToState.transform_ast(input_ast)
  assert result == expected_ast
end

test "transforms alias with :as option" do
  input_ast = quote do: alias AriaEngine.StateV2, as: S
  expected_ast = quote do: alias AriaEngine.State, as: S
  
  result = AstMigrate.Rules.StateV2ToState.transform_ast(input_ast)
  assert result == expected_ast
end
```

### **File Processing Tests**

**Complete File Transformation**

```elixir
test "transforms complete Elixir file" do
  input_code = """
  defmodule TestModule do
    alias AriaEngine.StateV2
    
    def create_state(data) do
      %StateV2{entities: data}
    end
    
    def update_state(state, field, value) do
      StateV2.put(state, field, value)
    end
  end
  """
  
  {:ok, result} = AstMigrate.Rules.StateV2ToState.transform_file_content(input_code)
  
  assert result =~ "alias AriaEngine.State"
  assert result =~ "%State{entities: data}"
  assert result =~ "State.put(state, field, value)"
  refute result =~ "StateV2"
end
```

**Syntax Preservation**

```elixir
test "maintains valid Elixir syntax after transformation" do
  input_code = """
  defmodule Complex do
    alias AriaEngine.StateV2, as: S
    
    def complex_function do
      with {:ok, state} <- S.create(),
           {:ok, updated} <- S.update(state, :field, "value") do
        %S{entities: updated.entities}
      end
    end
  end
  """
  
  {:ok, result} = AstMigrate.Rules.StateV2ToState.transform_file_content(input_code)
  
  # Verify the result is valid Elixir syntax
  assert {:ok, _ast} = Code.string_to_quoted(result)
  
  # Verify transformations occurred
  assert result =~ "alias AriaEngine.State, as: S"
  refute result =~ "StateV2"
end
```

### **Edge Cases and Error Handling**

**Malformed AST Handling**

```elixir
test "handles malformed AST gracefully" do
  # Test with invalid/incomplete AST structures
  malformed_ast = {:invalid_node, []}
  
  result = AstMigrate.Rules.StateV2ToState.transform_ast(malformed_ast)
  # Should return the input unchanged rather than crashing
  assert result == malformed_ast
end
```

**Deeply Nested Structures**

```elixir
test "handles deeply nested structures" do
  input_ast = quote do
    case some_condition do
      true -> %StateV2{nested: %{deep: %StateV2{value: 1}}}
      false -> StateV2.create()
    end
  end
  
  result = AstMigrate.Rules.StateV2ToState.transform_ast(input_ast)
  result_string = Macro.to_string(result)
  
  # Should transform all StateV2 references, even deeply nested ones
  refute result_string =~ "StateV2"
  assert result_string =~ "%State{"
  assert result_string =~ "State.create"
end
```

**Nested AST Preservation**

```elixir
test "preserves unrelated AST nodes" do
  input_ast = quote do
    def process(data) do
      result = SomeOtherModule.function(data)
      %StateV2{entities: result}
    end
  end
  
  result = AstMigrate.Rules.StateV2ToState.transform_ast(input_ast)
  
  # Should only transform the StateV2 struct, leaving other code intact
  assert match?({:def, _, _}, result)
  # Verify SomeOtherModule.function call is preserved
  assert Macro.to_string(result) =~ "SomeOtherModule.function"
  # Verify StateV2 was transformed to State
  assert Macro.to_string(result) =~ "%State{"
  refute Macro.to_string(result) =~ "%StateV2{"
end
```

### **Property-Based Tests**

**AST Validity Property**

```elixir
@tag :property
property "transformed AST always produces valid Elixir code" do
  check all ast <- valid_elixir_ast_generator() do
    transformed = AstMigrate.Rules.StateV2ToState.transform_ast(ast)
    code_string = Macro.to_string(transformed)
    
    # Should always produce parseable Elixir code
    assert {:ok, _} = Code.string_to_quoted(code_string)
  end
end
```

**Transformation Idempotency**

```elixir
@tag :property
property "transformations are idempotent" do
  check all code <- valid_elixir_code_generator() do
    {:ok, first_pass} = AstMigrate.Rules.StateV2ToState.transform_file_content(code)
    {:ok, second_pass} = AstMigrate.Rules.StateV2ToState.transform_file_content(first_pass)
    
    # Second transformation should not change anything
    assert first_pass == second_pass
  end
end
```

### **Git Integration Tests**

**Commit Creation**

```elixir
test "creates proper Git commits for transformations" do
  repo = setup_test_repo()
  files = ["lib/test_module.ex"]
  message = "Convert StateV2 to State in test module"
  
  {:ok, commit} = AstMigrate.Git.commit_transformations(repo, message, files)
  
  assert commit.message == "[AST] #{message}"
  assert commit.author.name == "AST Migration Tool"
end
```

**Branch Management**

```elixir
test "creates and manages transformation branches" do
  repo = setup_test_repo()
  rule_name = "state_v2_to_state"
  
  {:ok, branch_name} = AstMigrate.Git.create_transformation_branch(repo, rule_name)
  
  assert branch_name =~ "ast-migration/#{rule_name}"
  assert {:ok, current_branch} = EGit.current_branch(repo)
  assert current_branch == branch_name
end
```

**Rollback Functionality**

```elixir
test "successfully rolls back transformations" do
  repo = setup_test_repo()
  original_content = File.read!("lib/test_module.ex")
  
  # Apply transformation and commit
  {:ok, commit} = apply_transformation_and_commit(repo, "state_v2_to_state")
  
  # Rollback
  {:ok, _revert_commit} = AstMigrate.Git.rollback_transformation(repo, commit.hash)
  
  # Verify content is restored
  rolled_back_content = File.read!("lib/test_module.ex")
  assert rolled_back_content == original_content
end
```

### **Test Coverage Requirements**

**Minimum Coverage Targets**:

- **AST Transformation Logic**: 95% line coverage
- **File Processing**: 90% line coverage  
- **Git Integration**: 85% line coverage
- **Error Handling**: 90% line coverage
- **Edge Cases**: 80% line coverage

**Test Categories**:

- **Unit Tests**: Individual function testing (60% of test suite)
- **Integration Tests**: Component interaction testing (25% of test suite)
- **Property Tests**: Invariant verification (10% of test suite)
- **End-to-End Tests**: Complete workflow testing (5% of test suite)

This comprehensive unit testing strategy ensures the AST migration tool is robust, reliable, and maintains code quality throughout all transformations.

## Monitoring and Success Metrics

### **Transformation Quality**

- Syntax validity rate: 100% (target)
- Semantic preservation: 95% (measured by test pass rate)
- Confidence score accuracy: 90% (predicted vs actual success)
- Manual review rate: <10% (transformations requiring human input)

### **Performance Metrics**

- Processing speed: <2s per file (target for complex AST work)
- Memory usage: <200MB for 1000 files (realistic for AST processing)
- Changeset creation time: <5s for typical changeset
- Rollback speed: <1s per changeset

### **Usability Metrics**

- Developer adoption rate (usage frequency)
- Time to configure new rules: <5 minutes (target)
- Error recovery success rate: 95% (target)
- User satisfaction scores from team feedback

### **System Reliability**

- Data corruption rate: 0% (absolute requirement)
- Changeset failure rate: <1% (target)
- Rollback success rate: 100% (target)
- System uptime during migrations: 99.9% (target)

## Related ADRs

- **ADR-052**: Replace Membrane with Flow (context for architecture evolution)
- **ADR-146**: Replace AriaEngine StateV2 with State (primary immediate use case)
- **ADR-022**: Test-Driven Development (methodology alignment)
- **ADR-147**: Fix warnings and failures (current manual approach limitations)

## Immediate Next Steps

1. **Week 1**: Implement Phase 0 simple tool for StateV2→State migration with Git integration
2. **Week 2-3**: Build Phase 1 Git-integrated AST foundation with comprehensive tests
3. **Week 4-5**: Implement Phase 2 branch-based transformation workflows
4. **Week 6**: Add Phase 3 production features and optimization

**Total: 6 weeks** (reduced from 10+ weeks by leveraging Git instead of custom version control)

## Future Considerations

- Integration with language servers for real-time suggestions
- Machine learning for automatic rule generation from examples
- Distributed processing for extremely large codebases
- Integration with code review tools for transformation approval workflows
- Community marketplace for sharing transformation rules

---

**This ADR provides the definitive blueprint for a production-ready, Git-style AST migration tool that will revolutionize large-scale Elixir refactoring while delivering immediate value for our current StateV2 migration needs.**
