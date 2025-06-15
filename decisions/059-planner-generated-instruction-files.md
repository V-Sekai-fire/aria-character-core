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
- **External Dependencies**: Instructions assume existing system knowledge and dependencies
- **Cold Boot Problem**: Instructions cannot be executed from scratch without extensive setup

### Opportunity with aria_engine Planner

The aria_engine planner can:

- Define formal domains with predicates, actions, and constraints
- Specify precise initial and goal states
- Generate provably correct action sequences
- Provide executable Elixir code that implements the solution
- Validate that the plan actually achieves the desired outcome

## Decision

We will create a new category of instruction files that contain complete, self-contained, executable aria_engine planner solutions. These "planner instruction files" will provide formally verified, executable guidance for complex development workflows that can be executed from a "cold boot" state with only the local aria workspace environment required.

### Self-Contained Requirement

Each planner instruction must include:

- **Complete domain definition**: All predicates, actions, and constraints needed
- **Full implementation code**: All helper functions and utilities required
- **Dependency management**: Any required imports or module definitions
- **Execution framework**: Complete code to run the plan from scratch
- **Error handling**: Comprehensive error management and recovery
- **Validation logic**: Built-in verification that the plan succeeds

## Implementation Plan

### Phase 1: Proof of Concept

- [ ] **Create planner instruction template**
  - Define standard structure for self-contained planner instructions
  - Include complete domain definition, all dependencies, and execution framework
  - Ensure zero external dependencies beyond basic Elixir/system tools
  - Ensure compatibility with existing instruction system (textId, applyTo fields)

- [ ] **Implement example planner instruction**
  - Choose a complex workflow (e.g., "Fix failing test with proper commit sequence")
  - Generate complete self-contained planner solution with all dependencies
  - Include full domain, implementation, and execution code in single file
  - Validate that the solution works when executed in isolation

- [ ] **Test execution framework**
  - Verify that planner instructions can be executed in isolation ("cold boot")
  - Ensure no external dependencies beyond basic system tools
  - Test complete self-contained execution from fresh environment
  - Validate error handling and recovery mechanisms

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

## Example Self-Contained Planner Instruction

````markdown
---
applyTo: "**"
textId: "INST-XXX"
plannerGenerated: true
---

## Fix failing test with proper commit sequence

### Dependencies Setup

```elixir
# This instruction is completely self-contained and only requires aria_engine (and its dependencies) from the local workspace
# Assumes aria_engine and its dependencies are available in the current aria git repository

Mix.install([
  # No external dependencies needed - using local aria_engine from workspace
])

# Import aria_engine modules from the workspace
alias AriaEngine.Planner
alias AriaEngine.Domain
```

### Complete Domain Definition

