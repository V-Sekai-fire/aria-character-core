# ADR-059: Planner-Generated Instruction Files

## Status

Proposed (Draft: June 15, 2025)
**Priority**: Experimental - exploring AI-assisted instruction generation

## Context

The current instruction system relies on manually written guidelines that describe best practices and workflows. However, our aria_engine planner system has the capability to generate complete, formal solutions with domain definitions, initial states, goal states, and executable action sequences.

### Current Instruction Limitations

- **Manual Creation**: Instructions are written by hand based on experience and judgment
- **Informal Structure**: Current instructions use natural language without formal verification
- **No Execution Model**: Instructions describe what to do but cannot be directly executed
- **Limited Validation**: No way to verify that following instructions actually achieves desired outcomes

### Opportunity with aria_engine Planner

The aria_engine planner can:

- Define formal domains with predicates, actions, and constraints
- Specify precise initial and goal states
- Generate provably correct action sequences
- Provide executable Elixir code that implements the solution
- Validate that the plan actually achieves the desired outcome

## Decision

We will create a new category of instruction files that contain complete, executable aria_engine planner solutions. These "planner instruction files" will provide formally verified, executable guidance for complex development workflows.

## Implementation Plan

### Phase 1: Proof of Concept

- [ ] **Create planner instruction template**

  - Define standard structure for planner-generated instructions
  - Include domain definition, states, problem specification, and solution
  - Ensure compatibility with existing instruction system (textId, applyTo fields)

- [ ] **Implement example planner instruction**

  - Choose a complex workflow (e.g., "Fix failing test with proper commit sequence")
  - Generate complete planner solution with executable Elixir code
  - Validate that the solution actually works when executed

- [ ] **Test execution framework**
  - Verify that planner instructions can be executed directly
  - Ensure proper error handling and validation
  - Test integration with existing development workflows

### Phase 2: Integration and Validation

- [ ] **Create planner instruction generator**

  - Tool to convert problem descriptions into planner instruction files
  - Automated domain generation for common development scenarios
  - Integration with existing instruction creation workflow

- [ ] **Validate against real scenarios**
  - Test planner instructions on actual development tasks
  - Compare outcomes with manually written instructions
  - Measure effectiveness and correctness

### Phase 3: Documentation and Adoption

- [ ] **Document planner instruction format**

  - Clear specification for planner instruction structure
  - Guidelines for when to use planner vs. manual instructions
  - Integration with existing instruction guidelines

- [ ] **Training and adoption**
  - Update development workflow to support planner instructions
  - Create examples and templates for common scenarios
  - Establish maintenance procedures for planner instructions

## Example Planner Instruction Structure

````markdown
---
applyTo: "**"
textId: "INST-XXX"
plannerGenerated: true
---

## Fix failing test with proper commit sequence

### Problem Domain

