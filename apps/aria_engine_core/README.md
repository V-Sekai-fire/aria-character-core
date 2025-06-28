# AriaEngineCore

AriaEngineCore provides the core planning functionality for the Aria planning system with Mox-based dependency injection for improved testability.

## Overview

This module implements a clean, GTpyHOP-style interface for planning operations while maintaining separation from internal dependencies through dependency injection. The implementation follows ADR R25W1398085 specification.

## Architecture

### Dependency Injection Pattern

AriaEngineCore uses a behavior-based dependency injection pattern that allows for:

- **Unit testing without heavy dependencies**: Tests can run with mocked implementations
- **Clean separation of concerns**: Core logic is separated from external API calls
- **Flexible adapter implementations**: Easy to swap implementations for different environments

### Key Components

#### 1. Behaviors (`lib/aria_engine_core/behaviours/`)

- **`PlannerBehaviour`**: Defines the interface for planning operations
  - `new_coordinator/0` - Create coordinator instances
  - `plan/4` - Generate plans for achieving goals
  - `execute/4` - Execute plans and return final states

#### 2. Adapters (`lib/aria_engine_core/adapters/`)

- **`HybridPlannerAdapter`**: Production adapter wrapping `AriaHybridPlanner.Core`
  - Implements `PlannerBehaviour`
  - Provides error handling and logging
  - Translates exceptions to standardized error tuples

#### 3. Mocks (`test/mocks/`)

- **`PlannerMock`**: Mox-based mock for testing
- **`PlannerMockHelpers`**: Utilities for setting up common test scenarios

## Usage

### Basic Planning Operations

```elixir
# Plan without execution
{:ok, solution_tree} = AriaEngineCore.plan(domain, state, goals)

# Plan and execute with recovery
{:ok, {final_state, solution_tree}} = AriaEngineCore.run_lazy(domain, state, goals)

# Execute pre-made solution tree
{:ok, {final_state, updated_tree}} = AriaEngineCore.run_lazy_tree(domain, state, solution_tree)
```

### Configuration

The planner adapter is configured through application configuration:

```elixir
# config/prod.exs
config :aria_engine_core,
  planner_adapter: AriaEngineCore.Adapters.HybridPlannerAdapter

# config/test.exs
config :aria_engine_core,
  planner_adapter: AriaEngineCore.Mocks.PlannerMock
```

## Testing

### Unit Testing with Mocks

AriaEngineCore provides comprehensive testing utilities using Mox:

```elixir
defmodule MyTest do
  use ExUnit.Case, async: true
  import Mox
  import AriaEngineCore.Mocks.PlannerMockHelpers

  setup :verify_on_exit!

  test "successful planning" do
    expect_successful_planning()
    
    {:ok, solution_tree} = AriaEngineCore.plan(domain, state, goals)
    assert solution_tree != nil
  end

  test "planning failure handling" do
    expect_planning_failure(:no_solution_found)
    
    {:error, :planning_failed} = AriaEngineCore.plan(domain, state, goals)
  end
end
```

### Mock Helper Functions

The `PlannerMockHelpers` module provides convenient functions for common test scenarios:

- `expect_successful_planning/1` - Mock successful planning and execution
- `expect_planning_failure/2` - Mock planning failure with specific reason
- `expect_execution_failure/2` - Mock execution failure with specific reason
- `expect_coordinator_creation_failure/1` - Mock coordinator creation failure
- `expect_custom_planning/3` - Mock with custom plan data
- `expect_multiple_planning_calls/2` - Mock multiple planning attempts

### Test Configuration

Tests automatically use the mock adapter through configuration:

```elixir
# test/test_helper.exs
Mox.defmock(AriaEngineCore.Mocks.PlannerMock,
  for: AriaEngineCore.Behaviours.PlannerBehaviour)

ExUnit.start()
```

## Benefits

### Testing Improvements

- **Fast unit tests**: No need to spin up heavy internal dependencies
- **Controllable scenarios**: Mock expectations allow testing specific failure modes
- **Isolated testing**: Tests don't interfere with each other through shared state
- **Comprehensive coverage**: Easy to test edge cases and error conditions

### Architecture Benefits

- **Clear interfaces**: Behavior contracts define exact API requirements
- **Loose coupling**: Core logic doesn't depend directly on internal implementations
- **Easy maintenance**: Changes to internal APIs only require adapter updates
- **Better error handling**: Consistent error patterns across all implementations

### Development Benefits

- **Faster feedback**: Tests run quickly during development
- **Easier debugging**: Clear separation between core logic and external calls
- **Flexible deployment**: Different adapters for different environments
- **Better documentation**: Behaviors serve as living API documentation

## Implementation Details

### Error Handling

All adapters follow consistent error handling patterns:

```elixir
# Success cases
{:ok, result} = adapter.plan(coordinator, domain, state, goals)

# Error cases
{:error, :planning_failed} = adapter.plan(coordinator, domain, state, goals)
{:error, :execution_failed} = adapter.execute(coordinator, domain, state, plan)
```

### Logging

Adapters provide comprehensive logging for debugging:

```elixir
Logger.debug("Starting hybrid planning for #{length(goals)} goals")
Logger.warn("Hybrid planning failed: #{inspect(reason)}")
Logger.error("Hybrid planning error: #{inspect(error)}")
```

### Type Safety

All behaviors include comprehensive typespecs:

```elixir
@callback plan(coordinator(), domain(), state(), goals()) :: 
  {:ok, plan()} | {:error, atom()}
```

## Migration from Direct Dependencies

The dependency injection system maintains full backward compatibility. Existing code continues to work without changes, while new tests can take advantage of the mocking capabilities.

### Before (Direct Dependencies)

```elixir
# Hard-coded dependency on AriaHybridPlanner.Core
coordinator = HybridCore.new_coordinator()
{:ok, plan} = HybridCore.plan(coordinator, domain, state, goals)
```

### After (Dependency Injection)

```elixir
# Configurable dependency through adapter
coordinator = @planner_adapter.new_coordinator()
{:ok, plan} = @planner_adapter.plan(coordinator, domain, state, goals)
```

## Future Extensions

The behavior-based architecture makes it easy to add new implementations:

- **Alternative planners**: Implement `PlannerBehaviour` for different planning algorithms
- **Caching adapters**: Add caching layers that implement the same behaviors
- **Monitoring adapters**: Wrap existing adapters with telemetry and metrics
- **Fallback adapters**: Implement adapters that try multiple strategies

## Dependencies

- **Mox**: For mock implementations in tests
- **Logger**: For comprehensive logging in adapters
- **AriaHybridPlanner**: Wrapped by the production adapter (not directly used by core)

## Related Documentation

- ADR R25W1398085: Unified Action Specification and Planner Standardization
- `AriaEngineCore.Behaviours.PlannerBehaviour`: Behavior contract documentation
- `AriaEngineCore.Adapters.HybridPlannerAdapter`: Production adapter implementation
- `AriaEngineCore.Mocks.PlannerMockHelpers`: Testing utilities documentation