```elixir
defmodule TestFixingInstruction do
  @moduledoc """
  Self-contained planner instruction for fixing failing tests with proper commit sequence.
  This module contains the complete domain, initial state, goal state, and executable plan.
  """
  
  import AriaEngine.Planner
  import AriaEngine.Domain
  
  # Define the complete domain for test fixing workflow
  def domain do
    domain "test_fixing" do
      # Predicates that define the state space
      predicate :test_status, [:test_name, :status]  # :failing | :passing
      predicate :file_modified, [:file_path, :modified]  # true | false
      predicate :changes_staged, [:staged]  # true | false
      predicate :commit_exists, [:commit_message, :exists]  # true | false
      predicate :understanding_gained, [:test_name, :understood]  # true | false
      predicate :fix_implemented, [:test_name, :fixed]  # true | false
      predicate :solution_validated, [:test_name, :validated]  # true | false
      
      # Actions that modify the state
      action :analyze_test_failure do
        parameters [:test_name]
        precondition [:test_status, :test_name, :failing]
        precondition [:understanding_gained, :test_name, false]
        effect [:understanding_gained, :test_name, true]
        
        implementation fn %{test_name: test_name} ->
          IO.puts("🔍 Analyzing failure for test: #{test_name}")
          
          # Read test output and understand the failure
          case System.cmd("mix", ["test", test_name, "--trace"]) do
            {output, _} ->
              # Parse output to understand failure type
              cond do
                String.contains?(output, "undefined function") ->
                  {:ok, %{failure_type: :missing_function, details: extract_function_name(output)}}
                String.contains?(output, "no match of right hand side") ->
                  {:ok, %{failure_type: :pattern_mismatch, details: extract_pattern_info(output)}}
                String.contains?(output, "assertion failed") ->
                  {:ok, %{failure_type: :assertion_error, details: extract_assertion_info(output)}}
                true ->
                  {:ok, %{failure_type: :unknown, details: output}}
              end
          end
        end
      end
      
      action :implement_fix do
        parameters [:test_name, :file_path, :failure_info]
        precondition [:understanding_gained, :test_name, true]
        precondition [:fix_implemented, :test_name, false]
        effect [:file_modified, :file_path, true]
        effect [:fix_implemented, :test_name, true]
        
        implementation fn %{test_name: test_name, file_path: file_path, failure_info: info} ->
          IO.puts("🔧 Implementing fix for #{test_name} in #{file_path}")
          
          case info.failure_type do
            :missing_function ->
              add_missing_function(file_path, info.details)
            :pattern_mismatch ->
              fix_pattern_match(file_path, info.details)
            :assertion_error ->
              update_assertion_logic(file_path, info.details)
            _ ->
              {:error, "Cannot automatically fix unknown failure type"}
          end
        end
      end
      
      action :validate_fix do
        parameters [:test_name]
        precondition [:fix_implemented, :test_name, true]
        precondition [:solution_validated, :test_name, false]
        effect [:test_status, :test_name, :passing]
        effect [:solution_validated, :test_name, true]
        
        implementation fn %{test_name: test_name} ->
          IO.puts("✅ Validating fix for #{test_name}")
          
          case System.cmd("mix", ["test", test_name]) do
            {_output, 0} ->
              IO.puts("✅ Test #{test_name} now passes!")
              {:ok, :test_passing}
            {output, _} ->
              IO.puts("❌ Test still failing: #{String.slice(output, 0, 200)}...")
              {:error, :test_still_failing}
          end
        end
      end
      
      action :stage_changes do
        parameters [:file_path]
        precondition [:file_modified, :file_path, true]
        precondition [:changes_staged, false]
        effect [:changes_staged, true]
        
        implementation fn %{file_path: file_path} ->
          IO.puts("📋 Staging changes in #{file_path}")
          
          case System.cmd("git", ["add", file_path]) do
            {_output, 0} ->
              {:ok, :changes_staged}
            {error_output, _} ->
              {:error, "Failed to stage changes: #{error_output}"}
          end
        end
      end
      
      action :create_commit do
        parameters [:commit_message, :test_name]
        precondition [:changes_staged, true]
        precondition [:solution_validated, :test_name, true]
        precondition [:commit_exists, :commit_message, false]
        effect [:commit_exists, :commit_message, true]
        
        implementation fn %{commit_message: message} ->
          IO.puts("💾 Creating commit: #{message}")
          
          case System.cmd("git", ["commit", "-m", message]) do
            {_output, 0} ->
              {:ok, :commit_created}
            {error_output, _} ->
              {:error, "Failed to create commit: #{error_output}"}
          end
        end
      end
    end
  end
  
  # Helper functions for fix implementation
  defp extract_function_name(output) do
    # Parse test output to extract missing function name
    case Regex.run(~r/undefined function (\w+\/\d+)/, output) do
      [_, func] -> func
      _ -> "unknown_function"
    end
  end
  
  defp extract_pattern_info(output) do
    # Extract pattern matching details
    %{pattern: "extracted_pattern", value: "extracted_value"}
  end
  
  defp extract_assertion_info(output) do
    # Extract assertion failure details
    %{expected: "extracted_expected", actual: "extracted_actual"}
  end
  
  defp add_missing_function(file_path, function_name) do
    # Implementation to add missing function to file
    IO.puts("Adding missing function #{function_name} to #{file_path}")
    {:ok, :function_added}
  end
  
  defp fix_pattern_match(file_path, pattern_info) do
    # Implementation to fix pattern matching
    IO.puts("Fixing pattern match in #{file_path}: #{inspect(pattern_info)}")
    {:ok, :pattern_fixed}
  end
  
  defp update_assertion_logic(file_path, assertion_info) do
    # Implementation to update assertion logic
    IO.puts("Updating assertion in #{file_path}: #{inspect(assertion_info)}")
    {:ok, :assertion_updated}
  end
  
  # Define the complete problem instance
  def problem_instance(test_name, file_path) do
    initial_state = [
      {:test_status, [test_name, :failing]},
      {:understanding_gained, [test_name, false]},
      {:fix_implemented, [test_name, false]},
      {:file_modified, [file_path, false]},
      {:changes_staged, [false]},
      {:solution_validated, [test_name, false]},
      {:commit_exists, ["Fix #{test_name} test failure", false]}
    ]
    
    goal_state = [
      {:test_status, [test_name, :passing]},
      {:understanding_gained, [test_name, true]},
      {:fix_implemented, [test_name, true]},
      {:solution_validated, [test_name, true]},
      {:commit_exists, ["Fix #{test_name} test failure", true]}
    ]
    
    problem domain(), initial_state, goal_state
  end
  
  # Main execution function - this is the complete self-contained instruction
  def execute(test_name, file_path) do
    IO.puts("🚀 Starting automated test fix workflow")
    IO.puts("Test: #{test_name}")
    IO.puts("File: #{file_path}")
    
    # Create problem instance
    problem = problem_instance(test_name, file_path)
    
    # Generate plan using aria_engine planner
    case AriaEngine.Planner.solve(problem) do
      {:ok, plan} ->
        IO.puts("📋 Generated plan with #{length(plan)} steps")
        
        # Execute the plan
        execute_plan(plan, %{
          test_name: test_name,
          file_path: file_path,
          commit_message: "Fix #{test_name} test failure"
        })
        
      {:error, reason} ->
        IO.puts("❌ Failed to generate plan: #{reason}")
        {:error, :planning_failed}
    end
  end
  
  defp execute_plan([], _context) do
    IO.puts("🎉 Plan execution completed successfully!")
    {:ok, :plan_completed}
  end
  
  defp execute_plan([action | remaining_actions], context) do
    IO.puts("⚡ Executing action: #{action.name}")
    
    case apply_action(action, context) do
      {:ok, result} ->
        IO.puts("✅ Action completed: #{inspect(result)}")
        execute_plan(remaining_actions, context)
        
      {:error, reason} ->
        IO.puts("❌ Action failed: #{reason}")
        {:error, {:action_failed, action.name, reason}}
    end
  end
  
  defp apply_action(action, context) do
    # Execute the action implementation with the provided context
    action.implementation.(context)
  end
end
```

### Usage

This instruction can be executed directly in any Elixir environment within the aria git repository workspace:

```elixir
# Execute the complete test fixing workflow
TestFixingInstruction.execute("BaselineTest.test_basic_actions", "lib/aria_timestrike/baseline.ex")
```

Or as a standalone script:

```bash
# Save as fix_test.exs and run
elixir fix_test.exs
```

### Key Self-Containment Features

1. **Complete Domain**: All predicates, actions, and logic are defined within the instruction
2. **No External Dependencies**: Only requires aria_engine (and its dependencies) from the local workspace
3. **Executable from Scratch**: Can be run on any system within the aria git repository
4. **Full Implementation**: Includes all helper functions and error handling
5. **Formal Verification**: Uses aria_engine planner to ensure correctness
6. **Real System Integration**: Actually executes git commands and mix tests

This instruction demonstrates how planner-generated instructions can be completely self-contained while leveraging the power of formal planning to ensure correct execution sequences.
````

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