```elixir
# Domain: Test Fixing Workflow
# This domain models the process of fixing a failing test with proper commit practices

defmodule TestFixingDomain do
  @moduledoc """
  Domain for fixing failing tests with proper commit sequence
  """

  # Predicates
  defp predicates do
    [
      # State predicates
      test_status: [:test_name, :status],  # status: :failing | :passing
      file_modified: [:file_path, :modified],  # modified: true | false
      changes_staged: [:staged],  # staged: true | false
      commit_exists: [:commit_message, :exists],  # exists: true | false

      # Process predicates
      understanding_gained: [:test_name, :understood],  # understood: true | false
      fix_implemented: [:test_name, :fixed],  # fixed: true | false
      solution_validated: [:test_name, :validated]  # validated: true | false
    ]
  end

  # Actions
  def actions do
    [
      # Analysis actions
      analyze_test_failure: %{
        preconditions: [
          {:test_status, [:test_name, :failing]},
          {:understanding_gained, [:test_name, false]}
        ],
        effects: [
          {:understanding_gained, [:test_name, true]}
        ],
        implementation: &analyze_test_failure_impl/1
      },

      # Fix implementation
      implement_fix: %{
        preconditions: [
          {:understanding_gained, [:test_name, true]},
          {:fix_implemented, [:test_name, false]}
        ],
        effects: [
          {:file_modified, [:file_path, true]},
          {:fix_implemented, [:test_name, true]}
        ],
        implementation: &implement_fix_impl/1
      },

      # Validation
      run_test: %{
        preconditions: [
          {:fix_implemented, [:test_name, true]},
          {:solution_validated, [:test_name, false]}
        ],
        effects: [
          {:test_status, [:test_name, :passing]},
          {:solution_validated, [:test_name, true]}
        ],
        implementation: &run_test_impl/1
      },

      # Commit sequence
      stage_changes: %{
        preconditions: [
          {:file_modified, [:file_path, true]},
          {:changes_staged, [false]}
        ],
        effects: [
          {:changes_staged, [true]}
        ],
        implementation: &stage_changes_impl/1
      },

      create_commit: %{
        preconditions: [
          {:changes_staged, [true]},
          {:solution_validated, [:test_name, true]},
          {:commit_exists, [:commit_message, false]}
        ],
        effects: [
          {:commit_exists, [:commit_message, true]}
        ],
        implementation: &create_commit_impl/1
      }
    ]
  end

  # Action implementations
  defp analyze_test_failure_impl(%{test_name: test_name}) do
    # Read test file and analyze failure
    IO.puts("Analyzing failure for test: #{test_name}")
    # Implementation would examine test output, read relevant code
    {:ok, "Test failure analyzed"}
  end

  defp implement_fix_impl(%{test_name: test_name, file_path: file_path}) do
    # Apply the specific fix based on analysis
    IO.puts("Implementing fix for #{test_name} in #{file_path}")
    # Implementation would modify the actual file
    {:ok, "Fix implemented"}
  end

  defp run_test_impl(%{test_name: test_name}) do
    # Execute the test to validate fix
    case System.cmd("mix", ["test", "--only", test_name]) do
      {output, 0} ->
        IO.puts("Test passed: #{output}")
        {:ok, "Test validated"}
      {output, _} ->
        {:error, "Test still failing: #{output}"}
    end
  end

  defp stage_changes_impl(%{file_path: file_path}) do
    case System.cmd("git", ["add", file_path]) do
      {_, 0} -> {:ok, "Changes staged"}
      {error, _} -> {:error, "Failed to stage: #{error}"}
    end
  end

  defp create_commit_impl(%{commit_message: message}) do
    case System.cmd("git", ["commit", "-m", message]) do
      {_, 0} -> {:ok, "Commit created"}
      {error, _} -> {:error, "Failed to commit: #{error}"}
    end
  end
end
```
````

### Initial State

```elixir
initial_state = [
  # Test is currently failing
  {:test_status, ["BaselineTest.test_basic_actions", :failing]},

  # No understanding of the problem yet
  {:understanding_gained, ["BaselineTest.test_basic_actions", false]},

  # No fix implemented
  {:fix_implemented, ["BaselineTest.test_basic_actions", false]},

  # Files not modified
  {:file_modified, ["lib/aria_timestrike/baseline.ex", false]},

  # No changes staged
  {:changes_staged, [false]},

  # Solution not validated
  {:solution_validated, ["BaselineTest.test_basic_actions", false]},

  # No commit exists
  {:commit_exists, ["Fix BaselineTest basic actions test failure", false]}
]
```

### Goal State

```elixir
goal_state = [
  # Test is now passing
  {:test_status, ["BaselineTest.test_basic_actions", :passing]},

  # Understanding was gained
  {:understanding_gained, ["BaselineTest.test_basic_actions", true]},

  # Fix was implemented
  {:fix_implemented, ["BaselineTest.test_basic_actions", true]},

  # Solution was validated
  {:solution_validated, ["BaselineTest.test_basic_actions", true]},

  # Commit was created
  {:commit_exists, ["Fix BaselineTest basic actions test failure", true]}
]
```

