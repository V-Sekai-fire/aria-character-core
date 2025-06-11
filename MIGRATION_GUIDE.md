# AriaEngine Domain Definition Migration Guide

This guide explains the migration from the old WorkflowDefinition/WorkflowExecution system to the new unified AriaEngine.DomainDefinition approach.

## Key Insight: Todo Execution IS Span Tracing

The breakthrough insight is that span-based tracing is fundamentally just todo execution tracking:

- **Spans** = Individual todo items being executed
- **Span hierarchy** = Todo dependencies and nesting  
- **Span start/end times** = Todo execution lifecycle
- **Span context** = State passing between todos
- **Trace** = Complete execution path through todos

This eliminates the need for separate span infrastructure - the domain execution state IS the trace.

## What's Deprecated

❌ **AriaWorkflow.WorkflowDefinition** - Separate structure  
❌ **AriaWorkflow.WorkflowExecution** - Redundant span tracking  
❌ **AriaWorkflow.Span** - Separate span infrastructure  
❌ **AriaWorkflow.WorkflowEngine** - Complex execution framework  

## What's New

✅ **AriaEngine.DomainDefinition** - Unified capabilities + execution + tracing  

## Migration Examples

### Old Approach (Deprecated)
```elixir
# Create workflow definition
workflow = AriaWorkflow.WorkflowDefinition.new("my_workflow", %{
  goals: [{"system", "ready", true}],
  tasks: [{"setup_task", &MyModule.setup/2}],
  actions: [{:echo, &Actions.echo/2}]
})

# Plan execution
{:ok, execution} = AriaWorkflow.WorkflowEngine.plan_workflow(workflow, initial_state)

# Execute with separate span tracking
:ok = AriaWorkflow.WorkflowEngine.execute_plan(execution)
```

### New Approach (Recommended)
```elixir
# Create unified domain definition
domain_def = AriaEngine.DomainDefinition.new("my_domain", %{
  name: "My Domain",
  todos: [
    {:echo, ["Starting"]},               # Action
    {"system", "ready", true},           # Goal
    {"setup_task", []},                  # Task
    {:echo, ["Completed"]}               # Action
  ],
  actions: %{echo: &Actions.echo/2},
  task_methods: %{"setup_task" => [&MyModule.setup/2]},
  initial_state: State.new()
})

# Start execution (automatically creates trace_id and first span)
started = AriaEngine.DomainDefinition.start(domain_def)

# Execute todos with built-in span tracing
final = todos
|> Enum.reduce(started, fn _todo, acc ->
  # Each todo completion automatically manages spans
  AriaEngine.DomainDefinition.complete_current_todo(acc)
end)

# Complete execution
completed = AriaEngine.DomainDefinition.complete(final)

# Get comprehensive summary with trace information
summary = AriaEngine.DomainDefinition.get_summary(completed)
trace_log = AriaEngine.DomainDefinition.get_trace_log(completed)
```

## Key Benefits

1. **Unified Architecture**: Single structure combining capabilities, planning, and execution
2. **Built-in Tracing**: Todo execution state IS the trace - no redundant infrastructure
3. **Flexible Planning**: Goals, tasks, and actions can be mixed in any order
4. **Simplified API**: One structure to rule them all
5. **Better Performance**: Less overhead without separate span management

## Testing Migration

Old tests can be migrated by:

1. Replace `WorkflowDefinition.new` with `DomainDefinition.new`
2. Replace workflow execution with domain execution + todo completion
3. Use built-in span context instead of separate span assertions
4. Test trace logs and summaries instead of separate span data

## Running Tests

```bash
# Test the new unified approach
cd apps/aria_engine
mix test test/domain_definition_test.exs
mix test test/domain_action_integration_test.exs

# Legacy tests still work but are deprecated
cd apps/aria_workflow  
mix test  # Shows deprecation warnings
```

## Architecture Benefits

The new unified approach eliminates conceptual overhead:

- **Before**: Domain capabilities + WorkflowDefinition + WorkflowExecution + Span tracking
- **After**: DomainDefinition (capabilities + todos + execution state + built-in tracing)

This is a simpler, more elegant architecture that treats todo execution as the natural trace of work being done.