### Generated Plan Solution

```elixir
# Execute this plan to fix the failing test with proper commit sequence
defmodule GeneratedPlan do
  def execute do
    test_name = "BaselineTest.test_basic_actions"
    file_path = "lib/aria_timestrike/baseline.ex"
    commit_message = "Fix BaselineTest basic actions test failure"

    # Step 1: Analyze the test failure
    IO.puts("Step 1: Analyzing test failure...")
    TestFixingDomain.analyze_test_failure(%{test_name: test_name})

    # Step 2: Implement the fix
    IO.puts("Step 2: Implementing fix...")
    TestFixingDomain.implement_fix(%{test_name: test_name, file_path: file_path})

    # Step 3: Validate the solution
    IO.puts("Step 3: Validating solution...")
    case TestFixingDomain.run_test(%{test_name: test_name}) do
      {:ok, _} ->
        IO.puts("✓ Test now passes")

        # Step 4: Stage changes
        IO.puts("Step 4: Staging changes...")
        TestFixingDomain.stage_changes(%{file_path: file_path})

        # Step 5: Create commit
        IO.puts("Step 5: Creating commit...")
        TestFixingDomain.create_commit(%{commit_message: commit_message})

        IO.puts("✓ Test fix completed with proper commit sequence")

      {:error, reason} ->
        IO.puts("✗ Test still failing: #{reason}")
        {:error, "Fix validation failed"}
    end
  end
end

# Execute the plan
GeneratedPlan.execute()
```

### Usage

This instruction can be executed directly:

```bash
# Save the plan as a .exs file and execute
mix run fix_baseline_test_plan.exs
```

Or integrated into development workflow:

```elixir
# Load and execute within existing development context
Code.eval_file("fix_baseline_test_plan.exs")
```

```

## Consequences

### Positive

- **Formal Verification**: Instructions are mathematically proven to achieve their goals
- **Executable Guidance**: Instructions can be directly executed, not just read
- **Precise Specification**: No ambiguity about what needs to be done or achieved
- **Automated Validation**: Can verify that following instructions actually works
- **Consistent Quality**: AI-generated instructions follow consistent patterns
- **Complex Workflow Support**: Can handle multi-step, interdependent processes

### Negative

- **Implementation Complexity**: Requires significant infrastructure to support
- **Learning Curve**: Team must understand planner concepts and Elixir execution
- **Maintenance Overhead**: Planner instructions may be harder to modify than text
- **Tool Dependencies**: Requires aria_engine planner to be functional
- **Limited Scope**: May not be suitable for all types of guidance

### Risks

- **Over-Engineering**: May be too complex for simple instructions
- **Planner Limitations**: aria_engine planner may not handle all scenarios
- **Execution Safety**: Automatically executing code could cause system issues
- **Domain Modeling**: Accurately modeling development workflows may be challenging

## Success Criteria

- Planner instruction template is defined and documented
- At least one complex workflow is successfully modeled and executed
- Generated plans actually solve real development problems
- Integration with existing instruction system works seamlessly
- Team can create and maintain planner instructions effectively

## Monitoring

- Track accuracy of planner-generated solutions
- Measure development time savings from executable instructions
- Monitor adoption rate and developer feedback
- Assess maintenance burden compared to manual instructions

## Related ADRs

- **ADR-057**: Test Cleanup and Code Maintenance Plan (potential application area)
- **ADR-058**: Resolve aria_timestrike BaselineTest Failures (could be solved with planner instruction)
- **ADR-034**: Definitive Temporal Planner Architecture (underlying planner system)

## Next Steps

1. **Validate concept** with simple example planner instruction
2. **Test execution framework** in development environment
3. **Gather feedback** from team on approach and utility
4. **Decide on advancement** to full implementation or alternative approach

This ADR represents an experimental approach to combining formal planning with practical development guidance. The concept requires validation before proceeding to full implementation.
```
